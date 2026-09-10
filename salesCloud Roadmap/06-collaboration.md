# Phase 6: Sales Collaboration

## Learning Objectives
By the end of this phase, you will be able to:
- Configure and use Activities (Tasks & Events)
- Set up Chatter for team collaboration
- Configure email integration (Gmail, Outlook)
- Implement activity tracking and reporting
- Build automation around activities

---

## 1. Activities in Salesforce

Activities are the interactions your sales team logs — calls, meetings, emails, and tasks.

### Task
A to-do item with a due date and status:
| Field | Purpose |
|-------|---------|
| Subject | Task title (Call, Email, Meeting, etc.) |
| Status | Not Started, In Progress, Completed |
| Priority | High, Normal, Low |
| Due Date | When it's due |
| Assigned To | Who is responsible |
| Related To | Account, Contact, Opportunity, Lead |

### Event
A calendar item with start/end times:
| Field | Purpose |
|-------|---------|
| Subject | Meeting title |
| Start DateTime | When it starts |
| End DateTime | When it ends |
| Location | Where it happens |
| Related To | Account, Contact, Opportunity, Lead |

### Activity Timeline
The Activity Timeline on record pages shows all activities in chronological order:
- Past activities appear in gray
- Future activities appear in blue
- Overdue tasks appear in red

---

## 2. Activity Configuration

### Activity Settings
1. Setup > **Activity Settings**
2. Configure:
   - **Enable Activity Metrics** — track rollup counts
   - **Allow Logging of Recurring Events** — repeat meetings
   - **Enable Drag-and-Drop for Calendar** — drag tasks to calendar

### Activity Rollup Fields
Add rollup summary fields to track activity counts on parent objects:
- **Tasks Open** — COUNT of incomplete tasks
- **Tasks Completed** — COUNT of completed tasks
- **Events This Month** — COUNT of events this month
- **Last Activity Date** — MAX of all activity dates

### Activity Definitions
Customize the available activity types:
1. Setup > **Activity Definitions**
2. Create custom definitions:
   - Discovery Call
   - Demo
   - Proposal Sent
   - Contract Review
   - Follow-Up

---

## 3. Chatter

Chatter is Salesforce's social collaboration tool — like an internal social network.

### Chatter Feeds
Every record has a Chatter feed where team members can:
- Post updates and questions
- Share files
- Tag colleagues with @mentions
- Follow records for notifications

### Chatter Groups
Create groups for specific teams or topics:
| Group Type | Purpose |
|------------|---------|
| Public | Anyone in the org can join |
| Private | Invitation-only |
| Unlisted | Hidden, invite-only |

### Chatter Best Practices for Sales
- **Follow key Accounts** — get notified of changes
- **@mention teammates** — ask for help on deals
- **Post deal updates** — keep the team informed
- **Share files** — contracts, proposals, presentations

---

## 4. Email Integration

### Salesforce Inbox
Integrates email with Salesforce directly in your inbox:
- Log emails to Salesforce records
- Track email opens and clicks
- Use email templates
- Schedule emails

### Gmail Integration
1. Install the **Salesforce Gmail Integration** from AppExchange
2. Connect Gmail to Salesforce
3. Log emails with one click
4. See Salesforce data alongside emails

### Outlook Integration
1. Setup > **Outlook Integration**
2. Enable the Outlook add-in
3. Sync contacts and calendar
4. Log emails to related records

### Email Templates
Create reusable templates for common sales emails:
1. Setup > **Classic Email Templates** or **Lightning Email Templates**
2. Create folders for different use cases:
   - Initial Outreach
   - Follow-Up
   - Proposal
   - Thank You
3. Use merge fields: `{!Account.Name}`, `{!Contact.FirstName}`

---

## 5. Activity Reporting

### Standard Reports
| Report | Description |
|--------|-------------|
| Tasks & Events | All activities with filters |
| My Open Tasks | Tasks assigned to me |
| Activities by Account | Activities grouped by Account |
| Activity History | Completed activities |

### Key Activity Metrics
| Metric | Formula |
|--------|---------|
| **Activity Rate** | Total activities / Number of reps |
| **Tasks per Opportunity** | Total tasks / Open opportunities |
| **Response Time** | Time from lead creation to first activity |
| **Meeting Frequency** | Events per opportunity per week |

---

## 6. Automation

### Flow: Auto-Create Follow-Up Task
Record-Triggered Flow on Task:
- **Trigger:** When Task is marked Complete
- **Criteria:** Subject contains "Discovery Call"
- **Action:** Create new Task "Send follow-up email" with due date = TODAY + 2

### Flow: Notify Manager on Large Deal Activity
- **Trigger:** When Event is created
- **Criteria:** Related Opportunity Amount > $100,000
- **Action:** Post to Chatter mentioning the Opportunity owner's manager

### Apex: Auto-Log Email Activity
```apex
public class ActivityService {
    public static void createFollowUpTask(Id opportunityId, String subject) {
        Opportunity opp = [
            SELECT Id, Name, CloseDate, OwnerId
            FROM Opportunity WHERE Id = :opportunityId
        ];

        Task followUp = new Task(
            Subject = subject,
            Status = 'Not Started',
            Priority = 'Normal',
            WhatId = opportunityId,
            OwnerId = opp.OwnerId,
            ActivityDate = Date.today().addDays(3)
        );

        insert followUp;
    }
}
```

---

## 7. Hands-On Exercises

### Exercise 1: Log Activities
1. Create a Task "Call John Smith" related to a Contact
2. Create an Event "Demo with Acme Corp" related to an Opportunity
3. Complete the Task and verify it shows in the Activity Timeline

### Exercise 2: Set Up Chatter
1. Follow an Account record
2. Post an update with @mention to a colleague
3. Create a Chatter group "Sales Team - Q1"
4. Add team members to the group

### Exercise 3: Build an Activity Report
1. Create a Report Type: "Tasks and Events with Opportunity"
2. Build a report showing:
   - Activities per rep
   - Activities per opportunity
   - Completed vs. open tasks
3. Add to a Dashboard

---

## 8. SOQL Practice

```sql
-- Open tasks
SELECT Subject, Status, Priority, ActivityDate, Who.Name, What.Name
FROM Task
WHERE Status != 'Completed'
ORDER BY ActivityDate ASC

-- Activities on an opportunity
SELECT Subject, ActivityDate, Type, Who.Name
FROM Task
WHERE WhatId = '006[OPPORTUNITY_ID]'

-- Tasks completed this week
SELECT Subject, CompletedDateTime, Who.Name, What.Name
FROM Task
WHERE Status = 'Completed'
AND CompletedDate = THIS_WEEK

-- Activity count by type
SELECT Type, COUNT(Id) activityCount
FROM Task
GROUP BY Type
ORDER BY activityCount DESC

-- Overdue tasks
SELECT Subject, ActivityDate, Who.Name, Owner.Name
FROM Task
WHERE Status != 'Completed'
AND ActivityDate < TODAY
ORDER BY ActivityDate ASC
```

---

## Next Phase

**[Phase 7: Processes & Automation](./07-processes-automation.md)** — Build approval processes, Flows, and assignment rules for the full sales lifecycle.
