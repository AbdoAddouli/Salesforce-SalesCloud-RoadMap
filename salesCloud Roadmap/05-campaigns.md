# Phase 5: Campaigns & Marketing

## Learning Objectives
By the end of this phase, you will be able to:
- Create and manage marketing campaigns
- Track campaign members and statuses
- Implement campaign influence models
- Build automation around campaign membership
- Measure campaign ROI

---

## 1. Campaign Fundamentals

A Campaign represents a marketing initiative — a trade show, email blast, webinar, or advertising program.

### Campaign Types
| Type | Description |
|------|-------------|
| Conference | Industry conferences and events |
| Webinar | Online presentations and demos |
| Trade Show | In-person industry events |
| Direct Mail | Physical mail campaigns |
| Email | Email marketing blasts |
| Digital Ad | Online advertising |
| Referral | Partner or customer referrals |

### Campaign Fields
| Field | Purpose |
|-------|---------|
| Campaign Name | Unique identifier |
| Status | Planned, In Progress, Completed, Aborted |
| Start Date / End Date | Campaign duration |
| Budget | Expected cost |
| Actual Cost | Real spend |
| Expected Revenue | Projected return |
| Amount All Opportunities | Revenue from all influenced deals |

---

## 2. Campaign Members

Campaign Members track which Leads and Contacts are associated with a Campaign.

### Adding Members
1. Open a Campaign
2. Click **Manage Members**
3. Add Leads or Contacts (individually or via list view)
4. Set **Member Status** for each

### Standard Member Statuses
| Status | Meaning |
|--------|---------|
| Sent | Communication sent |
| Responded | Engaged with the campaign |

### Custom Statuses
Create additional statuses to match your process:
- Registered (for webinars)
- Attended (for events)
- Downloaded (for content)
- Visited Booth (for trade shows)

---

## 3. Campaign Influence

Campaign Influence measures how much each campaign contributed to winning a deal.

### Influence Models

#### 1. First Touch
- 100% credit to the first campaign that touched the opportunity
- Good for measuring lead generation

#### 2. Last Touch
- 100% credit to the most recent campaign before the deal closed
- Good for measuring conversion influence

#### 3. Even Distribution
- Equal credit across all campaigns that touched the opportunity
- Good for balanced view

#### 4. Time-Decay
- More credit to campaigns closer to the close date
- Good for complex B2B sales cycles

### Configuration
1. Setup > **Campaign Influence Settings**
2. Enable Campaign Influence
3. Select your model(s)
4. Configure the "Model Type" field on Campaign Influence

### Campaign Influence Records
| Field | Description |
|-------|-------------|
| Campaign | The influencing campaign |
| Opportunity | The influenced deal |
| Influence | Percentage of credit (0-100) |
| Model | Which influence model was used |
| First Touch | Boolean - was this the first touch? |
| Closer Touch | Boolean - was this the closing touch? |

---

## 4. Campaign ROI Metrics

### Key Metrics
| Metric | Formula |
|--------|---------|
| **ROI** | (Revenue - Cost) / Cost × 100 |
| **Cost per Lead** | Total Campaign Cost / Total Members |
| **Conversion Rate** | Members who became Opportunities / Total Members |
| **Pipeline Generated** | SUM of Opportunity Amounts influenced |
| **Revenue Generated** | SUM of Closed Won Amounts influenced |

### Building a Campaign ROI Report
1. Create Report Type: "Campaigns with Opportunities"
2. Add fields: Campaign Name, Actual Cost, Amount All Opportunities
3. Add formula fields for ROI calculations
4. Group by Campaign Type

---

## 5. Automation

### Flow: Auto-Add Contact to Campaign on Opportunity Close
Record-Triggered Flow on Opportunity:
- **Trigger:** When StageName changes to 'Closed Won'
- **Action:** Find the primary Campaign (from the most recent Campaign Member) and add the Opportunity's Account contacts to that Campaign

### Flow: Update Campaign Status on Member Activity
- **Trigger:** When a Task is logged
- **Criteria:** Task related to a Contact who is a Campaign Member
- **Action:** Update Campaign Member Status to 'Responded'

### Apex: Bulk Add Campaign Members
```apex
public class CampaignMemberService {
    public static void addMembersFromList(Id campaignId, List<Id> contactIds) {
        List<CampaignMember> members = new List<CampaignMember>();

        for (Id contactId : contactIds) {
            members.add(new CampaignMember(
                CampaignId = campaignId,
                ContactId = contactId,
                Status = 'Sent'
            ));
        }

        // Avoid duplicates
        Set<Id> existingMembers = new Set<Id>();
        for (CampaignMember cm : [
            SELECT ContactId FROM CampaignMember
            WHERE CampaignId = :campaignId AND ContactId IN :contactIds
        ]) {
            existingMembers.add(cm.ContactId);
        }

        List<CampaignMember> newMembers = new List<CampaignMember>();
        for (CampaignMember m : members) {
            if (!existingMembers.contains(m.ContactId)) {
                newMembers.add(m);
            }
        }

        if (!newMembers.isEmpty()) {
            insert newMembers;
        }
    }
}
```

---

## 6. Hands-On Exercises

### Exercise 1: Create a Campaign
1. Create a Campaign "2026 Q1 Trade Show"
2. Set Type = Trade Show, Status = In Progress
3. Add 10 Contacts as Campaign Members
4. Set different member statuses

### Exercise 2: Track Campaign Influence
1. Create 3 Campaigns: Trade Show, Webinar, Email
2. Create an Opportunity influenced by all 3
3. Review the Campaign Influence related list
4. Compare First Touch vs Last Touch models

### Exercise 3: Build a Campaign Performance Dashboard
1. Create reports for each campaign type
2. Build a dashboard showing:
   - Campaign ROI by type
   - Members vs. Responses
   - Pipeline generated per campaign
   - Cost per lead

---

## 7. SOQL Practice

```sql
-- Campaign with member counts
SELECT Name, Status, (SELECT Id FROM CampaignMembers) FROM Campaign

-- Campaign Members by status
SELECT Campaign.Name, Status, COUNT(Id) memberCount
FROM CampaignMember
GROUP BY Campaign.Name, Status

-- Campaigns influencing the most revenue
SELECT Campaign.Name, SUM(Opportunity.Amount) influencedRevenue
FROM CampaignMember
WHERE OpportunityId != NULL AND Opportunity.StageName = 'Closed Won'
GROUP BY Campaign.Name
ORDER BY influencedRevenue DESC

-- Contacts NOT in any campaign
SELECT Name, Email FROM Contact
WHERE Id NOT IN (SELECT ContactId FROM CampaignMember)
```

---

## Next Phase

**[Phase 6: Sales Collaboration](./06-collaboration.md)** — Leverage activities, Chatter, and email integration for team collaboration.
