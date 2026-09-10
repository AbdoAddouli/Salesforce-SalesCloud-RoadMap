# Phase 4: Opportunity Management

## Learning Objectives
By the end of this phase, you will be able to:
- Configure opportunity stages and sales processes
- Manage products, price books, and quotes
- Build pipeline reports and dashboards
- Implement validation rules and automation
- Create a simple LWC for pipeline visualization

---

## 1. The Opportunity Lifecycle

An Opportunity represents a potential deal. It moves through stages from creation to close:

```
Prospecting → Qualification → Needs Analysis → Proposal → Negotiation → Closed Won / Closed Lost
```

### Standard Opportunity Stages
| Stage | Probability | Typical Activities |
|-------|-------------|-------------------|
| Prospecting | 10% | Initial research, cold outreach |
| Qualification | 20% | Discovery call, needs assessment |
| Needs Analysis | 50% | Deep dive into requirements |
| Proposal/Price Quote | 70% | Send proposal, demo |
| Negotiation/Review | 80% | Legal review, contract terms |
| Closed Won | 100% | Deal signed, revenue recognized |
| Closed Lost | 0% | Deal lost to competitor or no decision |

### Customizing Stages
1. Setup > **Opportunity Stages**
2. Add/remove/reorder stages
3. Set probability and forecast category for each

### Sales Processes
Create multiple sales processes for different deal types:
- **New Business** — full sales cycle (7 stages)
- **Renewal** — simplified (3 stages: Pending, Confirmed, Closed)
- **Upsell/Expansion** — focused on existing accounts (4 stages)

---

## 2. Products & Price Books

### Products
Products are what you sell. Each product has:
- **Product Name** — the item name
- **Product Family** — categorization
- **Active** — whether it's available for selection

### Price Books
Price Books define the price for each product. A single product can have different prices in different price books:
- **Standard Price Book** — default pricing
- **Partner Price Book** — discounted for partners
- **Employee Price Book** — internal pricing

### Price Book Entries
The junction between Product and Price Book:
| Field | Description |
|-------|-------------|
| Unit Price | The price for this product in this price book |
| Active | Whether this entry is available |
| Use Standard Price | Inherit from standard price book |

### Adding Products to Opportunities
1. Open an Opportunity
2. Click **Add Products**
3. Select a Price Book
4. Check products and set quantity
5. Save

### Schedules
Configure revenue and quantity schedules:
- **Revenue Schedule** — spread revenue over months
- **Quantity Schedule** — track delivery over time

---

## 3. Quotes

Quotes capture the specific terms of a proposal sent to a customer.

### Creating a Quote
1. Open an Opportunity
2. Click **New Quote**
3. Add line items (auto-populated from Opportunity products)
4. Set quote-specific prices and discounts
5. Generate a PDF
6. Send to customer

### Quote Fields
| Field | Purpose |
|-------|---------|
| Quote Name | Unique identifier |
| Total Price | Sum of all line items |
| Discount % | Overall discount applied |
| Expiration Date | When the quote expires |
| Status | Draft → In Review → Presented → Accepted/Rejected |

---

## 4. Pipeline Management

### Key Metrics
| Metric | Formula |
|--------|---------|
| **Pipeline Value** | SUM of all open Opportunity Amounts |
| **Weighted Pipeline** | SUM(Amount × Probability) |
| **Win Rate** | Closed Won / (Closed Won + Closed Lost) |
| **Average Deal Size** | Total Revenue / Number of Closed Won |
| **Sales Cycle Length** | AVG(Close Date - Created Date) for Closed Won |
| **Quota Attainment** | Actual Revenue / Target Quota |

### Pipeline Dashboard
Build a dashboard with:
1. **Pipeline by Stage** — bar chart of Amount by StageName
2. **Pipeline Trend** — line chart of pipeline value over time
3. **Win Rate Gauge** — gauge showing current win rate
4. **Top Deals Table** — list of largest open opportunities

---

## 5. Validation Rules

