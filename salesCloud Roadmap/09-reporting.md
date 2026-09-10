# Phase 9: Reporting & Dashboards

## Learning Objectives
By the end of this phase, you will be able to:
- Create Custom Report Types for complex data relationships
- Build reports with grouping, filtering, and formulas
- Design effective dashboards with multiple components
- Implement dynamic dashboards
- Schedule and distribute reports

---

## 1. Report Types

Report Types define which objects and fields are available in a report.

### Standard Report Types
Salesforce provides pre-built report types:
| Report Type | Objects Included |
|-------------|-----------------|
| Accounts & Contacts | Account + Contact |
| Opportunities | Opportunity |
| Leads | Lead |
| Activities | Task + Event |
| Campaigns & Leads | Campaign + CampaignMember + Lead |
| Opportunities with Account | Opportunity + Account |

### Custom Report Types
Create your own when standard types aren't enough:
1. Setup > **Report Types**
2. Click "New Custom Report Type"
3. Define:
   - Primary Object: Opportunity
   - Related Object: Account (Accounts is a related object of Opportunity)
   - Relationship: Each Opportunity must have an Account

### Report Type Relationships
| Relationship | Description |
|--------------|-------------|
| **Primary** | The main object in the report |
| **Secondary** | Related objects (inner join — must have related records) |
| **Tertiary** | Additional related objects |

### Example: Full Sales Report
```
Primary: Opportunity
├── Secondary: Account
├── Secondary: Contact (via OpportunityContactRole)
├── Secondary: Campaign (via CampaignMember)
└── Secondary: User (Opportunity Owner)
```

---

## 2. Report Builder

### Report Formats
| Format | Description |
|--------|-------------|
| **Tabular** | Simple table, no grouping (like a spreadsheet) |
| **Summary** | Grouped by one or more fields |
| **Matrix** | Grouped by rows AND columns (pivot table) |
| **Joined** | Combine multiple reports in one view |

### Key Features

#### Grouping
Group data by any field:
- **Row Grouping**: Group opportunities by StageName
- **Column Grouping**: Group by Quarter (creates matrix)

#### Filters
| Filter Type | Example |
|-------------|---------|
| **Field Filter** | Amount > $10,000 |
| **Date Filter** | Close Date = THIS_QUARTER |
| **Logic Filter** | (Amount > 50000) AND (StageName = 'Closed Won') |
| **Cross Filter** | Opportunities that have Activities |
| **Relative Date** | Created = LAST_30_DAYS |

#### Formulas
Add calculated columns:
| Formula | Purpose |
|---------|---------|
| **Row Count** | Count of records |
| **Custom Summary** | Calculated field (e.g., Discount %) |
| **Bucket Field** | Categorize values (e.g., Small/Medium/Large deals) |

### Bucket Fields
Categorize numeric values without creating custom fields:
```
Bucket: Deal Size
  Field: Amount
  Ranges:
    Small: $0 - $25,000
    Medium: $25,001 - $100,000
    Large: $100,001 - $500,000
    Enterprise: $500,001+
```

---

## 3. Essential Sales Reports

### Pipeline Report
```
Report Type: Opportunities with Account
Grouping: Row = StageName
Columns: Opportunity Name, Account Name, Amount, Close Date, Probability
Filter: StageName NOT IN ('Closed Won', 'Closed Lost')
Sort: Amount DESC
```

### Win/Loss Analysis
```
Report Type: Opportunities
Grouping: Row = StageName
Columns: Opportunity Name, Amount, Close Date
Filter: StageName IN ('Closed Won', 'Closed Lost')
Add Bucket: Result (Won vs. Lost)
Add Formula: Win Rate %
```

### Activity Report
```
Report Type: Tasks & Events with Opportunity
Grouping: Row = Assigned To
Columns: Subject, Status, ActivityDate, Related Opportunity
Filter: ActivityDate = THIS_MONTH
```

### Lead Conversion Report
```
Report Type: Leads
Grouping: Row = Lead Source
Columns: Name, Company, Status, Converted Date, Converted Opportunity
Filter: IsConverted = true
Add Formula: Conversion Rate %
```

---

## 4. Dashboards

### Dashboard Components
| Component | Best For |
|-----------|----------|
| **Chart** | Visual trends and comparisons |
| **Metric** | Single KPI number |
| **Gauge** | Progress toward a goal |
| **Table** | Detailed data rows |
| **Visualforce** | Custom components |
| **Lightning Component** | Custom LWC widgets |

