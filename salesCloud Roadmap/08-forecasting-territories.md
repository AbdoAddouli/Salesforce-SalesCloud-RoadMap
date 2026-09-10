# Phase 8: Forecasting & Territories

## Learning Objectives
By the end of this phase, you will be able to:
- Configure forecast hierarchies and categories
- Build territory models and territory types
- Implement quota management
- Create forecast-related reports
- Understand collaboration forecasts

---

## 1. Sales Forecasting

Forecasts predict future revenue based on your pipeline and historical data.

### Forecast Categories
| Category | Description | Typical Stages |
|----------|-------------|----------------|
| **Pipeline** | Early-stage deals | Prospecting, Qualification |
| **Best Case** | Deals likely to close | Needs Analysis, Proposal |
| **Commit** | Deals expected to close | Negotiation, Verbal Agreement |
| **Closed** | Won deals | Closed Won |
| **Omitted** | Excluded from forecast | Closed Lost, On Hold |

### Forecast Hierarchy
```
VP of Sales
├── Director, East Coast
│   ├── Sales Manager, Northeast
│   │   ├── Rep 1
│   │   └── Rep 2
│   └── Sales Manager, Southeast
│       ├── Rep 3
│       └── Rep 4
└── Director, West Coast
    └── Sales Manager, West
        ├── Rep 5
        └── Rep 6
```

### How It Works
1. **Reps** enter their forecast amounts per Opportunity
2. **Managers** see rolled-up forecasts from their team
3. **Executives** see the full org forecast
4. Forecasts compare to quotas to measure performance

---

## 2. Forecast Configuration

### Enable Forecasts
1. Setup > **Forecasts Settings**
2. Enable forecasts
3. Select forecast types:
   - Revenue Forecast
   - Quantity Forecast
   - Custom Forecast (product-based)

### Forecast Settings
| Setting | Description |
|---------|-------------|
| Forecast Hierarchy | Based on Role Hierarchy |
| Lock Periods | Prevent changes to past forecasts |
| Forecast Sharing | Control who can see forecasts |
| Forecast Adjustments | Allow manual adjustments by managers |

### Custom Forecast Fields
Add custom fields to track additional forecast data:
- **Forecast Category** — picklist (Pipeline, Best Case, Commit)
- **Forecast Amount** — number field for manual entry
- **Forecast Notes** — text area for context

---

## 3. Quotas

Quotas define the revenue targets for each user or team.

### Quota Types
| Type | Description |
|------|-------------|
| **Revenue Quota** | Dollar amount target |
| **Quantity Quota** | Number of deals target |
| **Product Quota** | Revenue per product line |

### Setting Up Quotas
1. Setup > **Quotas**
2. Create quota records:
   - User: Rep 1
   - Quota Amount: $500,000
   - Period: Q1 2026
   - Type: Revenue

### Quota Attainment
Calculate attainment as a percentage:
```
Attainment % = (Actual Revenue / Quota Amount) × 100
```

### Dashboard Metrics
| Metric | Formula |
|--------|---------|
| **Quota Attainment** | SUM(Closed Won Amount) / Quota × 100 |
| **Pipeline Coverage** | Pipeline Value / Remaining Quota |
| **Forecast vs. Quota** | Forecast Amount / Quota × 100 |

---

## 4. Territory Management

Territory Management assigns accounts to territories based on rules.

### Territory Model
```
Global Territory Model
├── North America
│   ├── East Region
│   │   ├── Northeast Territory
│   │   └── Southeast Territory
│   └── West Region
│       ├── West Coast Territory
│       └── Mountain Territory
├── EMEA
│   ├── UK Territory
│   └── DACH Territory
└── APAC
    ├── Australia Territory
    └── Japan Territory
```

### Territory Types
Define categories for territories:
| Type | Purpose |
|------|---------|
| Geographic | Based on location (state, country) |
| Industry | Based on account industry |
| Named Account | Key strategic accounts |
| Product | Based on product line |

### Territory Rules
Configure rules to assign accounts:
```
Rule 1: Geographic
  Field: BillingState
  Operator: equals
  Value: CA, WA, OR
  Territory: West Coast

Rule 2: Industry
  Field: Industry
  Operator: equals
  Value: Technology
  Territory: Technology Vertical

Rule 3: Named Account
  Field: Account Name
  Operator: equals
  Value: Acme Corp
  Territory: Strategic Accounts
```

