/*
 * ============================================================================
 * CampaignService
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 5 - Campaigns & Marketing]
 *
 * WHAT THIS CLASS DOES:
 * Business logic for Marketing Campaigns in Salesforce.
 * Called from OpportunityTrigger (deal-close automation) and
 * TaskActivityTrigger (activity-to-campaign attribution).
 *
 * RESPONSIBILITIES:
 *   - Add contacts to campaigns when their deals close (win attribution)
 *   - Mark campaign members as "Responded" when sales activity happens
 *   - Compute campaign KPIs: members, response/conversion rate, revenue,
 *     ROI, budget usage, cost per lead.
 *   - Bulk-add members from a dynamic SOQL filter
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Dynamic SOQL with Database.query() - building a query string at runtime.
 *    CAREFUL: only safe to use where the filter comes from a trusted source
 *    (avoid SOQL injection in real code!).
 *
 * 2. Set of String "keys" to deduplicate - combining two Ids
 *    (ContactId + '-' + CampaignId) into a unique string to prevent
 *    duplicate campaign members.
 *
 * 3. Cross-object queries - parsing `CampaignMember.Contact.AccountId`
 *    traverses Contact to reach the Account.
 *
 * 4. Guarding with early returns - e.g. `if (accountIds.isEmpty()) return;`
 * ============================================================================
 */
