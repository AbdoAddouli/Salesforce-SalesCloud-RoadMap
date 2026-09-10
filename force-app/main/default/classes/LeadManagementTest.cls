/*
 * ============================================================================
 * LeadManagementTest
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 2 - Lead Management]
 *
 * WHAT THIS TEST CLASS DOES:
 * Tests the LeadScoringService logic, the LeadTrigger automation, and the
 * Lead assignment rules that work together to: score leads, set ratings,
 * manage nurture status, assign leads to queues, and convert them.
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. @TestSetup builds the QUEUES that the assignment rules need.
 *    In the real org, `Group` records of Type='Queue' represent Queues.
 * 2. Testing trigger behavior simply by inserting/updating records and
 *    then re-querying them to inspect what the trigger wrote.
 * 3. Edge case tests (null fields, score cap at 100).
 * 4. Bulk tests (200 records) to prove the logic is bulk-safe.
 * ============================================================================
 */
@isTest
private class LeadManagementTest {

    /*
     * makeData() [@TestSetup]
     * ----------------------------------------------------------------------
     * Creates the queue Groups referenced by the assignment rules metadata.
     * ----------------------------------------------------------------------
     */
    @TestSetup
    static void makeData() {
        // Each queue = a Group record where Type='Queue'
        Group techQueue = new Group(Name = 'Tech Sales Queue', Type = 'Queue');
        insert techQueue;

        Group enterpriseQueue = new Group(Name = 'Enterprise Sales Queue', Type = 'Queue');
        insert enterpriseQueue;

        Group westCoastQueue = new Group(Name = 'West Coast Team', Type = 'Queue');
        insert westCoastQueue;

        Group generalQueue = new Group(Name = 'Sales General Queue', Type = 'Queue');
        insert generalQueue;

        Group healthcareQueue = new Group(Name = 'Healthcare Sales Queue', Type = 'Queue');
        insert healthcareQueue;
    }

    // ------------------------------------------------------------------------
    // LEAD SCORING behavior (high / medium / low score leads).
    // ------------------------------------------------------------------------

    @isTest
    static void testLeadScoring_HighScore() {
        // A lead that hits ALL the scoring criteria
        Lead l = new Lead(
            FirstName = 'Tech',
            LastName = 'Prospect',
            Company = 'Tech Corp',
            Industry = 'Technology',       // +20
            AnnualRevenue = 2000000,        // +25
            LeadSource = 'Referral',        // +15
            Email = 'tech@prospect.com',    // +10
            Phone = '+1-555-0100',          // +10
            NumberOfEmployees = 200,        // +20  = 100 (capped)
            Status = 'Open - Not Contacted'
        );

        insert l;

        // Re-query to see what the LeadTrigger wrote
        Lead inserted = [SELECT Lead_Score__c, Nurture_Status__c, Rating
                         FROM Lead WHERE Id = :l.Id];

        System.assert(inserted.Lead_Score__c >= 80,
            'High-potential lead should score 80+');
        System.assertEquals('Active Nurture', inserted.Nurture_Status__c,
            'High-score lead should be Active Nurture');
        System.assertEquals('Hot', inserted.Rating,
            'High-score lead should be Hot');
    }

    @isTest
    static void testLeadScoring_MediumScore() {
        Lead l = new Lead(
            FirstName = 'Medium',
            LastName = 'Prospect',
            Company = 'Medium Corp',
            Industry = 'Manufacturing',     // no industry points
            AnnualRevenue = 500000,         // no revenue points (<1M)
            LeadSource = 'Web',             // no source points
            Email = 'medium@prospect.com',  // +10
            Status = 'Open - Not Contacted' // +0
        );

        insert l;

        Lead inserted = [SELECT Lead_Score__c, Nurture_Status__c, Rating
                         FROM Lead WHERE Id = :l.Id];

        System.assert(inserted.Lead_Score__c >= 30 && inserted.Lead_Score__c < 70,
            'Medium lead should score 30-69');
        System.assertEquals('Warm', inserted.Rating,
            'Medium-score lead should be Warm');
    }

