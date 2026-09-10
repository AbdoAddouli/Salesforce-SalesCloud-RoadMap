/*
 * ============================================================================
 * ActivityService
 * ============================================================================
 *
 * [LEARNING FOCUS: Phase 6 - Sales Collaboration & Activities]
 *
 * WHAT THIS CLASS DOES:
 * Business logic around Tasks, Events, and Chatter - the day-to-day
 * "activity" a sales rep logs against their deals and contacts.
 * Called from TaskActivityTrigger.
 *
 * RESPONSIBILITIES:
 *   - Auto-create follow-up tasks when a task is completed
 *   - Post Chatter updates on high-value deals
 *   - Calculate per-user activity metrics (call volume, meetings, etc.)
 *   - Notify a manager via Chatter when activity happens on big deals
 *
 * KEY CONCEPTS DEMONSTRATED:
 * 1. Private helper methods - `determineFollowUpSubject()` and
 *    `calculateFollowUpDate()` are `private static` because they are only
 *    used internally by this class. This keeps the public API clean.
 *
 * 2. Record prefixes - `String.valueOf(t.WhatId).startsWith('006')` checks
 *    that the related record is an Opportunity ('006' = Opportunity prefix).
 *
 * 3. Wrapper / Inner classes - `ActivityMetrics` bundles related metrics
 *    into one object and even computes derived values (completionRate,
 *    avgCallDuration) using GETTERS.
 *
 * 4. Chatter FeedItem - posting to a record's feed via the `FeedItem`
 *    object (ParentId = the record to post on).
 * ============================================================================
 */
