/*
 * ============================================================================
 * OpportunityService
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 4 - Opportunity Management]
 *
 * WHAT THIS CLASS DOES:
 * Contains business logic for Opportunities (the sales deals/pipeline).
 * Called from OpportunityTrigger (events on insert/update).
 *
 * RESPONSIBILITIES:
 *   - Set a default CloseDate based on the sales stage
 *   - Create review Tasks when the stage changes
 *   - Auto-close stale (inactive) opportunities
 *   - Calculate pipeline, win-rate, deal-size, and cycle-length analytics
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Using Trigger context variables: `Trigger.isInsert`, `Trigger.isUpdate`,
 *    `Trigger.oldMap` - to know WHY we are being called and compare
 *    old vs new field values.
 *
 * 2. AggregateResult - SOQL's GROUP BY summary queries return rows of type
 *    AggregateResult, and you must CAST the group values back to their
 *    original type with `(Decimal) ar.get('...')`.
 *
 * 3. Static utility methods - Everything is `static` so the class acts as a
 *    namespace of reusable functions (no need to instantiate).
 * ============================================================================
 */
public with sharing class OpportunityService {

    /*
     * setCloseDateByStage(List<Opportunity> opportunities)
     * ----------------------------------------------------------------------
     * PURPOSE: Automatically set the expected CloseDate when a deal enters a
     * known stage. Keeps the forecast realistic.
     *
     * LOGIC:
     *   - Only run when inserting, OR when the StageName actually changed
     *     (compare Trigger.oldMap). We DON'T want to overwrite the close date
     *     on every update of unrelated fields.
     *   - Prospecting  --> +90 days
     *   - Qualification--> +60 days
     *   - Needs Analysis--> +45 days
     *   - Proposal/Price Quote --> +30 days
     *   - Negotiation/Review --> +14 days
     * ----------------------------------------------------------------------
     */
    public static void setCloseDateByStage(List<Opportunity> opportunities) {
        for (Opportunity opp : opportunities) {
            // Insert OR (Update + the StageName actually changed)
            if (Trigger.isInsert || (Trigger.isUpdate &&
                Trigger.oldMap.get(opp.Id).StageName != opp.StageName)) {

                if (opp.StageName == 'Prospecting') {
                    opp.CloseDate = Date.today().addDays(90);
                } else if (opp.StageName == 'Qualification') {
                    opp.CloseDate = Date.today().addDays(60);
                } else if (opp.StageName == 'Needs Analysis') {
                    opp.CloseDate = Date.today().addDays(45);
                } else if (opp.StageName == 'Proposal/Price Quote') {
                    opp.CloseDate = Date.today().addDays(30);
                } else if (opp.StageName == 'Negotiation/Review') {
                    opp.CloseDate = Date.today().addDays(14);
                }
            }
        }
    }

    /*
     * createStageChangeTasks(List<Opportunity> opportunities)
     * ----------------------------------------------------------------------
     * PURPOSE: Whenever a deal moves to a new stage, create a Task assigned
     * to the opportunity owner to review the deal. Keeps reps on top of
     * their pipeline.
     *
     * WHY `Trigger.isUpdate` check? Tasks are only created on stage CHANGES,
     * and stage changes only happen on UPDATE. On insert there is no "old"
     * stage to compare against.
     *
     * HOW: This CREATEs new records, so it must run in an `after update`
     * trigger (record Ids exist at that point).
     * ----------------------------------------------------------------------
     */
    public static void createStageChangeTasks(List<Opportunity> opportunities) {
        List<Task> tasksToCreate = new List<Task>();

        for (Opportunity opp : opportunities) {
            if (Trigger.isUpdate) {
                Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
                if (oldOpp.StageName != opp.StageName) {
                    String subject = 'Review deal at stage: ' + opp.StageName;
                    tasksToCreate.add(new Task(
                        Subject = subject,
                        WhatId = opp.Id,            // link to the Opportunity
                        OwnerId = opp.OwnerId,      // assign to the rep
                        ActivityDate = Date.today().addDays(3),
                        Priority = 'Normal',
                        Status = 'Not Started',
                        Description = 'Stage changed from ' + oldOpp.StageName + ' to ' + opp.StageName
                    ));
                }
            }
        }

        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }

    /*
     * autoCloseStaleOpportunities(Integer staleDays)
     * ----------------------------------------------------------------------
     * PURPOSE: Close any open opportunity that has had NO activity for
     * `staleDays` days. Prevents dead deals from staying in the pipeline
     * and making forecasts look better than they are.
     *
     * HOW IT WORKS:
     *   - Queries for opportunities where:
     *       1. Stage is not already Closed Won or Closed Lost
     *       2. LastActivityDate is older than the cutoff
     *   - Marks each as Closed Lost with an explanatory description.
     *
     * NOTE: This is a "Scheduled" style method - an admin would run it via
     * Scheduled Apex, the Anonymous Apex window, or a scheduled flow.
     * ----------------------------------------------------------------------
     */
    public static void autoCloseStaleOpportunities(Integer staleDays) {
        Date cutoffDate = Date.today().addDays(-staleDays);

        List<Opportunity> staleOpps = [
            SELECT Id, Name, StageName, LastActivityDate, Days_Open__c
            FROM Opportunity
            WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
            AND LastActivityDate < :cutoffDate
            AND LastActivityDate != NULL
        ];

        for (Opportunity opp : staleOpps) {
            opp.StageName = 'Closed Lost';
            opp.Description = 'Auto-closed: No activity for ' + staleDays +
                ' days. Last activity: ' + opp.LastActivityDate.format();
        }

        if (!staleOpps.isEmpty()) {
            update staleOpps;
        }
    }

    /*
     * calculatePipelineByStage()
     * ----------------------------------------------------------------------
     * PURPOSE: Returns the total dollar value of open pipeline grouped by
     * sales stage. Uses an AggregateResult query (GROUP BY + SUM).
     *
     * NOTE: The Map key is the StageName cast to Id (odd choice kept for
     * learning - a String key would be more common).
     * ----------------------------------------------------------------------
     */
    public static Map<Id, Decimal> calculatePipelineByStage() {
        Map<Id, Decimal> pipelineByStage = new Map<Id, Decimal>();

        List<AggregateResult> results = [
            SELECT StageName stage, SUM(Amount) totalAmount
            FROM Opportunity
            WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
            GROUP BY StageName
            ORDER BY SUM(Amount) DESC
        ];

        for (AggregateResult ar : results) {
            // ar.get('stage') gets the grouped value; must cast to correct type
            pipelineByStage.put((Id) ar.get('stage'), (Decimal) ar.get('totalAmount'));
        }

        return pipelineByStage;
    }

    /*
     * calculateWinRate(Date startDate, Date endDate)
     * ----------------------------------------------------------------------
     * PURPOSE: What % of closed deals were won during a date range?
     * Uses two conditional aggregations (CASE WHEN in SOQL) in ONE query:
     *   - wins  = count of Closed Won
     *   - total = count of Closed Won OR Closed Lost
     * ----------------------------------------------------------------------
     */
    public static Decimal calculateWinRate(Date startDate, Date endDate) {
        AggregateResult result = [
            SELECT
                SUM(CASE WHEN StageName = 'Closed Won' THEN 1 ELSE 0 END) wins,
                SUM(CASE WHEN StageName IN ('Closed Won', 'Closed Lost') THEN 1 ELSE 0 END) total
            FROM Opportunity
            WHERE CloseDate >= :startDate AND CloseDate <= :endDate
        ];

        Decimal wins = (Decimal) result.get('wins');
        Decimal total = (Decimal) result.get('total');

        // Protect against division by zero
        if (total == null || total == 0) return 0;
        return (wins / total) * 100;
    }

    /*
     * calculateAverageDealSize(Date startDate, Date endDate)
     * ----------------------------------------------------------------------
     * PURPOSE: Average Amount of Closed Won deals in a period.
     * Uses AVG() aggregate in SOQL.
     * ----------------------------------------------------------------------
     */
    public static Decimal calculateAverageDealSize(Date startDate, Date endDate) {
        AggregateResult result = [
            SELECT AVG(Amount) avgAmount
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            AND CloseDate >= :startDate AND CloseDate <= :endDate
        ];

        return result.get('avgAmount') != null ? (Decimal) result.get('avgAmount') : 0;
    }

    /*
     * calculateAverageCycleLength(Date startDate, Date endDate)
     * ----------------------------------------------------------------------
     * PURPOSE: Average number of days from Opportunity creation to close
     * for won deals. A key sales-effectiveness metric ("velocity").
     * Computed in Apex (NOT with SOQL) because day-diff arithmetic isn't
     * natively available in SOQL aggregates.
     * ----------------------------------------------------------------------
     */
    public static Integer calculateAverageCycleLength(Date startDate, Date endDate) {
        List<Opportunity> closedOpps = [
            SELECT CreatedDate, CloseDate
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            AND CloseDate >= :startDate AND CloseDate <= :endDate
        ];

        if (closedOpps.isEmpty()) return 0;

        Long totalDays = 0;
        for (Opportunity opp : closedOpps) {
            // daysBetween() returns an Integer number of days between two Dates
            totalDays += opp.CreatedDate.date().daysBetween(opp.CloseDate);
        }

        return Integer.valueOf(totalDays / closedOpps.size());
    }
}