    @isTest
    static void testLeadScoring_LowScore() {
        // A lead that hits almost no criteria
        Lead l = new Lead(
            FirstName = 'Low',
            LastName = 'Prospect',
            Company = 'Small Corp',
            Industry = 'Retail',
            AnnualRevenue = 50000,
            LeadSource = 'Other',
            Status = 'Open - Not Contacted'
        );

        insert l;

        Lead inserted = [SELECT Lead_Score__c, Nurture_Status__c, Rating
                         FROM Lead WHERE Id = :l.Id];

        System.assert(inserted.Lead_Score__c < 30,
            'Low-score lead should score under 30');
        System.assertEquals('Cold', inserted.Rating,
            'Low-score lead should be Cold');
    }

    // ------------------------------------------------------------------------
    // Score REcalculation on UPDATE (the trigger runs on insert AND update).
    // ------------------------------------------------------------------------

    @isTest
    static void testLeadScoring_UpdateScore() {
        Lead l = new Lead(
            FirstName = 'Update',
            LastName = 'Test',
            Company = 'Update Corp',
            Industry = 'Retail',
            AnnualRevenue = 50000,
            LeadSource = 'Other',
            Status = 'Open - Not Contacted'
        );

        insert l;

        Lead inserted = [SELECT Lead_Score__c FROM Lead WHERE Id = :l.Id];
        System.assert(inserted.Lead_Score__c < 40,
            'Initial score should be low');

        // Change the lead to be high quality -> trigger should re-score
        l.Industry = 'Technology';
        l.AnnualRevenue = 2000000;
        l.LeadSource = 'Referral';
        l.NumberOfEmployees = 500;
        update l;

        Lead updated = [SELECT Lead_Score__c, Rating FROM Lead WHERE Id = :l.Id];
        System.assert(updated.Lead_Score__c >= 70,
            'Updated lead should score higher');
        System.assertEquals('Hot', updated.Rating,
            'Updated lead should be Hot');
    }

    // ------------------------------------------------------------------------
    // NURTURE STATUS transitions.
    // ------------------------------------------------------------------------

