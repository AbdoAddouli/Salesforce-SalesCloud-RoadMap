/*
 * ============================================================================
 * AccountService
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 3 - Account & Contact Management]
 *
 * WHAT THIS CLASS DOES:
 * Centralizes the business logic for Accounts (companies/customers).
 * Called from AccountTrigger and OpportunityTrigger. Handles:
 *   - Account hierarchy (parent/child relationships)
 *   - Auto-creation of default contacts
 *   - Health scoring of accounts
 *   - Aggregating sales metrics onto the Account for reporting
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Aggregation / Roll-Up fields - "Roll-up" means computing children
 *    totals (Opportunities, Contacts) and storing them on the parent
 *    (Account) for fast reporting and record-page display. Native roll-up
 *    summary fields exist in Setup, but Apex gives full control over the
 *    formula/logic.
 *
 * 2. SOQL relationship traversal - `Parent.Parent.ParentId` drills up the
 *    Account hierarchy multiple levels in one query.
 *
 * 3. Defensive null checks + early return - Guards against nulls so the
 *    method never crashes when data is missing.
 *
 * 4. Bulk-safe querying - Queries are done ONCE using WHERE IN set, not
 *    once per record (avoids hitting the SOQL 100-query governor limit).
 * ============================================================================
 */
public with sharing class AccountService {

    /*
     * setAccountLevel(List<Account> accounts)
     * ----------------------------------------------------------------------
     * PURPOSE: Mark accounts with no parent (standalone accounts) as "Global".
     * In an account hierarchy, the top-most account is the Global/holding
     * entity; its children are regional/divisional entities.
     *
     * NOTE: This only sets Global when ParentId is null. Child accounts keep
     * whatever the user entered.
     * ----------------------------------------------------------------------
     */
    public static void setAccountLevel(List<Account> accounts) {
        for (Account acc : accounts) {
            // ParentId is the standard Salesforce Lookup to Account (self-lookup)
            if (acc.ParentId == null) {
                acc.Account_Level__c = 'Global';
            }
        }
    }

    /*
     * setUltimateParent(List<Account> accounts)
     * ----------------------------------------------------------------------
     * PURPOSE: For each account that HAS a parent, find the highest ancestor
     * in the hierarchy and store its Id in the custom field Ultimate_Parent__c.
     *
     * WHY store this instead of just querying Parent.Parent...
     *  - SOQL can only go 5 levels deep.
     *  - Reporting on "which top company owns this account" is much faster
     *    with a denormalized field.
     *
     * ALGORITHM:
     *  1. Collect all ParentIds from the incoming accounts.
     *  2. Query those parents (and their parents up to 4 levels) in ONE query.
     *  3. Walk up with a while loop until reaching an account with no parent.
     * ----------------------------------------------------------------------
     */
    public static void setUltimateParent(List<Account> accounts) {
        // Step 1: Gather the immediate ParentIds we need info about
        Set<Id> parentIds = new Set<Id>();
        for (Account acc : accounts) {
            if (acc.ParentId != null) {
                parentIds.add(acc.ParentId);
            }
        }

        // No parents at all --> nothing to do, so exit early
        if (parentIds.isEmpty()) return;

        // Step 2: Query the parent chain in ONE bulk SOQL query.
        // Note the relationship syntax: Parent.Parent.Parent.ParentId reaches
        // 4 levels up the hierarchy.
        Map<Id, Account> parentMap = new Map<Id, Account>(
            [SELECT Id, ParentId, Parent.ParentId, Parent.Parent.ParentId,
                    Parent.Parent.Parent.ParentId
             FROM Account WHERE Id IN :parentIds]
        );

        // Step 3: Walk up each incoming account's hierarchy
        for (Account acc : accounts) {
            if (acc.ParentId != null) {
                Account current = parentMap.get(acc.ParentId);
                // Keep climbing while the current account still has a parent
                while (current != null && current.ParentId != null) {
                    current = parentMap.containsKey(current.ParentId)
                        ? parentMap.get(current.ParentId) : null;
                }
                // `current` is now the highest ancestor (no parent itself)
                if (current != null) {
                    acc.Ultimate_Parent__c = current.Id;
                }
            }
        }
    }

    /*
     * createDefaultContact(List<Account> accounts)
     * ----------------------------------------------------------------------
     * PURPOSE: When a new account is created, automatically create a
     * "Primary Contact" record so the account always has at least one
     * person attached. Saves sales reps a manual step.
     *
     * NOTE: This runs in an `after insert` trigger context because it
     * CREATES new records (DML). You cannot insert children in a `before`
     * trigger - the parent record doesn't have an Id yet.
     * ----------------------------------------------------------------------
     */
    public static void createDefaultContact(List<Account> accounts) {
        List<Contact> contactsToInsert = new List<Contact>();

        for (Account acc : accounts) {
            // Build a contact from the account data
            contactsToInsert.add(new Contact(
                FirstName = 'Primary',
                LastName = acc.Name + ' - Primary Contact',
                AccountId = acc.Id,
                Role__c = 'Decision Maker'
            ));
        }

        // One bulk DML instead of many single inserts
        if (!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
        }
    }

    /*
     * updateHealthScore(Set<Id> accountIds)
     * ----------------------------------------------------------------------
     * PURPOSE: Recalculate the Account health score (0-100) based on several
     * customer-health indicators. Used to decide which accounts deserve
     * more sales attention.
     *
     * SCORING RUBRIC:
     *   - Tenure (Customer_Since__c): >=5yr:+25, >=3yr:+15, >=1yr:+5
     *   - Revenue won:                  >=$1M:+25, >=$500k:+15, >=$100k:+10
     *   - Active pipeline > 0 ............ +15
     *   - Contacts:                    >=5:+15, >=2:+10
     *   - Has any opportunities .......... +10
     *   Max = 100.
     * ----------------------------------------------------------------------
     */
    public static void updateHealthScore(Set<Id> accountIds) {
        if (accountIds.isEmpty()) return;

        // Re-query with all fields needed to compute the score
        List<Account> accounts = [
            SELECT Id, Health_Score__c, Customer_Since__c,
                   Total_Opportunities__c, Total_Revenue_Won__c,
                   Pipeline_Value__c, Number_of_Contacts__c
            FROM Account WHERE Id IN :accountIds
        ];

        for (Account acc : accounts) {
            Integer score = 0;

            // 1) Tenure: how long have they been a customer?
            if (acc.Customer_Since__c != null) {
                Integer yearsAsCustomer = acc.Customer_Since__c.daysBetween(Date.today()) / 365;
                if (yearsAsCustomer >= 5) score += 25;
                else if (yearsAsCustomer >= 3) score += 15;
                else if (yearsAsCustomer >= 1) score += 5;
            }

            // 2) How much revenue have they historically generated?
            if (acc.Total_Revenue_Won__c != null) {
                if (acc.Total_Revenue_Won__c >= 1000000) score += 25;
                else if (acc.Total_Revenue_Won__c >= 500000) score += 15;
                else if (acc.Total_Revenue_Won__c >= 100000) score += 10;
            }

            // 3) Future revenue potential (active pipeline)?
            if (acc.Pipeline_Value__c != null && acc.Pipeline_Value__c > 0) {
                score += 15;
            }

            // 4) Relationship depth (number of contacts)?
            if (acc.Number_of_Contacts__c != null) {
                if (acc.Number_of_Contacts__c >= 5) score += 15;
                else if (acc.Number_of_Contacts__c >= 2) score += 10;
            }

            // 5) Engagement (has it bought anything before)?
            if (acc.Total_Opportunities__c != null && acc.Total_Opportunities__c > 0) {
                score += 10;
            }

            acc.Health_Score__c = Math.min(score, 100);
        }

        // Because we re-queried, we must explicitly update
        update accounts;
    }

    /*
     * refreshAccountMetrics(Set<Id> accountIds)
     * ----------------------------------------------------------------------
     * PURPOSE: Recompute the roll-up summary fields on the Account from its
     * related child records (Opportunities and Contacts).
     *
     * FIELDS RECALCULATED:
     *   - Total_Opportunities__c        = number of child opportunities
     *   - Total_Revenue_Won__c          = SUM(Amount) of Closed Won opps
     *   - Pipeline_Value__c             = SUM(Amount) of open opps
     *   - Number_of_Contacts__c         = count of related contacts
     *   - Last_Won_Opportunity_Date__c  = most recent Closed Won close date
     *
     * KEY: Using subquery syntax `(SELECT ... FROM Opportunities)` in SOQL
     * pulls all related records in one round trip.
     * ----------------------------------------------------------------------
     */
    public static void refreshAccountMetrics(Set<Id> accountIds) {
        if (accountIds.isEmpty()) return;

        // Subquery: (SELECT ... FROM Opportunities) and (SELECT ... FROM Contacts)
        // retrieve the children of each account in the SAME query.
        List<Account> accounts = [
            SELECT Id,
                   (SELECT Amount, StageName, CloseDate FROM Opportunities),
                   (SELECT Id FROM Contacts)
            FROM Account WHERE Id IN :accountIds
        ];

        for (Account acc : accounts) {
            Decimal totalWon = 0;
            Decimal totalPipeline = 0;
            Integer oppCount = 0;
            Date lastWonDate = null;

            // Iterate over the child opportunities collected by the subquery
            for (Opportunity opp : acc.Opportunities) {
                oppCount++;

                if (opp.StageName == 'Closed Won') {
                    totalWon += opp.Amount != null ? opp.Amount : 0;
                    // Track the most recent won date
                    if (lastWonDate == null || opp.CloseDate > lastWonDate) {
                        lastWonDate = opp.CloseDate;
                    }
                } else if (opp.StageName != 'Closed Lost') {
                    totalPipeline += opp.Amount != null ? opp.Amount : 0;
                }
            }

            // Write the computed values back to the account
            acc.Total_Opportunities__c = oppCount;
            acc.Total_Revenue_Won__c = totalWon;
            acc.Pipeline_Value__c = totalPipeline;
            acc.Number_of_Contacts__c = acc.Contacts.size();
            acc.Last_Won_Opportunity_Date__c = lastWonDate;
        }

        update accounts;
    }
}