public with sharing class CampaignService {

    /*
     * addContactsToCampaignOnDealClose(List<Opportunity> opportunities)
     * ----------------------------------------------------------------------
     * PURPOSE: When an Opportunity becomes Closed Won, automatically enroll
     * the winning Account's contacts as members of campaigns that were
     * involved in that deal (as "Responded" members). This gives marketing
     * credit/influence attribution for the revenue generated.
     *
     * STEPS:
     *   1. Collect the accounts behind won deals
     *   2. Find which campaigns their contacts already belong to
     *   3. Find all contacts on those accounts
     *   4. Create CampaignMember records ONLY where they don't already exist
     * ----------------------------------------------------------------------
     */
    public static void addContactsToCampaignOnDealClose(List<Opportunity> opportunities) {
        Set<Id> campaignIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        // Step 1: only interested in won deals with an account attached
        for (Opportunity opp : opportunities) {
            if (opp.StageName == 'Closed Won' && opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }

        if (accountIds.isEmpty()) return;

        // accountToCampaigns: for each AccountId, the set of Campaigns
        // that this account's contacts already belong to
        Map<Id, Set<Id>> accountToCampaigns = new Map<Id, Set<Id>>();
        List<CampaignMember> membersToAdd = new List<CampaignMember>();

        // Step 2: query existing memberships for those accounts.
        // `cm.Contact.AccountId` traverses the Contact lookup to reach Account.
        for (CampaignMember cm : [
            SELECT ContactId, Contact.AccountId, CampaignId
            FROM CampaignMember
            WHERE Contact.AccountId IN :accountIds
        ]) {
            if (!accountToCampaigns.containsKey(cm.Contact.AccountId)) {
                accountToCampaigns.put(cm.Contact.AccountId, new Set<Id>());
            }
            accountToCampaigns.get(cm.Contact.AccountId).add(cm.CampaignId);
        }

        // Step 3: all contacts on those accounts
        List<Contact> contacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
        ];

        // Build a set of existing member "keys" for deduplication.
        // Key = ContactId + '-' + CampaignId
        Set<Id> existingMemberKeys = new Set<Id>();
        for (CampaignMember cm : [
            SELECT ContactId, CampaignId
            FROM CampaignMember
            WHERE Contact.AccountId IN :accountIds
        ]) {
            existingMemberKeys.add(cm.ContactId + '-' + cm.CampaignId);
        }

        // Step 4: create members only where we don't already have one
        for (Contact c : contacts) {
            if (accountToCampaigns.containsKey(c.AccountId)) {
                for (Id campaignId : accountToCampaigns.get(c.AccountId)) {
                    String key = c.Id + '-' + campaignId;
                    if (!existingMemberKeys.contains(key)) {
                        membersToAdd.add(new CampaignMember(
                            ContactId = c.Id,
                            CampaignId = campaignId,
                            Status = 'Responded'
                        ));
                    }
                }
            }
        }

        if (!membersToAdd.isEmpty()) {
            insert membersToAdd;
        }
    }

    /*
     * updateMemberStatusOnActivity(List<Task> tasks)
     * ----------------------------------------------------------------------
     * PURPOSE: If a sales rep logs an activity against a Contact that is a
     * campaign member with status "Sent", switch that member to "Responded".
     * This auto-attributes the campaign with a response.
     *
     * KEY: `String.valueOf(t.WhoId).startsWith('003')` - the standard
     * Contact key prefix. '003...' = Contact record Id. This filters
     * out tasks whose WhoId is a Lead instead.
     * ----------------------------------------------------------------------
     */
    public static void updateMemberStatusOnActivity(List<Task> tasks) {
        Set<Id> whoIds = new Set<Id>();
        for (Task t : tasks) {
            if (t.WhoId != null && String.valueOf(t.WhoId).startsWith('003')) {
                whoIds.add(t.WhoId);
            }
        }

        if (whoIds.isEmpty()) return;

        // Only promote members that were merely "Sent" - don't overwrite
        // richer statuses.
        List<CampaignMember> membersToUpdate = [
            SELECT Id, Status, ContactId
            FROM CampaignMember
            WHERE ContactId IN :whoIds
            AND Status = 'Sent'
        ];

        for (CampaignMember cm : membersToUpdate) {
            cm.Status = 'Responded';
        }

        if (!membersToUpdate.isEmpty()) {
            update membersToUpdate;
        }
    }

    /*
     * calculateCampaignMetrics(Set<Id> campaignIds)
     * ----------------------------------------------------------------------
     * PURPOSE: Recompute KPI fields on Campaign records:
     *
     *   Total_Members__c          = number of campaign members
     *   Responded_Members__c      = members with status "Responded"
     *   Conversion_Rate__c        = responded / total * 100
     *   Total_Revenue_Generated__c= SUM(Amount) of Closed Won opportunities
     *   ROI__c                    = (revenue - cost) / cost * 100
     *   Budget_Used__c            = (actualCost / budget) * 100 (as percent)
     *   Cost_Per_Lead__c          = actualCost / totalMembers
     *
     * USES relationship subqueries on Campaign:
     *   (SELECT ... FROM CampaignMembers) AND (SELECT ... FROM Opportunities)
     * ----------------------------------------------------------------------
     */
    public static void calculateCampaignMetrics(Set<Id> campaignIds) {
        if (campaignIds.isEmpty()) return;

        List<Campaign> campaigns = [
            SELECT Id, Budget__c, ActualCost__c, AmountAllOpportunities__c,
                   (SELECT Id, Status FROM CampaignMembers),
                   (SELECT Amount, StageName FROM Opportunities)
            FROM Campaign WHERE Id IN :campaignIds
        ];

        for (Campaign camp : campaigns) {
            // Count members & responders
            Integer totalMembers = camp.CampaignMembers.size();
            Integer respondedMembers = 0;
            for (CampaignMember cm : camp.CampaignMembers) {
                if (cm.Status == 'Responded') respondedMembers++;
            }

            camp.Total_Members__c = totalMembers;
            camp.Responded_Members__c = respondedMembers;
            camp.Conversion_Rate__c = totalMembers > 0
                ? (respondedMembers * 100.0 / totalMembers) : 0;

            // Sum revenue from won opportunities
            Decimal totalRevenue = 0;
            for (Opportunity opp : camp.Opportunities) {
                if (opp.StageName == 'Closed Won' && opp.Amount != null) {
                    totalRevenue += opp.Amount;
                }
            }

            camp.Total_Revenue_Generated__c = totalRevenue;
            camp.ROI__c = camp.ActualCost__c != null && camp.ActualCost__c > 0
                ? ((totalRevenue - camp.ActualCost__c) / camp.ActualCost__c) * 100
                : 0;

            camp.Budget_Used__c = camp.Budget__c != null && camp.Budget__c > 0
                ? (camp.ActualCost__c / camp.Budget__c) * 100
                : 0;

            camp.Cost_Per_Lead__c = totalMembers > 0 && camp.ActualCost__c != null
                ? camp.ActualCost__c / totalMembers
                : 0;
        }

        update campaigns;
    }

    /*
     * bulkAddMembersFromQuery(Id campaignId, String soqlFilter)
     * ----------------------------------------------------------------------
     * PURPOSE: Add every Contact matching a dynamic SOQL WHERE clause as a
     * member of the given campaign, without creating duplicates.
     *
     * EXAMPLE (from test):
     *   CampaignService.bulkAddMembersFromQuery(webinar.Id, "Industry = 'Technology'");
     *
     * SECURITY WARNING: Database.query() with a user-supplied string is
     * vulnerable to SOQL injection. In production, use binding variables
     * (e.g. `Database.queryWithBinds`) or whitelist the filter choices.
     * ----------------------------------------------------------------------
     */
    public static void bulkAddMembersFromQuery(Id campaignId, String soqlFilter) {
        // Dynamic query: table is fixed (Contact), filter comes from caller
        List<Contact> contacts = Database.query(
            'SELECT Id FROM Contact WHERE ' + soqlFilter
        );

        // Which of these contacts are ALREADY members? (dedupe prevention)
        Set<Id> existingMembers = new Set<Id>();
        for (CampaignMember cm : [
            SELECT ContactId FROM CampaignMember
            WHERE CampaignId = :campaignId AND ContactId IN :contacts
        ]) {
            existingMembers.add(cm.ContactId);
        }

        // Build new members for contacts not already in the campaign
        List<CampaignMember> newMembers = new List<CampaignMember>();
        for (Contact c : contacts) {
            if (!existingMembers.contains(c.Id)) {
                newMembers.add(new CampaignMember(
                    CampaignId = campaignId,
                    ContactId = c.Id,
                    Status = 'Sent'
                ));
            }
        }

        if (!newMembers.isEmpty()) {
            insert newMembers;
        }
    }
}