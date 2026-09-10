/*
 * ============================================================================
 * ForecastingTerritoryTest
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 8 - Forecasting & Territory Management]
 *
 * WHAT THIS TEST CLASS DOES:
 * Verifies ForecastingService logic and OpportunityForecastTrigger behavior:
 *   - Weighted forecast formula (Amount x Probability)
 *   - Forecast category auto-set from stage
 *   - Forecast rollups per user (pipeline totals, deal count)
 *   - Quota attainment (actual revenue vs quota)
 *   - Pipeline coverage and territory rollups
 *   - Automatic territory assignment by State / Country
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Weighted_Forecast__c = Amount * (Probability/100) is computed in a
 *    BEFORE trigger so it is always stored, even mid-bulk-transaction.
 * 2. Quota__c is a custom object mapping a User to a quota amount for a
 *    period; attainment % = actual won revenue / quota.
 * 3. Territory assignment is a simple rules lookup (state/country -> region)
 *    - the lightest-weight version of real territory mapping tools.
 * 4. Manual override: once the user sets Forecast_Category__c directly, the
 *    trigger must respect it.
 * ============================================================================
 */
@isTest
private class ForecastingTerritoryTest {

    /*
     * makeData() [@TestSetup]
     * ----------------------------------------------------------------------
     * - 3 Accounts in different regions (NY, CA, UK)
     * - 4 Opportunities (one Closed Won) spread across territories
     * - 1 Quota__c record for the rep: $500k for the current quarter
     * ----------------------------------------------------------------------
     */
    @TestSetup
    static void makeData() {
        User salesRep = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Account naEastAcc = new Account(
            Name = 'NA East Account',
            Industry = 'Technology',
            BillingState = 'NY',
            AnnualRevenue = 5000000
        );

        Account naWestAcc = new Account(
            Name = 'NA West Account',
            Industry = 'Finance',
            BillingState = 'CA',
            AnnualRevenue = 3000000
        );

        Account emeaAcc = new Account(
            Name = 'EMEA Account',
            Industry = 'Healthcare',
            BillingCountry = 'UK',
            AnnualRevenue = 4000000
        );

        insert new List<Account>{naEastAcc, naWestAcc, emeaAcc};

        Opportunity opp1 = new Opportunity(
            Name = 'NA East Deal',
            AccountId = naEastAcc.Id,
            Amount = 100000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Territory__c = 'North America East',
            OwnerId = salesRep.Id
        );

        Opportunity opp2 = new Opportunity(
            Name = 'NA West Deal',
            AccountId = naWestAcc.Id,
            Amount = 200000,
            StageName = 'Negotiation/Review',
            CloseDate = Date.today().addDays(14),
            Territory__c = 'North America West',
            OwnerId = salesRep.Id
        );

        Opportunity opp3 = new Opportunity(
            Name = 'EMEA Deal',
            AccountId = emeaAcc.Id,
            Amount = 150000,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(21),
            Territory__c = 'EMEA',
            OwnerId = salesRep.Id
        );

        Opportunity closedOpp = new Opportunity(
            Name = 'Closed Won Deal',
            AccountId = naEastAcc.Id,
            Amount = 250000,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-10),
            Territory__c = 'North America East',
            OwnerId = salesRep.Id
        );

        insert new List<Opportunity>{opp1, opp2, opp3, closedOpp};

