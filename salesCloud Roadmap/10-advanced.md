# Phase 10: Advanced & Integrations

## Learning Objectives
By the end of this phase, you will be able to:
- Understand Salesforce CPQ basics
- Configure Einstein AI features for Sales Cloud
- Build REST API integrations
- Implement Platform Events for real-time data sync
- Use Change Data Capture for external system integration

---

## 1. Salesforce CPQ (Configure, Price, Quote)

CPQ extends the standard Opportunity/Quote process with advanced product configuration.

### Key Concepts
| Concept | Description |
|---------|-------------|
| **Product Bundle** | A group of products sold together |
| **Configuration Rules** | Rules that control which products can be selected |
| **Pricing Rules** | Dynamic pricing based on quantity, term, etc. |
| **Quote Templates** | PDF templates for generating quotes |
| **Contract Management** | Automated contract generation and renewal |

### CPQ Flow
```
1. Rep selects a Product Bundle
2. CPQ configures options based on rules
3. Pricing is calculated (volume discounts, term pricing)
4. Quote is generated with line items
5. PDF quote is created from template
6. Quote is sent to customer
7. Customer accepts → Opportunity closes
8. Contract is auto-generated
9. Renewal Opportunity is auto-created
```

### Standard CPQ Fields
| Object | Key Fields |
|--------|-----------|
| **Product** | SKU, Configuration Type, Configuration Event |
| **Product Option** | Optional SKU, Configuration Attribute |
| **Quote** | Subscription Term, Total Contract Value |
| **Quote Line** | Unit Price, Discount, Net Price |
| **Contract** | Start Date, End Date, Contract Term |

---

## 2. Einstein AI for Sales

### Einstein Opportunity Scoring
AI-powered scoring that predicts deal outcomes:
- Analyzes historical deal data
- Considers factors like activity, field values, and timing
- Provides a score (1-99) and key influencing factors
- Updates in real-time as deals progress

**Configuration:**
1. Setup > **Einstein Opportunity Scoring**
2. Turn on scoring
3. Select fields for the model
4. Wait for training (24-48 hours)

### Einstein Activity Capture
Automatically captures emails and calendar events:
- Syncs with Gmail or Outlook
- Logs activities to related Salesforce records
- Provides "Einstein Suggestions" for activity logging

**Configuration:**
1. Setup > **Einstein Activity Capture**
2. Connect email accounts
3. Select sync scope (all vs. filtered)

### Einstein Lead Scoring
Predicts which leads are most likely to convert:
- Analyzes lead fields and engagement history
- Provides a conversion probability score
- Helps prioritize lead follow-up

### Einstein Forecasting
AI-enhanced forecasting:
- Analyzes historical forecast accuracy
- Adjusts forecasts based on deal momentum
- Provides confidence intervals

---

## 3. REST API Integration

### Outbound: Calling External APIs
```apex
public class ExternalApiService {

    public static String callExternalApi(String endpoint, String method, String body) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + getAuthToken());
        request.setBody(body);
        request.setTimeout(10000);

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        } else {
            throw new CalloutException('API Error: ' + response.getStatusCode());
        }
    }

    private static String getAuthToken() {
        // Retrieve from Named Credential or Custom Metadata
        return 'your-auth-token';
    }
}
```

### Inbound: Exposing Salesforce Data via API
Create a REST resource:
```apex
@RestResource(urlMapping='/v1/accounts/*')
global with sharing class AccountRestResource {

    @HttpGet
    global static Account getAccount() {
        RestRequest request = RestContext.request;
        String accountId = request.requestURI.substring(
            request.requestURI.lastIndexOf('/') + 1
        );

        return [SELECT Id, Name, Industry, AnnualRevenue
                FROM Account WHERE Id = :accountId];
    }

    @HttpPost
    global static Account createAccount() {
        RestRequest request = RestContext.request;
        Account acc = (Account) JSON.deserialize(
            request.requestBody.toString(), Account.class
        );

        insert acc;
        return acc;
    }
}
```

### Named Credentials
Store external system credentials securely:
1. Setup > **Named Credentials**
2. Create a Named Credential:
   - URL: https://api.example.com
   - Identity Type: Named Principal
   - Authentication Protocol: OAuth 2.0
3. Use in callouts: `request.setEndpoint('callout:My_Named_Credential/api/data')`

---

## 4. Platform Events

Platform Events enable event-driven architecture within Salesforce.

### Publishing Events
```apex
// Publish a platform event
DealUpdate__e event = new DealUpdate__e(
    OpportunityId__c = opp.Id,
    OldStage__c = oldStage,
    NewStage__c = newStage,
    Amount__c = opp.Amount
);

EventBus.publish(event);
```

