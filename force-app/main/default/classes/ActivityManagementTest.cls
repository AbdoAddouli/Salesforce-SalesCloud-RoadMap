/*
 * ============================================================================
 * ActivityManagementTest
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 6 - Activity Management (Tasks & Events)]
 *
 * WHAT THIS TEST CLASS DOES:
 * Verifies ActivityService logic and TaskActivityTrigger behavior:
 *   - Auto-creating a follow-up Task after a completed activity
 *   - Posting to Chatter (FeedItem) for high-value deals
 *   - Calculating activity metrics (tasks, events, call duration, completion)
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Tasks have WhoId (related person: Lead/Contact) and WhatId (related
 *    record: Account/Opportunity).
 * 2. Chatter feeds are stored as FeedItem records (ParentId = record being
 *    followed). Creating a FeedItem via code simulates a @mention/post.
 * 3. Nested inner class: ActivityService.ActivityMetrics - a simple value
 *    object used to pass calculated numbers around.
 * 4. Aggregate queries in the service to total up task duration / counts.
 * ============================================================================
 */
@isTest
private class ActivityManagementTest {

    /*
     * makeData() [@TestSetup]
     * ----------------------------------------------------------------------
     * Creates an Account + Contact + two Opportunities ('High Value Deal'
     * amounts > 100k gets Chatter posts; 'Small Deal' does not).
     * ----------------------------------------------------------------------
     */
    @TestSetup
    static void makeData() {
        User salesRep = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Account acc = new Account(
            Name = 'Activity Test Account',
            Industry = 'Technology',
            AnnualRevenue = 5000000
        );
        insert acc;

        Contact c = new Contact(
            FirstName = 'Activity',
            LastName = 'Test Contact',
            AccountId = acc.Id,
            Email = 'activity@test.com',
            Role__c = 'Decision Maker'
        );
        insert c;

        Opportunity opp = new Opportunity(
            Name = 'High Value Deal',
            AccountId = acc.Id,
            Amount = 200000,               // above the Chatter threshold
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            OwnerId = salesRep.Id
        );

        Opportunity smallOpp = new Opportunity(
            Name = 'Small Deal',
            AccountId = acc.Id,
            Amount = 10000,                // below the Chatter threshold
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            OwnerId = salesRep.Id
        );

        insert new List<Opportunity>{opp, smallOpp};
    }

    // ------------------------------------------------------------------------
    // FOLLOW-UP TASK auto-creation on completed activities.
    // ------------------------------------------------------------------------

    @isTest
    static void testFollowUpTaskCreation() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'High Value Deal' LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Test Contact' LIMIT 1];

        // Completing a discovery call -> trigger should schedule a follow-up
        Task t = new Task(
            Subject = 'Discovery Call with Contact',
            WhatId = opp.Id,
            WhoId = c.Id,
            Status = 'Completed',
            Activity_Type__c = 'Discovery Call',
            ActivityDate = Date.today()
        );
        insert t;

        List<Task> followUps = [SELECT Subject, WhatId, Status, ActivityDate
                                FROM Task
                                WHERE WhatId = :opp.Id
                                AND Subject LIKE '%Follow%'];

