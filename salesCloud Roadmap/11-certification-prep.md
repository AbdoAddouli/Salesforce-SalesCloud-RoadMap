# Phase 11: Certification Prep

## Learning Objectives
By the end of this phase, you will be able to:
- Identify the key topics for Sales Cloud Consultant and Administrator exams
- Apply knowledge from all previous phases to exam scenarios
- Practice with sample questions and case studies
- Build a capstone project demonstrating end-to-end Sales Cloud implementation

---

## 1. Certification Paths

### Salesforce Administrator
| Detail | Info |
|--------|------|
| **Exam Code** | ADM-201 |
| **Questions** | 60 multiple-choice |
| **Time** | 105 minutes |
| **Passing Score** | 65% |
| **Cost** | $200 USD |

### Sales Cloud Consultant
| Detail | Info |
|--------|------|
| **Exam Code** | CON-401 |
| **Questions** | 60 multiple-choice |
| **Time** | 105 minutes |
| **Passing Score** | 65% |
| **Prerequisite** | Salesforce Administrator credential |
| **Cost** | $200 USD |

---

## 2. Admin Exam Topics

### Configuration & Setup (20%)
- Company Settings
- UI Customization
- User Management
- Security & Access

### Object Manager & Lightning App Builder (20%)
- Standard & Custom Objects
- Fields & Relationships
- Page Layouts
- Lightning App Builder

### User Management (7%)
- Users, Profiles, Permission Sets
- Groups & Queues
- Delegated Administration

### Security & Access (15%)
- OWD, Sharing Rules
- Role Hierarchy
- Field-Level Security
- Sharing Sets & Guest User Access

### Standard & Custom Objects (14%)
- Schema Builder
- Lookup & Master-Detail Relationships
- Validation Rules
- Record Types

### Automation (13%)
- Flows (Record-Triggered, Scheduled, Screen)
- Approval Processes
- Workflow Rules (legacy)
- Process Builder (legacy)

### Data & Analytics (11%)
- Data Import/Export
- Reports & Dashboards
- List Views

---

## 3. Sales Cloud Consultant Topics

### Lead Management (12%)
- Lead capture, scoring, and qualification
- Lead assignment rules
- Lead conversion process
- Duplicate management

### Opportunity Management (14%)
- Sales processes and stages
- Products and price books
- Quotes and CPQ
- Forecasting

### Account & Contact Management (13%)
- Account hierarchies
- Account and Contact Teams
- Contact Roles
- Territory Management

### Sales Analytics (11%)
- Pipeline reports
- Forecasting reports
- Dashboards
- Einstein Analytics

### Implementation Strategies (14%)
- Project planning
- Stakeholder management
- Change management
- Data migration

### Security (12%)
- Profiles and permission sets
- OWD and sharing rules
- Role hierarchy
- Field-level security

### Sales Cloud Applications (12%)
- Campaigns and marketing
- CPQ
- Einstein features
- Integration patterns

---

## 4. Study Plan

### Week 1-2: Review Fundamentals
- [ ] Review Phase 1-3 material
- [ ] Practice SOQL queries
- [ ] Complete all hands-on exercises

### Week 3-4: Core Features
- [ ] Review Phase 4-6 material
- [ ] Build pipeline reports and dashboards
- [ ] Practice approval processes

### Week 5-6: Automation & Analytics
- [ ] Review Phase 7-9 material
- [ ] Build complex Flows
- [ ] Create custom report types

### Week 7-8: Advanced Topics
- [ ] Review Phase 10 material
- [ ] Practice API integrations
- [ ] Review Einstein features

### Week 9-10: Practice Exams
- [ ] Take practice exams
- [ ] Review weak areas
- [ ] Schedule the exam

---

## 5. Sample Exam Questions

### Question 1 (Admin)
A user reports they cannot see the Annual Revenue field on the Account page layout. What should you check first?

A) The user's profile has Edit permission on Account
B) The field exists on the Account object
C) The field is included in the page layout assigned to the user
D) The field-level security allows the user to see the field

**Answer: D** — Field-Level Security is the first thing to check. Even if the field is on the page layout, FLS must allow the user to see it.

### Question 2 (Consultant)
A company wants leads from their website to automatically route to the appropriate sales team based on the lead's industry. What should you configure?

A) Workflow Rule
B) Lead Assignment Rule
C) Process Builder
D) Flow Builder

**Answer: B** — Lead Assignment Rules are specifically designed to route leads based on criteria.

