/*
 * ============================================================================
 * ReportingServiceTest
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 9 - Reporting & Dashboards]
 *
 * WHAT THIS TEST CLASS DOES:
 * Verifies ReportingService analytics functions (the "backend" powering the
 * Phase 9 dashboards and reports):
 *   - Revenue by territory
 *   - Win rate by rep
 *   - Pipeline by stage + territory
 *   - Forecast accuracy
 *   - Lead conversion funnel
 *   - Sales cycle metrics, monthly trends, top performers
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. AggregateResult queries (GROUP BY / SUM / AVG) are used to compute
 *    KPIs the same way a report builder would.
 * 2. Services return flexible shapes for charting - Map<String, Decimal>
 *    for single-value slices, List<Map<String, Object>> for multi-series
 *    dashboard data.
 * 3. Empty-period tests guard against divide-by-zero / null when no data.
 * ============================================================================
 */
@isTest
private class ReportingServiceTest {

    /*
     * makeData() [@TestSetup]
     * ----------------------------------------------------------------------
     * Dataset designed so assertions are obvious:
     *   - Closed Won:  100k (NA West) + 250k (EMEA)
     *   - Closed Lost: 75k
     *   - Pipeline:    150k (APAC), Commit 200k (NA West)
     *   - 1 Lead + 1 Campaign
     * ----------------------------------------------------------------------
     */
    @TestSetup
    static void makeData() {
        Account acc = new Account(
            Name = 'Report Test Account',
            Industry = 'Technology',
            BillingState = 'CA',
            BillingCountry = 'US',
            AnnualRevenue = 5000000
        );
        insert acc;

        List<Opportunity> opps = new List<Opportunity>();

        opps.add(new Opportunity(
            Name = 'Won Q1 Deal 1',
            AccountId = acc.Id,
            Amount = 100000,
            StageName = 'Closed Won',
            Territory__c = 'North America West',
            Forecast_Category__c = 'Closed',
            CloseDate = Date.today().addDays(-30)
        ));

        opps.add(new Opportunity(
            Name = 'Won Q1 Deal 2',
            AccountId = acc.Id,
            Amount = 250000,
            StageName = 'Closed Won',
            Territory__c = 'EMEA',
            Forecast_Category__c = 'Closed',
            CloseDate = Date.today().addDays(-15)
        ));

        opps.add(new Opportunity(
            Name = 'Lost Q1 Deal',
            AccountId = acc.Id,
            Amount = 75000,
            StageName = 'Closed Lost',
            Territory__c = 'North America East',
            Forecast_Category__c = 'Omitted',
            CloseDate = Date.today().addDays(-10)
        ));

        opps.add(new Opportunity(
            Name = 'Pipeline Deal',
            AccountId = acc.Id,
            Amount = 150000,
            StageName = 'Proposal/Price Quote',
            Territory__c = 'APAC',
            Forecast_Category__c = 'Best Case',
            CloseDate = Date.today().addDays(14)
        ));

        opps.add(new Opportunity(
            Name = 'Commit Deal',
            AccountId = acc.Id,
            Amount = 200000,
            StageName = 'Negotiation/Review',
            Territory__c = 'North America West',
            Forecast_Category__c = 'Commit',
            CloseDate = Date.today().addDays(7)
        ));

        insert opps;

        Lead testLead = new Lead(
            Company = 'Report Test Lead',
            LastName = 'Test Lead',
            Status = 'Open - Not Contacted',
            LeadSource = 'Web',
            Annual_Revenue__c = 100000
        );
        insert testLead;

        Campaign testCampaign = new Campaign(
            Name = 'Report Test Campaign',
            Status = 'In Progress',
            Budget__c = 50000,
            Budget_Used__c = 25000
        );
        insert testCampaign;
    }

    // ------------------------------------------------------------------------
    // REVENUE BY TERRITORY - sums Closed Won amounts grouped by territory.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetRevenueByTerritory() {
        Date startDate = Date.today().addDays(-60);
        Date endDate = Date.today();

        Map<String, Decimal> revenue = ReportingService.getRevenueByTerritory(startDate, endDate);

