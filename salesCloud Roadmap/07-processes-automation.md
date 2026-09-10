# Phase 7: Processes & Automation

## Learning Objectives
By the end of this phase, you will be able to:
- Build Approval Processes for deal discounts
- Configure Assignment Rules for lead and case routing
- Create Record-Triggered Flows for sales automation
- Implement Process Builder alternatives with Flow Builder
- Use Scheduled Flows for batch operations

---

## 1. Approval Processes

Approval Processes route records through a chain of approvers for review and approval.

### When to Use
- Discount approvals (> 10%, > 20%, etc.)
- Deal desk review for large deals
- Contract modifications
- Credit limit changes

### How to Build
1. Setup > **Approval Processes**
2. Select the object (Opportunity)
3. Configure:

| Step | Setting |
|------|---------|
| Entry Criteria | Amount > $50,000 AND Discount % > 20% |
| Approval Steps | Step 1: Sales Manager, Step 2: VP Sales |
| Final Approval Action | Update Status = 'Approved' |
| Final Rejection Action | Update Status = 'Rejected' |
| Recall Options | Allow recall from approval history |

### Approval Step Configuration
```
Step 1: Sales Manager
  - Criteria: Amount > $50,000
  - Approver: Role > Sales Manager
  - Allow delegate: Yes

Step 2: VP Sales
  - Criteria: Amount > $100,000 OR Discount > 30%
  - Approver: User > VP of Sales
  - Allow delegate: Yes
```

### Approval Actions
| Action | Description |
|--------|-------------|
| Field Update | Set a field value |
| Task | Create a follow-up task |
| Email Alert | Send notification email |
| Outbound Message | Send data to external system |

---

## 2. Assignment Rules

Assignment Rules automatically route records to users or queues based on criteria.

### Lead Assignment Rules
Configure in Setup > **Lead Assignment Rules**:

```
Rule 1: "Enterprise Leads"
  Entry: Annual Revenue > $1,000,000
  Action: Assign to Enterprise Sales Queue

Rule 2: "Technology Leads"
  Entry: Industry = 'Technology'
  Action: Assign to Tech Sales Queue

Rule 3: "West Coast Leads"
  Entry: State = 'CA' OR State = 'WA' OR State = 'OR'
  Action: Assign to West Coast Team

Default: Assign to Sales General Queue
```

### Case Assignment Rules
Same concept for support cases:
```
Rule 1: "Critical Issues"
  Entry: Priority = 'Critical' AND Product = 'Enterprise'
  Action: Assign to Senior Support Queue

Rule 2: "Billing Issues"
  Entry: Subject CONTAINS 'billing' OR Subject CONTAINS 'invoice'
  Action: Assign to Billing Support Queue
```

### territories-Based Assignment
Use Territory Management for geographic routing:
```
Territory: "North America East"
  Criteria: State IN ('NY', 'NJ', 'CT', 'MA', 'PA')
  Assigned To: East Coast Sales Team

Territory: "EMEA"
  Criteria: Country IN ('UK', 'Germany', 'France')
  Assigned To: EMEA Sales Team
```

---

## 3. Record-Triggered Flows

Flows are the modern replacement for Process Builder and Workflow Rules.

### Flow: Auto-Set Opportunity Close Date
```
Trigger: Opportunity is created or updated
  Field: StageName
  Type: Before Save

Decision:
  IF StageName = 'Prospecting' → Set CloseDate = TODAY + 90
  IF StageName = 'Qualification' → Set CloseDate = TODAY + 60
  IF StageName = 'Proposal/Price Quote' → Set CloseDate = TODAY + 30
  IF StageName = 'Negotiation/Review' → Set CloseDate = TODAY + 14
```

### Flow: Auto-Create Child Records
```
Trigger: Account is created
  Type: After Save

Action: Create Contact
  FirstName = 'Primary'
  LastName = 'Contact'
  AccountId = {!Record.Id}
  Role__c = 'Decision Maker'

Action: Create Task
  Subject = 'Welcome call for new account'
  WhatId = {!Record.Id}
  ActivityDate = TODAY + 3
```

### Flow: Send Notification on Deal Close
```
Trigger: Opportunity StageName changes to 'Closed Won'
  Type: After Save

Action: Post to Chatter
  Body: "Deal closed! {!Record.Name} - ${!Record.Amount} - Congrats @{!Record.OwnerId}"

Action: Send Email Alert
  Template: Deal Closed Notification
  Recipients: {!Record.OwnerId}, {!Record.Account.OwnerId}
```

---

## 4. Scheduled Flows

Scheduled Flows run at defined intervals to perform batch operations.

### Flow: Auto-Close Stale Opportunities
```
Schedule: Every Monday at 8 AM
Object: Opportunity
Criteria: StageName NOT IN ('Closed Won', 'Closed Lost')
          AND LastActivityDate < TODAY - 30

Action: Update StageName = 'Closed Lost'
        Description = 'Auto-closed: No activity for 30+ days'
```

### Flow: Weekly Pipeline Report Email
```
Schedule: Every Friday at 5 PM
Object: Opportunity
Criteria: StageName NOT IN ('Closed Won', 'Closed Lost')

Action: Send Email
  To: Sales Manager
  Subject: Weekly Pipeline Summary
  Body: Include count of open deals, total value, top 5 deals
```

---

## 5. Process Builder Migration

If your org still uses Process Builder, migrate to Flow Builder:

| Process Builder Feature | Flow Builder Equivalent |
|------------------------|------------------------|
| Record Update | Update Records element |
| Record Create | Create Records element |
| Send Email | Send Email action |
| Post to Chatter | Post to Chatter action |
| Submit for Approval | Submit for Approval action |
| Launch a Flow | Subflow element |
| Quick Action | Action element |

### Migration Steps
1. Identify all Process Builder processes
2. Recreate each in Flow Builder
3. Test in a sandbox
4. Deactivate the old Process Builder process
5. Activate the new Flow

---

## 6. Hands-On Exercises

### Exercise 1: Build an Approval Process
1. Create an Approval Process on Opportunity
2. Entry: Amount > $100,000
3. Step 1: Sales Manager approves
4. Step 2: VP Sales approves (if discount > 30%)
5. Test by submitting an Opportunity for approval

### Exercise 2: Create a Record-Triggered Flow
1. Build a Flow that auto-sets the Lead Nurture Status
2. Trigger: Lead is created or updated
3. Criteria: Lead_Score__c > 50
4. Action: Set Nurture_Status__c = 'Active Nurture'

### Exercise 3: Build a Scheduled Flow
1. Create a Scheduled Flow that runs weekly
2. Find Opportunities with no activity in 30 days
3. Update their StageName to 'Closed Lost'
4. Post a summary to Chatter

---

## 7. SOQL Practice

```sql
-- Opportunities pending approval
SELECT Name, Amount, StageName, ApprovalStatus
FROM Opportunity
WHERE ApprovalStatus = 'Pending'

-- Opportunities auto-closed
SELECT Name, Amount, ClosedDate, Description
FROM Opportunity
WHERE Description LIKE '%Auto-closed%'
AND StageName = 'Closed Lost'

-- Approval history
SELECT TargetObjectId, Status, Actor.Name, Comments
FROM ProcessInstanceStep
WHERE TargetObjectId IN (SELECT Id FROM Opportunity)

-- Assignment rule tracking
SELECT Name, Owner.Name, CreatedDate
FROM Lead
WHERE LastAssignmentDate = THIS_WEEK
```

---

## Next Phase

**[Phase 8: Forecasting & Territories](./08-forecasting-territories.md)** — Build forecast hierarchies, territory models, and quota management.
