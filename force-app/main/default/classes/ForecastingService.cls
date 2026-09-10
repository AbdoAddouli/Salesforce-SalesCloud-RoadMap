/*
 * ============================================================================
 * ForecastingService
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 8 - Forecasting & Territories]
 *
 * WHAT THIS CLASS DOES:
 * Implements the math and query logic behind SALES FORECASTING and
 * TERRITORY assignment:
 *   - Weighted forecast calculation (Amount * Probability)
 *   - Default forecast category mapping
 *   - Per-user forecast breakdown (pipeline, commit, best case)
 *   - Quota attainment tracking
 *   - Territory-based pipeline reporting
 *   - Pipeline coverage ratio (pipeline vs remaining quota)
 *   - Territory auto-assignment by State or Country
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Forecast terminology:
 *    - Pipeline      = all open deals
 *    - Commit        = deals the rep is confident will close
 *    - Best Case     = deals that could close
 *    - Weighted      = deal size x probability (expected value)
 *
 * 2. AggregateResult with GROUP BY for roll-ups.
 * 3. Map<Id, InnerClass> - returning rich computed objects keyed by User.
 * 4. Multiple inner classes as typed result containers.
 * ============================================================================
 */
public with sharing class ForecastingService {

    /*
     * calculateWeightedForecast(List<Opportunity> opportunities)
     * ----------------------------------------------------------------------
     * PURPOSE: Set Weighted_Forecast__c = Amount * (Probability / 100).
     * This is the "expected value" of the deal - what it contributes to the
     * forecast statistically.
     * ----------------------------------------------------------------------
     */
    public static void calculateWeightedForecast(List<Opportunity> opportunities) {
        for (Opportunity opp : opportunities) {
            if (opp.Amount != null && opp.Probability != null) {
                opp.Weighted_Forecast__c = opp.Amount * (opp.Probability / 100);
            }
        }
    }

    /*
     * setDefaultForecastCategory(List<Opportunity> opportunities)
     * ----------------------------------------------------------------------
     * PURPOSE: If a rep has not chosen a Forecast_Category__c, infer one
     * from the deal's StageName. This keeps forecasts consistent.
     *
     * MAPPING:
     *   Closed Won / Closed Lost  --> "Closed"
     *   Negotiation/Review        --> "Commit"   (almost there)
     *   Proposal/Price Quote      --> "Best Case"
     *   Anything else             --> "Pipeline"
     * ----------------------------------------------------------------------
     */
    public static void setDefaultForecastCategory(List<Opportunity> opportunities) {
        for (Opportunity opp : opportunities) {
            if (opp.Forecast_Category__c == null) {
                if (opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost') {
                    opp.Forecast_Category__c = 'Closed';
                } else if (opp.StageName == 'Negotiation/Review') {
                    opp.Forecast_Category__c = 'Commit';
                } else if (opp.StageName == 'Proposal/Price Quote') {
                    opp.Forecast_Category__c = 'Best Case';
                } else {
                    opp.Forecast_Category__c = 'Pipeline';
                }
            }
        }
    }

    /*
     * getForecastByUser(Set<Id> userIds, Date periodStart, Date periodEnd)
     * ----------------------------------------------------------------------
     * PURPOSE: Build a forecast breakdown per user for a date range.
     *
     * RESULTS (per user, in the ForecastSummary inner class):
     *   totalPipeline   = $ of all open deals (excluding Closed Lost)
     *   totalWeighted   = $ of weighted forecasts
     *   commitAmount    = $ of Commit-category + Closed Won deals
     *   bestCaseAmount  = $ of Best Case-category deals
     *   closedWon       = $ actually won
     *   dealCount       = number of deals
     *
     * NOTE: We pre-seed the map with an empty summary per user so every
     * requested user appears even if they have no data.
     * ----------------------------------------------------------------------
     */
    public static Map<Id, ForecastSummary> getForecastByUser(Set<Id> userIds, Date periodStart, Date periodEnd) {
        // Initialize: every user gets an (empty) forecast summary
        Map<Id, ForecastSummary> forecastsByUser = new Map<Id, ForecastSummary>();

        for (Id userId : userIds) {
            forecastsByUser.put(userId, new ForecastSummary());
        }

        // Query all matching open opportunities in the period
        List<Opportunity> opportunities = [
            SELECT Id, Amount, Forecast_Category__c, Forecast_Amount__c,
                   Weighted_Forecast__c, StageName, OwnerId, CloseDate
            FROM Opportunity
            WHERE OwnerId IN :userIds
            AND CloseDate >= :periodStart AND CloseDate <= :periodEnd
            AND StageName NOT IN ('Closed Lost')
        ];

        for (Opportunity opp : opportunities) {
            ForecastSummary fs = forecastsByUser.get(opp.OwnerId);

            fs.totalPipeline += opp.Amount != null ? opp.Amount : 0;
            fs.totalWeighted += opp.Weighted_Forecast__c != null ? opp.Weighted_Forecast__c : 0;

            // Commit = committed deals OR already won
            if (opp.Forecast_Category__c == 'Commit' || opp.StageName == 'Closed Won') {
                fs.commitAmount += opp.Amount != null ? opp.Amount : 0;
            } else if (opp.Forecast_Category__c == 'Best Case') {
                fs.bestCaseAmount += opp.Amount != null ? opp.Amount : 0;
            }

            if (opp.StageName == 'Closed Won') {
                fs.closedWon += opp.Amount != null ? opp.Amount : 0;
            }

            fs.dealCount++;
        }

        return forecastsByUser;
    }

    /*
     * getQuotaAttainment(Set<Id> userIds, Date periodStart, Date periodEnd)
     * ----------------------------------------------------------------------
     * PURPOSE: Compare each user's QUOTA (target) against their ACTUAL won
     * revenue, and return the attainment %.
     *
     * SOURCES:
     *   - Quota__c object: the target amounts (filtered by period overlap)
     *   - Opportunity data: sum of Closed Won Amount (by owner)
     *
     * RETURNS Map<Id, QuotaAttainment> where:
     *   quotaAmount       = the user's quota for the period
     *   actualRevenue     = closed won revenue in the period
     *   attainmentPercent = actual / quota * 100
     * ----------------------------------------------------------------------
     */
    public static Map<Id, QuotaAttainment> getQuotaAttainment(Set<Id> userIds, Date periodStart, Date periodEnd) {
        Map<Id, QuotaAttainment> attainmentByUser = new Map<Id, QuotaAttainment>();

        // 1) Fetch the quotas in range
        List<Quota__c> quotas = [
            SELECT Id, User__c, Amount__c, Period_Start__c, Period_End__c
            FROM Quota__c
            WHERE User__c IN :userIds
            AND Period_Start__c >= :periodStart
            AND Period_End__c <= :periodEnd
        ];

        // Map user -> quota amount
        Map<Id, Decimal> quotaMap = new Map<Id, Decimal>();
        for (Quota__c q : quotas) {
            quotaMap.put(q.User__c, q.Amount__c);
        }

        // 2) Aggregate actual closed-won revenue per user
        List<AggregateResult> results = [
            SELECT OwnerId, SUM(Amount) totalRevenue
            FROM Opportunity
            WHERE OwnerId IN :userIds
            AND StageName = 'Closed Won'
            AND CloseDate >= :periodStart AND CloseDate <= :periodEnd
            GROUP BY OwnerId
        ];

        Map<Id, Decimal> revenueByUser = new Map<Id, Decimal>();
        for (AggregateResult ar : results) {
            revenueByUser.put((Id) ar.get('OwnerId'), (Decimal) ar.get('totalRevenue'));
        }

        // 3) Combine into the result map
        for (Id userId : userIds) {
            QuotaAttainment qa = new QuotaAttainment();
            qa.userId = userId;
            qa.quotaAmount = quotaMap.containsKey(userId) ? quotaMap.get(userId) : 0;
            qa.actualRevenue = revenueByUser.containsKey(userId) ? revenueByUser.get(userId) : 0;
            qa.attainmentPercent = qa.quotaAmount > 0
                ? (qa.actualRevenue / qa.quotaAmount) * 100 : 0;

            attainmentByUser.put(userId, qa);
        }

        return attainmentByUser;
    }

    /*
     * getPipelineByTerritory()
     * ----------------------------------------------------------------------
     * PURPOSE: Total $ of open pipeline grouped by Territory__c, sorted
     * largest first. Uses GROUP BY + SUM in one AggregateResult query.
     * ----------------------------------------------------------------------
     */
    public static Map<String, Decimal> getPipelineByTerritory() {
        Map<String, Decimal> pipelineByTerritory = new Map<String, Decimal>();

        List<AggregateResult> results = [
            SELECT Territory__c territory, SUM(Amount) totalAmount
            FROM Opportunity
            WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
            AND Territory__c != NULL
            GROUP BY Territory__c
            ORDER BY SUM(Amount) DESC
        ];

        for (AggregateResult ar : results) {
            pipelineByTerritory.put((String) ar.get('territory'), (Decimal) ar.get('totalAmount'));
        }

        return pipelineByTerritory;
    }

    /*
     * calculatePipelineCoverage(Id userId, Date periodStart, Date periodEnd)
     * ----------------------------------------------------------------------
     * PURPOSE: A classic sales metric - the "pipeline coverage ratio".
     *
     * FORMULA:  (open pipeline today) / (quota - revenue already won)
     *
     * What it means: how many dollars of open pipeline exist for every
     * dollar of quota that still needs to be closed? A ratio of ~3x is a
     * common healthy target.
     * ----------------------------------------------------------------------
     */
    public static Decimal calculatePipelineCoverage(Id userId, Date periodStart, Date periodEnd) {
        // Open pipeline
        AggregateResult pipelineResult = [
            SELECT SUM(Amount) totalPipeline
            FROM Opportunity
            WHERE OwnerId = :userId
            AND StageName NOT IN ('Closed Won', 'Closed Lost')
            AND CloseDate >= :periodStart AND CloseDate <= :periodEnd
        ];

        Decimal pipeline = pipelineResult.get('totalPipeline') != null
            ? (Decimal) pipelineResult.get('totalPipeline') : 0;

        // Quota for the same period
        List<Quota__c> quotas = [
            SELECT Amount__c
            FROM Quota__c
            WHERE User__c = :userId
            AND Period_Start__c >= :periodStart
            AND Period_End__c <= :periodEnd
        ];

        Decimal quota = !quotas.isEmpty() ? quotas[0].Amount__c : 0;

        // Revenue already closed this period (subtract from remaining quota)
        Decimal closedWon = [
            SELECT SUM(Amount) total
            FROM Opportunity
            WHERE OwnerId = :userId
            AND StageName = 'Closed Won'
            AND CloseDate >= :periodStart AND CloseDate <= :periodEnd
        ].get('total') != null
            ? (Decimal) [SELECT SUM(Amount) total FROM Opportunity
                          WHERE OwnerId = :userId AND StageName = 'Closed Won'
                          AND CloseDate >= :periodStart AND CloseDate <= :periodEnd].get('total')
            : 0;

        Decimal remainingQuota = quota - closedWon;

        // Never divide by zero or a negative
        return remainingQuota > 0 ? pipeline / remainingQuota : 0;
    }

    /*
     * assignTerritoryByState(List<Account> accounts)
     * ----------------------------------------------------------------------
     * PURPOSE: Set Sales_Territory__c on an Account based on its Billing
     * State (US states only). Uses String comparison after uppercasing.
     * ----------------------------------------------------------------------
     */
    public static void assignTerritoryByState(List<Account> accounts) {
        for (Account acc : accounts) {
            if (acc.BillingState != null) {
                String state = acc.BillingState.toUpperCase();

                if (state == 'CA' || state == 'WA' || state == 'OR' || state == 'NV' || state == 'AZ') {
                    acc.Sales_Territory__c = 'North America West';
                } else if (state == 'NY' || state == 'NJ' || state == 'CT' || state == 'MA' ||
                           state == 'PA' || state == 'DC' || state == 'VA' || state == 'MD') {
                    acc.Sales_Territory__c = 'North America East';
                } else {
                    acc.Sales_Territory__c = 'North America East'; // default
                }
            }
        }
    }

    /*
     * assignTerritoryByCountry(List<Account> accounts)
     * ----------------------------------------------------------------------
     * PURPOSE: Same as the state version but for international accounts.
     * Uses Sets of country names to decide EMEA / APAC / LATAM / NA.
     * ----------------------------------------------------------------------
     */
    public static void assignTerritoryByCountry(List<Account> accounts) {
        // Pre-defined country groups
        Set<String> emeaCountries = new Set<String>{
            'UK', 'Germany', 'France', 'Spain', 'Italy', 'Netherlands', 'Sweden', 'Norway',
            'Denmark', 'Finland', 'Switzerland', 'Austria', 'Belgium', 'Ireland', 'Portugal'
        };

        Set<String> apacCountries = new Set<String>{
            'Australia', 'New Zealand', 'Japan', 'South Korea', 'Singapore', 'India',
            'China', 'Hong Kong', 'Taiwan', 'Thailand', 'Malaysia', 'Indonesia', 'Philippines'
        };

        Set<String> latamCountries = new Set<String>{
            'Brazil', 'Mexico', 'Argentina', 'Chile', 'Colombia', 'Peru', 'Venezuela'
        };

        for (Account acc : accounts) {
            if (acc.BillingCountry != null) {
                String country = acc.BillingCountry;

                if (emeaCountries.contains(country)) {
                    acc.Sales_Territory__c = 'EMEA';
                } else if (apacCountries.contains(country)) {
                    acc.Sales_Territory__c = 'APAC';
                } else if (latamCountries.contains(country)) {
                    acc.Sales_Territory__c = 'LATAM';
                } else {
                    acc.Sales_Territory__c = 'North America East'; // default
                }
            }
        }
    }

    /*
     * ForecastSummary  [INNER CLASS - RESULT CONTAINER]
     * ----------------------------------------------------------------------
     * Holds per-user forecast totals.
     * ----------------------------------------------------------------------
     */
    public class ForecastSummary {
        public Decimal totalPipeline = 0;
        public Decimal totalWeighted = 0;
        public Decimal commitAmount = 0;
        public Decimal bestCaseAmount = 0;
        public Decimal closedWon = 0;
        public Integer dealCount = 0;
    }

    /*
     * QuotaAttainment  [INNER CLASS - RESULT CONTAINER]
     * ----------------------------------------------------------------------
     * Holds quota vs actual revenue + computed attainment %.
     * ----------------------------------------------------------------------
     */
    public class QuotaAttainment {
        public Id userId;
        public Decimal quotaAmount = 0;
        public Decimal actualRevenue = 0;
        public Decimal attainmentPercent = 0;
    }
}