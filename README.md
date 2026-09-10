# Salesforce Sales Cloud RoadMap

A complete, hands-on learning roadmap to master **Salesforce Sales Cloud** — from zero to certification-ready — using real SFDX metadata, Apex automation, practice SOQL, and a 20-week structured study plan.

![Salesforce CLI](https://img.shields.io/badge/Salesforce%20CLI-✓-00A1E0?logo=salesforce)
![API Version](https://img.shields.io/badge/API%20Version-68.0-00A1E0)
![Apex Classes](https://img.shields.io/badge/Apex-21%20classes-1798c1)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)

---

## 📘 Overview

This repository is a **learning lab**, not just documentation. Every concept covered in the roadmap comes with **deployable metadata** you can push to a free Developer Edition org, run in **Flow Builder / Reports / Approval**, and study line-by-line in **commented Apex classes** and **SOQL practice scripts**.

> **Who is this for?**
> - Beginners starting from zero on the Salesforce platform
> - Admins transitioning into Sales Cloud configuration
> - Developers who want Real Apex, triggers, flows, and integration patterns
> - Anyone prepping for the **Salesforce Administrator** or **Sales Cloud Consultant** certification

> **Scope** — The full revenue lifecycle: lead capture → scoring → opportunity pipeline → deal close → forecasting → reporting → certification prep.

> **Duration** — ~20 weeks, self-paced (each phase is one week of study + hands-on labs).

---

## 🧭 The 20-Week Learning Roadmap

| Phase | Topic | Guide | Key Concepts |
|------:|-------|-------|--------------|
| 1 | **Fundamentals** | [01-fundamentals.md](./salesCloud%20Roadmap/01-fundamentals.md) | Platform, data model, security model, custom fields |
| 2 | **Lead Management** | [02-lead-management.md](./salesCloud%20Roadmap/02-lead-management.md) | Lead capture, scoring, assignment rules, conversion |
| 3 | **Account & Contact Mgmt** | [03-accounts-contacts.md](./salesCloud%20Roadmap/03-accounts-contacts.md) | Hierarchy, roll-ups, teams, health score |
| 4 | **Opportunity Management** | [04-opportunity-management.md](./salesCloud%20Roadmap/04-opportunity-management.md) | Stages, pipeline, close dates, products & price books |
| 5 | **Campaigns & Marketing** | [05-campaigns.md](./salesCloud%20Roadmap/05-campaigns.md) | Campaigns, influence model, ROI |
| 6 | **Sales Collaboration** | [06-collaboration.md](./salesCloud%20Roadmap/06-collaboration.md) | Activities, follow-ups, Chatter, emails |
| 7 | **Processes & Automation** | [07-processes-automation.md](./salesCloud%20Roadmap/07-processes-automation.md) | Approval processes, Flows, automation best practices |
| 8 | **Forecasting & Territories** | [08-forecasting-territories.md](./salesCloud%20Roadmap/08-forecasting-territories.md) | Weighted forecast, quotas, territory routing |
| 9 | **Reporting & Dashboards** | [09-reporting.md](./salesCloud%20Roadmap/09-reporting.md) | Reports, dashboards, KPI design |
| 10 | **Advanced & Integrations** | [10-advanced.md](./salesCloud%20Roadmap/10-advanced.md) | REST/API patterns, platform events, custom metadata |
| 11 | **Certification Prep** | [11-certification-prep.md](./salesCloud%20Roadmap/11-certification-prep.md) | Admin & Sales Cloud Consultant exam blueprint |

Each guide follows the same structure: **Week 1 core concepts → Week 2 hands-on labs → weekly practice quiz → SOQL practice** to build skills incrementally.

---

## ✨ What's Inside

### 🧠 Apex: 10 Service Classes + 11 Test Classes (100% commented for learning)

Every Apex file is documented with **learning-focused comments** explaining *why* the pattern is used (governors, bulkification, sharing, AggregateResult, Approval API, platform events...).

| Service Class | Responsibility | Test Class |
|---------------|----------------|------------|
| `LeadScoringService` | Lead scoring, ratings, nurture status | `LeadManagementTest` |
| `AccountService` | Hierarchy, metrics roll-ups, health score | `AccountContactManagementTest` |
| `OpportunityService` | Close dates, stale auto-close, analytics | `OpportunityManagementTest` |
| `CampaignService` | Member add, metrics, ROI | `CampaignManagementTest` |
| `ActivityService` | Follow-up tasks, metrics | `ActivityManagementTest` |
| `ProcessAutomationService` | Approvals, emails, stale automation | `ProcessAutomationTest` |
| `ForecastingService` | Forecast, quotas, territories | `ForecastingTerritoryTest` |
| `ReportingService` | KPIs powering the dashboards | `ReportingServiceTest` |
| `IntegrationService` | Logging, retries, webhooks | `IntegrationServiceTest` |
| `CertificationPrepService` | Question bank, study plans, quiz engine | `CertificationPrepServiceTest` |

Plus `SalesCloudFundamentalsTest` covering Phase 1 core CRUD and SOQL.

### ⚡ Triggers (7)

`LeadTrigger`, `AccountTrigger`, `OpportunityTrigger`, `OpportunityStageTrigger`, `OpportunityCampaignTrigger`, `OpportunityForecastTrigger`, `TaskActivityTrigger`, `CampaignMemberStatusTrigger` — each delegating work to its service class (trigger-light / logic-in-service best practice).

### ⚙️ Metadata

- **5 custom objects**: `Quota__c`, `Territory__c`, `Integration_Log__c`, `Certification_Question__c`, `Certification_Study_Plan__c`
- **70+ custom fields** across `Account`, `Contact`, `Lead`, `Opportunity`, `Campaign`, `Task`, `Event`, `User`
- **9 Flows** (scoring, follow-ups, nurture status, chatter notifications, pipeline summary email, stale close...)
- **6 validation rules** (stage guards, lead contact info, closed-deal locks)
- **1 approval process** for discount approval
- **Lead assignment rules** (industry-based queue routing)
- **1 permission set** `Sales_Cloud_User`
- **1 platform event** `Integration_Event__e`
- **4 dashboards + 7 reports**

> **Learning note**: Flows / Reports / Dashboards exist as **simplified reference metadata**. Best practice is to re-create them in the Flow Builder / Report Builder UI (the guides in `salesCloud Roadmap/` walk through every click).

### 📜 Practice Scripts

One SOQL practice file per phase in [`scripts/soql/`](./scripts/soql): build queries progressively — from basic `SELECT` to `GROUP BY`, rolls-ups, and territory/forecast aggregations. Run them with:

```bash
sf apex run --apex-code-file scripts/soql/opportunity-management.soql --target-org myDevOrg
```

---

## 🚀 Quick Start

### 1. Prerequisites

- **Salesforce CLI** — [install guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- **VS Code + Salesforce Extension Pack** — [install guide](https://developer.salesforce.com/docs/platform/sfvscode-extensions/guide/install.html)
- A free **Developer Edition org** — [sign up](https://developer.salesforce.com/signup)

### 2. Authenticate an org

```bash
sf org login web --alias myDevOrg
```

### 3. Deploy all metadata

```bash
sf project deploy start --source-dir force-app/main/default --target-org myDevOrg --wait 15
```

Or deploy in **phases** as you study (example — Phase 2 only):

```bash
sf project deploy start \
  --metadata ApexClass:LeadScoringService,ApexTrigger:LeadTrigger \
  --target-org myDevOrg --wait 15
```

### 3b. (Optional) Scratch org workflow

```bash
sf org create scratch -f config/project-scratch-def.json --alias scratch-org --set-default
```

### 4. Run the tests

```bash
sf apex run test --target-org myDevOrg --test-level RunLocalTests --wait 15
# or a single class
sf apex run test --class-names LeadManagementTest --target-org myDevOrg --wait 15
```

All test classes use `@TestSetup` + `@isTest` and assert real business behavior — a great model for 75% coverage requirements and quality test-writing.

---

## 📂 Project Structure

```
.
├── force-app/main/default/
│   ├── classes/            # 21 commented Apex classes (service + test)
│   ├── triggers/           # 8 triggers delegating to services
│   ├── objects/            # Custom objects + custom fields + validation rules
│   ├── flows/              # 9 flows (reference metadata)
│   ├── approvalProcesses/  # Discount approval process
│   ├── assignmentRules/    # Industry-based lead queues
│   ├── permissionsets/     # Sales_Cloud_User
│   ├── reports/            # 7 reports (reference metadata)
│   ├── dashboards/         # 4 dashboards (reference metadata)
│   ├── platformEvents/     # Integration_Event__e
│   └── customMetadata/     # Integration API configuration record
├── salesCloud Roadmap/     # 11 phase study guides (the actual curriculum)
├── scripts/soql/           # One practice query file per phase
├── config/                 # Scratch org definition
├── manifest/               # package.xml
├── sfdx-project.json       # Project config (API 68.0)
└── README.md
```

---

## 🎓 Certification Path

Phase 11 bundles everything into certification prep for:

- **Salesforce Administrator** — 60 questions, 65% passing score, 90 minutes
- **Sales Cloud Consultant** — scenario-based questions on sales processes, territories, and forecasting

Use `Certification_Question__c` as a mini question bank and `CertificationPrepService` as a quiz engine to build your own practice exams.

---

## 📚 Additional Resources

- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/)
- [Salesforce Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)
- [Salesforce Flow Documentation](https://help.salesforce.com/s/articleView?id=sf.flow.htm&type=5)
- [Trailhead: Sales Cloud](https://trailhead.salesforce.com/)

---

## 🤝 Contributing

Found a bug, improved a comment, or added a phase exercise? PRs are welcome. Please keep the **learning-first** spirit: explain *why*, keep the metadata deployable, and add a test when you add logic.

## 📝 License

This project is for **learning and educational purposes**. Free to use, fork, and adapt.