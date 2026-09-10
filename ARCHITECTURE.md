# 🏗️ Sales Cloud RoadMap — Architecture

This document is a visual walkthrough of the system built across the 11 phases. All diagrams are [Mermaid](https://mermaid.js.org) and render natively on GitHub.

---

## 1. High-Level Architecture (Layered)

The project follows a **layered architecture**: Lightning Experience on top, automation in the middle, an Apex service layer doing the business logic, and clean, normalized data underneath.

```mermaid
flowchart TB
    subgraph UI["PRESENTATION"]
        UX["Lightning Experience — Sales Cloud App"]
        DSB["Reports (7) & Dashboards (4)"]
        QUIZ["Certification Prep — Question Bank UI"]
    end

    subgraph AUTOMATION["AUTOMATION LAYER"]
        F[Flows (9)<br/>scoring, follow-ups, nurture, chatter, stale-close]
        VR[Validation Rules (6)<br/>stage guards, closed-deal locks, lead contact info]
        AR[Assignment Rules<br/>industry → queue routing]
        AP[Approval Process<br/>Opportunity discount approval]
    end

    subgraph APEX["APEX LAYER (business logic)"]
        TRIGGERS["8 Triggers<br/>Lead, Account, Opportunity x3, CampaignMember, Task, Forecast"]
        SERVICES["10 Service Classes<br/>Scoring, Account, Opportunity, Campaign, Activity,<br/>Process Automation, Forecasting, Reporting, Integration, Certification"]
        AI["Integration_Event__e<br/>Platform Event"]
        CMT["API_Configuration__mdt<br/>Custom Metadata"]
    end

    subgraph DATA["DATA LAYER"]
        STD["Standard Objects<br/>Account, Contact, Lead, Opportunity, Campaign,<br/>Task, Event, User, CampaignMember"]
        CUSTOM["Custom Objects<br/>Quota__c, Territory__c, Integration_Log__c,<br/>Certification_Question__c, Certification_Study_Plan__c"]
    end

    UX --> F
    UX --> VR
    UX --> AR
    UX --> AP

    F --> SERVICES
    VR --> DATA
    AR --> DATA
    AP --> SERVICES

    UX --> TRIGGERS
    TRIGGERS --> SERVICES
    SERVICES --> DATA

    SERVICES --> AI
    AI --> CMT

    DSB --> SERVICES
    QUIZ --> SERVICES
    QUIZ --> CUSTOM

    DATA --> DSB
    DATA --> QUIZ
```

> **Architecture principles used throughout:**
> - **Trigger-light / Service-heavy**: triggers only detect events; all logic lives in testable service classes.
> - **Bulk-safe**: every trigger iterates `Trigger.new` lists, never `for` loops with per-record DML.
> - **`with sharing`**: services enforce the security model.
> - **Test-isolated**: every service has a `@isTest` companion using `@TestSetup`.

---

## 2. Data Model

Salesforce standard objects + the 5 custom objects and their relationships. Custom fields extend each standard object (e.g. `Health_Score__c` on Account, `Lead_Score__c` on Lead).

```mermaid
erDiagram
    USER ||--o{ OPPORTUNITY : "owns"
    USER ||--o{ QUOTA__C : "has target"
    USER ||--o{ CERTIFICATION_STUDY_PLAN__C : "plans"
    USER ||--o{ TERRITORY__C : "manages"

    ACCOUNT ||--o{ CONTACT : "has"
    ACCOUNT ||--o{ OPPORTUNITY : "has"

    LEAD }o--|| ACCOUNT : "converts to (ConvertedAccountId)"
    LEAD }o--|| CONTACT : "converts to (ConvertedContactId)"
    LEAD }o--o{ OPPORTUNITY : "converts to (ConvertedOpportunityId)"

    CAMPAIGN ||--o{ CAMPAIGN_MEMBER : "includes"
    CONTACT ||--o{ CAMPAIGN_MEMBER : "joins"
    LEAD ||--o{ CAMPAIGN_MEMBER : "joins"

    CONTACT ||--o{ TASK : "WhoId"
    OPPORTUNITY ||--o{ TASK : "WhatId"
    ACCOUNT ||--o{ TASK : "WhatId"

    OPPORTUNITY ||--o{ OPPORTUNITY_LINE_ITEM : "contains"
    PRICEBOOK_ENTRY ||--o{ OPPORTUNITY_LINE_ITEM : "priced by"
    PRODUCT2 ||--o{ PRICEBOOK_ENTRY : "listed in"
    PRICEBOOK2 ||--o{ PRICEBOOK_ENTRY : "groups"

    QUOTA__C }o--|| USER : "User__c"
    TERRITORY__C }o--|| USER : "Territory_Manager__c"
    INTEGRATION_LOG__C }o--o| ACCOUNT : "references (Record_Id__c)"

    CERTIFICATION_QUESTION__C {
        string Question_Text__c
        string Option_A__c
        string Correct_Answer__c
        string Topic__c
        string Difficulty__c
    }
```

**Custom objects & their purpose:**

| Custom Object | Purpose | Used By |
|---------------|---------|---------|
| `Quota__c` | Sales targets (user + amount + period) | `ForecastingService` |
| `Territory__c` | Territory definitions (region, manager) | `ForecastingService` |
| `Integration_Log__c` | Audit trail for every API call | `IntegrationService` |
| `Certification_Question__c` | Mini question bank | `CertificationPrepService` |
| `Certification_Study_Plan__c` | User study plans on custom objects | `CertificationPrepService` |
| `Integration_Event__e` (platform event) | Asynchronous integration notification | `IntegrationService` |
| `API_Configuration__mdt` (custom metadata) | Read-only API endpoint config | `IntegrationService` |

---

## 3. Trigger → Service Wiring

Every trigger delegates to exactly one service — no logic lives inside a trigger.

```mermaid
flowchart LR
    subgraph T["TRIGGERS (8)"]
        LT["LeadTrigger"] --> LSS["LeadScoringService"]
        AT["AccountTrigger"] --> ACS["AccountService"]
        OT["OpportunityTrigger"] --> ACS
        OST["OpportunityStageTrigger"] --> OPS["OpportunityService"]
        OCT["OpportunityCampaignTrigger"] --> CAS["CampaignService"]
        CMS["CampaignMemberStatusTrigger"] --> CAS
        TAT["TaskActivityTrigger"] --> ACTS["ActivityService"]
        OFT["OpportunityForecastTrigger"] --> FS["ForecastingService"]
    end

    subgraph SUPPORT["INVOKED FROM TESTS & FLOWS"]
        PAS["ProcessAutomationService"]
        RS["ReportingService"]
        IS["IntegrationService"]
        CS["CertificationPrepService"]
    end

    LSS --> DB
    ACS --> DB
    OPS --> DB
    CAS --> DB
    ACTS --> DB
    FS --> DB
    PAS --> DB
    RS --> DB
    IS --> DB
    CS --> DB

    DB[("f(x) Salesforce Org Data")]
```

> **Note:** `ProcessAutomationService`, `ReportingService`, `IntegrationService` and `CertificationPrepService` are orchestrated services — invoked from Flows, scheduled automation, or Apex tests rather than object triggers.

---

## 4. End-to-End Sales Process Flow

How a lead becomes a won opportunity, forecast-worthy revenue, and a KPI on a dashboard.

```mermaid
flowchart TD
    A[Lead captured] --> B[LeadTrigger scores + rates<br/>LeadScoringService]
    B --> C[Assignment Rules route<br/>to industry queue]
    C --> D[Lead conversion<br/>→ Account + Contact + Opportunity]
    D --> E[OpportunityStageTrigger<br/>sets close date, opens tasks]
    E --> F{Stage management}
    F -->|campaign influence| G[OpportunityCampaignTrigger<br/>adds contacts to campaign]
    F -->|time passes| H[ProcessAutomationService<br/>auto-closes stale deals]
    F -->|big discount| I[Approval Process<br/>discount sign-off]
    F -->|high value| J[TaskActivityTrigger<br/>follow-ups + Chatter]
    G --> K{CampaignService}<br/>ROI & influence metrics
    F --> L[Won / Lost]
    L -->|Won| M[AccountService rolls up<br/>revenue onto Account]
    M --> N[ForecastingService<br/>quota attainment + weighted forecast]
    N --> O[ReportingService<br/>territory revenue, win rate, funnel]
    O --> P[Reports + Dashboards]
```

---

## 5. Integration Architecture (Phase 10)

```mermaid
flowchart LR
    EXT["External System<br/>(ERP, Webhook, REST API)"] -->|HTTP| WEB{"IntegrationService"}
    WEB -->|"serialize request/response"| LOG["Integration_Log__c<br/>audit trail"]
    WEB -->|"publish platform event"| PE["Integration_Event__e"]
    PE -->|"subscriber flow/trigger"| SUB["Async processors"]
    WEB -->|"read config"| MDT["API_Configuration__mdt"]
    WEB -->|failure| RETRY{"Retry? (Retry_Count__c)"}
    RETRY -->|yes, under max| WEB
    RETRY -->|past max| ERR["Custom IntegrationException<br/>'Max retries exceeded'"]
```

---

## 6. Certification Prep Architecture (Phase 11)

```mermaid
flowchart LR
    QB[Certification_Question__c<br/>question bank] --> SVC[CertificationPrepService]
    SVC --> FILTER[filter by topic / difficulty]
    SVC --> QUIZ[getQuizQuestions<br/>randomized set]
    SVC --> SCORE[validateAnswer<br/>grade + explanation]
    SVC --> STATS[stats by topic & difficulty]
    SVC --> PLAN[createStudyPlan<br/>Certification_Study_Plan__c]
    QUIZ --> UI[Quiz UI]
    PLAN --> UI2[Study dashboard]
```

---

## 7. Folder → Architectural Layer Mapping

| Roadmap folder | Layer |
|----------------|-------|
| `force-app/main/default/classes/` | Apex service + test classes |
| `force-app/main/default/triggers/` | Event detection (thin) |
| `force-app/main/default/flows/` | Declarative automation |
| `force-app/main/default/objects/` | Data model (fields, validation rules) |
| `force-app/main/default/approvalProcesses/` | Human-in-the-loop approvals |
| `force-app/main/default/assignmentRules/` | Routing (queues) |
| `force-app/main/default/reports/` + `dashboards/` | Analytics |
| `force-app/main/default/platformEvents/` + `customMetadata/` | Integration substrate |
| `force-app/main/default/permissionsets/` | Security / FLS |
| `salesCloud Roadmap/` | Curriculum (11 phase guides) |
| `scripts/soql/` | Practice queries per phase |