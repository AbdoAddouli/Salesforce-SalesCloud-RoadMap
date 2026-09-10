/*
 * ============================================================================
 * IntegrationServiceTest
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 10 - Advanced & Integrations]
 *
 * WHAT THIS TEST CLASS DOES:
 * Verifies IntegrationService logic:
 *   - Writing Integration_Log__c records for every inbound/outbound call
 *   - Querying failed integrations
 *   - Retrying failed integrations (with a max-retry guard)
 *   - Integration statistics (aggregate counts)
 *   - Processing an inbound Webhook payload (JSON)
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Integration_Log__c is our custom "audit trail" - every API call writes
 *    System, Type, Direction, Status, response code, payloads, error msg.
 * 2. Retry logic wraps external calls; a custom exception
 *    (IntegrationService.IntegrationException) is thrown past the retry cap.
 * 3. JSON.serialize / JSON.deserialize are the Apex-native way to turn
 *    Maps into JSON strings and back (what webhooks use in practice).
 * 4. Null-safe handling: payloads, record IDs and sync IDs may legitimately
 *    be null in tests (e.g. a batch job that has no single parent record).
 * ============================================================================
 */
@isTest
private class IntegrationServiceTest {

    /*
     * makeData() [@TestSetup]
     * ----------------------------------------------------------------------
     * A representative Salesforce dataset (Account + Opportunity + Lead)
     * used purely as anchor records for the integration logs.
     * ----------------------------------------------------------------------
     */
    @TestSetup
    static void makeData() {
        Account acc = new Account(
            Name = 'Integration Test Account',
            Industry = 'Technology',
            AnnualRevenue = 2000000,
            Phone = '555-0100',
            Website = 'https://example.com'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Integration Test Deal',
            AccountId = acc.Id,
            Amount = 150000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Territory__c = 'North America West'
        );
        insert opp;

        Lead testLead = new Lead(
            Company = 'Integration Test Lead',
            LastName = 'Test Lead',
            Email = 'test@integration.com',
            Phone = '555-0101',
            LeadSource = 'Web',
            Lead_Score__c = 75
        );
        insert testLead;
    }

    // ------------------------------------------------------------------------
    // LOGGING - the happy path writes a full audit record.
    // ------------------------------------------------------------------------

    @isTest
    static void testLogIntegration() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        IntegrationService.logIntegration(
            'Test System',
            'REST API',
            'Outbound',
            'Success',
            '{"test": "request"}',
            '{"test": "response"}',
            200,
            acc.Id,
            null
        );

        Integration_Log__c log = [
            SELECT System_Name__c, Integration_Type__c, Direction__c,
                   Status__c, Response_Code__c, Record_Id__c
            FROM Integration_Log__c
            LIMIT 1
        ];

