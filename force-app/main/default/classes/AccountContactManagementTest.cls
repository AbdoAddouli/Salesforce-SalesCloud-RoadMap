/*
 * ============================================================================
 * AccountContactManagementTest
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 3 - Account & Contact Management]
 *
 * WHAT THIS TEST CLASS DOES:
 * Validates the AccountService logic and AccountTrigger/OpportunityTrigger
 * automation for:
 *   - Account hierarchy (parent/child + Ultimate Parent resolution)
 *   - Default contact auto-creation
 *   - Roll-up of Opportunity metrics onto the Account
 *   - Health score calculation
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Building a multi-level hierarchy in @TestSetup:
 *    Global Corp (parent) -> children -> grandchild.
 * 2. Testing that roll-up fields stay correct after child data changes.
 * 3. Bulk tests (200 accounts each with a default contact).
 * ============================================================================
 */
@isTest
private class AccountContactManagementTest {

    /*
     * makeData() [@TestSetup]
     * ----------------------------------------------------------------------
     * Builds a 3-level account hierarchy plus a primary contact:
     *
     *   Global Corp  (parent, alone)
     *     |-- Global Corp - North America
     *     |     `-- Global Corp - US        (grandchild)
     *     `-- Global Corp - Europe
     * ----------------------------------------------------------------------
     */
    @TestSetup
    static void makeData() {
        Account parentAcc = new Account(
            Name = 'Global Corp',
            Industry = 'Technology',
            Industry_Segment__c = 'Technology',
            AnnualRevenue = 50000000,
            Health_Score__c = 90,
            Customer_Since__c = Date.today().addYears(-10)
        );
        insert parentAcc;

        Account child1 = new Account(
            Name = 'Global Corp - North America',
            Industry = 'Technology',
            Industry_Segment__c = 'Technology',
            AnnualRevenue = 20000000,
            ParentId = parentAcc.Id,             // points UP the hierarchy
            Customer_Since__c = Date.today().addYears(-5)
        );

        Account child2 = new Account(
            Name = 'Global Corp - Europe',
            Industry = 'Finance',
            Industry_Segment__c = 'Finance',
            AnnualRevenue = 15000000,
            ParentId = parentAcc.Id,
            Customer_Since__c = Date.today().addYears(-3)
        );

        insert new List<Account>{child1, child2};

        // Grandchild under child1
        Account grandchild = new Account(
            Name = 'Global Corp - US',
            Industry = 'Technology',
            Industry_Segment__c = 'Technology',
            AnnualRevenue = 10000000,
            ParentId = child1.Id,
            Customer_Since__c = Date.today().addYears(-2)
        );
        insert grandchild;

        Contact primaryContact = new Contact(
            FirstName = 'John',
            LastName = 'CEO',
            AccountId = parentAcc.Id,
            Email = 'ceo@globalcorp.com',
            Role__c = 'Decision Maker',
            Engagement_Score__c = 95
        );
        insert primaryContact;
    }

    // ------------------------------------------------------------------------
    // HIERARCHY behavior.
    // ------------------------------------------------------------------------

    @isTest
    static void testAccountHierarchyCreation() {
        Account parent = [SELECT Id, Name, Account_Level__c FROM Account WHERE Name = 'Global Corp' LIMIT 1];
        System.assertEquals('Global', parent.Account_Level__c, 'Parent should be Global level');

        // Two children directly under the parent
        List<Account> children = [SELECT Id, Name, ParentId, Account_Level__c
                                   FROM Account WHERE ParentId = :parent.Id];
        System.assertEquals(2, children.size(), 'Should have 2 child accounts');
    }

    @isTest
    static void testUltimateParentLookup() {
        // The grandchild's Ultimate_Parent__c must point to the TOP account
        Account grandchild = [SELECT Id, Ultimate_Parent__c, ParentId FROM Account
                               WHERE Name = 'Global Corp - US' LIMIT 1];

        Account parent = [SELECT Id FROM Account WHERE Name = 'Global Corp' LIMIT 1];

        System.assertEquals(parent.Id, grandchild.Ultimate_Parent__c,
            'Ultimate parent should point to Global Corp');
    }

