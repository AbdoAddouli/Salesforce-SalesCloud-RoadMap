/*
 * ============================================================================
 * OpportunityManagementTest
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 4 - Opportunity Management]
 *
 * WHAT THIS TEST CLASS DOES:
 * Verifies the OpportunityService logic and OpportunityTrigger behavior:
 *   - Auto set CloseDate based on StageName
 *   - Auto create Tasks on stage changes
 *   - Auto-close stale opportunities
 *   - Pipeline / win-rate / cycle-length analytics
 *   - Products & Price Books (OpportunityLineItem)
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Testing `before` trigger behavior (field auto-population) by inserting
 *    records and re-querying the saved values.
 * 2. Testing stage-change detection (the trigger must NOT fire on unrelated
 *    field updates).
 * 3. Standard price book + Product2 + PricebookEntry setup needed to test
 *    OpportunityLineItem (products on an opportunity).
 * ============================================================================
 */
@isTest
private class OpportunityManagementTest {

    /*
     * makeData() [@TestSetup]
     * ----------------------------------------------------------------------
     * Creates one Account + four test opportunities covering various stages,
     * and one "stale" deal (no recent LastActivityDate).
     * ----------------------------------------------------------------------
     */
    @TestSetup
    static void makeData() {
        Account acc = new Account(
            Name = 'Test Account',
            Industry = 'Technology',
            AnnualRevenue = 5000000,
            Customer_Since__c = Date.today().addYears(-2)
        );
        insert acc;

        Opportunity opp1 = new Opportunity(
            Name = 'Deal 1 - Prospecting',
            AccountId = acc.Id,
            Amount = 50000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(90)
        );

        Opportunity opp2 = new Opportunity(
            Name = 'Deal 2 - Negotiation',
            AccountId = acc.Id,
            Amount = 150000,
            StageName = 'Negotiation/Review',
            CloseDate = Date.today().addDays(14)
        );

        Opportunity opp3 = new Opportunity(
            Name = 'Deal 3 - Closed Won',
            AccountId = acc.Id,
            Amount = 200000,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-10)
        );

        Opportunity opp4 = new Opportunity(
            Name = 'Deal 4 - Stale',
            AccountId = acc.Id,
            Amount = 75000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(-60),
            LastActivityDate = Date.today().addDays(-45)   // stale: >30 days ago
        );