        Quota__c quota = new Quota__c(
            User__c = salesRep.Id,
            Amount__c = 500000,
            Period_Start__c = Date.today().toStartOfMonth(),
            Period_End__c = Date.today().toStartOfMonth().addMonths(3).addDays(-1)
        );
        insert quota;
    }

    // ------------------------------------------------------------------------
    // WEIGHTED FORECAST = Amount x Probability (before trigger computes it).
    // ------------------------------------------------------------------------

    @isTest
    static void testWeightedForecastCalculation() {
        Opportunity opp = new Opportunity(
            Name = 'Weighted Test',
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            Amount = 100000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

        insert opp;

        Opportunity inserted = [SELECT Weighted_Forecast__c, Probability
                                FROM Opportunity WHERE Id = :opp.Id];

        System.assertNotEquals(null, inserted.Weighted_Forecast__c,
            'Weighted forecast should be calculated');
        System.assertEquals(100000 * (inserted.Probability / 100),
            inserted.Weighted_Forecast__c,
            'Weighted forecast should equal Amount * Probability');
    }

    // ------------------------------------------------------------------------
    // FORECAST CATEGORY - mapped from the stage, and updateable on change.
    // ------------------------------------------------------------------------

    @isTest
    static void testDefaultForecastCategory() {
        Opportunity opp = [SELECT Id, Forecast_Category__c, StageName
                           FROM Opportunity WHERE Name = 'NA East Deal' LIMIT 1];

        // Prospecting = early stage = "Pipeline"
        System.assertEquals('Pipeline', opp.Forecast_Category__c,
            'Prospecting stage should be Pipeline category');

        // Moving to Negotiation should re-map to "Commit"
        opp.StageName = 'Negotiation/Review';
        update opp;

        Opportunity updated = [SELECT Forecast_Category__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Commit', updated.Forecast_Category__c,
            'Negotiation stage should be Commit category');
    }

    // ------------------------------------------------------------------------
    // FORECAST rollup per user.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetForecastByUser() {
        User salesRep = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Date periodStart = Date.today().toStartOfMonth();
        Date periodEnd = periodStart.addMonths(3).addDays(-1);

        Map<Id, ForecastingService.ForecastSummary> forecasts =
            ForecastingService.getForecastByUser(
                new Set<Id>{salesRep.Id}, periodStart, periodEnd
            );

        ForecastingService.ForecastSummary fs = forecasts.get(salesRep.Id);
        System.assert(fs.totalPipeline > 0, 'Pipeline should have value');
        System.assert(fs.dealCount > 0, 'Should have deals');
    }

    // ------------------------------------------------------------------------
    // QUOTA ATTAINMENT.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetQuotaAttainment() {
        User salesRep = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Date periodStart = Date.today().toStartOfMonth();
        Date periodEnd = periodStart.addMonths(3).addDays(-1);

        Map<Id, ForecastingService.QuotaAttainment> attainment =
            ForecastingService.getQuotaAttainment(
                new Set<Id>{salesRep.Id}, periodStart, periodEnd
            );

        ForecastingService.QuotaAttainment qa = attainment.get(salesRep.Id);
        System.assertNotEquals(null, qa, 'Quota attainment should exist');
        // From @TestSetup: quota is 500k, won deal is 250k
        System.assertEquals(500000, qa.quotaAmount, 'Quota should be 500k');
        System.assert(qa.actualRevenue >= 250000, 'Should have at least 250k revenue');
        System.assert(qa.attainmentPercent >= 50, 'Attainment should be at least 50%');
    }

    // ------------------------------------------------------------------------
    // PIPELINE BY TERRITORY + PIPELINE COVERAGE.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetPipelineByTerritory() {
        Map<String, Decimal> pipeline = ForecastingService.getPipelineByTerritory();

        System.assert(!pipeline.isEmpty(), 'Pipeline by territory should have data');
        System.assert(pipeline.containsKey('North America East'), 'Should have NA East');
        System.assert(pipeline.containsKey('North America West'), 'Should have NA West');
        System.assert(pipeline.containsKey('EMEA'), 'Should have EMEA');
    }

    @isTest
    static void testCalculatePipelineCoverage() {
        // coverage = pipeline value / remaining quota -> >= some sanity bound
        User salesRep = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Date periodStart = Date.today().toStartOfMonth();
        Date periodEnd = periodStart.addMonths(3).addDays(-1);

        Decimal coverage = ForecastingService.calculatePipelineCoverage(
            salesRep.Id, periodStart, periodEnd
        );

        System.assert(coverage >= 0, 'Pipeline coverage should be non-negative');
    }

    // ------------------------------------------------------------------------
    // TERRITORY ASSIGNMENT (state -> region).
    // ------------------------------------------------------------------------

    @isTest
    static void testAssignTerritoryByState() {
        List<Account> accounts = new List<Account>{
            new Account(Name = 'CA Account', BillingState = 'CA'),
            new Account(Name = 'NY Account', BillingState = 'NY'),
            new Account(Name = 'TX Account', BillingState = 'TX'),
            new Account(Name = 'WA Account', BillingState = 'WA')
        };

        insert accounts;

        // The service mutates Sales_Territory__c on the passed-in records
        // (in memory - the caller is responsible for DML).
        ForecastingService.assignTerritoryByState(accounts);

        Map<String, String> territoryByState = new Map<String, String>();
        for (Account acc : accounts) {
            territoryByState.put(acc.BillingState, acc.Sales_Territory__c);
        }

        System.assertEquals('North America West', territoryByState.get('CA'));
        System.assertEquals('North America East', territoryByState.get('NY'));
        System.assertEquals('North America East', territoryByState.get('TX'));
        System.assertEquals('North America West', territoryByState.get('WA'));
    }

    @isTest
    static void testAssignTerritoryByCountry() {
        List<Account> accounts = new List<Account>{
            new Account(Name = 'UK Account', BillingCountry = 'UK'),
            new Account(Name = 'Germany Account', BillingCountry = 'Germany'),
            new Account(Name = 'Japan Account', BillingCountry = 'Japan'),
            new Account(Name = 'Brazil Account', BillingCountry = 'Brazil')
        };

        insert accounts;

        ForecastingService.assignTerritoryByCountry(accounts);

        Map<String, String> territoryByCountry = new Map<String, String>();
        for (Account acc : accounts) {
            territoryByCountry.put(acc.BillingCountry, acc.Sales_Territory__c);
        }

        System.assertEquals('EMEA', territoryByCountry.get('UK'));
        System.assertEquals('EMEA', territoryByCountry.get('Germany'));
        System.assertEquals('APAC', territoryByCountry.get('Japan'));
        System.assertEquals('LATAM', territoryByCountry.get('Brazil'));
    }

    // ------------------------------------------------------------------------
    // MANUAL OVERRIDE + EDGE CASES.
    // ------------------------------------------------------------------------

    @isTest
    static void testForecastCategoryManualOverride() {
        // Once the user sets the category by hand, the trigger keeps it
        Opportunity opp = [SELECT Id, Forecast_Category__c FROM Opportunity
                           WHERE Name = 'NA East Deal' LIMIT 1];

        opp.Forecast_Category__c = 'Commit';
        update opp;

        Opportunity updated = [SELECT Forecast_Category__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Commit', updated.Forecast_Category__c,
            'Manual override should be preserved');
    }

    @isTest
    static void testQuotaAttainmentWithNoQuota() {
        // No Quota__c in the queried period -> quotaAmount = 0, not a crash
        User salesRep = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Date pastStart = Date.today().addMonths(-6);
        Date pastEnd = Date.today().addMonths(-3);

        Map<Id, ForecastingService.QuotaAttainment> attainment =
            ForecastingService.getQuotaAttainment(
                new Set<Id>{salesRep.Id}, pastStart, pastEnd
            );

        ForecastingService.QuotaAttainment qa = attainment.get(salesRep.Id);
        System.assertEquals(0, qa.quotaAmount, 'No quota for past period');
    }

    // ------------------------------------------------------------------------
    // BULK forecast calculation (100 opportunities, single DML).
    // ------------------------------------------------------------------------

    @isTest
    static void testBulkForecastCalculation() {
        List<Opportunity> opps = new List<Opportunity>();

        for (Integer i = 0; i < 100; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Forecast ' + i,
                AccountId = [SELECT Id FROM Account LIMIT 1].Id,
                Amount = (i + 1) * 1000,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }

        insert opps;

        List<Opportunity> inserted = [SELECT Weighted_Forecast__c, Forecast_Category__c
                                       FROM Opportunity WHERE Name LIKE 'Bulk Forecast %'];

        for (Opportunity opp : inserted) {
            System.assertNotEquals(null, opp.Weighted_Forecast__c);
            System.assertNotEquals(null, opp.Forecast_Category__c);
        }
    }

    @isTest
    static void testPipelineCoverageWithClosedWon() {
        // Coverage still computes cleanly even when a deal already closed
        User salesRep = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Date periodStart = Date.today().toStartOfMonth();
        Date periodEnd = periodStart.addMonths(3).addDays(-1);

        Decimal coverage = ForecastingService.calculatePipelineCoverage(
            salesRep.Id, periodStart, periodEnd
        );

        System.assert(coverage >= 0, 'Pipeline coverage should be calculated');
    }
}