    @isTest
    static void testMultipleAccountsHierarchy() {
        // Build a separate 5-account tree from scratch to count its size
        Account globalAcc = new Account(Name = 'MegaGlobal', Account_Level__c = 'Global');
        insert globalAcc;

        Account region1 = new Account(Name = 'MegaGlobal - NA', ParentId = globalAcc.Id);
        Account region2 = new Account(Name = 'MegaGlobal - EMEA', ParentId = globalAcc.Id);
        insert new List<Account>{region1, region2};

        Account div1 = new Account(Name = 'MegaGlobal - US East', ParentId = region1.Id);
        Account div2 = new Account(Name = 'MegaGlobal - UK', ParentId = region2.Id);
        insert new List<Account>{div1, div2};

        List<Account> allAccounts = [SELECT Name, ParentId FROM Account WHERE Name LIKE 'MegaGlobal%'];
        System.assertEquals(5, allAccounts.size(), 'Should have 5 accounts in hierarchy');
    }

    // ------------------------------------------------------------------------
    // DEFAULT CONTACT auto-creation.
    // ------------------------------------------------------------------------

    @isTest
    static void testDefaultContactCreation() {
        Account newAcc = new Account(
            Name = 'New Test Corp',
            Industry = 'Technology',
            AnnualRevenue = 1000000
        );

        insert newAcc;

        // The AccountTrigger after-insert should have created a contact
        List<Contact> contacts = [SELECT FirstName, LastName, Role__c, AccountId
                                   FROM Contact WHERE AccountId = :newAcc.Id];

        System.assertEquals(1, contacts.size(), 'Default contact should be created');
        System.assertEquals('Decision Maker', contacts[0].Role__c, 'Default role should be Decision Maker');
        System.assert(contacts[0].FirstName.contains('Primary'), 'Should start with Primary');
    }

    // ------------------------------------------------------------------------
    // ROLL-UP metrics (Account fields updated from child Opportunities).
    // ------------------------------------------------------------------------

    @isTest
    static void testAccountMetricsRefresh() {
        Account acc = [SELECT Id, Total_Opportunities__c, Total_Revenue_Won__c, Pipeline_Value__c
                       FROM Account WHERE Name = 'Global Corp' LIMIT 1];

        Opportunity opp1 = new Opportunity(
            Name = 'Global Corp - Deal 1',
            AccountId = acc.Id,
            Amount = 500000,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-30)
        );

        Opportunity opp2 = new Opportunity(
            Name = 'Global Corp - Deal 2',
            AccountId = acc.Id,
            Amount = 250000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

        insert new List<Opportunity>{opp1, opp2};

        // Manually invoke the roll-up (normally the trigger does this)
        AccountService.refreshAccountMetrics(new Set<Id>{acc.Id});

        Account updated = [SELECT Total_Opportunities__c, Total_Revenue_Won__c, Pipeline_Value__c
                           FROM Account WHERE Id = :acc.Id];

        System.assertEquals(2, updated.Total_Opportunities__c, 'Should have 2 opportunities');
        System.assertEquals(500000, updated.Total_Revenue_Won__c, 'Should have 500k revenue won');
        System.assertEquals(250000, updated.Pipeline_Value__c, 'Should have 250k pipeline');
    }

    @isTest
    static void testOpportunityMetricsOnAccount() {
        // Mix of won / open / lost - only won and open should count
        Account acc = [SELECT Id FROM Account WHERE Name = 'Global Corp - North America' LIMIT 1];

        Opportunity opp1 = new Opportunity(Name = 'NA Deal 1', AccountId = acc.Id,
            Amount = 100000, StageName = 'Closed Won', CloseDate = Date.today().addDays(-10));

        Opportunity opp2 = new Opportunity(Name = 'NA Deal 2', AccountId = acc.Id,
            Amount = 75000, StageName = 'Negotiation/Review', CloseDate = Date.today().addDays(15));

        Opportunity opp3 = new Opportunity(Name = 'NA Deal 3', AccountId = acc.Id,
            Amount = 50000, StageName = 'Closed Lost', CloseDate = Date.today().addDays(-5));

        insert new List<Opportunity>{opp1, opp2, opp3};

        AccountService.refreshAccountMetrics(new Set<Id>{acc.Id});

        Account updated = [SELECT Total_Opportunities__c, Total_Revenue_Won__c, Pipeline_Value__c
                           FROM Account WHERE Id = :acc.Id];

        // All 3 count toward "total opportunities"
        System.assertEquals(3, updated.Total_Opportunities__c);
        // Only the won one counts toward revenue
        System.assertEquals(100000, updated.Total_Revenue_Won__c);
        // Only the open one counts toward pipeline
        System.assertEquals(75000, updated.Pipeline_Value__c);
    }