### Subscribing to Events
Apex Trigger on Platform Event:
```apex
trigger DealUpdateTrigger on DealUpdate__e (after insert) {
    for (DealUpdate__e event : Trigger.new) {
        // Process the event
        System.debug('Deal updated: ' + event.OpportunityId__c);

        // Create a notification, update a record, etc.
        Notification__c notif = new Notification__c(
            Title__c = 'Deal Stage Changed',
            Message__c = 'Opportunity ' + event.OpportunityId__c +
                         ' moved from ' + event.OldStage__c +
                         ' to ' + event.NewStage__c
        );
        insert notif;
    }
}
```

### Streaming API (CometD)
Subscribe to events in real-time from a client:
```javascript
// Client-side subscription
const cometd = new CometD();
cometd.configure({
    url: '/cometd',
    requestHeaders: { Authorization: 'Bearer ' + sessionId }
});

cometd.subscribe('/event/DealUpdate__e', function(message) {
    console.log('Deal updated:', message.data.payload);
    updateUI(message.data.payload);
});
```

---

## 5. Change Data Capture (CDC)

CDC tracks changes to Salesforce records and publishes events.

### Enable CDC
1. Setup > **Change Data Capture**
2. Select objects to track (Account, Contact, Opportunity, Lead)
3. CDC events are published automatically

### CDC Event Fields
| Field | Description |
|-------|-------------|
| ChangeType | CREATED, UPDATED, DELETED, UNDELETE |
| ChangedFields | List of fields that changed |
| ChangeOrigin | API, UI, BULK_API, etc. |
| CommitUser | User who made the change |
| CommitTimestamp | When the change happened |

### Subscribing to CDC
```apex
trigger AccountCdcTrigger on Account (after insert, after update, after delete) {
    // Process CDC events
    for (Account acc : Trigger.new) {
        // Handle record changes
    }
}
```

### Use Cases for CDC
- Sync Salesforce data to external systems
- Trigger downstream processes on data changes
- Maintain audit logs
- Real-time data warehouse updates

---

## 6. Sandbox Strategy

### Sandbox Types
| Type | Data | Purpose |
|------|------|---------|
| **Developer** | metadata only | Development and testing |
| **Developer Pro** | metadata + some data | Integration testing |
| **Partial Copy** | metadata + sample data | UAT and staging |
| **Full** | complete copy | Performance testing, training |

### Deployment Pipeline
```
Developer Sandbox → Developer Pro → Partial Copy → Production
     (Dev)          (Integration)      (UAT)       (Release)
```

### Best Practices
1. **Never develop directly in Production**
2. **Use version control** (Git) for all metadata
3. **Test in lower environments** before deploying up
4. **Use scratch orgs** for feature development
5. **Automate deployments** with CI/CD pipelines

---

## 7. Hands-On Exercises

### Exercise 1: Build a REST API Integration
1. Create a Named Credential for a mock API
2. Build an Apex class that calls the API
3. Create a button on Account that triggers the callout
4. Display the response on the Account page

### Exercise 2: Implement Platform Events
1. Create a Platform Event: Deal_Update__e
2. Build a trigger on Opportunity that publishes the event
3. Build a subscriber that creates a notification
4. Test by changing an Opportunity stage

### Exercise 3: Enable CDC
1. Enable CDC for the Account object
2. Create a trigger that logs all Account changes
3. Test by updating an Account
4. Review the change log

---

## 8. SOQL Practice

```sql
-- Complex: Opportunities with full context
SELECT Name, Amount, StageName, CloseDate,
       Account.Name, Account.Industry, Account.AnnualRevenue,
       Owner.Name, Owner.Manager.Name,
       (SELECT Contact.Name, Role FROM OpportunityContactRoles),
       (SELECT Product2.Name, UnitPrice, Quantity FROM OpportunityLineItems)
FROM Opportunity
WHERE StageName NOT IN ('Closed Won', 'Closed Lost')
AND Amount > 50000
ORDER BY Amount DESC

-- Aggregate: Revenue by Industry and Quarter
SELECT Account.Industry, CALENDAR_QUARTER(CloseDate) quarter, SUM(Amount) revenue
FROM Opportunity
WHERE StageName = 'Closed Won'
GROUP BY Account.Industry, CALENDAR_QUARTER(CloseDate)

-- Cross-object: Accounts with pipeline and won revenue
SELECT Name,
       (SELECT Amount FROM Opportunities WHERE StageName NOT IN ('Closed Won', 'Closed Lost')) pipeline,
       (SELECT Amount FROM Opportunities WHERE StageName = 'Closed Won') won
FROM Account
WHERE Id IN (SELECT AccountId FROM Opportunity)
```

---

## Next Phase

**[Phase 11: Certification Prep](./11-certification-prep.md)** — Prepare for the Sales Cloud Consultant and Administrator certification exams.