        insert new List<Opportunity>{opp1, opp2, opp3, opp4};
    }

    // ------------------------------------------------------------------------
    // CLOSE DATE auto-set by stage.
    // ------------------------------------------------------------------------

    @isTest
    static void testCloseDateByStage_Prospecting() {
        Opportunity opp = new Opportunity(
            Name = 'New Prospecting Deal',
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            Amount = 10000,
            StageName = 'Prospecting',
            CloseDate = Date.today()   // we set something - the trigger overrides it
        );

        insert opp;

        Opportunity inserted = [SELECT CloseDate, StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(Date.today().addDays(90), inserted.CloseDate,
            'Close date should be 90 days from today for Prospecting');
    }

    @isTest
    static void testCloseDateByStage_Qualification() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Qualification Deal',
            AccountId = acc.Id,
            Amount = 25000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(90)
        );
        insert opp;

        // Change stage -> trigger should re-set the close date
        opp.StageName = 'Qualification';
        update opp;

        Opportunity updated = [SELECT CloseDate FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(Date.today().addDays(60), updated.CloseDate,
            'Close date should update to 60 days for Qualification');
    }

    @isTest
    static void testCloseDateByStage_Proposal() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Proposal Deal',
            AccountId = acc.Id,
            Amount = 100000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(90)
        );
        insert opp;

        opp.StageName = 'Proposal/Price Quote';
        update opp;

        Opportunity updated = [SELECT CloseDate FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(Date.today().addDays(30), updated.CloseDate,
            'Close date should update to 30 days for Proposal');
    }

    @isTest
    static void testCloseDateByStage_Negotiation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Negotiation Deal',
            AccountId = acc.Id,
            Amount = 200000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(90)
        );
        insert opp;

        opp.StageName = 'Negotiation/Review';
        update opp;

        Opportunity updated = [SELECT CloseDate FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(Date.today().addDays(14), updated.CloseDate,
            'Close date should update to 14 days for Negotiation');
    }

    // ------------------------------------------------------------------------
    // STAGE-CHANGE TASK creation.
    // ------------------------------------------------------------------------

    @isTest
    static void testStageChangeTaskCreation() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity
                           WHERE Name = 'Deal 1 - Prospecting' LIMIT 1];

        opp.StageName = 'Qualification';   // this triggers a stage change
        update opp;

        List<Task> tasks = [SELECT Subject, WhatId, ActivityDate, Status
                            FROM Task WHERE WhatId = :opp.Id];

        System.assert(tasks.size() > 0, 'Task should be created on stage change');
        System.assert(tasks[0].Subject.contains('Qualification'),
            'Task subject should mention the new stage');
        System.assertEquals('Not Started', tasks[0].Status);
    }

    @isTest
    static void testStageChangeNoTaskWhenSameStage() {
        Opportunity opp = [SELECT Id, StageName, Amount FROM Opportunity
                           WHERE Name = 'Deal 1 - Prospecting' LIMIT 1];

        Integer taskCountBefore = [SELECT COUNT() FROM Task WHERE WhatId = :opp.Id];

        // Update a NON-stage field (Amount) - trigger must NOT create a task
        opp.Amount = 60000;
        update opp;

        Integer taskCountAfter = [SELECT COUNT() FROM Task WHERE WhatId = :opp.Id];

        System.assertEquals(taskCountBefore, taskCountAfter,
            'No task should be created when stage does not change');
    }

    @isTest
    static void testBulkStageChanges() {
        // Change stage on MANY opportunities at once (bulk trigger handling)
        List<Opportunity> opps = [SELECT Id, StageName FROM Opportunity
                                   WHERE Name LIKE 'Deal %'
                                   AND StageName != 'Closed Won'
                                   AND StageName != 'Closed Lost'];

        for (Opportunity opp : opps) {
            opp.StageName = 'Qualification';
        }

        update opps;

        List<Task> tasks = [SELECT Id FROM Task WHERE Subject LIKE '%Qualification%'];
        System.assert(tasks.size() >= opps.size(),
            'Should create a task for each stage change');
    }

    // ------------------------------------------------------------------------
    // AUTO-CLOSE of stale opportunities.
    // ------------------------------------------------------------------------

    @isTest
    static void testAutoCloseStaleOpportunities() {
        Integer staleDays = 30;

        OpportunityService.autoCloseStaleOpportunities(staleDays);

        List<Opportunity> closedOpps = [
            SELECT Name, StageName, Description
            FROM Opportunity
            WHERE Name = 'Deal 4 - Stale'
        ];

        System.assertEquals(1, closedOpps.size(), 'Stale opportunity should be found');
        System.assertEquals('Closed Lost', closedOpps[0].StageName,
            'Stale opportunity should be Closed Lost');
        System.assert(closedOpps[0].Description.contains('Auto-closed'),
            'Description should indicate auto-close');
    }

    @isTest
    static void testAutoCloseDoesNotCloseRecentOpps() {
        OpportunityService.autoCloseStaleOpportunities(30);

        List<Opportunity> recentOpps = [
            SELECT StageName FROM Opportunity
            WHERE Name = 'Deal 2 - Negotiation'
        ];

        System.assertEquals('Negotiation/Review', recentOpps[0].StageName,
            'Recent opportunity should not be auto-closed');
    }

    // ------------------------------------------------------------------------
    // ANALYTICS calculations.
    // ------------------------------------------------------------------------

    @isTest
    static void testCalculateWinRate() {
        Date quarterStart = Date.today().toStartOfMonth();
        Date quarterEnd = quarterStart.addMonths(3).addDays(-1);

        Decimal winRate = OpportunityService.calculateWinRate(quarterStart, quarterEnd);

        System.assert(winRate >= 0 && winRate <= 100,
            'Win rate should be between 0 and 100');
    }

    @isTest
    static void testCalculateAverageDealSize() {
        Date quarterStart = Date.today().toStartOfMonth();
        Date quarterEnd = quarterStart.addMonths(3).addDays(-1);

        Decimal avgDealSize = OpportunityService.calculateAverageDealSize(quarterStart, quarterEnd);

        System.assert(avgDealSize > 0, 'Average deal size should be positive');
    }

    @isTest
    static void testCalculateAverageCycleLength() {
        Date quarterStart = Date.today().toStartOfMonth();
        Date quarterEnd = quarterStart.addMonths(3).addDays(-1);

        Integer avgCycleDays = OpportunityService.calculateAverageCycleLength(quarterStart, quarterEnd);

        System.assert(avgCycleDays >= 0, 'Average cycle length should be non-negative');
    }

    @isTest
    static void testCalculatePipelineByStage() {
        Map<Id, Decimal> pipeline = OpportunityService.calculatePipelineByStage();

        System.assert(!pipeline.isEmpty(), 'Pipeline should have data');
    }

    // ------------------------------------------------------------------------
    // PRODUCTS & PRICEBOOKS on an Opportunity.
    // ------------------------------------------------------------------------

    @isTest
    static void testOpportunityWithProducts() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Product2 = the catalog item
        Product2 prod = new Product2(
            Name = 'Enterprise License',
            IsActive = true,
            ProductCode = 'ENT-001'
        );
        insert prod;

        // PricebookEntry = product + price in a pricebook
        // Test.getStandardPricebookId() gives the standard (default) pricebook
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 10000,
            IsActive = true
        );
        insert pbe;

        Opportunity opp = new Opportunity(
            Name = 'Product Deal',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // OpportunityLineItem = a product LINE on an opportunity (qty x price)
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 10000
        );
        insert oli;

        // Salesforce auto-calculates Amount = SUM(qty * unit price)
        Opportunity withProducts = [SELECT Amount,
                                     (SELECT UnitPrice, Quantity FROM OpportunityLineItems)
                                    FROM Opportunity WHERE Id = :opp.Id];

        System.assertEquals(50000, withProducts.Amount);   // 5 x 10000
        System.assertEquals(1, withProducts.OpportunityLineItems.size());
    }
}