        System.assertEquals('Test System', log.System_Name__c);
        System.assertEquals('REST API', log.Integration_Type__c);
        System.assertEquals('Outbound', log.Direction__c);
        System.assertEquals('Success', log.Status__c);
        System.assertEquals(200, log.Response_Code__c);
    }

    // ------------------------------------------------------------------------
    // LOGGING - error path stores the failure reason.
    // ------------------------------------------------------------------------

    @isTest
    static void testLogIntegrationWithError() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        IntegrationService.logIntegration(
            'Test System',
            'SOAP API',
            'Inbound',
            'Failed',
            null,
            null,
            500,
            acc.Id,
            'Connection timeout'
        );

        Integration_Log__c log = [
            SELECT Status__c, Error_Message__c, Response_Code__c
            FROM Integration_Log__c
            LIMIT 1
        ];

        System.assertEquals('Failed', log.Status__c);
        System.assertEquals('Connection timeout', log.Error_Message__c);
        System.assertEquals(500, log.Response_Code__c);
    }

    // ------------------------------------------------------------------------
    // FAILED INTEGRATIONS - retrieves recent failures for ops review.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetFailedIntegrations() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Integration_Log__c failedLog = new Integration_Log__c(
            System_Name__c = 'Failed System',
            Integration_Type__c = 'REST API',
            Direction__c = 'Outbound',
            Status__c = 'Failed',
            Error_Message__c = 'Test error',
            Record_Id__c = acc.Id
        );
        insert failedLog;

        List<Integration_Log__c> failed = IntegrationService.getFailedIntegrations(24);

        System.assert(!failed.isEmpty(), 'Should have failed integrations');
        System.assertEquals('Failed', failed[0].Status__c);
    }

    // ------------------------------------------------------------------------
    // RETRY - failed call flips to Pending and the counter increments.
    // ------------------------------------------------------------------------

    @isTest
    static void testRetryFailedIntegration() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Integration_Log__c failedLog = new Integration_Log__c(
            System_Name__c = 'Retry System',
            Integration_Type__c = 'REST API',
            Direction__c = 'Outbound',
            Status__c = 'Failed',
            Request_Body__c = '{"test": "retry"}',
            Retry_Count__c = 0,
            Record_Id__c = acc.Id
        );
        insert failedLog;

        IntegrationService.retryFailedIntegration(failedLog.Id);

        Integration_Log__c updated = [
            SELECT Status__c, Retry_Count__c
            FROM Integration_Log__c WHERE Id = :failedLog.Id
        ];

        System.assertEquals('Pending', updated.Status__c);
        System.assertEquals(1, updated.Retry_Count__c);
    }

    // ------------------------------------------------------------------------
    // RETRY SAFETY - past the max retries the service throws our exception.
    // ------------------------------------------------------------------------

    @isTest
    static void testRetryMaxExceeded() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Integration_Log__c failedLog = new Integration_Log__c(
            System_Name__c = 'Max Retry System',
            Integration_Type__c = 'REST API',
            Direction__c = 'Outbound',
            Status__c = 'Failed',
            Retry_Count__c = 3,
            Record_Id__c = acc.Id
        );
        insert failedLog;

        Boolean exceptionThrown = false;

        try {
            IntegrationService.retryFailedIntegration(failedLog.Id);
        } catch (IntegrationService.IntegrationException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Max retries exceeded'));
        }

        System.assert(exceptionThrown, 'Should throw exception for max retries');
    }

    // ------------------------------------------------------------------------
    // STATS - aggregate totals for the integration dashboard.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetIntegrationStats() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Integration_Log__c successLog = new Integration_Log__c(
            System_Name__c = 'Stats System',
            Integration_Type__c = 'REST API',
            Direction__c = 'Outbound',
            Status__c = 'Success',
            Record_Id__c = acc.Id
        );

        Integration_Log__c failedLog = new Integration_Log__c(
            System_Name__c = 'Stats System',
            Integration_Type__c = 'REST API',
            Direction__c = 'Outbound',
            Status__c = 'Failed',
            Record_Id__c = acc.Id
        );

        insert new List<Integration_Log__c>{successLog, failedLog};

        Map<String, Integer> stats = IntegrationService.getIntegrationStats(24);

        System.assert(stats.containsKey('total'), 'Should have total');
        System.assert(stats.containsKey('success'), 'Should have success count');
        System.assert(stats.containsKey('failed'), 'Should have failed count');
        System.assert(stats.get('total') >= 2, 'Should have at least 2 logs');
    }

    // ------------------------------------------------------------------------
    // WEBHOOK - deserializes a JSON payload and logs an inbound event.
    // ------------------------------------------------------------------------

    @isTest
    static void testProcessInboundWebhook() {
        Map<String, Object> webhookData = new Map<String, Object>{
            'eventType' => 'Order_Created',
            'sourceSystem' => 'ERP',
            'data' => '{"orderId": "12345", "amount": 1000}'
        };

        String payload = JSON.serialize(webhookData);

        IntegrationService.processInboundWebhook(payload);

        Integration_Log__c log = [
            SELECT System_Name__c, Integration_Type__c, Direction__c, Status__c
            FROM Integration_Log__c
            LIMIT 1
        ];

        System.assertEquals('ERP', log.System_Name__c);
        System.assertEquals('Webhook', log.Integration_Type__c);
        System.assertEquals('Inbound', log.Direction__c);
        System.assertEquals('Success', log.Status__c);
    }

    // ------------------------------------------------------------------------
    // NULL-SAFE logging - a batch job with no single parent record works.
    // ------------------------------------------------------------------------

    @isTest
    static void testLogIntegrationNullRecordId() {
        IntegrationService.logIntegration(
            'Test System',
            'Batch',
            'Both',
            'Pending',
            '{"batch": true}',
            null,
            null,
            null,
            null
        );

        Integration_Log__c log = [
            SELECT Record_Id__c, Status__c
            FROM Integration_Log__c
            LIMIT 1
        ];

        System.assertEquals(null, log.Record_Id__c);
        System.assertEquals('Pending', log.Status__c);
    }

    // ------------------------------------------------------------------------
    // EMPTY result sets are handled (no records in the lookback window).
    // ------------------------------------------------------------------------

    @isTest
    static void testGetFailedIntegrationsEmpty() {
        // No failed logs exist yet -> empty list, not an error
        List<Integration_Log__c> failed = IntegrationService.getFailedIntegrations(1);

        System.assert(failed.isEmpty(), 'Should have no failed integrations');
    }
}