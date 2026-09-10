/*
 * ============================================================================
 * ReportingService
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 9 - Reporting & Dashboards]
 *
 * WHAT THIS CLASS DOES:
 * Provides the Apex-side analytics behind sales reports/dashboards. While
 * most reporting uses Declarative Reports, this class shows how to compute
 * the SAME metrics in Apex when you need them embedded in code, Lightning
 * components, emails, or scheduled jobs.
 *
 * METRICS PROVIDED:
 *   - Revenue by territory
 *   - Win rate by rep
 *   - Pipeline by stage + territory
 *   - Forecast accuracy (committed vs actual won)
 *   - Lead conversion funnel (new -> qualified -> converted)
 *   - Sales cycle metrics (win rate, avg deal size, avg cycle days)
 *   - Monthly revenue trend (6 months)
 *   - Top performers (by revenue and by largest deal)
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. AggregateResult-heavy patterns: SUM, COUNT, AVG, MAX, CASE WHEN.
 * 2. Returning `List<Map<String, Object>>` for loosely-structured results -
 *    useful when the caller is another layer (e.g. LWC) that can consume
 *    flexible JSON-ish structures.
 * 3. Defensive math: avoiding division-by-zero with ternaries.
 * 4. Date arithmetic: toStartOfMonth(), addMonths(), daysBetween().
 * ============================================================================
 */