### Chart Types
| Chart | Use Case |
|-------|----------|
| Bar Chart | Compare values across categories |
| Stacked Bar | Compare parts of a whole |
| Line Chart | Show trends over time |
| Pie/Donut | Show proportions |
| Funnel | Show pipeline stages |
| Scatter | Show correlation between two metrics |

### Dashboard Best Practices
1. **Executive View** — top-level KPIs only (4-6 components)
2. **Manager View** — team performance with drill-down
3. **Rep View** — individual pipeline and activities
4. **Consistent Color Scheme** — use the same colors for the same metrics
5. **Title Everything** — clear, descriptive titles

---

## 5. Dynamic Dashboards

Dynamic dashboards let users change the running user at runtime.

### Configuration
1. Create or edit a Dashboard
2. Click **Properties**
3. Set **Running User** to "The dashboard viewer"
4. Users can switch between their view and others'

### Use Cases
- Sales Manager views their team's performance
- Rep views only their own data
- Executive views the entire org

### Dashboard Filters
Add filters to let users slice data:
```
Filter: Region
  Options: All, North America, EMEA, APAC
  Field: Territory__c

Filter: Time Period
  Options: This Week, This Month, This Quarter, This Year
  Field: CloseDate
```

---

## 6. Report Scheduling & Distribution

### Schedule a Report
1. Open a report
2. Click **Subscribe**
3. Set schedule:
   - Frequency: Daily, Weekly, Monthly
   - Time: When to send
   - Recipients: Users, Roles, Groups

### Report Folders
Organize reports into folders:
| Folder | Purpose |
|--------|---------|
| Sales Reports | Pipeline, forecasting, win rates |
| Marketing Reports | Campaign performance, lead sources |
| Management Reports | Executive dashboards, quota tracking |
| Operations | Activity reports, task completion |

### Report Sharing
Control who can see reports:
- **Public** — everyone
- **Private** — only the creator
- **Shared** — specific users, roles, or groups

---

## 7. Hands-On Exercises

### Exercise 1: Create a Custom Report Type
1. Create a Report Type: "Opportunities with Account and Contacts"
2. Primary: Opportunity
3. Related: Account, Contact (via OpportunityContactRole)
4. Add fields from all three objects
5. Build a report using this type

### Exercise 2: Build a Pipeline Dashboard
1. Create 4 reports:
   - Pipeline by Stage (bar chart)
   - Win Rate (gauge)
   - Top 10 Deals (table)
   - Activity This Week (metric)
2. Combine into a dashboard
3. Add filters for Region and Time Period

### Exercise 3: Schedule Reports
1. Subscribe to your Pipeline report
2. Set it to send every Monday at 8 AM
3. Add your Sales Manager as a recipient

---

## 8. SOQL Practice

```sql
-- Report-ready: Pipeline by stage and owner
SELECT StageName, Owner.Name, COUNT(Name) dealCount, SUM(Amount) totalValue
FROM Opportunity
WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
GROUP BY StageName, Owner.Name

-- Report-ready: Win rate by rep
SELECT Owner.Name,
       SUM(CASE WHEN StageName = 'Closed Won' THEN 1 ELSE 0 END) wins,
       SUM(CASE WHEN StageName = 'Closed Lost' THEN 1 ELSE 0 END) losses,
       ROUND(SUM(CASE WHEN StageName = 'Closed Won' THEN 1 ELSE 0 END) * 100.0 /
             NULLIF(SUM(CASE WHEN StageName IN ('Closed Won', 'Closed Lost') THEN 1 ELSE 0 END), 0), 1) winRate
FROM Opportunity
WHERE StageName IN ('Closed Won', 'Closed Lost')
AND CloseDate = THIS_QUARTER
GROUP BY Owner.Name

-- Report-ready: Activity completion rate
SELECT Owner.Name,
       SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) completed,
       COUNT(Id) total,
       ROUND(SUM(CASE WHEN Status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(Id), 1) completionRate
FROM Task
WHERE ActivityDate = THIS_MONTH
GROUP BY Owner.Name
```

---

## Next Phase

**[Phase 10: Advanced & Integrations](./10-advanced.md)** — Explore CPQ, Einstein AI, API integrations, and platform events.
