/*
 * ============================================================================
 * IntegrationService
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 10 - Advanced & Integrations]
 *
 * WHAT THIS CLASS DOES:
 * Demonstrates integration patterns between Salesforce and external systems
 * (ERP, other CRMs, marketing platforms). Since this is a LEARNING project
 * with no real endpoint, the class simulates the integration flow:
 *
 *   1. Build a JSON payload from a Salesforce record
 *   2. Log a PENDING Integration_Log__c record (the audit trail)
 *   3. Publish a Platform Event (Integration_Event__e) so external
 *      subscribers / flows can react asynchronously
 *   4. Provide monitoring + retry utilities
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. JSON.serialize() - convert a Map/List into a JSON string for an API body.
 * 2. JSON.deserializeUntyped() - parse an incoming JSON webhook into a Map.
 * 3. Platform Events - `Integration_Event__e` (the "__e" suffix) published
 *    with EventBus.publish(). Delivered asynchronously to subscribers.
 * 4. Custom object as an integration audit log.
 * 5. Custom exception (IntegrationException) for specific error handling.
 * 6. Defensive null-checks and max-retry guardrails.
 * ============================================================================
 */
public with sharing class IntegrationService {

    /*
     * logIntegration(String systemName, ... )
     * ----------------------------------------------------------------------
     * PURPOSE: Append a row to Integration_Log__c - the audit trail for all
     * integration activity. Every call to a remote system (or receiving one)
     * should be logged for troubleshooting and compliance.
     *
     * PARAMETERS: (self-explanatory)
     *   - systemName, integrationType, direction (Inbound/Outbound/Both)
     *   - status (Success/Failed/Pending/Partial)
     *   - requestBody / responseBody (JSON strings)
     *   - responseCode (HTTP code, e.g. 200/500)
     *   - recordId (optional Salesforce record this relates to)
     *   - errorMessage (optional)
     * ----------------------------------------------------------------------
     */
    public static void logIntegration(
        String systemName,
        String integrationType,
        String direction,
        String status,
        String requestBody,
        String responseBody,
        Integer responseCode,
        Id recordId,
        String errorMessage
    ) {
        Integration_Log__c log = new Integration_Log__c(
            System_Name__c = systemName,
            Integration_Type__c = integrationType,
            Direction__c = direction,
            Status__c = status,
            Request_Body__c = requestBody,
            Response_Body__c = responseBody,
            Response_Code__c = responseCode,
            Record_Id__c = recordId != null ? String.valueOf(recordId) : null,
            Error_Message__c = errorMessage
        );

        insert log;
    }

    /*
     * publishIntegrationEvent(String eventType, ... )
     * ----------------------------------------------------------------------
     * PURPOSE: Publish a Platform Event (Integration_Event__e). Platform
     * Events are the modern, scalable way to notify external systems (or
     * internal flows) that something happened - without the subscriber
     * having to poll or be online when it happens.
     *
     * KEY: EventBus.publish(event) returns a SaveResult. A failure does NOT
     * roll back the rest of the transaction - hence the explicit check.
     * ----------------------------------------------------------------------
     */
    public static void publishIntegrationEvent(
        String eventType,
        String sourceSystem,
        String targetSystem,
        String payload
    ) {
        Integration_Event__e event = new Integration_Event__e(
            Event_Type__c = eventType,
            Source_System__c = sourceSystem,
            Target_System__c = targetSystem,
            Payload__c = payload
        );

        Database.SaveResult result = EventBus.publish(event);

        if (!result.isSuccess()) {
            System.debug('Failed to publish event: ' + result.getErrors()[0].getMessage());
        }
    }

    /*
     * syncOpportunityToERP(Id opportunityId)
     * ----------------------------------------------------------------------
     * PURPOSE: Outbound integration - serialize an Opportunity into a JSON
     * payload for an ERP system, log it, and publish the platform event.
     *
     * This is a SIMULATED sync: in production, after building the payload you
     * would actually call the external API via `Http`, `HttpRequest`,
     * `HttpResponse` (callout). The callout is always done AFTER the local
     * DML in a transaction (via queueable/future if triggered from a trigger).
     *
     * WHY JSON? JSON is the standard interchange format for REST APIs; we
     * build it with JSON.serialize() from a Map.
     * ----------------------------------------------------------------------
     */
    public static void syncOpportunityToERP(Id opportunityId) {
        // Query the data we want to send (only necessary fields)
        Opportunity opp = [
            SELECT Id, Name, Amount, StageName, CloseDate,
                   Account.Name, Account.BillingAddress,
                   Territory__c, Owner.Name
            FROM Opportunity WHERE Id = :opportunityId
        ];

        // Assemble the JSON body
        Map<String, Object> payload = new Map<String, Object>{
            'opportunityId' => opp.Id,
            'opportunityName' => opp.Name,
            'amount' => opp.Amount,
            'stage' => opp.StageName,
            'closeDate' => opp.CloseDate,
            'accountName' => opp.Account.Name,
            'territory' => opp.Territory__c,
            'owner' => opp.Owner.Name
        };

        // Convert Map -> JSON string
        String jsonPayload = JSON.serialize(payload);

        // Audit trail: mark as Pending until the (simulated) callout completes
        logIntegration(
            'ERP System',
            'REST API',
            'Outbound',
            'Pending',
            jsonPayload,
            null,
            null,
            opp.Id,
            null
        );

        // Notify subscribers async-ly
        publishIntegrationEvent(
            'Opportunity_Sync',
            'Salesforce',
            'ERP',
            jsonPayload
        );
    }

    /*
     * syncAccountToCRM(Id accountId)
     * ----------------------------------------------------------------------
     * PURPOSE: Outbound sync of an Account to an external CRM.
     * Same pattern as syncOpportunityToERP() but for Account data.
     * ----------------------------------------------------------------------
     */
    public static void syncAccountToCRM(Id accountId) {
        Account acc = [
            SELECT Id, Name, Industry, AnnualRevenue,
                   BillingAddress, ShippingAddress,
                   Phone, Website, Owner.Name
            FROM Account WHERE Id = :accountId
        ];

        Map<String, Object> payload = new Map<String, Object>{
            'accountId' => acc.Id,
            'accountName' => acc.Name,
            'industry' => acc.Industry,
            'annualRevenue' => acc.AnnualRevenue,
            'phone' => acc.Phone,
            'website' => acc.Website,
            'owner' => acc.Owner.Name
        };

        String jsonPayload = JSON.serialize(payload);

        logIntegration(
            'External CRM',
            'REST API',
            'Outbound',
            'Pending',
            jsonPayload,
            null,
            null,
            acc.Id,
            null
        );

        publishIntegrationEvent(
            'Account_Sync',
            'Salesforce',
            'External CRM',
            jsonPayload
        );
    }

    /*
     * syncLeadToMarketing(Id leadId)
     * ----------------------------------------------------------------------
     * PURPOSE: Outbound sync of a Lead to a marketing automation platform.
     * Demonstrates the same pattern for a third object type.
     * ----------------------------------------------------------------------
     */
    public static void syncLeadToMarketing(Id leadId) {
        Lead lead = [
            SELECT Id, FirstName, LastName, Email, Phone,
                   Company, Industry, LeadSource, Lead_Score__c
            FROM Lead WHERE Id = :leadId
        ];

        Map<String, Object> payload = new Map<String, Object>{
            'leadId' => lead.Id,
            'firstName' => lead.FirstName,
            'lastName' => lead.LastName,
            'email' => lead.Email,
            'phone' => lead.Phone,
            'company' => lead.Company,
            'industry' => lead.Industry,
            'source' => lead.LeadSource,
            'score' => lead.Lead_Score__c
        };

        String jsonPayload = JSON.serialize(payload);

        logIntegration(
            'Marketing Platform',
            'REST API',
            'Outbound',
            'Pending',
            jsonPayload,
            null,
            null,
            lead.Id,
            null
        );

        publishIntegrationEvent(
            'Lead_Sync',
            'Salesforce',
            'Marketing Platform',
            jsonPayload
        );
    }

    /*
     * batchSyncOpportunities(Set<Id> opportunityIds)
     * ----------------------------------------------------------------------
     * PURPOSE: Same idea as syncOpportunityToERP but for MANY opportunities
     * at once - uses a List<Map> serialized to a JSON array. This is what a
     * bulk/batch integration endpoint would accept.
     * ----------------------------------------------------------------------
     */
    public static void batchSyncOpportunities(Set<Id> opportunityIds) {
        List<Opportunity> opportunities = [
            SELECT Id, Name, Amount, StageName, CloseDate,
                   Account.Name, Territory__c
            FROM Opportunity WHERE Id IN :opportunityIds
        ];

        // Build ONE list of maps, then serialize the whole list
        List<Map<String, Object>> batchPayload = new List<Map<String, Object>>();

        for (Opportunity opp : opportunities) {
            batchPayload.add(new Map<String, Object>{
                'opportunityId' => opp.Id,
                'opportunityName' => opp.Name,
                'amount' => opp.Amount,
                'stage' => opp.StageName,
                'closeDate' => opp.CloseDate,
                'accountName' => opp.Account.Name,
                'territory' => opp.Territory__c
            });
        }

        String jsonPayload = JSON.serialize(batchPayload);

        logIntegration(
            'ERP System',
            'Batch',
            'Outbound',
            'Pending',
            jsonPayload,
            null,
            null,
            null,
            null
        );

        publishIntegrationEvent(
            'Batch_Opportunity_Sync',
            'Salesforce',
            'ERP',
            jsonPayload
        );
    }

    /*
     * getFailedIntegrations(Integer hoursBack)
     * ----------------------------------------------------------------------
     * PURPOSE: Return the failed integration logs from the last N hours -
     * for building an admin alert list or a "fix me" screen.
     * ----------------------------------------------------------------------
     */
    public static List<Integration_Log__c> getFailedIntegrations(Integer hoursBack) {
        DateTime cutoff = DateTime.now().addHours(-hoursBack);

        return [
            SELECT Id, System_Name__c, Integration_Type__c,
                   Status__c, Error_Message__c, CreatedDate
            FROM Integration_Log__c
            WHERE Status__c = 'Failed'
            AND CreatedDate >= :cutoff
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }

    /*
     * retryFailedIntegration(Id logId)
     * ----------------------------------------------------------------------
     * PURPOSE: Re-queue a failed integration for another attempt. Contains a
     * guardrail: maximum 3 retries (throws IntegrationException beyond that).
     *
     * HOW: Sets status back to 'Pending', increments Retry_Count__c, clears
     * the error message, and republishes the platform event.
     * ----------------------------------------------------------------------
     */
    public static void retryFailedIntegration(Id logId) {
        Integration_Log__c log = [
            SELECT Id, System_Name__c, Integration_Type__c,
                   Request_Body__c, Retry_Count__c
            FROM Integration_Log__c WHERE Id = :logId
        ];

        // Guardrail: don't retry forever
        if (log.Retry_Count__c >= 3) {
            throw new IntegrationException('Max retries exceeded for integration: ' + logId);
        }

        log.Retry_Count__c = log.Retry_Count__c != null
            ? log.Retry_Count__c + 1 : 1;
        log.Status__c = 'Pending';
        log.Error_Message__c = null;

        update log;

        publishIntegrationEvent(
            'Retry_' + log.Integration_Type__c,
            'Salesforce',
            log.System_Name__c,
            log.Request_Body__c
        );
    }

    /*
     * getIntegrationStats(Integer hoursBack)
     * ----------------------------------------------------------------------
     * PURPOSE: Health dashboard - count integration logs by status over the
     * last N hours. Returns Map<String, Integer> with keys: total, success,
     * failed, pending.
     * ----------------------------------------------------------------------
     */
    public static Map<String, Integer> getIntegrationStats(Integer hoursBack) {
        DateTime cutoff = DateTime.now().addHours(-hoursBack);

        Map<String, Integer> stats = new Map<String, Integer>{
            'total' => 0,
            'success' => 0,
            'failed' => 0,
            'pending' => 0
        };

        List<AggregateResult> results = [
            SELECT Status__c, COUNT(Id) cnt
            FROM Integration_Log__c
            WHERE CreatedDate >= :cutoff
            GROUP BY Status__c
        ];

        for (AggregateResult ar : results) {
            String status = (String) ar.get('Status__c');
            Integer count = (Integer) ar.get('cnt');

            stats.put('total', stats.get('total') + count);

            if (status == 'Success') {
                stats.put('success', stats.get('success') + count);
            } else if (status == 'Failed') {
                stats.put('failed', stats.get('failed') + count);
            } else if (status == 'Pending') {
                stats.put('pending', stats.get('pending') + count);
            }
        }

        return stats;
    }

    /*
     * processInboundWebhook(String payload)
     * ----------------------------------------------------------------------
     * PURPOSE: The INBOUND side - receive a JSON webhook (e.g. from an
     * external system) and process it.
     *
     * JSON.deserializeUntyped() turns JSON into a Map<String, Object>.
     * Keys are accessed with .get() and must be cast to their real type.
     *
     * In production, this method would be exposed via an Apex REST class
     * (@RestResource) as an HTTP endpoint.
     * ----------------------------------------------------------------------
     */
    public static void processInboundWebhook(String payload) {
        // Parse the incoming JSON
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(payload);

        String eventType = (String) data.get('eventType');
        String sourceSystem = (String) data.get('sourceSystem');
        String recordData = (String) data.get('data');

        // Log the reception
        logIntegration(
            sourceSystem,
            'Webhook',
            'Inbound',
            'Success',
            recordData,
            payload,
            200,
            null,
            null
        );

        // Re-publish as a platform event so internal subscribers can react
        publishIntegrationEvent(
            eventType,
            sourceSystem,
            'Salesforce',
            recordData
        );
    }

    /*
     * IntegrationException  [CUSTOM EXCEPTION]
     * ----------------------------------------------------------------------
     * PURPOSE: Named exception for integration failures so callers can
     * `catch (IntegrationService.IntegrationException e)` specifically.
     * ----------------------------------------------------------------------
     */
    public class IntegrationException extends Exception {}
}