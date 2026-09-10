/*
 * ============================================================================
 * ProcessAutomationService
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 7 - Processes & Automation]
 *
 * WHAT THIS CLASS DOES:
 * Demonstrates programmatic APPROVAL PROCESS and automation logic in Apex.
 * The class contains the Apex side of the "Opportunity Discount Approval"
 * approval process, plus utilities for:
 *   - Submitting / recalling approvals
 *   - Querying approval status
 *   - Bulk approving / rejecting work items
 *   - Auto-closing stale opportunities (with notification tasks)
 *   - Sending pipeline summary emails
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Approval API - `Approval.ProcessSubmitRequest`, `Approval.process()`,
 *    `Approval.ProcessWorkitemRequest` etc. This is how approval processes
 *    are executed programmatically instead of clicking "Submit for Approval".
 *
 * 2. ProcessInstance / ProcessInstanceStep / ProcessInstanceWorkitem - the
 *    system objects that store approval metadata (history of each approval).
 *
 * 3. Custom exception - `ApprovalException extends Exception` gives the
 *    class its own named exception type so callers can catch it specifically.
 *
 * 4. Email via Messaging API - `Messaging.SingleEmailMessage`.
 * 5. Bulk processing - looping requests into a list, then ONE `Approval.process(requests)`.
 * ============================================================================
 */
