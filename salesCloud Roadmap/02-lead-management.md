# Phase 2: Lead Management

## Learning Objectives
By the end of this phase, you will be able to:
- Configure lead capture from multiple sources (web, email, import)
- Build and manage lead assignment rules
- Implement lead scoring (manual and Einstein)
- Customize the lead conversion process
- Build automation around lead qualification

---

## 1. The Lead Lifecycle

A Lead goes through a defined lifecycle from capture to conversion:

```
New Lead → Contacted → Qualified → Converted (or Disqualified)
```

### Lead Status Values (Standard)
| Status | Meaning |
|--------|---------|
| Open - Not Contacted | Newly created, awaiting first outreach |
| Working - Contacted | Active engagement in progress |
| Closed - Converted | Qualified and converted to Account/Contact/Opportunity |
| Closed - Not Converted | Disqualified or not a fit |

### Custom Lead Statuses
You can create additional statuses to match your business process:
- Nurturing
- Unresponsive
- Duplicate
- Bad Data

---

## 2. Lead Capture Sources

Leads can enter Salesforce from multiple channels:

| Source | How It Works |
|--------|-------------|
| **Web-to-Lead** | HTML form on your website that creates a Lead record |
| **Email-to-Lead** | Inbound email parsed into a Lead |
| **List Import** | CSV file imported via Data Loader or Import Wizard |
| **Manual Entry** | Sales rep creates the Lead directly |
| **API / Integration** | External system pushes leads via REST/SOAP API |
| **Marketing Automation** | Pardot, Marketo, HubSpot sync leads to Salesforce |
| **Social Leads** | Facebook Lead Ads, LinkedIn Lead Gen Forms |

### Exercise: Create a Web-to-Lead Form
1. Setup > Web-to-Lead
2. Select fields: Company, First Name, Last Name, Email, Phone, Lead Source
3. Generate the HTML
4. Preview in a browser and submit

---

## 3. Lead Assignment Rules

Assignment rules automatically route leads to the right sales rep or queue based on criteria.

### How to Configure
1. Setup > **Lead Assignment Rules**
2. Create a new rule (e.g., "Enterprise Leads")
3. Add rule entries with criteria:

```
Rule Entry 1: IF Industry = 'Technology' THEN assign to "Tech Sales Queue"
Rule Entry 2: IF Annual Revenue > 1000000 THEN assign to "Enterprise Sales Queue"
Rule Entry 3: IF State = 'California' THEN assign to "West Coast Team"
```

### Rule Entry Criteria Examples
| Field | Operator | Value |
|-------|----------|-------|
| Industry | equals | Technology |
| Annual Revenue | greater than | 1000000 |
| Lead Source | equals | Web |
| Number of Employees | greater than | 500 |
| State | equals | CA |

### Queues
Queues are holding areas where leads wait until assigned to a specific user:
1. Setup > **Queues**
2. Create queue, add members
3. Use in assignment rules

---

## 4. Lead Scoring

### Manual Lead Scoring
Use a custom Number field (`Lead_Score__c`) and update it via:
- Validation rules requiring data entry
- Flows that score based on field values
- Apex triggers for complex logic

**Scoring Example:**
| Criteria | Points |
|----------|--------|
| Industry = Technology | +20 |
| Annual Revenue > $1M | +25 |
| Lead Source = Referral | +15 |
| Has Phone Number | +10 |
| Has Email | +10 |
| Company Size > 100 | +20 |

### Einstein Lead Scoring (Paid Feature)
AI-powered scoring that learns from your historical conversion data:
1. Setup > **Einstein Lead Scoring**
2. Turn on scoring for the Lead object
3. Select fields for the model to consider
4. Wait for the model to train (24-48 hours)
5. The `EinsteinScore` field populates automatically

---

## 5. Lead Conversion

### Standard Conversion Process
1. Rep clicks **Convert** on the Lead
2. System prompts for:
   - Account (existing or new)
   - Contact (existing or new)
   - Opportunity (optional, with name)
3. Lead fields map to Account, Contact, and Opportunity fields

### Field Mapping
Configure how Lead fields map to converted records:
1. Setup > **Lead Settings**
2. Click **Modify** next to "Lead Custom Field Mappings"
3. Map:
   - `Industry_Segment__c` → Account.Industry_Segment__c
   - `Role__c` → Contact.Role__c
   - `Lead_Score__c` → Opportunity.Lead_Score__c

### Conversion Settings
- **Require Validation** — enforce data completeness before conversion
- **Prompt for Notes** — require notes before converting
- **Require Subject** — force activity logging

### Apex: Programmatic Lead Conversion
```apex
Database.LeadConvert lc = new Database.LeadConvert();
lc.setLeadId(leadRecord.Id);
lc.setConvertedStatus('Closed - Converted');
lc.setDoNotCreateOpportunity(false);
lc.setOpportunityName('New Deal - ' + leadRecord.Company);

Database.LeadConvertResult result = Database.convertLead(lc);
if (result.isSuccess()) {
    Id accountId = result.getAccountId();
    Id contactId = result.getContactId();
    Id opportunityId = result.getOpportunityId();
}
```

---

## 6. Lead Automation

### Flow: Auto-Update Nurture Status
Create a Record-Triggered Flow on Lead:
- **Trigger:** When Lead is created or updated
- **Criteria:** Lead_Score__c > 50 AND Status = 'Open - Not Contacted'
- **Action:** Set Nurture_Status__c = 'Active Nurture'

### Flow: Auto-Create Task on Lead Assignment
- **Trigger:** When Lead is assigned (Owner change)
- **Action:** Create Task "Follow up with new lead" with due date = TODAY + 2

### Validation Rule: Require Qualification Date
```
AND(
    ISNEW(),
    ISPICKVAL(Status, 'Working - Contacted'),
    ISBLANK(Qualification_Date__c)
)
```

---

## 7. Hands-On Exercises

### Exercise 1: Create a Lead Assignment Rule
1. Create a Lead Assignment Rule called "By Industry"
2. Add rule entries for Technology, Healthcare, and Finance
3. Create queues for each industry
4. Test by creating leads with different industries

### Exercise 2: Build a Lead Scoring Flow
1. Create a Record-Triggered Flow on Lead
2. Add a Decision element checking multiple fields
3. Assign points based on the scoring matrix above
4. Update the Lead_Score__c field

### Exercise 3: Test Lead Conversion
1. Create a Lead with complete data
2. Convert the Lead
3. Verify the Account, Contact, and Opportunity were created
4. Check that custom fields mapped correctly

---

## 8. SOQL Practice

```sql
-- Leads by status
SELECT Status, COUNT(Name) cnt FROM Lead GROUP BY Status

-- High-scoring leads
SELECT Name, Company, Lead_Score__c FROM Lead WHERE Lead_Score__c > 50 ORDER BY Lead_Score__c DESC

-- Leads created this week
SELECT Name, CreatedDate, Owner.Name FROM Lead WHERE CreatedDate = THIS_WEEK

-- Unconverted leads with no activity
SELECT Name, LastActivityDate FROM Lead WHERE IsConverted = false AND LastActivityDate = NULL

-- Leads by source
SELECT LeadSource, COUNT(Name) cnt FROM Lead GROUP BY LeadSource ORDER BY cnt DESC
```

---

## Next Phase

**[Phase 3: Account & Contact Management](./03-accounts-contacts.md)** — Master account hierarchies, contact roles, and relationship management.