public with sharing class ActivityService {

    /*
     * createFollowUpTasks(List<Task> completedTasks)
     * ----------------------------------------------------------------------
     * PURPOSE: Whenever a Task is marked "Completed", immediately create a
     * new follow-up Task so the next step of the sales process is already
     * scheduled. Trust the sales process, not the rep's memory!
     *
     * WHEN: Called from an `after update`/`after insert` trigger context,
     * because it performs DML (creating new records).
     * ----------------------------------------------------------------------
     */
    public static void createFollowUpTasks(List<Task> completedTasks) {
        List<Task> followUps = new List<Task>();

        for (Task t : completedTasks) {
            // Only completed tasks that are linked to a record (WhatId)
            if (t.Status == 'Completed' && t.WhatId != null) {
                // Delegate the "what text" and "when" decisions to helpers
                String followUpSubject = determineFollowUpSubject(t);

                followUps.add(new Task(
                    Subject = followUpSubject,
                    WhatId = t.WhatId,
                    WhoId = t.WhoId,
                    OwnerId = t.OwnerId,
                    ActivityDate = calculateFollowUpDate(t),
                    Priority = 'Normal',
                    Status = 'Not Started',
                    Description = 'Auto-created follow-up from: ' + t.Subject
                ));
            }
        }

        if (!followUps.isEmpty()) {
            insert followUps;
        }
    }

    /*
     * determineFollowUpSubject(Task t)  [PRIVATE]
     * ----------------------------------------------------------------------
     * PURPOSE: Decide the subject line of the follow-up based on the type of
     * activity that was completed. Uses String.contains() so it works even
     * when the task subject has extra words.
     * ----------------------------------------------------------------------
     */
    private static String determineFollowUpSubject(Task t) {
        if (t.Subject != null && t.Subject.contains('Discovery Call')) {
            return 'Send follow-up email after Discovery Call';
        } else if (t.Subject != null && t.Subject.contains('Demo')) {
            return 'Send demo summary and next steps';
        } else if (t.Subject != null && t.Subject.contains('Proposal')) {
            return 'Follow up on proposal - check for questions';
        } else if (t.Subject != null && t.Subject.contains('Contract')) {
            return 'Follow up on contract review';
        }
        return 'Follow up on: ' + t.Subject;
    }

    /*
     * calculateFollowUpDate(Task t)  [PRIVATE]
     * ----------------------------------------------------------------------
     * PURPOSE: Compute WHEN the follow-up is due. Different activity types
     * have different urgency (a contract review gets a 1-day follow-up,
     * a proposal gets 3 days).
     * ----------------------------------------------------------------------
     */
    private static Date calculateFollowUpDate(Task t) {
        if (t.Activity_Type__c == 'Discovery Call') {
            return Date.today().addDays(2);
        } else if (t.Activity_Type__c == 'Demo') {
            return Date.today().addDays(1);
        } else if (t.Activity_Type__c == 'Proposal Sent') {
            return Date.today().addDays(3);
        } else if (t.Activity_Type__c == 'Contract Review') {
            return Date.today().addDays(1);
        }
        return Date.today().addDays(3);
    }

    /*
     * postChatterOnHighValueActivity(List<Task> tasks)
     * ----------------------------------------------------------------------
     * PURPOSE: For activities logged against Opportunities worth $100k+,
     * post a Chatter update on the opportunity so the whole team can see
     * the activity and stay informed.
     *
     * FEEDITEM: The Chatter "post" object. ParentId is the record the post
     * appears on. Body is the text of the post.
     * ----------------------------------------------------------------------
     */
    public static void postChatterOnHighValueActivity(List<Task> tasks) {
        List<FeedItem> posts = new List<FeedItem>();

        for (Task t : tasks) {
            // '006' prefix = Opportunity record
            if (t.WhatId != null && String.valueOf(t.WhatId).startsWith('006')) {
                Opportunity opp = [
                    SELECT Name, Amount, StageName, Owner.Name
                    FROM Opportunity WHERE Id = :t.WhatId
                ];

                // Only for high-value deals
                if (opp.Amount != null && opp.Amount >= 100000) {
                    String body = 'High-value activity logged on ' + opp.Name +
                                  ' ($' + opp.Amount.setScale(0).format() + ')\n\n' +
                                  'Activity: ' + t.Subject + '\n' +
                                  'Status: ' + t.Status + '\n' +
                                  'Type: ' + (t.Activity_Type__c != null ? t.Activity_Type__c : 'N/A');

                    posts.add(new FeedItem(
                        Body = body,
                        ParentId = t.WhatId
                    ));
                }
            }
        }

        if (!posts.isEmpty()) {
            insert posts;
        }
    }

    /*
     * calculateActivityMetrics(Set<Id> userIds, Date startDate, Date endDate)
     * ----------------------------------------------------------------------
     * PURPOSE: Produce an ActivityMetrics object per user covering a date
     * range. Drives "who is actually selling" dashboards.
     *
     * Collects from TWO sources:
     *   - Task records (calls, follow-ups) - counted individually
     *   - Event records (meetings) - counted with an AggregateResult query
     *
     * RETURNS: Map<Id, ActivityMetrics> - keyed by user Id for easy lookup.
     * ----------------------------------------------------------------------
     */
    public static Map<Id, ActivityMetrics> calculateActivityMetrics(Set<Id> userIds, Date startDate, Date endDate) {
        // Pre-populate the map so every requested user has an entry
        Map<Id, ActivityMetrics> metricsByUser = new Map<Id, ActivityMetrics>();

        for (Id userId : userIds) {
            metricsByUser.put(userId, new ActivityMetrics());
        }

        // Task metrics
        List<Task> tasks = [
            SELECT OwnerId, Status, Subject, ActivityDate, Activity_Type__c,
                   Call_Duration_Minutes__c
            FROM Task
            WHERE OwnerId IN :userIds
            AND ActivityDate >= :startDate AND ActivityDate <= :endDate
        ];

        for (Task t : tasks) {
            ActivityMetrics m = metricsByUser.get(t.OwnerId);
            m.totalTasks++;

            if (t.Status == 'Completed') {
                m.completedTasks++;
                if (t.Call_Duration_Minutes__c != null) {
                    m.totalCallMinutes += Integer.valueOf(t.Call_Duration_Minutes__c);
                }
            } else {
                m.openTasks++;
            }

            // Tally by activity type
            if (t.Activity_Type__c == 'Discovery Call') m.discoveryCalls++;
            if (t.Activity_Type__c == 'Demo') m.demos++;
            if (t.Activity_Type__c == 'Follow-Up') m.followUps++;
        }

        // Event (meeting) metrics, gathered with GROUP BY (AggregateResult)
        List<AggregateResult> results = [
            SELECT OwnerId, COUNT(Id) eventCount, SUM(DurationInMinutes) totalMinutes
            FROM Event
            WHERE OwnerId IN :userIds
            AND ActivityDate >= :startDate AND ActivityDate <= :endDate
            GROUP BY OwnerId
        ];

        for (AggregateResult ar : results) {
            Id ownerId = (Id) ar.get('OwnerId');
            ActivityMetrics m = metricsByUser.get(ownerId);
            m.totalEvents = (Integer) ar.get('eventCount');
            m.totalMeetingMinutes = (Integer) ar.get('totalMinutes');
        }

        return metricsByUser;
    }

    /*
     * notifyManagerOnLargeDealActivity(List<Task> tasks)
     * ----------------------------------------------------------------------
     * PURPOSE: When activity is logged against a $100k+ opportunity, post a
     * Chatter mention to the owning rep's MANAGER, so leadership stays aware
     * of strategic deals.
     *
     * TRAVERSAL: `Owner.ManagerId` reaches from the Opportunity to its owner
     * (a User) and then to that User's manager. If no manager, skip.
     * ----------------------------------------------------------------------
     */
    public static void notifyManagerOnLargeDealActivity(List<Task> tasks) {
        Set<Id> oppIds = new Set<Id>();

        for (Task t : tasks) {
            if (t.WhatId != null && String.valueOf(t.WhatId).startsWith('006')) {
                oppIds.add(t.WhatId);
            }
        }

        if (oppIds.isEmpty()) return;

        // Only big deals ($100k+) that have a manager on the owner
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, Name, Amount, OwnerId, Owner.ManagerId
             FROM Opportunity WHERE Id IN :oppIds
             AND Amount >= 100000]
        );

        List<FeedItem> posts = new List<FeedItem>();

        for (Task t : tasks) {
            if (oppMap.containsKey(t.WhatId)) {
                Opportunity opp = oppMap.get(t.WhatId);
                if (opp.Owner.ManagerId != null) {
                    // '@' + Id creates a mention in the post body
                    posts.add(new FeedItem(
                        Body = '@' + opp.Owner.ManagerId + ' Activity logged on high-value deal: ' +
                               opp.Name + ' ($' + opp.Amount.setScale(0).format() + ')\n' +
                               t.Subject,
                        ParentId = t.WhatId
                    ));
                }
            }
        }

        if (!posts.isEmpty()) {
            insert posts;
        }
    }

    /*
     * ActivityMetrics  [INNER CLASS]
     * ----------------------------------------------------------------------
     * PURPOSE: A lightweight "wrapper" object (a class nested inside the
     * service class) that bundles all activity statistics for one user.
     *
     * GETTER METHODS: `completionRate` and `avgCallDuration` are computed
     * on the fly when you access them. Note the syntax:
     *   public Decimal completionRate { get { return ...; } }
     * They are READ-ONLY (no setter) - intentionally, since they are derived.
     * ----------------------------------------------------------------------
     */
    public class ActivityMetrics {
        // Raw counters populated by calculateActivityMetrics()
        public Integer totalTasks = 0;
        public Integer completedTasks = 0;
        public Integer openTasks = 0;
        public Integer totalEvents = 0;
        public Integer totalCallMinutes = 0;
        public Integer totalMeetingMinutes = 0;
        public Integer discoveryCalls = 0;
        public Integer demos = 0;
        public Integer followUps = 0;

        // Derived value: % of tasks completed
        public Decimal completionRate {
            get {
                return totalTasks > 0 ? (completedTasks * 100.0 / totalTasks) : 0;
            }
        }

        // Derived value: average minutes per completed call task
        public Decimal avgCallDuration {
            get {
                return completedTasks > 0 ? (totalCallMinutes * 1.0 / completedTasks) : 0;
            }
        }
    }
}