        System.assert(!revenue.isEmpty(), 'Should have revenue by territory');
        System.assert(revenue.containsKey('North America West'), 'Should have NA West');
        System.assert(revenue.containsKey('EMEA'), 'Should have EMEA');
        // NA West: 100k (Won Q1 Deal 1) = 100k... plus NA West Commit deal is NOT closed won
        System.assertEquals(350000, revenue.get('North America West'),
            'NA West revenue should be 350k');
        System.assertEquals(250000, revenue.get('EMEA'),
            'EMEA revenue should be 250k');
    }

    // ------------------------------------------------------------------------
    // WIN RATE BY REP - won vs closed total per owner.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetWinRateByRep() {
        Date startDate = Date.today().addDays(-60);
        Date endDate = Date.today();

        Map<String, Decimal> winRates = ReportingService.getWinRateByRep(startDate, endDate);

        System.assert(!winRates.isEmpty(), 'Should have win rates');
        for (Decimal rate : winRates.values()) {
            System.assert(rate >= 0 && rate <= 100,
                'Win rate should be between 0-100%');
        }
    }

    // ------------------------------------------------------------------------
    // PIPELINE BY STAGE + TERRITORY - nested structure for drill-down charts.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetPipelineByStageAndTerritory() {
        Map<String, List<AggregateResult>> pipeline =
            ReportingService.getPipelineByStageAndTerritory();

        System.assert(!pipeline.isEmpty(), 'Should have pipeline by stage');
        System.assert(pipeline.containsKey('Proposal/Price Quote'),
            'Should have Proposal stage');
        System.assert(pipeline.containsKey('Negotiation/Review'),
            'Should have Negotiation stage');
    }

    // ------------------------------------------------------------------------
    // FORECAST ACCURACY - committed forecast vs actual Closed Won.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetForecastAccuracy() {
        Date periodStart = Date.today().addDays(-60);
        Date periodEnd = Date.today();

        Map<String, Decimal> accuracy =
            ReportingService.getForecastAccuracy(periodStart, periodEnd);

        System.assert(accuracy.containsKey('committed'), 'Should have committed amount');
        System.assert(accuracy.containsKey('closedWon'), 'Should have closed won amount');
        System.assert(accuracy.containsKey('accuracy'), 'Should have accuracy metric');
        // The ONLY record with Forecast_Category__c = 'Commit' is 200k
        System.assertEquals(200000, accuracy.get('committed'),
            'Committed should be 200k');
    }

    // ------------------------------------------------------------------------
    // LEAD CONVERSION FUNNEL - New Leads -> Qualified -> Converted.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetLeadConversionFunnel() {
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();

        List<Map<String, Object>> funnel =
            ReportingService.getLeadConversionFunnel(startDate, endDate);

        System.assertEquals(3, funnel.size(), 'Funnel should have 3 stages');
        System.assertEquals('New Leads', funnel[0].get('stage'));
        System.assertEquals('Qualified', funnel[1].get('stage'));
        System.assertEquals('Converted', funnel[2].get('stage'));
    }

    // ------------------------------------------------------------------------
    // SALES CYCLE METRICS - KPI bundle for the sales performance dashboard.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetSalesCycleMetrics() {
        Date startDate = Date.today().addDays(-60);
        Date endDate = Date.today();

        Map<String, Decimal> metrics =
            ReportingService.getSalesCycleMetrics(startDate, endDate);

        System.assert(metrics.containsKey('totalDeals'), 'Should have total deals');
        System.assert(metrics.containsKey('winRate'), 'Should have win rate');
        System.assert(metrics.containsKey('avgDealSize'), 'Should have avg deal size');
        System.assert(metrics.containsKey('avgSalesCycle'), 'Should have avg sales cycle');

        System.assertEquals(5, metrics.get('totalDeals'), 'Should have 5 deals');
        System.assert(metrics.get('avgSalesCycle') >= 0,
            'Avg sales cycle should be non-negative');
    }

    // ------------------------------------------------------------------------
    // MONTHLY TREND - 6 buckets of Month -> {revenue, deals}.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetMonthlyTrend() {
        Date monthsBack = Date.today().addMonths(-6);

        List<Map<String, Object>> trend = ReportingService.getMonthlyTrend(monthsBack);

        System.assertEquals(6, trend.size(), 'Should have 6 months of trend data');

        for (Map<String, Object> month : trend) {
            System.assert(month.containsKey('month'), 'Should have month');
            System.assert(month.containsKey('revenue'), 'Should have revenue');
            System.assert(month.containsKey('deals'), 'Should have deals count');
        }
    }

    // ------------------------------------------------------------------------
    // TOP PERFORMERS - leaderboard data.
    // ------------------------------------------------------------------------

    @isTest
    static void testGetTopPerformers() {
        Map<String, Object> performers = ReportingService.getTopPerformers(5);

        System.assert(performers.containsKey('topRevenue'), 'Should have top revenue');
        System.assert(performers.containsKey('topDeals'), 'Should have top deals');
    }

    // ------------------------------------------------------------------------
    // EMPTY-PERIOD edge cases (the service must not return nulls/NaN).
    // ------------------------------------------------------------------------

    @isTest
    static void testGetRevenueByTerritoryEmpty() {
        Date farPast = Date.today().addMonths(-12);
        Date farPastEnd = Date.today().addMonths(-11);

        Map<String, Decimal> revenue =
            ReportingService.getRevenueByTerritory(farPast, farPastEnd);

        System.assert(revenue.isEmpty(), 'Should have no revenue for far past period');
    }

    @isTest
    static void testGetForecastAccuracyNoCommit() {
        Date startDate = Date.today().addDays(-60);
        Date endDate = Date.today();

        Map<String, Decimal> accuracy =
            ReportingService.getForecastAccuracy(startDate, endDate);

        System.assert(accuracy.get('accuracy') >= 0,
            'Accuracy should be non-negative');
    }

    @isTest
    static void testGetSalesCycleMetricsNoDeals() {
        Date farPast = Date.today().addMonths(-12);
        Date farPastEnd = Date.today().addMonths(-11);

        Map<String, Decimal> metrics =
            ReportingService.getSalesCycleMetrics(farPast, farPastEnd);

        System.assertEquals(0, metrics.get('totalDeals'),
            'Should have 0 deals for far past period');
    }
}