public with sharing class ProcessAutomationService {

    /*
     * submitForApproval(Id opportunityId, String comments)
     * ----------------------------------------------------------------------
     * PURPOSE: Programmatically submit an Opportunity into the
     * "Opportunity_Discount_Approval" approval process.
     *
     * STEPS:
     *   1. Build an Approval.ProcessSubmitRequest
     *   2. Point it at the object (setObjectId) and process name
     *   3. Call Approval.process(req) which returns a ProcessResult
     *   4. Throw a custom exception if submission failed
     * ----------------------------------------------------------------------
     */
    public static void submitForApproval(Id opportunityId, String comments) {
        // 1) Build the submission request
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(opportunityId);
        req.setComments(comments);
        req.setProcessDefinitionNameOrId('Opportunity_Discount_Approval');
        req.setSkipEntryCriteria(false);   // evaluate the entry criteria in the process

        // 2) Submit - this performs the actual DML
        Approval.ProcessResult result = Approval.process(req);

        // 3) Check outcome
        if (!result.isSuccess()) {
            throw new ApprovalException('Approval submission failed: ' + result.getErrors()[0].getMessage());
        }
    }

    /*
     * recallApproval(Id opportunityId)
     * ----------------------------------------------------------------------
     * PURPOSE: Withdraw a PENDING approval (e.g. the rep realized the
     * discount was wrong and wants to fix it before the manager reviews).
     *
     * APPROACH:
     *   1. Find the pending ProcessInstance for the opportunity (SOQL)
     *   2. Build an Approval.ProcessRecallRequest + set its IDs
     *   3. Approval.recall(req)
     * ----------------------------------------------------------------------
     */
    public static void recallApproval(Id opportunityId) {
        List<ProcessInstance> pendingApprovals = [
            SELECT Id, TargetObjectId
            FROM ProcessInstance
            WHERE TargetObjectId = :opportunityId
            AND Status = 'Pending'
        ];

        if (!pendingApprovals.isEmpty()) {
            Approval.ProcessRecallRequest req = new Approval.ProcessRecallRequest();
            req.setProcessInstanceIds(new List<Id>{pendingApprovals[0].Id});
            req.setComments('Recalled by user');

            Approval.recall(req);
        }
    }

    /*
     * getApprovalStatuses(Set<Id> opportunityIds)
     * ----------------------------------------------------------------------
     * PURPOSE: Return the latest approval status for each opportunity.
     * Uses ProcessInstance + its child Steps subquery to find the most
     * recent step (approver, status, comments).
     *
     * NOTE: Uses first entry in the Map; because we ORDER BY CreatedDate
     * DESC, the first instance found for a target object is the most recent.
     * ----------------------------------------------------------------------
     */
    public static Map<Id, ApprovalStatus> getApprovalStatuses(Set<Id> opportunityIds) {
        Map<Id, ApprovalStatus> statusMap = new Map<Id, ApprovalStatus>();

        List<ProcessInstance> instances = [
            SELECT Id, TargetObjectId, Status, CreatedDate,
                   (SELECT Id, ActorId, Comments, StepStatus, CreatedDate
                    FROM Steps
                    ORDER BY CreatedDate DESC)
            FROM ProcessInstance
            WHERE TargetObjectId IN :opportunityIds
            ORDER BY CreatedDate DESC
        ];

        for (ProcessInstance pi : instances) {
            // Only keep the newest instance per target object
            if (!statusMap.containsKey(pi.TargetObjectId)) {
                ApprovalStatus status = new ApprovalStatus();
                status.instanceId = pi.Id;
                status.overallStatus = pi.Status;
                status.submittedDate = pi.CreatedDate;

                // The first step (in DESC order) = most recent step
                if (!pi.Steps.isEmpty()) {
                    status.currentApprover = pi.Steps[0].ActorId;
                    status.lastStepStatus = pi.Steps[0].StepStatus;
                    status.lastComments = pi.Steps[0].Comments;
                }

                statusMap.put(pi.TargetObjectId, status);
            }
        }

        return statusMap;
    }

    /*
     * autoCloseStaleOpportunities(Integer staleDays)
     * ----------------------------------------------------------------------
     * PURPOSE: Close open opportunities with no activity for N days, and in
     * the SAME transaction create a Task telling the owner to review the
     * auto-close (they can reopen it if it was premature).
     * ----------------------------------------------------------------------
     */
    public static void autoCloseStaleOpportunities(Integer staleDays) {
        Date cutoffDate = Date.today().addDays(-staleDays);

        List<Opportunity> staleOpps = [
            SELECT Id, Name, StageName, LastActivityDate, OwnerId
            FROM Opportunity
            WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
            AND LastActivityDate < :cutoffDate
            AND LastActivityDate != NULL
        ];

        List<Task> notificationTasks = new List<Task>();

        for (Opportunity opp : staleOpps) {
            opp.StageName = 'Closed Lost';
            opp.Description = 'Auto-closed: No activity for ' + staleDays + ' days';

            notificationTasks.add(new Task(
                Subject = 'Review auto-closed opportunity: ' + opp.Name,
                WhatId = opp.Id,
                OwnerId = opp.OwnerId,
                ActivityDate = Date.today().addDays(1),
                Priority = 'Normal',
                Status = 'Not Started',
                Description = 'This opportunity was auto-closed due to inactivity. Please review and reopen if necessary.'
            ));
        }

        if (!staleOpps.isEmpty()) {
            update staleOpps;
            insert notificationTasks;
        }
    }

    /*
     * processBulkApproval(List<Id> opportunityIds, String action)
     * ----------------------------------------------------------------------
     * PURPOSE: Approve or reject MULTIPLE pending work items (opportunities)
     * in one call - e.g. an admin cleaning up a queue of discount requests.
     *
     * HOW:
     *   1. Query all pending ProcessInstanceWorkitem records for those targets
     *   2. Build an Approval.ProcessWorkitemRequest for EACH
     *   3. Call Approval.process(requests) with the LIST (bulk)
     *
     * NOTE: This pattern is N+1-safe because we find the work items in ONE
     * query and process them in ONE API call.
     * ----------------------------------------------------------------------
     */
    public static void processBulkApproval(List<Id> opportunityIds, String action) {
        // Same query is needed for both Approve and Reject; only the
        // request action + comments differ.
        if (action == 'Approve') {
            processWorkItems(opportunityIds, 'Approve', 'Bulk approved by admin');
        } else if (action == 'Reject') {
            processWorkItems(opportunityIds, 'Reject', 'Bulk rejected by admin');
        }
    }

    // Private helper that builds requests and submits them in a batch
    private static void processWorkItems(List<Id> opportunityIds, String action, String comments) {
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();

        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId IN :opportunityIds
            AND ProcessInstance.Status = 'Pending'
        ];

        for (ProcessInstanceWorkitem wi : workItems) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkItemId(wi.Id);
            req.setAction(action);
            req.setComments(comments);
            requests.add(req);
        }

        if (!requests.isEmpty()) {
            Approval.process(requests);
        }
    }

    /*
     * sendPipelineSummaryEmail(Id userId)
     * ----------------------------------------------------------------------
     * PURPOSE: Compose and send the user an email summarizing their TOP 10
     * open opportunities (sorted by amount).
     *
     * KEY: Messaging.SingleEmailMessage + Messaging.sendEmail()
     * Note the SOQL-in-for-loop alternative avoided here - we use a single
     * query. The user's email is fetched only when needed.
     * ----------------------------------------------------------------------
     */
    public static void sendPipelineSummaryEmail(Id userId) {
        List<Opportunity> openOpps = [
            SELECT Name, Amount, StageName, CloseDate
            FROM Opportunity
            WHERE OwnerId = :userId
            AND StageName NOT IN ('Closed Won', 'Closed Lost')
            ORDER BY Amount DESC
            LIMIT 10
        ];

        if (openOpps.isEmpty()) return;

        Decimal totalPipeline = 0;
        String body = 'Your Top Open Opportunities:\n\n';

        for (Opportunity opp : openOpps) {
            totalPipeline += opp.Amount != null ? opp.Amount : 0;
            body += opp.Name + ' - $' + (opp.Amount != null ? opp.Amount.setScale(0).format() : '0') +
                    ' (' + opp.StageName + ') - Close: ' + opp.CloseDate.format() + '\n';
        }

        body += '\nTotal Pipeline: $' + totalPipeline.setScale(0).format();

        // Build and send the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{[SELECT Email FROM User WHERE Id = :userId].Email});
        email.setSubject('Your Weekly Pipeline Summary');
        email.setPlainTextBody(body);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }

    /*
     * ApprovalStatus  [INNER CLASS - DATA HOLDER]
     * ----------------------------------------------------------------------
     * PURPOSE: A simple data wrapper used to return the approval info of one
     * opportunity from getApprovalStatuses(). Better than returning raw
     * ProcessInstance records because it hides platform internals from callers.
     * ----------------------------------------------------------------------
     */
    public class ApprovalStatus {
        public Id instanceId;
        public String overallStatus;
        public Datetime submittedDate;
        public Id currentApprover;
        public String lastStepStatus;
        public String lastComments;
    }

    /*
     * ApprovalException  [CUSTOM EXCEPTION]
     * ----------------------------------------------------------------------
     * PURPOSE: A dedicated exception type so callers can differentiate
     * errors coming from this service from generic Apex exceptions.
     * Usage: `throw new ApprovalException('...')` inside this class.
     * ----------------------------------------------------------------------
     */
    public class ApprovalException extends Exception {}
}