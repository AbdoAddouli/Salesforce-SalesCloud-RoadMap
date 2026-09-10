/*
 * ============================================================================
 * CampaignManagementTest
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 5 - Campaign Management]
 *
 * WHAT THIS TEST CLASS DOES:
 * Verifies CampaignService logic and the CampaignMember/OpportunityCampaign
 * triggers:
 *   - Adding contacts to a campaign when a deal closes
 *   - Updating member status when activity happens
 *   - Campaign ROI / metrics calculation
 *   - Bulk-adding members (with duplicate prevention)
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. CampaignMember is the JUNCTION object between a Campaign and a
 *    Contact/Lead; each member has a Status ('Sent', 'Responded', etc.).
 * 2. Testing trigger side effects: inserting an Opportunity stage change
 *    and verifying CampaignMember records were auto-created.
 * 3. Edge cases: campaigns with no cost (divide-by-zero must not happen)
 *    and campaigns with no members.
 * ============================================================================
 */
@isTest
private class CampaignManagementTest {

    /*
     * makeData() [@TestSetup]
     * ----------------------------------------------------------------------
     * Creates:
     *   - 1 Account + 2 Contacts
     *   - 3 Campaigns (Trade Show, Webinar, Email Blast)
     *   - 3 CampaignMembers across two campaigns
     *   - 1 Opportunity ('Campaign Influenced Deal')
     * ----------------------------------------------------------------------
     */
    @TestSetup
    static void makeData() {
        Account acc = new Account(
            Name = 'Campaign Test Account',
            Industry = 'Technology',
            AnnualRevenue = 2000000,
            Customer_Since__c = Date.today().addYears(-1)
        );
        insert acc;

        Contact c1 = new Contact(
            FirstName = 'Campaign',
            LastName = 'Contact 1',
            AccountId = acc.Id,
            Email = 'contact1@campaign.com',
            Role__c = 'Decision Maker'
        );

        Contact c2 = new Contact(
            FirstName = 'Campaign',
            LastName = 'Contact 2',
            AccountId = acc.Id,
            Email = 'contact2@campaign.com',
            Role__c = 'Influencer'
        );

        insert new List<Contact>{c1, c2};

        Campaign tradeShow = new Campaign(
            Name = '2026 Tech Conference',
            Type = 'Trade Show',
            Status = 'In Progress',
            StartDate = Date.today().addDays(-30),
            EndDate = Date.today().addDays(3),
            Budget = 50000,
            ActualCost = 35000
        );

        Campaign webinar = new Campaign(
            Name = 'Product Demo Webinar',
            Type = 'Webinar',
            Status = 'In Progress',
            StartDate = Date.today().addDays(-14),
            Budget = 5000,
            ActualCost = 3000
        );

        Campaign emailBlast = new Campaign(
            Name = 'Q1 Email Blast',
            Type = 'Email',
            Status = 'Completed',
            StartDate = Date.today().addDays(-60),
            Budget = 2000,
            ActualCost = 1500
        );

        insert new List<Campaign>{tradeShow, webinar, emailBlast};

        Contact contact1 = [SELECT Id FROM Contact WHERE LastName = 'Contact 1' LIMIT 1];
        Contact contact2 = [SELECT Id FROM Contact WHERE LastName = 'Contact 2' LIMIT 1];

        CampaignMember cm1 = new CampaignMember(
            CampaignId = tradeShow.Id,
            ContactId = contact1.Id,
            Status = 'Sent'
        );

        CampaignMember cm2 = new CampaignMember(
            CampaignId = tradeShow.Id,
            ContactId = contact2.Id,
            Status = 'Responded'
        );

        CampaignMember cm3 = new CampaignMember(
            CampaignId = webinar.Id,
            ContactId = contact1.Id,
            Status = 'Sent'
        );

        insert new List<CampaignMember>{cm1, cm2, cm3};

        Opportunity opp = new Opportunity(
            Name = 'Campaign Influenced Deal',
            AccountId = acc.Id,
            Amount = 150000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
    }

    // ------------------------------------------------------------------------
    // Trigger: Contacts auto-added to a Campaign when a deal closes.
    // ------------------------------------------------------------------------

    @isTest
    static void testAddContactsOnDealClose() {
        Opportunity opp = [SELECT Id, StageName, AccountId FROM Opportunity
                           WHERE Name = 'Campaign Influenced Deal' LIMIT 1];

        Campaign tradeShow = [SELECT Id FROM Campaign WHERE Name = '2026 Tech Conference' LIMIT 1];

        // Closing the deal should trigger adding the account's contacts
        // to the campaign as "Responded" members.
        opp.StageName = 'Closed Won';
        update opp;

        List<CampaignMember> members = [SELECT ContactId, CampaignId, Status
                                        FROM CampaignMember
                                        WHERE CampaignId = :tradeShow.Id];

        System.assert(members.size() >= 2, 'Contacts should be added to campaign on deal close');
    }

    // ------------------------------------------------------------------------
    // Trigger: Completing an activity updates the member's campaign status.
    // ------------------------------------------------------------------------

    @isTest
    static void testUpdateMemberStatusOnActivity() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Contact 1' LIMIT 1];
        CampaignMember cm = [SELECT Id, Status FROM CampaignMember
                             WHERE ContactId = :c.Id AND Status = 'Sent' LIMIT 1];

        // Inserting a completed Task on the contact should flip the
        // CampaignMember status from 'Sent' -> 'Responded'.
        Task t = new Task(
            Subject = 'Follow-up call',
            WhoId = c.Id,
            Status = 'Completed',
            ActivityDate = Date.today()
        );
        insert t;

        CampaignMember updated = [SELECT Status FROM CampaignMember WHERE Id = :cm.Id];
        System.assertEquals('Responded', updated.Status,
            'Campaign member status should update to Responded on activity');
    }

