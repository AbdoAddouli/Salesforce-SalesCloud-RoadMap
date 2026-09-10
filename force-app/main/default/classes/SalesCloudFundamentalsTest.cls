/*
 * ============================================================================
 * SalesCloudFundamentalsTest
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 1 - Sales Cloud Fundamentals]
 *
 * WHAT THIS TEST CLASS DOES:
 * Verifies the CUSTOM FIELDS created in Phase 1 and the core CRUD behaviors
 * of the standard objects (Account, Contact, Lead, Opportunity).
 *
 * WHY ARE TESTS REQUIRED?
 *  - Salesforce REQUIRES >= 75% code coverage before Apex can be deployed.
 *  - Tests run in their own isolated environment (data created by @TestSetup
 *    is rolled back automatically, never visible to real users).
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. @isTest - marks a class as a test class.
 * 2. @TestSetup - runs ONCE before all test methods in the class; builds
 *    common data so tests don't repeat setup code.
 * 3. System.assert / assertEquals - verify our expectations; a FAILING
 *    assertion fails the test.
 * 4. SOQL assertions - the standard way to read back inserted records and
 *    check what the system (or a trigger) wrote to them.
 * ============================================================================
 */
@isTest
private class SalesCloudFundamentalsTest {

    /*
     * makeData() [@TestSetup]
     * ----------------------------------------------------------------------
     * Runs once before every test method. Creates:
     *   - An Account + Contact + Lead + Opportunity
     * These records are available (with their IDs) to every test.
     * ----------------------------------------------------------------------
     */
    @TestSetup
    static void makeData() {
        // Standard Salesforce objects with our custom fields from Phase 1
        Account acct = new Account(
            Name = 'Test Corporation',
            Industry = 'Technology',
            Industry_Segment__c = 'Technology',   // custom field
            AnnualRevenue = 5000000,
            Health_Score__c = 85,                  // custom field
            Customer_Since__c = Date.today().addYears(-2)  // custom field
        );
        insert acct;

        Contact c = new Contact(
            FirstName = 'John',
            LastName = 'Smith',
            Email = 'john.smith@testcorp.com',
            Phone = '+1-555-0100',
            AccountId = acct.Id,
            Role__c = 'Decision Maker',            // custom field
            Engagement_Score__c = 72               // custom field
        );
        insert c;

        Lead l = new Lead(
            FirstName = 'Jane',
            LastName = 'Doe',
            Company = 'Acme Industries',
            Email = 'jane.doe@acme.com',
            Phone = '+1-555-0200',
            Lead_Score__c = 65,                    // custom field
            Nurture_Status__c = 'Active Nurture',  // custom field
            Status = 'Open - Not Contacted'        // standard picklist
        );
        insert l;

        Opportunity opp = new Opportunity(
            Name = 'Test Corp - Enterprise Deal',
            AccountId = acct.Id,
            Amount = 150000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
    }

    // ------------------------------------------------------------------------
    // Verify custom fields were saved correctly on each object.
    // ------------------------------------------------------------------------

    @isTest
    static void testAccountCustomFields() {
        Account acct = [SELECT Name, Industry_Segment__c, Health_Score__c, Customer_Since__c
                        FROM Account WHERE Name = 'Test Corporation' LIMIT 1];

        System.assertEquals('Technology', acct.Industry_Segment__c,
            'Industry Segment should be Technology');
        System.assertEquals(85, acct.Health_Score__c,
            'Health Score should be 85');
        System.assertNotEquals(null, acct.Customer_Since__c,
            'Customer Since should not be null');
    }

    @isTest
    static void testContactCustomFields() {
        Contact c = [SELECT Name, Role__c, Engagement_Score__c, Account.Name
                     FROM Contact WHERE LastName = 'Smith' LIMIT 1];

        System.assertEquals('Decision Maker', c.Role__c,
            'Role should be Decision Maker');
        System.assertEquals(72, c.Engagement_Score__c,
            'Engagement Score should be 72');
        System.assertEquals('Test Corporation', c.Account.Name,
            'Contact should be related to Test Corporation');
    }

    @isTest
    static void testLeadCustomFields() {
        Lead l = [SELECT Name, Company, Lead_Score__c, Nurture_Status__c
                  FROM Lead WHERE LastName = 'Doe' LIMIT 1];

        System.assertEquals('Acme Industries', l.Company,
            'Company should be Acme Industries');
        System.assertEquals(65, l.Lead_Score__c,
            'Lead Score should be 65');
        System.assertEquals('Active Nurture', l.Nurture_Status__c,
            'Nurture Status should be Active Nurture');
    }

    @isTest
    static void testOpportunityWithAccount() {
        // Demonstrates the Opportunity -> Account relationship (Lookup to Account)
        Opportunity opp = [SELECT Name, Amount, StageName, Account.Name
                           FROM Opportunity WHERE Name = 'Test Corp - Enterprise Deal' LIMIT 1];

        System.assertEquals(150000, opp.Amount,
            'Amount should be 150000');
        System.assertEquals('Test Corporation', opp.Account.Name,
            'Opportunity should be linked to Test Corporation');
    }

    // ------------------------------------------------------------------------
    // Lead conversion - turning a Lead into Account/Contact/Opportunity.
    // ------------------------------------------------------------------------

    @isTest
    static void testLeadConversion() {
        Lead l = [SELECT Id, FirstName, LastName, Company, Email
                  FROM Lead WHERE LastName = 'Doe' LIMIT 1];

        // Database.LeadConvert is the API behind the "Convert" button.
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(false);        // also make an Opportunity
        lc.setOpportunityName('Acme - New Deal');

        // Test.startTest()/stopTest() brackets the code we want to measure
        // (used for governor-limit isolation in future optimization tests).
        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(lc);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Lead conversion should succeed');
        System.assertNotEquals(null, result.getAccountId(),
            'Account should be created on conversion');
        System.assertNotEquals(null, result.getContactId(),
            'Contact should be created on conversion');
        System.assertNotEquals(null, result.getOpportunityId(),
            'Opportunity should be created on conversion');
    }

    // ------------------------------------------------------------------------
    // SOQL aggregates - GROUP BY style queries.
    // ------------------------------------------------------------------------

    @isTest
    static void testSoqlAggregateQueries() {
        // COUNT grouped by a field -> List<AggregateResult>
        List<AggregateResult> results = [
            SELECT Status, COUNT(Name) cnt
            FROM Lead
            GROUP BY Status
        ];
        System.assert(results.size() > 0, 'Should have at least one Lead status group');

        List<AggregateResult> oppResults = [
            SELECT StageName, SUM(Amount) totalAmount
            FROM Opportunity
            GROUP BY StageName
        ];
        System.assert(oppResults.size() > 0, 'Should have at least one Opportunity stage group');
    }

    // ------------------------------------------------------------------------
    // Bulk data creation (bulkification / DML in lists).
    // ------------------------------------------------------------------------

    @isTest
    static void testBulkDataCreation() {
        // Inserting 200 records in ONE DML call (a List), not 200 inserts.
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Account ' + i,
                Industry = 'Technology',
                Industry_Segment__c = 'Technology',
                Health_Score__c = Math.mod(i, 100)
            ));
        }
        insert accounts;

        System.assertEquals(200, accounts.size(), 'Should have created 200 accounts');

        // Parent-child insert: build contacts referencing the accounts
        List<Contact> contacts = new List<Contact>();
        for (Account a : accounts) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + a.Name,
                AccountId = a.Id,
                Role__c = 'End User'
            ));
        }
        insert contacts;

        System.assertEquals(200, contacts.size(), 'Should have created 200 contacts');
    }
}