public with sharing class ReportingService {

    /*
     * getRevenueByTerritory(Date startDate, Date endDate)
     * ----------------------------------------------------------------------
     * PURPOSE: Total Closed Won revenue grouped by Territory__c, sorted
     * highest first. Core input for a "Revenue by Territory" dashboard.
     * ----------------------------------------------------------------------
     */
    public static Map<String, Decimal> getRevenueByTerritory(Date startDate, Date endDate) {
        Map<String, Decimal> revenueByTerritory = new Map<String, Decimal>();

        List<AggregateResult> results = [
            SELECT Territory__c, SUM(Amount) totalRevenue
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            AND CloseDate >= :startDate AND CloseDate <= :endDate
            AND Territory__c != NULL
            GROUP BY Territory__c
            ORDER BY SUM(Amount) DESC
        ];

        for (AggregateResult ar : results) {
            revenueByTerritory.put(
                (String) ar.get('Territory__c'),
                (Decimal) ar.get('totalRevenue')
            );
        }

        return revenueByTerritory;
    }

    /*
     * getWinRateByRep(Date startDate, Date endDate)
     * ----------------------------------------------------------------------
     * PURPOSE: Compute each rep's win rate (%) = won deals / closed deals.
     * Uses conditional SUMs in ONE query (no separate queries needed).
     * ----------------------------------------------------------------------
     */
    public static Map<String, Decimal> getWinRateByRep(Date startDate, Date endDate) {
        Map<String, Decimal> winRateByRep = new Map<String, Decimal>();

        List<AggregateResult> results = [
            SELECT Owner.Name repName,
                   COUNT(Id) totalDeals,
                   SUM(CASE WHEN StageName = 'Closed Won' THEN 1 ELSE 0 END) wonDeals
            FROM Opportunity
            WHERE CloseDate >= :startDate AND CloseDate <= :endDate
            AND StageName IN ('Closed Won', 'Closed Lost')
            GROUP BY Owner.Name
        ];

        for (AggregateResult ar : results) {
            Integer total = (Integer) ar.get('totalDeals');
            Integer won = (Integer) ar.get('wonDeals');
            Decimal winRate = total > 0 ? ((Decimal) won / total) * 100 : 0;
            winRateByRep.put((String) ar.get('repName'), winRate);
        }

        return winRateByRep;
    }

    /*
     * getPipelineByStageAndTerritory()
     * ----------------------------------------------------------------------
     * PURPOSE: Pipeline broken down by (stage, territory) pairs.
     * Returns a Map where the KEY is the stage and the VALUE is the list of
     * AggregateResult rows for that stage (each row = one territory).
     * This is useful for drill-down style dashboards.
     * ----------------------------------------------------------------------
     */
    public static Map<String, List<AggregateResult>> getPipelineByStageAndTerritory() {
        Map<String, List<AggregateResult>> pipelineByStage = new Map<String, List<AggregateResult>>();

        List<AggregateResult> results = [
            SELECT StageName stage, Territory__c territory,
                   COUNT(Id) dealCount, SUM(Amount) pipelineValue
            FROM Opportunity
            WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
            GROUP BY StageName, Territory__c
            ORDER BY StageName, pipelineValue DESC
        ];

        // Group the flat result rows by stage
        for (AggregateResult ar : results) {
            String stage = (String) ar.get('stage');
            if (!pipelineByStage.containsKey(stage)) {
                pipelineByStage.put(stage, new List<AggregateResult>());
            }
            pipelineByStage.get(stage).add(ar);
        }

        return pipelineByStage;
    }

    /*
     * getForecastAccuracy(Date periodStart, Date periodEnd)
     * ----------------------------------------------------------------------
     * PURPOSE: Compare the amount COMMITTED for a period vs what was ACTUALLY
     * won in that period. A high accuracy % means reps' commitments were
     * realistic. A low % means they over-commit.
     *
     * Returns Map with keys: 'committed', 'closedWon', 'accuracy'.
     * ----------------------------------------------------------------------
     */
    public static Map<String, Decimal> getForecastAccuracy(Date periodStart, Date periodEnd) {
        Map<String, Decimal> accuracy = new Map<String, Decimal>();

        // Total amount in "Commit" forecast category for the period
        AggregateResult committed = [
            SELECT SUM(Amount) total
            FROM Opportunity
            WHERE Forecast_Category__c = 'Commit'
            AND CloseDate >= :periodStart AND CloseDate <= :periodEnd
        ];

        // Total amount actually Closed Won in the period
        AggregateResult closedWon = [
            SELECT SUM(Amount) total
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            AND CloseDate >= :periodStart AND CloseDate <= :periodEnd
        ];

        Decimal committedAmount = committed.get('total') != null
            ? (Decimal) committed.get('total') : 0;
        Decimal closedWonAmount = closedWon.get('total') != null
            ? (Decimal) closedWon.get('total') : 0;

        accuracy.put('committed', committedAmount);
        accuracy.put('closedWon', closedWonAmount);
        accuracy.put('accuracy',
            committedAmount > 0 ? (closedWonAmount / committedAmount) * 100 : 0);

        return accuracy;
    }

    /*
     * getLeadConversionFunnel(Date startDate, Date endDate)
     * ----------------------------------------------------------------------
     * PURPOSE: Classic marketing funnel - count leads at each stage:
     *   1. New Leads       (Status = 'Open - Not Contacted')
     *   2. Qualified       (Status = 'Working - Contacted')
     *   3. Converted       (IsConverted = true)
     *
     * Returns a List of Maps (one entry per stage) so it can be directly
     * rendered by a front-end component or fed into a chart.
     * ----------------------------------------------------------------------
     */
    public static List<Map<String, Object>> getLeadConversionFunnel(Date startDate, Date endDate) {
        List<Map<String, Object>> funnel = new List<Map<String, Object>>();

        AggregateResult newLeads = [
            SELECT COUNT(Id) total FROM Lead
            WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
            AND Status = 'Open - Not Contacted'
        ];

        AggregateResult qualifiedLeads = [
            SELECT COUNT(Id) total FROM Lead
            WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
            AND Status = 'Working - Contacted'
        ];

        AggregateResult convertedLeads = [
            SELECT COUNT(Id) total FROM Lead
            WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
            AND IsConverted = true
        ];

        funnel.add(new Map<String, Object>{
            'stage' => 'New Leads',
            'count' => (Integer) newLeads.get('total')
        });

        funnel.add(new Map<String, Object>{
            'stage' => 'Qualified',
            'count' => (Integer) qualifiedLeads.get('total')
        });

        funnel.add(new Map<String, Object>{
            'stage' => 'Converted',
            'count' => (Integer) convertedLeads.get('total')
        });

        return funnel;
    }

    /*
     * getSalesCycleMetrics(Date startDate, Date endDate)
     * ----------------------------------------------------------------------
     * PURPOSE: Compute a bundle of deal-performance KPIs for a date range:
     *   totalDeals, wonDeals, winRate (%), totalRevenue,
     *   avgDealSize, avgSalesCycle (days).
     *
     * The sales cycle length is computed IN APEX (not SOQL) using
     * CreatedDate.daysBetween(CloseDate) because SOQL cannot do date math.
     * ----------------------------------------------------------------------
     */
    public static Map<String, Decimal> getSalesCycleMetrics(Date startDate, Date endDate) {
        Map<String, Decimal> metrics = new Map<String, Decimal>();

        List<Opportunity> closedOpps = [
            SELECT Id, CreatedDate, CloseDate, StageName, Amount
            FROM Opportunity
            WHERE CloseDate >= :startDate AND CloseDate <= :endDate
            AND StageName IN ('Closed Won', 'Closed Lost')
        ];

        Integer totalDeals = closedOpps.size();
        Integer wonDeals = 0;
        Decimal totalRevenue = 0;
        Decimal totalDays = 0;

        for (Opportunity opp : closedOpps) {
            if (opp.StageName == 'Closed Won') {
                wonDeals++;
                totalRevenue += opp.Amount != null ? opp.Amount : 0;
            }

            if (opp.CreatedDate != null && opp.CloseDate != null) {
                Integer days = opp.CreatedDate.date().daysBetween(opp.CloseDate);
                totalDays += days;
            }
        }

        metrics.put('totalDeals', totalDeals);
        metrics.put('wonDeals', wonDeals);
        metrics.put('winRate', totalDeals > 0
            ? ((Decimal) wonDeals / totalDeals) * 100 : 0);
        metrics.put('totalRevenue', totalRevenue);
        metrics.put('avgDealSize', wonDeals > 0
            ? totalRevenue / wonDeals : 0);
        metrics.put('avgSalesCycle', totalDeals > 0
            ? totalDays / totalDeals : 0);

        return metrics;
    }

    /*
     * getMonthlyTrend(Date monthsBack)
     * ----------------------------------------------------------------------
     * PURPOSE: Return the last 6 months of Closed Won revenue + deal counts,
     * one entry per month. Month boundaries are computed with toStartOfMonth()
     * and addMonths()/addDays().
     *
     * NOTE: 6 SOQL queries - acceptable here for a small fixed batch, but in
     * production you'd batch this differently (e.g. GROUP BY CALENDAR_MONTH).
     * ----------------------------------------------------------------------
     */
    public static List<Map<String, Object>> getMonthlyTrend(Date monthsBack) {
        List<Map<String, Object>> trend = new List<Map<String, Object>>();

        // Loop 6 times, once per month, starting at the month of monthsBack
        for (Integer i = 0; i < 6; i++) {
            Date monthStart = monthsBack.addMonths(i).toStartOfMonth();
            Date monthEnd = monthStart.addMonths(1).addDays(-1);

            AggregateResult closedWon = [
                SELECT SUM(Amount) revenue, COUNT(Id) deals
                FROM Opportunity
                WHERE StageName = 'Closed Won'
                AND CloseDate >= :monthStart AND CloseDate <= :monthEnd
            ];

            Decimal revenue = closedWon.get('revenue') != null
                ? (Decimal) closedWon.get('revenue') : 0;
            Integer deals = (Integer) closedWon.get('deals');

            trend.add(new Map<String, Object>{
                'month' => monthStart,
                'revenue' => revenue,
                'deals' => deals
            });
        }

        return trend;
    }

    /*
     * getTopPerformers(Integer limit_count)
     * ----------------------------------------------------------------------
     * PURPOSE: Return the top N reps in two ways:
     *   - topRevenue: ranked by total closed-won revenue this quarter
     *   - topDeals:   ranked by their largest single deal this quarter
     *
     * Returns both lists inside a single Map so callers can choose which
     * view to display.
     * ----------------------------------------------------------------------
     */
    public static Map<String, Object> getTopPerformers(Integer limit_count) {
        Map<String, Object> result = new Map<String, Object>();

        List<AggregateResult> topRevenue = [
            SELECT Owner.Name repName, SUM(Amount) totalRevenue, COUNT(Id) deals
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            AND CloseDate = THIS_QUARTER
            GROUP BY Owner.Name
            ORDER BY SUM(Amount) DESC
            LIMIT :limit_count
        ];

        List<AggregateResult> topDeals = [
            SELECT Owner.Name repName, MAX(Amount) largestDeal, COUNT(Id) totalDeals
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            AND CloseDate = THIS_QUARTER
            GROUP BY Owner.Name
            ORDER BY MAX(Amount) DESC
            LIMIT :limit_count
        ];

        result.put('topRevenue', topRevenue);
        result.put('topDeals', topDeals);

        return result;
    }
}