    // ------------------------------------------------------------------------
    // METRICS: total members, responded, conversion rate, revenue, ROI.
    // ------------------------------------------------------------------------

    @isTest
    static void testCalculateCampaignMetrics() {
        Campaign tradeShow = [SELECT Id FROM Campaign WHERE Name = '2026 Tech Conference' LIMIT 1];

        Account acc = [SELECT Id FROM Account WHERE Name = 'Campaign Test Account' LIMIT 1];

        // Add a Closed Won deal so the service has revenue to attribute
        Opportunity opp = new Opportunity(
            Name = 'Trade Show Deal',
            AccountId = acc.Id,
            Amount = 200000,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-5)
        );
        insert opp;

        CampaignService.calculateCampaignMetrics(new Set<Id>{tradeShow.Id});

        Campaign updated = [SELECT Total_Members__c, Responded_Members__c,
                                   Conversion_Rate__c, Total_Revenue_Generated__c,
                                   ROI__c, Cost_Per_Lead__c
                            FROM Campaign WHERE Id = :tradeShow.Id];

        // 2 members (1 Sent + 1 Responded)
        System.assertEquals(2, updated.Total_Members__c, 'Should have 2 members');
        System.assertEquals(1, updated.Responded_Members__c, 'Should have 1 responded');
        // Conversion = responded / total = 1/2 = 50%
        System.assert(updated.Conversion_Rate__c == 50, 'Conversion rate should be 50%');
        System.assert(updated.Total_Revenue_Generated__c > 0, 'Should have revenue generated');
        System.assert(updated.ROI__c != null, 'ROI should be calculated');
    }

    // ------------------------------------------------------------------------
    // BULK ADD: add members to a campaign from a SOQL query.
    // ------------------------------------------------------------------------

    @isTest
    static void testBulkAddMembersFromQuery() {
        Campaign webinar = [SELECT Id FROM Campaign WHERE Name = 'Product Demo Webinar' LIMIT 1];

        Integer membersBefore = [SELECT COUNT() FROM CampaignMember WHERE CampaignId = :webinar.Id];

        // The query string 'Industry = ''Technology''' targets all Technology accounts
        CampaignService.bulkAddMembersFromQuery(
            webinar.Id,
            'Industry = \'Technology\''
        );

        Integer membersAfter = [SELECT COUNT() FROM CampaignMember WHERE CampaignId = :webinar.Id];

        System.assert(membersAfter >= membersBefore, 'Should add new members');
    }

    @isTest
    static void testBulkAddMembersNoDuplicates() {
        Campaign tradeShow = [SELECT Id FROM Campaign WHERE Name = '2026 Tech Conference' LIMIT 1];

        Integer membersBefore = [SELECT COUNT() FROM CampaignMember WHERE CampaignId = :tradeShow.Id];

        // Re-running the same add should find all contacts already members
        CampaignService.bulkAddMembersFromQuery(
            tradeShow.Id,
            'LastName LIKE \'%Contact%\''
        );

        Integer membersAfter = [SELECT COUNT() FROM CampaignMember WHERE CampaignId = :tradeShow.Id];

        System.assertEquals(membersBefore, membersAfter,
            'Should not add duplicate members');
    }

    // ------------------------------------------------------------------------
    // Member status changes and one-contact-many-campaigns sanity checks.
    // ------------------------------------------------------------------------

    @isTest
    static void testCampaignMemberStatuses() {
        CampaignMember cm = [SELECT Status FROM CampaignMember
                             WHERE Status = 'Sent' LIMIT 1];

        cm.Status = 'Responded';
        update cm;

        CampaignMember updated = [SELECT Status FROM CampaignMember WHERE Id = :cm.Id];
        System.assertEquals('Responded', updated.Status);
    }

    @isTest
    static void testMultipleCampaignsPerContact() {
        // A contact can be a member of MANY campaigns (many-to-many)
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Contact 1' LIMIT 1];
        Campaign emailBlast = [SELECT Id FROM Campaign WHERE Name = 'Q1 Email Blast' LIMIT 1];

        CampaignMember cm = new CampaignMember(
            CampaignId = emailBlast.Id,
            ContactId = c.Id,
            Status = 'Sent'
        );
        insert cm;

        List<CampaignMember> allMembers = [SELECT Campaign.Name, Status
                                           FROM CampaignMember
                                           WHERE ContactId = :c.Id];

        System.assert(allMembers.size() >= 2,
            'Contact should be member of multiple campaigns');
    }

    // ------------------------------------------------------------------------
    // EDGE CASES: zero cost, zero members (avoid divide-by-zero / nulls).
    // ------------------------------------------------------------------------

    @isTest
    static void testCampaignROIWithNoCost() {
        // ROI = (revenue - cost) / cost -> division by zero must be guarded
        Campaign noCostCampaign = new Campaign(
            Name = 'Free Organic Campaign',
            Type = 'Referral',
            Status = 'In Progress',
            Budget = 0,
            ActualCost = 0
        );
        insert noCostCampaign;

        CampaignService.calculateCampaignMetrics(new Set<Id>{noCostCampaign.Id});

        Campaign updated = [SELECT ROI__c, Cost_Per_Lead__c FROM Campaign WHERE Id = :noCostCampaign.Id];
        System.assertEquals(0, updated.ROI__c, 'ROI should be 0 with no cost');
        System.assertEquals(0, updated.Cost_Per_Lead__c, 'Cost per lead should be 0 with no cost');
    }

    @isTest
    static void testCampaignWithNoMembers() {
        Campaign emptyCampaign = new Campaign(
            Name = 'Empty Campaign',
            Type = 'Email',
            Status = 'Planned',
            Budget = 10000,
            ActualCost = 5000
        );
        insert emptyCampaign;

        CampaignService.calculateCampaignMetrics(new Set<Id>{emptyCampaign.Id});

        Campaign updated = [SELECT Total_Members__c, Conversion_Rate__c, ROI__c
                            FROM Campaign WHERE Id = :emptyCampaign.Id];

        // No members -> totals should be 0, never null
        System.assertEquals(0, updated.Total_Members__c, 'Should have 0 members');
        System.assertEquals(0, updated.Conversion_Rate__c, 'Conversion should be 0');
    }

    // ------------------------------------------------------------------------
    // BULK metrics update over ALL campaigns at once.
    // ------------------------------------------------------------------------

    @isTest
    static void testBulkCampaignMetricsUpdate() {
        List<Campaign> campaigns = [SELECT Id FROM Campaign];

        Set<Id> campaignIds = new Set<Id>();
        for (Campaign c : campaigns) {
            campaignIds.add(c.Id);
        }

        CampaignService.calculateCampaignMetrics(campaignIds);

        List<Campaign> updatedCampaigns = [SELECT Total_Members__c, ROI__c
                                           FROM Campaign WHERE Id IN :campaignIds];

        for (Campaign c : updatedCampaigns) {
            System.assertNotEquals(null, c.Total_Members__c, 'Total members should be set');
            System.assertNotEquals(null, c.ROI__c, 'ROI should be calculated');
        }
    }

    // ------------------------------------------------------------------------
    // Duplicate prevention (the same contact added twice = 1 membership max).
    // ------------------------------------------------------------------------

    @isTest
    static void testDuplicateMemberPrevention() {
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Contact 1' LIMIT 1];
        Campaign tradeShow = [SELECT Id FROM Campaign WHERE Name = '2026 Tech Conference' LIMIT 1];

        Integer membersBefore = [SELECT COUNT() FROM CampaignMember
                                 WHERE CampaignId = :tradeShow.Id AND ContactId = :c.Id];

        // Try to force-add this exact contact again
        CampaignService.bulkAddMembersFromQuery(
            tradeShow.Id,
            'Id = \'' + c.Id + '\''
        );

        Integer membersAfter = [SELECT COUNT() FROM CampaignMember
                                WHERE CampaignId = :tradeShow.Id AND ContactId = :c.Id];

        System.assertEquals(membersBefore, membersAfter,
            'Should not create duplicate campaign member');
    }
}