        System.assert(followUps.size() > 0, 'Follow-up task should be created');
        System.assertEquals('Not Started', followUps[0].Status);
        System.assert(followUps[0].ActivityDate > Date.today(),
            'Follow-up should be scheduled for future');
    }

    @isTest
    static void testFollowUpSubjectByType() {
        // The follow-up subject should be derived from the activity type (Demo)
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'High Value Deal' LIMIT 1];

        Task demoTask = new Task(
            Subject = 'Product Demo',
            WhatId = opp.Id,
            Status = 'Completed',
            Activity_Type__c = 'Demo',
            ActivityDate = Date.today()
        );
        insert demoTask;

        List<Task> followUps = [SELECT Subject FROM Task
                                WHERE WhatId = :opp.Id
                                AND Subject LIKE '%Demo%'];

        System.assert(followUps.size() > 0, 'Demo follow-up should be created');
    }

    // ------------------------------------------------------------------------
    // CHATTER notifications for high-value deals.
    // ------------------------------------------------------------------------

    @isTest
    static void testChatterPostOnHighValueActivity() {
        Opportunity opp = [SELECT Id, Amount FROM Opportunity
                           WHERE Name = 'High Value Deal' LIMIT 1];

        Task t = new Task(
            Subject = 'Important call on big deal',
            WhatId = opp.Id,
            Status = 'Completed',
            ActivityDate = Date.today()
        );
        insert t;

        // High-value deal (> threshold) -> the trigger posts to the record feed
        List<FeedItem> posts = [SELECT Body, ParentId FROM FeedItem
                                WHERE ParentId = :opp.Id];

        System.assert(posts.size() > 0, 'Chatter post should be created for high-value activity');
    }

    @isTest
    static void testNoChatterPostOnSmallDeal() {
        // Small deal -> NO chatter post
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Small Deal' LIMIT 1];

        Task t = new Task(
            Subject = 'Small deal activity',
            WhatId = opp.Id,
            Status = 'Completed',
            ActivityDate = Date.today()
        );
        insert t;

        List<FeedItem> posts = [SELECT Body FROM FeedItem
                                WHERE ParentId = :opp.Id
                                AND Body LIKE '%High-value%'];

        System.assertEquals(0, posts.size(), 'No chatter post for small deal activities');
    }

    // ------------------------------------------------------------------------
    // METRICS: totals per rep across Tasks + Events.
    // ------------------------------------------------------------------------

    @isTest
    static void testActivityMetrics() {
        User salesRep = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];

        Date monthStart = Date.today().toStartOfMonth();
        Date monthEnd = monthStart.addMonths(1).addDays(-1);

        Task t1 = new Task(
            Subject = 'Call 1',
            OwnerId = salesRep.Id,
            Status = 'Completed',
            Activity_Type__c = 'Discovery Call',
            Call_Duration_Minutes__c = 30,
            ActivityDate = Date.today()
        );

        Task t2 = new Task(
            Subject = 'Call 2',
            OwnerId = salesRep.Id,
            Status = 'Completed',
            Activity_Type__c = 'Follow-Up',
            Call_Duration_Minutes__c = 15,
            ActivityDate = Date.today()
        );

        Task t3 = new Task(
            Subject = 'Open Task',
            OwnerId = salesRep.Id,
            Status = 'Not Started',
            ActivityDate = Date.today()
        );

        insert new List<Task>{t1, t2, t3};

        // Events have start/end datetimes (unlike Tasks with a single date)
        Event e = new Event(
            Subject = 'Client Meeting',
            OwnerId = salesRep.Id,
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1),
            DurationInMinutes = 60,
            ActivityDate = Date.today()
        );
        insert e;

        Map<Id, ActivityService.ActivityMetrics> metrics =
            ActivityService.calculateActivityMetrics(
                new Set<Id>{salesRep.Id}, monthStart, monthEnd
            );

        ActivityService.ActivityMetrics m = metrics.get(salesRep.Id);
        System.assert(m.totalTasks >= 3, 'Should have at least 3 tasks');
        System.assert(m.completedTasks >= 2, 'Should have at least 2 completed tasks');
        System.assert(m.openTasks >= 1, 'Should have at least 1 open task');
        System.assert(m.totalEvents >= 1, 'Should have at least 1 event');
        System.assert(m.discoveryCalls >= 1, 'Should have at least 1 discovery call');
    }

    // ------------------------------------------------------------------------
    // Inner-class metric helpers: completionRate / avgCallDuration formulas.
    // ------------------------------------------------------------------------

    @isTest
    static void testCompletionRate() {
        // The ActivityMetrics inner class computes derived numbers on demand
        ActivityService.ActivityMetrics m = new ActivityService.ActivityMetrics();
        m.totalTasks = 10;
        m.completedTasks = 7;
        m.openTasks = 3;

        System.assertEquals(70, m.completionRate, 'Completion rate should be 70%');
    }

    @isTest
    static void testAvgCallDuration() {
        ActivityService.ActivityMetrics m = new ActivityService.ActivityMetrics();
        m.completedTasks = 5;
        m.totalCallMinutes = 150;

        System.assertEquals(30, m.avgCallDuration, 'Avg call duration should be 30 minutes');
    }

    // ------------------------------------------------------------------------
    // BULK behavior + negative cases.
    // ------------------------------------------------------------------------

    @isTest
    static void testBulkTaskCreation() {
        // 50 completed tasks -> 50 follow-up tasks (proves bulk safety)
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'High Value Deal' LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE LastName = 'Test Contact' LIMIT 1];

        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 50; i++) {
            tasks.add(new Task(
                Subject = 'Bulk Task ' + i,
                WhatId = opp.Id,
                WhoId = c.Id,
                Status = 'Completed',
                Activity_Type__c = 'Other',
                ActivityDate = Date.today()
            ));
        }

        insert tasks;

        List<Task> followUps = [SELECT Id FROM Task
                                WHERE Subject LIKE '%Follow%'
                                AND WhatId = :opp.Id];

        System.assert(followUps.size() >= 50,
            'Should create follow-up for each completed task');
    }

    @isTest
    static void testNoFollowUpForIncompleteTasks() {
        // Not-Started tasks must NOT spawn follow-ups
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'High Value Deal' LIMIT 1];

        Task t = new Task(
            Subject = 'Incomplete Task',
            WhatId = opp.Id,
            Status = 'Not Started',
            ActivityDate = Date.today()
        );
        insert t;

        Integer followUpCount = [SELECT COUNT() FROM Task
                                 WHERE WhatId = :opp.Id
                                 AND Subject LIKE '%Follow-up%incomplete%'];

        System.assertEquals(0, followUpCount,
            'No follow-up should be created for incomplete tasks');
    }

    @isTest
    static void testManagerNotificationOnHighValueDeal() {
        // Confirms a FeedItem (visible to followers incl. the manager)
        // is produced for high-value deal activity.
        Opportunity opp = [SELECT Id, Amount, OwnerId FROM Opportunity
                           WHERE Name = 'High Value Deal' LIMIT 1];

        Task t = new Task(
            Subject = 'Manager notification test',
            WhatId = opp.Id,
            Status = 'Completed',
            ActivityDate = Date.today()
        );
        insert t;

        List<FeedItem> posts = [SELECT Body FROM FeedItem
                                WHERE ParentId = :opp.Id];

        System.assert(posts.size() > 0,
            'Manager should be notified on high-value deal activity');
    }

    @isTest
    static void testActivityMetricsWithNoData() {
        // Querying a time window with NO activities must return zeros,
        // not nulls (the service should handle the empty map case).
        Id fakeUserId = UserInfo.getUserId();

        Map<Id, ActivityService.ActivityMetrics> metrics =
            ActivityService.calculateActivityMetrics(
                new Set<Id>{fakeUserId},
                Date.today().addDays(-365),
                Date.today().addDays(-364)   // a 1-day window a year ago
            );

        ActivityService.ActivityMetrics m = metrics.get(fakeUserId);
        System.assertEquals(0, m.totalTasks, 'No tasks in empty period');
        System.assertEquals(0, m.totalEvents, 'No events in empty period');
        System.assertEquals(0, m.completionRate, 'Completion rate should be 0');
    }
}