    @isTest
    static void testContactEngagementOnAccount() {
        // Adding a contact should increase the account's contact count roll-up
        Account acc = [SELECT Id, Number_of_Contacts__c FROM Account
                       WHERE Name = 'Global Corp' LIMIT 1];

        Contact c2 = new Contact(
            FirstName = 'Jane',
            LastName = 'CFO',
            AccountId = acc.Id,
            Email = 'cfo@globalcorp.com',
            Role__c = 'Economic Buyer',
            Engagement_Score__c = 80
        );
        insert c2;

        AccountService.refreshAccountMetrics(new Set<Id>{acc.Id});

        Account updated = [SELECT Number_of_Contacts__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(2, updated.Number_of_Contacts__c, 'Should have 2 contacts');
    }

    // ------------------------------------------------------------------------
    // HEALTH SCORE calculation.
    // ------------------------------------------------------------------------

    @isTest
    static void testHealthScoreUpdate() {
        // An established customer with a big won deal should score high
        Account acc = [SELECT Id, Health_Score__c, Customer_Since__c FROM Account
                       WHERE Name = 'Global Corp' LIMIT 1];

        Opportunity won = new Opportunity(
            Name = 'Big Deal',
            AccountId = acc.Id,
            Amount = 2000000,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-60)
        );
        insert won;

        AccountService.refreshAccountMetrics(new Set<Id>{acc.Id});
        AccountService.updateHealthScore(new Set<Id>{acc.Id});

        Account updated = [SELECT Health_Score__c FROM Account WHERE Id = :acc.Id];
        System.assert(updated.Health_Score__c > 50, 'Health score should be high for established customer with revenue');
    }

    @isTest
    static void testHealthScoreNewAccount() {
        // New account, small, no history -> healthy score should be LOW
        Account newAcc = new Account(
            Name = 'Brand New Corp',
            Industry = 'Retail',
            AnnualRevenue = 50000,
            Customer_Since__c = Date.today().addMonths(-3)
        );
        insert newAcc;

        AccountService.updateHealthScore(new Set<Id>{newAcc.Id});

        Account updated = [SELECT Health_Score__c FROM Account WHERE Id = :newAcc.Id];
        System.assert(updated.Health_Score__c < 50, 'New account should have lower health score');
    }

    // ------------------------------------------------------------------------
    // TRIGGER BEHAVIOR + BULK handling.
    // ------------------------------------------------------------------------

    @isTest
    static void testOpportunityTriggerUpdatesAccount() {
        // Prove that the OPPORTUNITY trigger automatically refreshes account metrics
        Account acc = [SELECT Id, Total_Opportunities__c, Total_Revenue_Won__c
                       FROM Account WHERE Name = 'Global Corp' LIMIT 1];

        Opportunity opp = new Opportunity(
            Name = 'Trigger Test Deal',
            AccountId = acc.Id,
            Amount = 300000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(20)
        );
        insert opp;

        Account afterInsert = [SELECT Total_Opportunities__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1, afterInsert.Total_Opportunities__c);

        opp.StageName = 'Closed Won';
        update opp;

        Account afterUpdate = [SELECT Total_Revenue_Won__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(300000, afterUpdate.Total_Revenue_Won__c);
    }

    @isTest
    static void testBulkAccountCreation() {
        // 200 accounts -> should produce 200 default contacts (bulk runs the trigger once)
        List<Account> accounts = new List<Account>();

        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Account ' + i,
                Industry = Math.mod(i, 2) == 0 ? 'Technology' : 'Finance',
                AnnualRevenue = i * 10000,
                Customer_Since__c = Date.today().addYears(-Math.mod(i, 10))
            ));
        }

        insert accounts;

        List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId IN :accounts];
        System.assertEquals(200, contacts.size(), 'Should have created 200 default contacts');

        List<Account> inserted = [SELECT Account_Level__c FROM Account WHERE Name LIKE 'Bulk Account %'];
        for (Account acc : inserted) {
            System.assertEquals('Global', acc.Account_Level__c, 'Standalone accounts should be Global');
        }
    }
}