### Territory Alignment
1. Create a Territory Model (draft)
2. Add territories and rules
3. Run alignment to assign accounts
4. Review and adjust
5. Activate the model

---

## 5. Forecast Reports & Dashboards

### Key Reports
| Report | Description |
|--------|-------------|
| Forecast vs. Quota | Compare forecast to target |
| Pipeline by Territory | Open opportunities grouped by territory |
| Quota Attainment | Individual and team attainment |
| Forecast Trend | Forecast changes over time |

### Dashboard Components
1. **Quota Attainment Gauge** — shows % attainment per rep
2. **Pipeline by Territory** — bar chart of pipeline value
3. **Forecast Trend Line** — forecast over time
4. **Top Performers Table** — ranked list by attainment

---

## 6. Automation

### Flow: Auto-Update Forecast on Deal Close
Record-Triggered Flow on Opportunity:
- **Trigger:** When StageName changes to 'Closed Won'
- **Action:** Update the Opportunity owner's forecast record

### Flow: Alert When Quota is at Risk
Scheduled Flow (weekly):
- **Criteria:** Quota Attainment < 50% AND Less than 30 days left in quarter
- **Action:** Send email alert to Sales Manager

### Apex: Calculate Quota Attainment
```apex
public class QuotaService {
    public static Map<Id, Decimal> getQuotaAttainment(Set<Id> userIds, Date quarterStart, Date quarterEnd) {
        Map<Id, Decimal> attainment = new Map<Id, Decimal>();

        // Get closed won amounts
        Map<Id, Decimal> revenueByUser = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT OwnerId, SUM(Amount) totalRevenue
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            AND CloseDate >= :quarterStart
            AND CloseDate <= :quarterEnd
            AND OwnerId IN :userIds
            GROUP BY OwnerId
        ]) {
            revenueByUser.put((Id) ar.get('OwnerId'), (Decimal) ar.get('totalRevenue'));
        }

        // Get quotas
        for (Quota__c q : [SELECT User__c, Amount__c FROM Quota__c
                           WHERE User__c IN :userIds
                           AND Period_Start__c >= :quarterStart
                           AND Period_End__c <= :quarterEnd]) {
            Decimal revenue = revenueByUser.containsKey(q.User__c) ? revenueByUser.get(q.User__c) : 0;
            attainment.put(q.User__c, (revenue / q.Amount__c) * 100);
        }

        return attainment;
    }
}
```

---

## 7. Hands-On Exercises

### Exercise 1: Configure Forecasts
1. Enable Forecasts in Setup
2. Create a forecast hierarchy matching your role structure
3. Enter forecast amounts for each rep
4. Review the rolled-up forecast

### Exercise 2: Set Up Territories
1. Create a Territory Model
2. Add territories for 3 regions
3. Define rules based on BillingState
4. Run alignment and review results

### Exercise 3: Build a Forecast Dashboard
1. Create reports for quota attainment and pipeline
2. Build a dashboard with:
   - Quota attainment gauge per rep
   - Pipeline by territory bar chart
   - Forecast trend line chart
3. Share with the sales team

---

## 8. SOQL Practice

```sql
-- Forecast summary by user
SELECT Owner.Name, SUM(Amount) forecastTotal
FROM Opportunity
WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
GROUP BY Owner.Name
ORDER BY forecastTotal DESC

-- Quota attainment
SELECT Owner.Name,
       SUM(CASE WHEN StageName = 'Closed Won' THEN Amount ELSE 0 END) actualRevenue,
       COUNT(Id) openDeals
FROM Opportunity
WHERE CloseDate = THIS_QUARTER
GROUP BY Owner.Name

-- Pipeline by territory
SELECT Territory__c, COUNT(Name) dealCount, SUM(Amount) pipelineValue
FROM Opportunity
WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
GROUP BY Territory__c
ORDER BY pipelineValue DESC

-- Forecast accuracy (past quarters)
SELECT CloseDate, SUM(Amount) actualRevenue
FROM Opportunity
WHERE StageName = 'Closed Won'
AND CloseDate = LAST_QUARTER
GROUP BY CloseDate
```

---

## Next Phase

**[Phase 9: Reporting & Dashboards](./09-reporting.md)** — Master Salesforce reporting, custom report types, and dashboard design.