### Rule: Cannot Skip Opportunity Stages
```
AND(
    ISCHANGED(StageName),
    NOT(
        OR(
            // Allow forward movement only
            (ISPICKVAL(PriorValue(StageName), 'Prospecting') && ISPICKVAL(StageName, 'Qualification')),
            (ISPICKVAL(PriorValue(StageName), 'Qualification') && ISPICKVAL(StageName, 'Needs Analysis')),
            (ISPICKVAL(PriorValue(StageName), 'Needs Analysis') && ISPICKVAL(StageName, 'Proposal/Price Quote')),
            (ISPICKVAL(PriorValue(StageName), 'Proposal/Price Quote') && ISPICKVAL(StageName, 'Negotiation/Review')),
            // Allow closing from any stage
            (ISPICKVAL(StageName, 'Closed Won')),
            (ISPICKVAL(StageName, 'Closed Lost'))
        )
    )
)
```

### Rule: Require Close Date for Open Opportunities
```
AND(
    ISBLANK(CloseDate),
    NOT(ISPICKVAL(StageName, 'Closed Won')),
    NOT(ISPICKVAL(StageName, 'Closed Lost'))
)
```

### Rule: Amount Required for High-Probability Stages
```
AND(
    ISBLANK(Amount),
    Probability >= 50,
    NOT(ISPICKVAL(StageName, 'Closed Won')),
    NOT(ISPICKVAL(StageName, 'Closed Lost'))
)
```

---

## 6. Automation

### Flow: Auto-Set Close Date Based on Stage
Record-Triggered Flow on Opportunity:
- **Trigger:** When StageName changes
- **Decision:**
  - If Prospecting → Close Date = TODAY + 90
  - If Qualification → Close Date = TODAY + 60
  - If Proposal → Close Date = TODAY + 30
  - If Negotiation → Close Date = TODAY + 14

### Flow: Auto-Create Task on Stage Change
- **Trigger:** When StageName changes
- **Action:** Create Task "Review deal at [Stage]" with due date

### Apex: Auto-Close Stale Opportunities
```apex
public class OpportunityService {
    public static void closeStaleOpportunities(Integer staleDays) {
        Date cutoffDate = Date.today().addDays(-staleDays);

        List<Opportunity> staleOpps = [
            SELECT Id, Name, StageName, LastActivityDate
            FROM Opportunity
            WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
            AND LastActivityDate < :cutoffDate
            AND LastActivityDate != NULL
        ];

        for (Opportunity opp : staleOpps) {
            opp.StageName = 'Closed Lost';
            opp.Description = 'Auto-closed: No activity for ' + staleDays + ' days';
        }

        if (!staleOpps.isEmpty()) {
            update staleOpps;
        }
    }
}
```

---

## 7. Hands-On Exercises

### Exercise 1: Configure Your Sales Process
1. Create a "New Business" sales process with 7 stages
2. Create a "Renewal" process with 3 stages
3. Assign each to a different Record Type

### Exercise 2: Set Up Products & Price Book
1. Create 5 Products in the Standard Price Book
2. Add Price Book Entries with different prices
3. Create an Opportunity and add all 5 products
4. Apply a 10% discount
5. Create a Quote from the Opportunity

### Exercise 3: Build a Pipeline Report
1. Create a Report Type: Opportunities with Account
2. Build a report showing open opportunities by stage
3. Add a chart showing pipeline value by stage
4. Create a Dashboard with the report

---

## 8. SOQL Practice

```sql
-- Open pipeline
SELECT Name, Amount, StageName, Probability, CloseDate, Account.Name
FROM Opportunity
WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
ORDER BY Amount DESC

-- Closed Won this quarter
SELECT Name, Amount, CloseDate
FROM Opportunity
WHERE StageName = 'Closed Won'
AND CloseDate = THIS_QUARTER

-- Pipeline by stage
SELECT StageName, COUNT(Name) oppCount, SUM(Amount) totalValue, AVG(Probability) avgProbability
FROM Opportunity
WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
GROUP BY StageName

-- Opportunity with products
SELECT Name, Amount,
       (SELECT Product2.Name, UnitPrice, Quantity FROM OpportunityLineItems)
FROM Opportunity

-- Win rate calculation
SELECT StageName, COUNT(Name) cnt
FROM Opportunity
WHERE StageName IN ('Closed Won', 'Closed Lost')
GROUP BY StageName
```

---

## Next Phase

**[Phase 5: Campaigns & Marketing](./05-campaigns.md)** — Build marketing campaigns and track campaign influence on deals.
