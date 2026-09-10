/*
 * ============================================================================
 * LeadScoringService
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 2 - Lead Management]
 *
 * WHAT THIS CLASS DOES:
 * This "Service" class contains the business logic for scoring, ranking,
 * and nurturing leads in Salesforce. It is called from the LeadTrigger
 * (before insert and before update) so that everytime a Lead is created or
 * edited in the system, its quality is automatically assessed.
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Service Layer Pattern - Business logic is kept OUT of triggers and in
 *    reusable classes. Triggers stay thin and simply delegate work here.
 *    This is a best practice recommended by Salesforce.
 *
 * 2. `with sharing` - This keyword enforces the user's record-level security
 *    (CRUD and FLS). Users running this code can only see/edit records they
 *    have permission to see, even if Apex would normally bypass security.
 *    Without `with sharing` (or using `without sharing`), a flow/class could
 *    expose records the user shouldn't see.
 *
 * 3. Bulkification - Methods take a `List<Lead>` so they work with the
 *    batch of records that a trigger processes. For example, if a user
 *    imports 200 leads in a Data Loader job, the trigger must handle all
 *    200 records at once - NOT in a For Loop that runs queries per record
 *    (which would hit governor limits).
 *
 * 4. Field updates in-memory - These methods modify fields on the records
 *    already in Trigger.new. Because the trigger runs `before insert/update`,
 *    Salesforce saves these changes automatically with the original DML.
 *    No additional update call is needed.
 *
 * 5. Score calculation with `Math.min(score, 100)` - Caps the score at 100
 *    so it never exceeds the max allowed value.
 * ============================================================================
 */
public with sharing class LeadScoringService {

    /*
     * calculateLeadScore(List<Lead> leads)
     * ----------------------------------------------------------------------
     * PURPOSE: Assign a numeric score (0-100) to each lead based on how
     * valuable the lead appears to be. Used to prioritize which sales reps
     * should call first.
     *
     * BUSINESS RULES (each contributes points):
     *   - Technology or Finance industry ......... +20  (profitable buyers)
     *   - Annual revenue >= $1M ................... +25  (large company budget)
     *   - Referral or Partner source .............. +15  (trusted) 
     *   - Has an email address .................... +10  (reachable)
     *   - Has a phone number ...................... +10  (reachable)
     *   - 100+ employees .......................... +20  (size indicator)
     *
     * WHY IT'S IN A "before" TRIGGER: We can modify the record in memory
     * before it is saved, which is more efficient than doing it "after"
     * and then performing a second update DML operation.
     * ----------------------------------------------------------------------
     */
    public static void calculateLeadScore(List<Lead> leads) {
        // Loop over every lead in the batch (Trigger.new)
        for (Lead l : leads) {
            Integer score = 0; // Start at zero for each lead

            // High-value industry check
            if (l.Industry == 'Technology' || l.Industry == 'Finance') {
                score += 20;
            }

            // Large company check ($1M+ annual revenue)
            if (l.AnnualRevenue != null && l.AnnualRevenue >= 1000000) {
                score += 25;
            }

            // Trusted lead source check
            if (l.LeadSource == 'Referral' || l.LeadSource == 'Partner') {
                score += 15;
            }

            // Contactability checks
            if (l.Email != null) {
                score += 10;
            }

            if (l.Phone != null) {
                score += 10;
            }

            // Company size check (100+ employees)
            if (l.NumberOfEmployees != null && l.NumberOfEmployees >= 100) {
                score += 20;
            }

            // Cap at 100 so the score field never exceeds its max
            l.Lead_Score__c = Math.min(score, 100);
        }
    }

    /*
     * updateNurtureStatus(List<Lead> leads)
     * ----------------------------------------------------------------------
     * PURPOSE: Automatically update the lead's Nurture_Status__c based on
     * its score. This mimics real-world "lead nurturing" where marketing
     * decides whether to keep engaging a lead or stop spending time on it.
     *
     * TRANSITIONS:
     *   - High score (>50) + Not getting nurtured yet
     *         --> "Active Nurture"  (marketing should engage this lead)
     *   - Score drops to <=20 + was being actively nurtured
     *         --> "Dormant"  (this lead went cold, stop spending budget)
     *
     * Note that the middle score range (21-50) keeps the current status.
     * ----------------------------------------------------------------------
     */
    public static void updateNurtureStatus(List<Lead> leads) {
        for (Lead l : leads) {
            if (l.Lead_Score__c != null && l.Lead_Score__c > 50
                && l.Nurture_Status__c == 'Not Started') {
                l.Nurture_Status__c = 'Active Nurture';
            } else if (l.Lead_Score__c != null && l.Lead_Score__c <= 20
                       && l.Nurture_Status__c == 'Active Nurture') {
                l.Nurture_Status__c = 'Dormant';
            }
        }
    }

    /*
     * setHotRating(List<Lead> leads)
     * ----------------------------------------------------------------------
     * PURPOSE: Set the STANDARD Salesforce `Rating` field (Hot/Warm/Cold)
     * based on the lead score. Rating is a built-in field on Lead.
     *
     * MAPPING:
     *   - Score >= 70  --> Hot   (call RIGHT NOW, high urgency)
     *   - Score 40-69  --> Warm  (call soon)
     *   - Score < 40   --> Cold  (low priority, nurture first)
     * ----------------------------------------------------------------------
     */
    public static void setHotRating(List<Lead> leads) {
        for (Lead l : leads) {
            if (l.Lead_Score__c != null && l.Lead_Score__c >= 70) {
                l.Rating = 'Hot';
            } else if (l.Lead_Score__c != null && l.Lead_Score__c >= 40) {
                l.Rating = 'Warm';
            } else if (l.Lead_Score__c != null) {
                l.Rating = 'Cold';
            }
        }
    }
}