### Question 3 (Consultant)
A sales manager wants to see a forecast that includes all opportunities expected to close this quarter, weighted by probability. What should you configure?

A) Opportunity Report with Amount field
B) Collaboration Forecasts with Forecast Category
C) Dashboard with pipeline chart
D) Kanban view on Opportunities

**Answer: B** — Collaboration Forecasts with Forecast Categories (Pipeline, Best Case, Commit) provide weighted forecasting.

### Question 4 (Admin)
Which feature allows you to grant additional object permissions to users without changing their profile?

A) Role Hierarchy
B) Sharing Rules
C) Permission Sets
D) Public Groups

**Answer: C** — Permission Sets add additional permissions on top of a profile.

### Question 5 (Consultant)
A company needs to track which marketing campaigns influenced closed deals. What should you configure?

A) Campaign Members
B) Campaign Influence
C) Campaign Reports
D) Lead Source field

**Answer: B** — Campaign Influence models measure how campaigns contribute to winning deals.

---

## 6. Key Formulas to Know

| Formula | Description |
|---------|-------------|
| `ISPICKVAL(Field, 'Value')` | Check picklist value |
| `ISCHANGED(Field)` | Detect field change |
| `PRIORVALUE(Field)` | Get previous field value |
| `ISNEW()` | Check if record is new |
| `ISBLANK(Field)` | Check if field is empty |
| `CONTAINS(Field, 'text')` | Check if field contains text |
| `AND(condition1, condition2)` | Both conditions must be true |
| `OR(condition1, condition2)` | Either condition must be true |
| `NOT(condition)` | Negate a condition |
| `IF(condition, true_value, false_value)` | Conditional logic |

---

## 7. Key Limits to Memorize

| Limit | Value |
|-------|-------|
| SOQL queries per transaction | 100 |
| SOQL query rows returned | 50,000 |
| DML statements per transaction | 150 |
| DML rows per transaction | 10,000 |
| Apex trigger per object | 1 per event type |
| Validation rules per object | 50 |
| Roll-up summary fields per object | 10 |
| Custom fields per object | 500 (standard), 500 (custom) |
| Lookup relationships per object | 40 |
| Master-detail relationships per object | 2 |

---

## 8. Capstone Project

### End-to-End Sales Cloud Implementation

Build a complete Sales Cloud solution for a fictional company:

#### Scenario
**TechNova Solutions** is a B2B software company that sells enterprise SaaS products.

#### Requirements
1. **Lead Management**
   - Capture leads from web, events, and referrals
   - Auto-route leads by industry and region
   - Implement lead scoring

2. **Account & Contact Management**
   - Track parent-subsidiary relationships
   - Use Account Teams for collaboration
   - Manage Contact Roles on opportunities

3. **Opportunity Management**
   - 3 sales processes: New Business, Renewal, Expansion
   - Products with multiple price books
   - Quote generation

4. **Campaign Management**
   - Track marketing campaigns
   - Measure campaign influence on deals
   - ROI reporting

5. **Automation**
   - Approval process for discounts > 20%
   - Flow for auto-setting close dates
   - Scheduled flow for stale deal cleanup

6. **Reporting & Dashboards**
   - Pipeline report by stage and rep
   - Win rate analysis
   - Quota attainment dashboard
   - Campaign performance dashboard

#### Deliverables
- [ ] Custom fields and objects configured
- [ ] Sales processes and record types
- [ ] Approval process
- [ ] 3+ Flows
- [ ] Custom report types
- [ ] 5+ reports
- [ ] 2 dashboards
- [ ] Permission sets
- [ ] Test classes with 75%+ coverage

---

## 9. Exam Day Tips

1. **Read carefully** — questions often have subtle wording
2. **Eliminate wrong answers** — narrow to 2 options
3. **Think "Salesforce way"** — choose the most declarative solution
4. **Watch for "first"** — what should you do FIRST?
5. **Time management** — 1.75 minutes per question
6. **Flag and return** — don't get stuck on hard questions

---

## Congratulations!

You've completed the Sales Cloud RoadMap! You now have:
- **11 comprehensive learning guides**
- **Hands-on metadata** to deploy and practice with
- **SOQL queries** for every topic
- **Apex code** for automation and integration
- **A capstone project** to demonstrate your skills

**Next Steps:**
1. Deploy all metadata to your org
2. Complete the capstone project
3. Take practice exams
4. Schedule your certification exam
5. Join the Salesforce Trailblazer Community

---

*Happy learning, and good luck on your certification!*