    @isTest
    static void testNurtureStatusTransitions() {
        Lead l = new Lead(
            FirstName = 'Nurture',
            LastName = 'Test',
            Company = 'Nurture Corp',
            Industry = 'Technology',
            AnnualRevenue = 2000000,
            LeadSource = 'Referral',
            Email = 'nurture@test.com',
            Phone = '+1-555-0300',
            NumberOfEmployees = 200,
            Status = 'Open - Not Contacted'
        );

        insert l;

        Lead inserted = [SELECT Nurture_Status__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals('Active Nurture', inserted.Nurture_Status__c,
            'High-score lead should start as Active Nurture');

        // Drop all the lead's quality indicators -> becomes Dormant
        l.Industry = 'Retail';
        l.AnnualRevenue = 10000;
        l.LeadSource = 'Other';
        l.Email = null;
        l.Phone = null;
        l.NumberOfEmployees = 5;
        update l;

        Lead updated = [SELECT Nurture_Status__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals('Dormant', updated.Nurture_Status__c,
            'Low-score lead should become Dormant');
    }

    // ------------------------------------------------------------------------
    // LEAD CONVERSION - the full flow including opportunity creation.
    // ------------------------------------------------------------------------

    @isTest
    static void testLeadConversionWithScoring() {
        Lead l = new Lead(
            FirstName = 'Convert',
            LastName = 'Test',
            Company = 'Convert Corp',
            Industry = 'Technology',
            AnnualRevenue = 5000000,
            LeadSource = 'Referral',
            Email = 'convert@test.com',
            Phone = '+1-555-0400',
            NumberOfEmployees = 500,
            Status = 'Open - Not Contacted'
        );

        insert l;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setConvertedStatus('Closed - Converted');
        lc.setDoNotCreateOpportunity(false);
        lc.setOpportunityName('Convert Corp - New Deal');

        Test.startTest();
        Database.LeadConvertResult result = Database.convertLead(lc);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Lead conversion should succeed');
        System.assertNotEquals(null, result.getAccountId());
        System.assertNotEquals(null, result.getContactId());
        System.assertNotEquals(null, result.getOpportunityId());

        // The lead's IsConverted flag should now be true
        Lead converted = [SELECT IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId
                          FROM Lead WHERE Id = :l.Id];
        System.assert(converted.IsConverted, 'Lead should be marked as converted');
    }

    // ------------------------------------------------------------------------
    // BULK - 200 leads to prove the trigger/scoring handles batches.
    // ------------------------------------------------------------------------

    @isTest
    static void testBulkLeadCreation() {
        List<Lead> leads = new List<Lead>();

        for (Integer i = 0; i < 200; i++) {
            leads.add(new Lead(
                FirstName = 'Bulk',
                LastName = 'Lead ' + i,
                Company = 'Bulk Corp ' + i,
                Industry = Math.mod(i, 2) == 0 ? 'Technology' : 'Retail',
                AnnualRevenue = i * 10000,
                LeadSource = Math.mod(i, 3) == 0 ? 'Referral' : 'Web',
                Email = 'bulk' + i + '@test.com',
                Phone = '+1-555-' + String.valueOf(1000 + i),
                NumberOfEmployees = i * 10,
                Status = 'Open - Not Contacted'
            ));
        }

        insert leads;

        List<Lead> insertedLeads = [SELECT Lead_Score__c, Rating, Nurture_Status__c
                                     FROM Lead WHERE Company LIKE 'Bulk Corp %'];

        System.assertEquals(200, insertedLeads.size(), 'Should have created 200 leads');

        Integer hotCount = 0;
        for (Lead l : insertedLeads) {
            System.assertNotEquals(null, l.Lead_Score__c, 'All leads should have a score');
            if (l.Rating == 'Hot') hotCount++;
        }

        System.assert(hotCount > 0, 'Some leads should be rated Hot');
    }

    // ------------------------------------------------------------------------
    // ASSIGNMENT RULES - leads routed to the correct queue by industry.
    // ------------------------------------------------------------------------

    @isTest
    static void testLeadAssignmentByIndustry() {
        Lead techLead = new Lead(
            FirstName = 'Tech',
            LastName = 'Assigned',
            Company = 'Tech Assign Corp',
            Industry = 'Technology',
            Status = 'Open - Not Contacted'
        );

        Lead healthLead = new Lead(
            FirstName = 'Health',
            LastName = 'Assigned',
            Company = 'Health Assign Corp',
            Industry = 'Healthcare',
            Status = 'Open - Not Contacted'
        );

        List<Lead> leads = new List<Lead>{techLead, healthLead};
        insert leads;

        // Assignment rules store the assigned target on OwnerId (a group Id)
        Group techQueue = [SELECT Id FROM Group WHERE Name = 'Tech Sales Queue' AND Type = 'Queue' LIMIT 1];
        Group healthQueue = [SELECT Id FROM Group WHERE Name = 'Healthcare Sales Queue' AND Type = 'Queue' LIMIT 1];

        List<Lead> insertedLeads = [SELECT Name, Industry, OwnerId FROM Lead WHERE Id IN :leads];

        for (Lead l : insertedLeads) {
            if (l.Industry == 'Technology') {
                System.assertEquals(techQueue.Id, l.OwnerId,
                    'Technology lead should be assigned to Tech queue');
            } else if (l.Industry == 'Healthcare') {
                System.assertEquals(healthQueue.Id, l.OwnerId,
                    'Healthcare lead should be assigned to Healthcare queue');
            }
        }
    }

    // ------------------------------------------------------------------------
    // EDGE CASES - null fields and the 100-point cap.
    // ------------------------------------------------------------------------

    @isTest
    static void testLeadScoringEdgeCases() {
        // A lead with NOTHING relevant -> expected score 0
        Lead nullFieldsLead = new Lead(
            FirstName = 'Null',
            LastName = 'Fields',
            Company = 'Null Corp',
            Status = 'Open - Not Contacted'
        );

        insert nullFieldsLead;

        Lead inserted = [SELECT Lead_Score__c, Rating FROM Lead WHERE Id = :nullFieldsLead.Id];
        System.assertEquals(0, inserted.Lead_Score__c,
            'Lead with no qualifying fields should score 0');
        System.assertEquals('Cold', inserted.Rating,
            'Zero-score lead should be Cold');
    }

    @isTest
    static void testScoreCapAt100() {
        // All criteria hit -> natural score is 100, Math.min caps it
        Lead l = new Lead(
            FirstName = 'Max',
            LastName = 'Score',
            Company = 'Max Corp',
            Industry = 'Technology',
            AnnualRevenue = 5000000,
            LeadSource = 'Referral',
            Email = 'max@test.com',
            Phone = '+1-555-9999',
            NumberOfEmployees = 1000,
            Status = 'Open - Not Contacted'
        );

        insert l;

        Lead inserted = [SELECT Lead_Score__c FROM Lead WHERE Id = :l.Id];
        System.assert(inserted.Lead_Score__c <= 100,
            'Lead score should never exceed 100');
    }
}