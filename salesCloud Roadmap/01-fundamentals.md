# Phase 1: Sales Cloud Fundamentals

## Learning Objectives
By the end of this phase, you will be able to:
- Explain what Salesforce Sales Cloud is and its core value proposition
- Navigate the Salesforce platform and understand the data model
- Describe the lifecycle of a Lead and an Opportunity
- Identify the standard objects used in Sales Cloud
- Understand profiles, permission sets, and record-level security

---

## 1. What is Salesforce?

Salesforce is a **cloud-based Customer Relationship Management (CRM)** platform. It helps businesses manage their relationships with customers, prospects, and partners. Instead of running software on your own servers, Salesforce runs in the cloud — you access it through a web browser.

### Why Salesforce?
- **No hardware** to maintain
- **Automatic updates** three times a year (Spring, Summer, Winter)
- **Customizable** without coding (declarative) and with code (programmatic)
- **Scalable** from 1 user to 100,000+
- **Massive ecosystem** of apps on the AppExchange

---

## 2. The Core Data Model

Every Salesforce org is built on a **data model** — a set of standard and custom objects that store your data. Think of objects as database tables, fields as columns, and records as rows.

### Standard Objects in Sales Cloud

| Object | Purpose | Key Fields |
|--------|---------|------------|
| **Account** | A company or organization you do business with | Name, Industry, Annual Revenue, Billing Address |
| **Contact** | A person associated with an Account | First Name, Last Name, Email, Phone, Role |
| **Lead** | A potential customer or prospect | Company, Name, Lead Source, Status, Rating |
| **Opportunity** | A potential deal or sale | Name, Stage, Amount, Close Date, Probability |
| **Campaign** | A marketing initiative | Name, Type, Status, Budget, Expected Revenue |
| **Case** | A customer issue or support request | Subject, Status, Priority, Contact |

### Relationships

Understanding how objects relate is critical:

```
Account  ─── 1:Many  ───> Contact
Account  ─── 1:Many  ───> Opportunity
Opportunity ─── 1:Many ───> OpportunityLineItem (Product)
Lead     ─── Converts to ───> Account + Contact + Opportunity
Campaign ─── Many:Many ───> Contact (via CampaignMember)
```

### Key Concept: Lead Conversion

When a Lead is qualified, it is **converted** — this creates:
1. An **Account** (the company)
2. A **Contact** (the person)
3. An **Opportunity** (the deal)

This is one of the most important workflows in Sales Cloud.

---

## 3. Org Setup & Navigation

### The Salesforce UI
- **App Launcher** (waffle icon) — switch between apps (Sales, Service, Marketing)
- **Tabs** — Home, Accounts, Contacts, Leads, Opportunities, Campaigns, Reports, Dashboards
- **Setup** — the admin backend (gear icon > Setup)
- **Record Pages** — detail view of any single record

### Key Setup Areas
- **Object Manager** — configure standard and custom objects
- **User Management** — create users, assign profiles, permission sets
- **Security Controls** — field-level security, sharing rules, OWD (Org-Wide Defaults)
- **Automation** — Flows, Approval Processes, Assignment Rules

---

## 4. Users, Profiles, and Permission Sets

### Users
Every person who logs into Salesforce is a **User**. Users are assigned a **Profile** and optionally one or more **Permission Sets**.

### Profiles
A Profile controls:
- **Object-level permissions** (CRUD — Create, Read, Update, Delete)
- **Field-level security** (which fields are visible/editable)
- **Tab visibility**
- **App access**

Examples: System Administrator, Standard User, Sales User

### Permission Sets
Permission Sets are **add-on permissions** layered on top of a profile. Use them to grant additional access without changing the profile.

```
Profile (baseline)  +  Permission Set (extras)  =  User's total access
```

### OWD (Org-Wide Defaults)
The most restrictive level of access. Controls who can see records by default:
- **Private** — only the owner and users above in the role hierarchy
- **Public Read Only** — everyone can see, only owner can edit
- **Public Read/Write** — everyone can see and edit

---

## 5. Hands-On Exercises

### Exercise 1: Navigate Your Org
1. Log into your Developer Edition org
2. Use the App Launcher to open the **Sales** app
3. Navigate to each tab: Accounts, Contacts, Leads, Opportunities
4. Create a new Account record
5. Create a Contact and relate it to your Account

### Exercise 2: Explore Setup
1. Click the gear icon > **Setup**
2. Go to **Object Manager** > Account > **Fields & Relationships**
3. Notice the custom fields we've added (Industry Segment, Health Score, Customer Since)
4. Go to **Users** > **Profiles** — review the Standard User profile
5. Go to **Users** > **Permission Sets** — find the `Sales_Cloud_User` permission set

### Exercise 3: Run a SOQL Query
Open the Developer Console (Setup > Developer Console > Query Editor) and run:

```sql
SELECT Name, Industry, AnnualRevenue FROM Account LIMIT 10
```

---

## 6. Key Terms Glossary

| Term | Definition |
|------|-----------|
| **Org** | Your Salesforce instance and all its data |
| **Record** | A single row of data in an object |
| **Metadata** | The configuration of your org (fields, layouts, code) |
| **Declarative** | Clicks-not-code configuration |
| **Programmatic** | Code-based development (Apex, LWC) |
| **API** | Application Programming Interface — for integrations |
| **Scratch Org** | A temporary, disposable org for development |
| **SFDX** | Salesforce Developer Experience — the modern dev toolchain |
| **Governor Limits** | Salesforce platform limits (query rows, CPU time, etc.) |

---

## 7. Quiz — Test Your Knowledge

1. What are the three objects created when a Lead is converted?
2. What is the difference between a Profile and a Permission Set?
3. Name 3 standard objects in Sales Cloud.
4. What does CRUD stand for?
5. If Org-Wide Default is set to "Private," who can see a record by default?

---

## Next Phase

**[Phase 2: Lead Management](./02-lead-management.md)** — Dive deep into lead capture, scoring, assignment rules, and the qualification process.
