# Phase 3: Account & Contact Management

## Learning Objectives
By the end of this phase, you will be able to:
- Build and manage Account hierarchies
- Configure Account and Contact Teams
- Implement roll-up summary fields
- Manage Contact Roles on Opportunities
- Build Apex triggers for account-related automation

---

## 1. Account Hierarchies

Account hierarchies model parent-subsidiary relationships:

```
Global Corp (Parent)
├── Global Corp - North America (Child)
│   ├── Global Corp - US (Grandchild)
│   └── Global Corp - Canada (Grandchild)
└── Global Corp - Europe (Child)
    ├── Global Corp - UK (Grandchild)
    └── Global Corp - Germany (Grandchild)
```

### How to Set Up
1. Create the parent Account (Global Corp)
2. Create child Accounts, setting **Parent Account** field
3. Navigate to the parent and view the **Account Hierarchy** related list

### Key Fields
| Field | Purpose |
|-------|---------|
| **Parent Account** | Links child to parent |
| **Ultimate Parent Account** | Custom field pointing to the top of the hierarchy |
| **Ticker Symbol** | Stock ticker for public companies |
| **Duns Number** | Dun & Bradstreet identifier |

### Roll-Up Summary Fields (Parent Account)
Configure roll-ups on the parent to aggregate child data:
- **Number of Child Accounts**: COUNT of child accounts
- **Total Child Revenue**: SUM of Annual Revenue from children
- **Child Account List**: Related list of all children

---

## 2. Account Teams

Account Teams allow multiple users to collaborate on an Account.

### Configuration
1. Setup > **Account Teams**
2. Enable Account Teams
3. Add the "Account Teams" related list to the page layout
4. Define team roles:

| Role | Purpose |
|------|---------|
| Account Manager | Primary owner, manages relationship |
| Sales Engineer | Technical support |
| Executive Sponsor | Senior leadership involvement |
| Support Rep | Post-sale support contact |

### Sharing Settings
When a team member is added:
- **Read/Write** access granted (based on sharing rules)
- Team member can see the Account in their "Accounts I'm on Team For" list

---

## 3. Contact Roles

Contact Roles identify the people involved in a deal on the Opportunity side.

### Standard Contact Roles
- Decision Maker
- Champion
- Economic Buyer
- Technical Evaluator
- End User
- Influencer
- Legal
- Other

### Why Contact Roles Matter
- **Identify** who's involved in the deal
- **Track** engagement per contact
- **Report** on deal influence
- **Einstein Opportunity Scoring** uses contact engagement data

### Configuration
1. Setup > **Contact Roles under Opportunities**
2. Add/remove roles
3. Add the Contact Roles related list to the Opportunity page layout

---

## 4. Roll-Up Summary Fields

Roll-up summary fields aggregate data from child records to the parent.

### Supported Operations
| Operation | Example |
|-----------|---------|
| **COUNT** | Number of Contacts on an Account |
| **SUM** | Total Opportunity Amount for an Account |
| **MIN** | Earliest Close Date of Opportunities |
| **MAX** | Latest Close Date of Opportunities |

### How to Create
1. Object Manager > Account > Fields & Relationships > New
2. Select "Roll-Up Summary"
3. Define the roll-up:
   - **Field to Aggregate**: Annual Revenue (from child Opportunities)
   - **Operation**: SUM
   - **Filter Criteria**: Stage = 'Closed Won'

### Limitations
- Only works on Master-Detail relationships
- Maximum 10 roll-up summary fields per object
- Cannot roll up to a different object (e.g., Contact → Account)

---

## 5. Apex Triggers for Accounts

### Trigger: Auto-Create Default Contact on New Account
```apex
trigger AccountTrigger on Account (after insert) {
    List<Contact> contactsToInsert = new List<Contact>();

    for (Account acc : Trigger.new) {
        contactsToInsert.add(new Contact(
            FirstName = 'Primary',
            LastName = 'Contact',
            AccountId = acc.Id,
            Role__c = 'Decision Maker'
        ));
    }

    if (!contactsToInsert.isEmpty()) {
        insert contactsToInsert;
    }
}
```

### Trigger: Update Account Health Score Based on Opportunity Wins
```apex
trigger OpportunityTrigger on Opportunity (after update) {
    Set<Id> accountIds = new Set<Id>();

    for (Opportunity opp : Trigger.new) {
        if (opp.StageName == 'Closed Won' && Trigger.oldMap.get(opp.Id).StageName != 'Closed Won') {
            accountIds.add(opp.AccountId);
        }
    }

    if (!accountIds.isEmpty()) {
        List<Account> accounts = [
            SELECT Id, Health_Score__c,
                   (SELECT Amount FROM Opportunities WHERE StageName = 'Closed Won')
            FROM Account WHERE Id IN :accountIds
        ];

        for (Account acc : accounts) {
            Decimal totalWon = 0;
            for (Opportunity opp : acc.Opportunities) {
                totalWon += opp.Amount != null ? opp.Amount : 0;
            }
            acc.Health_Score__c = Math.min(100, totalWon.divide(10000, 0).intValue());
        }

        update accounts;
    }
}
```

---

## 6. Hands-On Exercises

### Exercise 1: Build an Account Hierarchy
1. Create a parent Account "Acme Corporation"
2. Create 3 child Accounts under it
3. Create 5 Opportunities across the children
4. Add a Roll-Up Summary to sum the Opportunity amounts

### Exercise 2: Configure Account Teams
1. Enable Account Teams in Setup
2. Add the related list to the Account page layout
3. Create an Account Team with 3 members
4. Verify sharing permissions

### Exercise 3: Add Contact Roles to an Opportunity
1. Open an existing Opportunity
2. Add 3 Contact Roles (Decision Maker, Champion, Technical Evaluator)
3. Create a report showing Contact Roles per Opportunity

---

## 7. SOQL Practice

```sql
-- Accounts with child Opportunities
SELECT Name, AnnualRevenue,
       (SELECT Name, Amount, StageName FROM Opportunities)
FROM Account

-- Contacts with their Account hierarchy
SELECT Name, Account.Name, Account.Parent.Name, Account.Parent.Parent.Name
FROM Contact

-- Accounts with most Contacts
SELECT Account.Name, COUNT(Id) contactCount
FROM Contact
WHERE AccountId != NULL
GROUP BY Account.Name
ORDER BY contactCount DESC
LIMIT 10

-- Opportunities with Contact Roles
SELECT Opportunity.Name, Contact.Name, Role
FROM OpportunityContactRole
```

---

## Next Phase

**[Phase 4: Opportunity Management](./04-opportunity-management.md)** — Master the sales pipeline, stages, products, and deal tracking.
