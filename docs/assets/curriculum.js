/* =============================================================================
 * Sales Cloud Academy — Curriculum data
 * 11 phases following the salesCloud Roadmap/ guides. Content is condensed
 * from the phase guides and points back to the real repo artifacts.
 * ============================================================================= */

const GUIDE = 'https://github.com/AbdoAddouli/Salesforce-SalesCloud-RoadMap/blob/main/salesCloud%20Roadmap/';

const ACADEMY = [

/* ─────────────────────────── PHASE 1 ─────────────────────────── */
{
  id: 'fund', n: 1, title: 'Salesforce Fundamentals', icon: '☁️', color: '#00A1E0',
  tagline: 'Platform, data model & security model',
  guide: '01-fundamentals.md',
  art: [
    { label: 'SalesCloudFundamentalsTest.cls', href: 'force-app/main/default/classes/SalesCloudFundamentalsTest.cls' },
    { label: 'Sales_Cloud_User Permission Set', href: 'force-app/main/default/permissionsets/Sales_Cloud_User.permissionset-meta.xml' },
    { label: 'Custom fields (Account · Contact · Lead · Opportunity)', href: 'force-app/main/default/objects' },
  ],
  objectives: [
    'Explain what Salesforce is and why it matters',
    'Describe objects, fields, records & relationships',
    'Navigate the platform: app launcher, tabs, Setup',
    'Explain Profiles vs Permission Sets vs OWD',
  ],
  lessons: [
    {
      title: 'What is Salesforce & Sales Cloud', mins: 8,
      blocks: [
        { t: 'p', x: `Salesforce is a cloud-based Customer Relationship Management (CRM) platform. Instead of running software on your own servers, you access it through a web browser.` },
        { t: 'p', x: `Sales Cloud is the sales module: it manages leads, accounts, opportunities, campaigns and quotes — the full revenue lifecycle.` },
        { t: 'list', items: [`No hardware to maintain`, `Automatic updates 3× a year (Spring, Summer, Winter)`, `Customizable both declaratively (clicks) and programmatically (Apex)`, `Scalable from 1 user to 100,000+`] },
        { t: 'selfcheck', q: `Name the 3 main ways to customize Salesforce.`, a: `Declarative (clicks — fields, flows, layouts), programmatic (Apex, LWC), and AppExchange (installed apps).` },
      ]
    },
    {
      title: 'The Core Data Model', mins: 12,
      blocks: [
        { t: 'p', x: `Everything in Salesforce is built on a data model. Think of objects as database tables, fields as columns, and records as rows.` },
        { t: 'table', head: ['Object', 'Purpose'], rows: [
          [ 'Account', 'A company / organization you do business with' ],
          [ 'Contact', 'A person associated with an Account' ],
          [ 'Lead', 'A potential customer (unqualified prospect)' ],
          [ 'Opportunity', 'A potential deal in the pipeline' ],
          [ 'Campaign', 'A marketing initiative' ],
        ]},
        { t: 'h', x: 'Key relationships' },
        { t: 'code', lang: 'text', x: `Account   ─── 1:N ───▶ Contact
Account   ─── 1:N ───▶ Opportunity
Opportunity ─── 1:N ───▶ OpportunityLineItem (Product)
Lead      ─── converts ───▶ Account + Contact + Opportunity
Campaign  ─── N:N ───▶ Contact  (via CampaignMember)` },
        { t: 'callout', kind: 'tip', x: `Lead conversion is the most important workflow in Sales Cloud. A qualified Lead converts into an Account (company), a Contact (person) and an Opportunity (deal).` },
        { t: 'selfcheck', q: `What three records are created when a Lead converts?`, a: `An Account, a Contact and an Opportunity.` },
      ]
    },
    {
      title: 'Org Setup & Navigation', mins: 10,
      blocks: [
        { t: 'list', items: [
          `App Launcher (waffle) — switch between Sales, Service, Marketing apps`,
          `Tabs — Home, Accounts, Contacts, Leads, Opportunities, Reports, Dashboards`,
          `Setup (gear icon) — the admin backend`,
        ]},
        { t: 'h', x: 'Key Setup areas' },
        { t: 'table', head: ['Area', 'What you configure'], rows: [
          ['Object Manager', 'Standard & custom objects, fields, relationships'],
          ['User Management', 'Users, profiles, permission sets'],
          ['Security Controls', 'Field-level security, sharing rules, OWD'],
          ['Automation', 'Flows, Approval Processes, Assignment Rules'],
        ]},
        { t: 'selfcheck', q: `Where do you go to create a new custom field on Account?`, a: `Setup → Object Manager → Account → Fields & Relationships → New.` },
      ]
    },
    {
      title: 'Users, Profiles & Permission Sets', mins: 14,
      blocks: [
        { t: 'p', x: `Every person who logs in is a User. Each User has a Profile, plus optional Permission Sets layered on top.` },
        { t: 'h', x: 'Profile' },
        { t: 'list', items: [
          `Object-level permissions (CRUD — Create, Read, Update, Delete)`,
          `Field-level security (which fields are visible / editable)`,
          `Tab visibility and app access`,
        ]},
        { t: 'h', x: 'Permission Set' },
        { t: 'p', x: `Permission Sets add extra permissions on top of a profile — without changing the profile. This is the recommended pattern: keep a baseline profile, grant extras via permission sets.` },
        { t: 'code', lang: 'text', x: `Profile (baseline)  +  Permission Set (extras)  =  User's total access` },
        { t: 'h', x: 'Org-Wide Defaults (OWD)' },
        { t: 'p', x: `OWD is the most restrictive level of record access. It controls who can see records by default when no sharing is granted: Private (owner + role hierarchy), Public Read Only, or Public Read/Write.` },
        { t: 'selfcheck', q: `A rep can't modify a field even though it's on their layout. What's the first thing to check?`, a: `Field-Level Security — the visible/editable flag on that field for the rep's profile or permission set.` },
      ]
    },
    {
      title: 'Hands-On Labs', mins: 20,
      blocks: [
        { t: 'h', x: 'Lab 1 — Navigate your org' },
        { t: 'num', items: [
          `Log into your Developer Edition org`,
          `Use the App Launcher to open the Sales app`,
          `Visit Accounts, Contacts, Leads, Opportunities`,
          `Create an Account, then attach a Contact to it`,
        ]},
        { t: 'h', x: 'Lab 2 — Explore Setup' },
        { t: 'num', items: [
          `Gear → Setup → Object Manager → Account → Fields & Relationships`,
          `Find the custom fields we added (Industry Segment, Health Score, Customer Since)`,
          `Review the Standard User profile`,
          `Locate the Sales_Cloud_User permission set`,
        ]},
        { t: 'h', x: 'Lab 3 — Run SOQL' },
        { t: 'code', lang: 'sql', x: `SELECT Name, Industry, AnnualRevenue FROM Account LIMIT 10` },
      ]
    },
    {
      title: 'SOQL Practice', mins: 10,
      blocks: [
        { t: 'p', x: `SOQL is the query language for Salesforce. Run these in Developer Console → Query Editor.` },
        { t: 'code', lang: 'sql', x: `-- All accounts
SELECT Name, Industry, AnnualRevenue FROM Account

-- Accounts with their contacts
SELECT Name, (SELECT FirstName, LastName FROM Contacts) FROM Account

-- Leads converted
SELECT Name, Company, IsConverted FROM Lead WHERE IsConverted = true

-- Opportunities last quarter
SELECT Name, Amount, CloseDate FROM Opportunity WHERE CloseDate = LAST_QUARTER` },
        { t: 'selfcheck', q: `Which clause limits the number of rows returned by a query?`, a: `LIMIT — e.g. SELECT Name FROM Account LIMIT 10.` },
      ]
    },
  ],
  quiz: {
    title: 'Phase 1 Quiz · Fundamentals', mins: 5,
    questions: [
      { q: `Which three records are created when a Lead converts?`,
        opts: [`Account, Contact, Opportunity`, `Account, Contact, Case`, `Contact, Opportunity, Quote`, `Account, Opportunity, Campaign`], a: 0, why: `Lead conversion creates an Account (company), a Contact (person) and an Opportunity (deal).` },
      { q: `What is a "record" in Salesforce?`,
        opts: [`A column in a table`, `A single row of data in an object`, `A type of object`, `A field definition`], a: 1, why: `Objects = tables, fields = columns, records = rows.` },
      { q: `A Profile controls all of the following EXCEPT:`,
        opts: [`CRUD permissions on objects`, `Which fields a user can see`, `Record-level visibility via OWD`, `Tab visibility`], a: 2, why: `OWD controls record-level (row-level) visibility; the profile controls fields, tabs and object CRUD.` },
      { q: `Which feature grants extra permissions WITHOUT changing a user's profile?`,
        opts: [`Role hierarchy`, `Permission Set`, `Assignment Rule`, `Queue`], a: 1, why: `Permission Sets layer add-on permissions on top of a profile.` },
      { q: `The default sharing model where only the record owner (and role hierarchy above them) can see a record is called…`,
        opts: [`Public Read Only`, `Public Read/Write`, `Private`, `Controlled by Parent`], a: 2, why: `Private OWD restricts record access to the owner and, if enabled, users above them in the role hierarchy.` },
    ]
  }
},

/* ─────────────────────────── PHASE 2 ─────────────────────────── */
{
  id: 'lead', n: 2, title: 'Lead Management', icon: '🎯', color: '#7C3AED',
  tagline: 'Capture, scoring, assignment & conversion',
  guide: '02-lead-management.md',
  art: [
    { label: 'LeadTrigger', href: 'force-app/main/default/triggers/LeadTrigger.trigger-meta.xml' },
    { label: 'LeadScoringService', href: 'force-app/main/default/classes/LeadScoringService.cls' },
    { label: 'Lead Assignment Rules', href: 'force-app/main/default/assignmentRules/Lead.assignmentRules-meta.xml' },
    { label: 'Lead_Scoring_Flow', href: 'force-app/main/default/flows/Lead_Scoring_Flow.flow-meta.xml' },
  ],
  objectives: [
    'Model the Lead lifecycle from capture to conversion',
    'Configure Web-to-Lead and other capture sources',
    'Build lead assignment rules and queues',
    'Implement lead scoring (manual + Einstein)',
    'Automate qualification with flows & validation',
  ],
  lessons: [
    {
      title: 'The Lead Lifecycle', mins: 8,
      blocks: [
        { t: 'code', lang: 'text', x: `New Lead → Contacted → Qualified → Converted (or Disqualified)` },
        { t: 'table', head: ['Status', 'Meaning'], rows: [
          ['Open - Not Contacted', 'Newly created, awaiting first outreach'],
          ['Working - Contacted', 'Active engagement in progress'],
          ['Closed - Converted', 'Qualified, converted to Account/Contact/Opportunity'],
          ['Closed - Not Converted', 'Disqualified or not a fit'],
        ]},
        { t: 'p', x: `You can add custom statuses — Nurturing, Unresponsive, Duplicate, Bad Data — to match your real process.` },
      ]
    },
    {
      title: 'Lead Capture Sources', mins: 8,
      blocks: [
        { t: 'table', head: ['Source', 'How it works'], rows: [
          ['Web-to-Lead', 'An HTML form on your site creates a Lead'],
          ['Email-to-Lead', 'Inbound email parsed into a Lead'],
          ['List Import', 'CSV via Data Loader or Import Wizard'],
          ['Manual Entry', 'Rep creates the Lead directly'],
          ['API / Integration', 'External systems push leads via REST/SOAP'],
          ['Marketing Automation', 'Pardot / Marketo / HubSpot sync leads'],
          ['Social', 'Facebook Lead Ads, LinkedIn Lead Gen Forms'],
        ]},
        { t: 'selfcheck', q: `A form on your website creates a Lead record without any code. Which feature is this?`, a: `Web-to-Lead — Setup → Web-to-Lead, pick fields, generate the HTML.` },
      ]
    },
    {
      title: 'Lead Assignment Rules & Queues', mins: 12,
      blocks: [
        { t: 'p', x: `Assignment Rules route leads to the right rep or queue based on criteria. Entries are evaluated in order — the first match wins.` },
        { t: 'code', lang: 'text', x: `Rule Entry 1: IF Industry = 'Technology'   THEN Tech Sales Queue
Rule Entry 2: IF AnnualRevenue > 1000000   THEN Enterprise Queue
Rule Entry 3: IF State = 'California'      THEN West Coast Team` },
        { t: 'p', x: `Queues are holding areas where records wait until a user claims or receives them. Teams pull from queues rather than being assigned automatically.` },
        { t: 'list', items: [`Setup → Queues: create queue, add members`, `Setup → Lead Assignment Rules: create rule + entries`, `Queues are also used for Cases and custom objects`] },
        { t: 'selfcheck', q: `Why use a queue instead of assigning directly to a user?`, a: `To balance workload — any team member can claim the lead, rather than one rep being stuck with it.` },
      ]
    },
    {
      title: 'Lead Scoring', mins: 14,
      blocks: [
        { t: 'p', x: `Score leads so reps prioritize the hottest prospects. Use a Number field (Lead_Score__c) and update it via flow, validation, or Apex.` },
        { t: 'table', head: ['Criteria', 'Points'], rows: [
          ['Industry = Technology', '+20'],
          ['Annual Revenue > $1M', '+25'],
          ['Lead Source = Referral', '+15'],
          ['Has Phone', '+10'],
          ['Has Email', '+10'],
          ['Employees > 100', '+20'],
        ]},
        { t: 'p', x: `In this repo, LeadTrigger delegates scoring to LeadScoringService (Apex). Lead_Scoring_Flow is a Screen Flow reps can run to score manually, and Auto_Update_Nurture_Status re-derives Nurture_Status__c when criteria change.` },
        { t: 'h', x: 'Einstein Lead Scoring (paid)' },
        { t: 'p', x: `AI that learns from historical conversion data. Turn it on in Setup → Einstein Lead Scoring, pick fields for the model, wait 24–48h for training; the EinsteinScore field populates automatically.` },
        { t: 'selfcheck', q: `A lead scores 60/100. What should the nurture flow do?`, a: `Set Nurture_Status__c = 'Active Nurture' when Score > 50 AND Status = Open — exactly what the Auto_Update_Nurture_Status flow implements.` },
      ]
    },
    {
      title: 'Lead Conversion', mins: 12,
      blocks: [
        { t: 'num', items: [
          `Rep clicks Convert on the Lead`,
          `System prompts for Account (existing or new)`,
          `System prompts for Contact (existing or new)`,
          `Opportunity is optional, created with a name`,
          `Lead custom fields map to the converted records`,
        ]},
        { t: 'p', x: `Field mapping is configured in Setup → Lead Settings → "Lead Custom Field Mappings". Example: Lead_Score__c → Opportunity.Lead_Score__c.` },
        { t: 'code', lang: 'apex', x: `Database.LeadConvert lc = new Database.LeadConvert();
lc.setLeadId(lead.Id);
lc.setConvertedStatus('Closed - Converted');
lc.setDoNotCreateOpportunity(false);
lc.setOpportunityName('New Deal - ' + lead.Company);

Database.LeadConvertResult res = Database.convertLead(lc);
if (res.isSuccess()) {
    System.debug('Account: ' + res.getAccountId());
    System.debug('Contact: ' + res.getContactId());
    System.debug('Opportunity: ' + res.getOpportunityId());
}` },
        { t: 'selfcheck', q: `True or false: conversion can reuse an existing Account instead of creating a new one.`, a: `True — the rep chooses an existing or a new Account, which prevents duplicates.` },
      ]
    },
  ],
  quiz: {
    title: 'Phase 2 Quiz · Lead Management', mins: 5,
    questions: [
      { q: `Which feature routes inbound website leads to the right sales team by Industry?`,
        opts: [`Workflow Rule`, `Lead Assignment Rule`, `Process Builder`, `Lead Conversion`], a: 1, why: `Assignment rules route leads by criteria to users or queues.` },
      { q: `What is the first status a new Lead usually has?`,
        opts: [`Working - Contacted`, `Qualified`, `Open - Not Contacted`, `Closed - Converted`], a: 2, why: `New leads start at Open - Not Contacted, awaiting first outreach.` },
      { q: `A rep wants Einstein to predict which leads convert. Which feature?`,
        opts: [`Einstein Lead Scoring`, `Lead Assignment Rules`, `Web-to-Lead`, `Einstein Forecasting`], a: 0, why: `Einstein Lead Scoring learns from conversion history and returns an EinsteinScore.` },
      { q: `During conversion, which record is OPTIONAL?`,
        opts: [`Account`, `Opportunity`, `Contact`, `All are required`], a: 1, why: `Account and Contact are required; the Opportunity is optional.` },
      { q: `Which validation prevents a Lead from being marked "Working" without a qualification date?`,
        opts: [`ISBLANK(Qualification_Date__c) AND ISPICKVAL(Status,'Working - Contacted') AND ISNEW()`,
        `ISPICKVAL(Qualification_Date__c,'Working')`,
        `ISCHANGED(Status) AND IsConverted=true`,
        `CONTAINS(Status,'Working')`], a: 0, why: `The shown guard requires a Qualification Date at the moment the status becomes Working.` },
    ]
  }
},

/* ─────────────────────────── PHASE 3 ─────────────────────────── */
{
  id: 'acct', n: 3, title: 'Accounts & Contacts', icon: '🏢', color: '#F59E0B',
  tagline: 'Hierarchies, roll-ups, teams & health score',
  guide: '03-accounts-contacts.md',
  art: [
    { label: 'AccountService', href: 'force-app/main/default/classes/AccountService.cls' },
    { label: 'AccountTrigger', href: 'force-app/main/default/triggers/AccountTrigger.trigger-meta.xml' },
    { label: 'OpportunityTrigger', href: 'force-app/main/default/triggers/OpportunityTrigger.trigger-meta.xml' },
    { label: 'Auto_Create_Child_Records_On_Account flow', href: 'force-app/main/default/flows/Auto_Create_Child_Records_On_Account.flow-meta.xml' },
  ],
  objectives: [
    'Model parent–subsidiary account hierarchies',
    'Use roll-up summary fields for metrics',
    'Configure Account Teams & sharing',
    'Manage Contact Roles on Opportunities',
    'Automate account-related triggers',
  ],
  lessons: [
    {
      title: 'Account Hierarchies', mins: 12,
      blocks: [
        { t: 'p', x: `Account hierarchies model parent → subsidiary relationships, mirroring how real companies are structured.` },
        { t: 'code', lang: 'text', x: `Global Corp (Parent)
├── Global Corp - North America (Child)
│   ├── Global Corp - US (Grandchild)
│   └── Global Corp - Canada (Grandchild)
└── Global Corp - Europe (Child)` },
        { t: 'list', items: [
          `Set the Parent Account field on the child`,
          `View the hierarchy on the parent's Account Hierarchy related list`,
          `Custom Ultimate_Parent__c points to the top of the chain`,
        ]},
        { t: 'selfcheck', q: `Which field links a child Account to its parent?`, a: `The standard Parent Account lookup field.` },
      ]
    },
    {
      title: 'Roll-Up Summary Fields', mins: 12,
      blocks: [
        { t: 'p', x: `Roll-up summaries aggregate child data up to a parent — great for account health metrics.` },
        { t: 'table', head: ['Operation', 'Example'], rows: [
          ['COUNT', 'Number of Contacts on the Account'],
          ['SUM', 'Total Opportunity Amount'],
          ['MIN', 'Earliest Opportunity Close Date'],
          ['MAX', 'Latest Opportunity Close Date'],
        ]},
        { t: 'p', x: `Object Manager → Account → Fields & Relationships → New → Roll-Up Summary. Pick the child object, the field to aggregate, the operation, and optionally a filter (e.g. Stage = 'Closed Won').` },
        { t: 'callout', kind: 'warn', x: `Roll-up summaries only work on Master-Detail relationships, max 10 per object, and cannot cross to a different object.` },
        { t: 'selfcheck', q: `How would you sum only won opportunity amounts on an Account?`, a: `A roll-up summary with Field-to-Aggregate = Opportunity.Amount, Operation = SUM, filter Stage = Closed Won.` },
      ]
    },
    {
      title: 'Account Teams & Contact Roles', mins: 12,
      blocks: [
        { t: 'p', x: `Account Teams let several people collaborate on one Account without changing ownership.` },
        { t: 'table', head: ['Role', 'Purpose'], rows: [
          ['Account Manager', 'Primary owner, owns the relationship'],
          ['Sales Engineer', 'Technical support'],
          ['Executive Sponsor', 'Senior leadership involvement'],
          ['Support Rep', 'Post-sale support contact'],
        ]},
        { t: 'p', x: `Contact Roles sit on the Opportunity side and name the people involved in a deal: Decision Maker, Champion, Economic Buyer, Technical Evaluator, End User, Influencer, Legal. Einstein Opportunity Scoring uses this engagement data.` },
        { t: 'callout', kind: 'tip', x: `Setup → Contact Roles under Opportunities lets you add/remove roles; add the related list to the Opportunity layout.` },
        { t: 'selfcheck', q: `Which role identifies the person who influences a purchase decision financially?`, a: `Economic Buyer — the person controlling budget for the deal.` },
      ]
    },
    {
      title: 'Account Automation', mins: 14,
      blocks: [
        { t: 'p', x: `In this repo, triggers keep logic out of Apex as much as possible: AccountTrigger → AccountService handles hierarchy + metrics + health score.` },
        { t: 'code', lang: 'apex', x: `trigger OpportunityTrigger on Opportunity (after update) {
    Set<Id> accountIds = new Set<Id>();
    for (Opportunity opp : Trigger.new) {
        if (opp.StageName == 'Closed Won'
            && Trigger.oldMap.get(opp.Id).StageName != 'Closed Won') {
            accountIds.add(opp.AccountId);
        }
    }
    // AccountService recomputes revenue + Health_Score__c
    AccountService.refreshMetrics(accountIds);
}` },
        { t: 'p', x: `Auto_Create_Child_Records_On_Account (flow) bootstraps default contacts with Role = Decision Maker when an account is created.` },
        { t: 'selfcheck', q: `Why detect the stage TRANSITION (old vs new) instead of just 'Closed Won'?`, a: `So health/revenue metrics update only when a deal actually reaches Closed Won — not on every edit of an already-won deal.` },
      ]
    },
  ],
  quiz: {
    title: 'Phase 3 Quiz · Accounts & Contacts', mins: 5,
    questions: [
      { q: `Which object type supports a roll-up summary field?`,
        opts: [`The child in a Master-Detail relationship`, `Any child in a Lookup`, `The parent in a Lookup`, `Standard objects only`], a: 0, why: `Roll-up summaries require a Master-Detail relationship and live on the master.` },
      { q: `Which feature lets multiple users work on one Account without changing ownership?`,
        opts: [`Sharing Rule`, `Account Team`, `Public Group`, `Role Hierarchy`], a: 1, why: `Account Teams add members with roles (Account Manager, SE, Sponsor…) sharing read/write access.` },
      { q: `A customer is a named individual at a company. That's a…`,
        opts: [`Lead`, `Account`, `Contact`, `Opportunity`], a: 2, why: `Contacts are people; Accounts are the organizations.` },
      { q: `Which Contact Role best represents a stakeholder who champions your solution internally?`,
        opts: [`Economic Buyer`, `Technical Evaluator`, `Champion`, `Legal`], a: 2, why: `A Champion advocates for your solution inside the buying org.` },
      { q: `Health_Score__c in this repo is driven by…`,
        opts: [`A roll-up + AccountService recompute`, `A picklist users edit by hand`, `Einstein only`, `A scheduled report`], a: 0, why: `Won revenue rolls up and AccountService refreshes the score after stage changes.` },
    ]
  }
},

/* ─────────────────────────── PHASE 4 ─────────────────────────── */
{
  id: 'opp', n: 4, title: 'Opportunity Management', icon: '💼', color: '#10B981',
  tagline: 'Stages, pipeline, products, price books & quotes',
  guide: '04-opportunity-management.md',
  art: [
    { label: 'OpportunityService', href: 'force-app/main/default/classes/OpportunityService.cls' },
    { label: 'OpportunityStageTrigger', href: 'force-app/main/default/triggers/OpportunityStageTrigger.trigger-meta.xml' },
    { label: 'Opportunity validation rules', href: 'force-app/main/default/objects/Opportunity/validationRules' },
    { label: 'Auto_Assign_Tasks_New_Opportunity flow', href: 'force-app/main/default/flows/Auto_Assign_Tasks_New_Opportunity.flow-meta.xml' },
  ],
  objectives: [
    'Configure stages, probabilities & sales processes',
    'Manage products, price books and quotes',
    'Track pipeline metrics like weighted value & win rate',
    'Enforce stage discipline with validation rules',
    'Automate the deal lifecycle',
  ],
  lessons: [
    {
      title: 'The Opportunity Lifecycle', mins: 8,
      blocks: [
        { t: 'code', lang: 'text', x: `Prospecting → Qualification → Needs Analysis → Proposal → Negotiation → Closed Won / Closed Lost` },
        { t: 'table', head: ['Stage', 'Probability', 'Activity'], rows: [
          ['Prospecting', '10%', 'Research, cold outreach'],
          ['Qualification', '20%', 'Discovery call, needs assessment'],
          ['Needs Analysis', '50%', 'Deep requirements dive'],
          ['Proposal / Price Quote', '70%', 'Proposal + demo'],
          ['Negotiation / Review', '80%', 'Legal review, contract terms'],
          ['Closed Won', '100%', 'Revenue recognized'],
          ['Closed Lost', '0%', 'Lost to competitor or stalled'],
        ]},
        { t: 'p', x: `Stages are configured in Setup → Opportunity Stages. You can define multiple Sales Processes (New Business, Renewal, Upsell) per Record Type.` },
      ]
    },
    {
      title: 'Products & Price Books', mins: 12,
      blocks: [
        { t: 'p', x: `Products are what you sell. Price Books define how much each product costs. One product can appear in many price books at different prices (Standard, Partner, Employee).` },
        { t: 'code', lang: 'text', x: `Product2  ──1:N──▶  PricebookEntry  ──1:N──▶  OpportunityLineItem` },
        { t: 'list', items: [
          `PricebookEntry is the junction: Unit Price + Active + Use Standard Price`,
          `OpportunityLineItem = the product ON a deal (qty × price → Amount)`,
          `Add products to an Opportunity via the Products related list → Add Products`,
        ]},
        { t: 'callout', kind: 'tip', x: `Revenue and Quantity Schedules let you spread revenue or delivery across multiple months/periods.` },
        { t: 'selfcheck', q: `Which object pairs a Product with a Price in a specific Price Book?`, a: `PricebookEntry — the junction between Product2 and Pricebook2.` },
      ]
    },
    {
      title: 'Quotes', mins: 10,
      blocks: [
        { t: 'p', x: `A Quote captures the exact terms sent to the customer. Line items copy from the Opportunity's products.` },
        { t: 'num', items: [
          `Open the Opportunity → New Quote`,
          `Line items auto-populate from opportunity products`,
          `Set per-quote prices and discounts`,
          `Generate a PDF and send it to the customer`,
        ]},
        { t: 'table', head: ['Field', 'Purpose'], rows: [
          ['Total Price', 'Sum of all line items'],
          ['Discount %', 'Overall deal discount'],
          ['Expiration Date', 'When the quote expires'],
          ['Status', 'Draft → In Review → Presented → Accepted / Rejected'],
        ]},
      ]
    },
    {
      title: 'Pipeline Metrics', mins: 10,
      blocks: [
        { t: 'table', head: ['Metric', 'Formula'], rows: [
          ['Pipeline Value', 'SUM of open opportunity Amounts'],
          ['Weighted Pipeline', 'SUM(Amount × Probability)'],
          ['Win Rate', 'Closed Won / (Won + Lost)'],
          ['Average Deal Size', 'Total Revenue / # Closed Won'],
          ['Sales Cycle Length', 'AVG(CloseDate − CreatedDate) for won'],
          ['Quota Attainment', 'Actual Revenue / Target Quota'],
        ]},
        { t: 'p', x: `Weighted forecast uses Amount × Probability — exactly what the OpportunityService.Forecast fields and ForecastingService compute.` },
        { t: 'selfcheck', q: `A deal is $100k at 70% probability. What's its weighted value?`, a: `$70,000 (Amount × Probability).` },
      ]
    },
    {
      title: 'Validation & Automation', mins: 12,
      blocks: [
        { t: 'h', x: 'No skipping stages' },
        { t: 'code', lang: 'apex', x: `AND(
  ISCHANGED(StageName),
  NOT(OR(
    (ISPICKVAL(PRIORVALUE(StageName),'Prospecting') && ISPICKVAL(StageName,'Qualification')),
    (ISPICKVAL(PRIORVALUE(StageName),'Qualification') && ISPICKVAL(StageName,'Needs Analysis')),
    (ISPICKVAL(PRIORVALUE(StageName),'Needs Analysis') && ISPICKVAL(StageName,'Proposal/Price Quote')),
    (ISPICKVAL(PRIORVALUE(StageName),'Proposal/Price Quote') && ISPICKVAL(StageName,'Negotiation/Review')),
    ISPICKVAL(StageName,'Closed Won'),   // closing is always allowed
    ISPICKVAL(StageName,'Closed Lost')
  ))
)` },
        { t: 'h', x: 'Auto-close stale deals (Apex)' },
        { t: 'code', lang: 'apex', x: `public class OpportunityService {
    public static void closeStaleOpportunities(Integer staleDays) {
        Date cutoff = Date.today().addDays(-staleDays);
        List<Opportunity> stale = [
            SELECT Id, Name, StageName, LastActivityDate
            FROM Opportunity
            WHERE StageName NOT IN ('Closed Won','Closed Lost')
              AND LastActivityDate < :cutoff
        ];
        for (Opportunity opp : stale) {
            opp.StageName = 'Closed Lost';
            opp.Description = 'Auto-closed: no activity for ' + staleDays + ' days';
        }
        if (!stale.isEmpty()) update stale;
    }
}` },
        { t: 'callout', kind: 'tip', x: `Auto_Assign_Tasks_New_Opportunity (flow) creates discovery tasks for the owner when a deal is created.` },
      ]
    },
  ],
  quiz: {
    title: 'Phase 4 Quiz · Opportunity Management', mins: 5,
    questions: [
      { q: `Which object joins a Product to a Price Book?`,
        opts: [`OpportunityLineItem`, `PricebookEntry`, `QuoteLineItem`, `Product2`], a: 1, why: `PricebookEntry = Product2 + Pricebook2 + Unit Price. OpportunityLineItem is the product on a deal.` },
      { q: `VA = Weighted pipeline value of a $50k deal at 40% probability?`,
        opts: [`$50,000`, `$20,000`, `$10,000`, `$5,000`], a: 1, why: `Weighted = Amount × Probability = 50,000 × 0.40 = 20,000.` },
      { q: `Which validation rule prevents skipping from Prospecting to Negotiation?`,
        opts: [`ISBLANK(Amount)`, `A rule checking PRIORVALUE vs next allowed stage`, `ISPICKVAL(Probability, 80)`, `CONTAINS(StageName,'Negotiation')`], a: 1, why: `Stage-skip guards compare PRIORVALUE(StageName) to the allowed next stage.` },
      { q: `What status automatically moves an opportunity's Forecast Category to Closed?`,
        opts: [`Closed Won`, `Needs Analysis`, `Proposal`, `Qualification`], a: 0, why: `Closed Won = Closed category (revenue); Closed Lost is omitted from forecast.` },
      { q: `Repetitive to-do rules per stage are best built as…`,
        opts: [`A Record-Triggered Flow`, `Validation Rules only`, `A Dashboard`, `A Queue`], a: 0, why: `Flows can create tasks (Auto_Assign_Tasks_New_Opportunity) when the stage changes.` },
    ]
  }
},

/* ─────────────────────────── PHASE 5 ─────────────────────────── */
{
  id: 'camp', n: 5, title: 'Campaigns & Marketing', icon: '📣', color: '#EC4899',
  tagline: 'Campaign influence models, ROI & membership',
  guide: '05-campaigns.md',
  art: [
    { label: 'CampaignService', href: 'force-app/main/default/classes/CampaignService.cls' },
    { label: 'OpportunityCampaignTrigger', href: 'force-app/main/default/triggers/OpportunityCampaignTrigger.trigger-meta.xml' },
    { label: 'CampaignMemberStatusTrigger', href: 'force-app/main/default/triggers/CampaignMemberStatusTrigger.trigger-meta.xml' },
    { label: 'Campaign metrics (Reporter view)', href: 'force-app/main/default/objects/Campaign/' },
  ],
  objectives: [
    'Create campaigns and manage members & statuses',
    'Explain the four influence models',
    'Measure ROI, cost-per-lead & conversion',
    'Automate membership and status updates',
  ],
  lessons: [
    {
      title: 'Campaign Fundamentals', mins: 8,
      blocks: [
        { t: 'p', x: `A Campaign is a marketing initiative: a trade show, email blast, webinar, or ad program.` },
        { t: 'table', head: ['Field', 'Purpose'], rows: [
          ['Status', 'Planned, In Progress, Completed, Aborted'],
          ['Budget / Actual Cost', 'Expected vs real spend'],
          ['Expected Revenue', 'Projected return'],
          ['Amount All Opportunities', 'Revenue from influenced deals'],
        ]},
        { t: 'callout', kind: 'tip', x: `Campaign types: Conference, Webinar, Trade Show, Direct Mail, Email, Digital Ad, Referral.` },
      ]
    },
    {
      title: 'Campaign Members', mins: 10,
      blocks: [
        { t: 'p', x: `CampaignMembers are the junction object linking a Campaign to Leads/Contacts (many-to-many).` },
        { t: 'list', items: [
          `Add members via Manage Members (individual or bulk from a list view)`,
          `Member Status tracks the pipeline: Sent → Responded → Converted`,
          `Custom statuses: Registered, Attended, Downloaded, Visited Booth`,
        ]},
        { t: 'code', lang: 'text', x: `Campaign ──1:N──▶ CampaignMember ◀──1:N── Contact/Lead` },
        { t: 'selfcheck', q: `Why is CampaignMember needed instead of a direct field on Contact?`, a: `Because it's many-to-many — one Contact can be touched by many campaigns, and each campaign touches many contacts.` },
      ]
    },
    {
      title: 'Campaign Influence', mins: 12,
      blocks: [
        { t: 'table', head: ['Model', 'Credit', 'Best for'], rows: [
          ['First Touch', '100% to the first campaign', 'Lead generation'],
          ['Last Touch', '100% to the campaign before close', 'Conversion influence'],
          ['Even Distribution', 'Equal credit across all campaigns', 'Balanced view'],
          ['Time-Decay', 'More credit to campaigns closer to close', 'Complex B2B cycles'],
        ]},
        { t: 'p', x: `Enable in Setup → Campaign Influence Settings. The CampaignService and OpportunityCampaignTrigger in this repo simulate attribution by attaching won account contacts to campaigns and computing ROI fields.` },
        { t: 'selfcheck', q: `An email campaign + trade show both touched a won deal. Which model splits credit 50/50?`, a: `Even Distribution — equal credit across all touching campaigns.` },
      ]
    },
    {
      title: 'Campaign ROI', mins: 10,
      blocks: [
        { t: 'table', head: ['Metric', 'Formula'], rows: [
          ['ROI', '(Revenue − Cost) / Cost × 100'],
          ['Cost per Lead', 'Total Cost / Total Members'],
          ['Conversion Rate', 'Members who became Opps / Total Members'],
          ['Pipeline Generated', 'SUM of influenced opportunity amounts'],
          ['Revenue Generated', 'SUM of Closed Won influenced amounts'],
        ]},
        { t: 'p', x: `CampaignService computes Conversion_Rate__c, ROI__c and Cost_Per_Lead__c — the KPIs behind the Campaign Performance reports.` },
        { t: 'selfcheck', q: `A campaign spent $10k and produced $40k of revenue. ROI?`, a: `((40k − 10k) / 10k) × 100 = 300%.` },
      ]
    },
  ],
  quiz: {
    title: 'Phase 5 Quiz · Campaigns & Marketing', mins: 5,
    questions: [
      { q: `Which object links a Contact to multiple campaigns?`,
        opts: [`CampaignMember`, `CampaignInfluence`, `OpportunityLineItem`, `CampaignOwner`], a: 0, why: `CampaignMember is the many-to-many junction between Campaigns and Contacts/Leads.` },
      { q: `A company wants full credit attributed to whichever campaign first touched a lead. Model?`,
        opts: [`Last Touch`, `Even Distribution`, `First Touch`, `Time-Decay`], a: 2, why: `First Touch gives 100% credit to the earliest campaign — good for lead-gen measurement.` },
      { q: `ROI formula is…`,
        opts: [`Cost / Revenue`, `(Revenue − Cost) / Cost × 100`, `Revenue − Cost`, `Revenue × Cost`], a: 1, why: `ROI = (Revenue − Cost)/Cost × 100.` },
      { q: `Cost per lead for $20k spend and 500 members?`,
        opts: [`$40`, `$200`, `$0.04`, `$100`], a: 0, why: `20,000 / 500 = $40 per lead.` },
      { q: `Which trigger attaches won deal contacts back to campaigns for attribution?`,
        opts: [`OpportunityCampaignTrigger`, `TaskActivityTrigger`, `AccountTrigger`, `LeadTrigger`], a: 0, why: `OpportunityCampaignTrigger → CampaignService handles attribution & ROI on close.` },
    ]
  }
},

/* ─────────────────────────── PHASE 6 ─────────────────────────── */
{
  id: 'collab', n: 6, title: 'Sales Collaboration', icon: '💬', color: '#06B6D4',
  tagline: 'Activities, follow-ups, Chatter & email',
  guide: '06-collaboration.md',
  art: [
    { label: 'ActivityService', href: 'force-app/main/default/classes/ActivityService.cls' },
    { label: 'TaskActivityTrigger', href: 'force-app/main/default/triggers/TaskActivityTrigger.trigger-meta.xml' },
    { label: 'Deal_Close_Chatter_Notification flow', href: 'force-app/main/default/flows/Deal_Close_Chatter_Notification.flow-meta.xml' },
    { label: 'Activity custom fields (Task/Event)', href: 'force-app/main/default/objects/Task/' },
  ],
  objectives: [
    'Track Tasks & Events and use the activity timeline',
    'Configure activity settings and definitions',
    'Use Chatter for team collaboration',
    'Integrate email (Inbox, Gmail, Outlook)',
    'Automate follow-ups and notifications',
  ],
  lessons: [
    {
      title: 'Tasks & Events', mins: 8,
      blocks: [
        { t: 'p', x: `Activities are the interactions your team logs: calls, meetings, emails, and to-dos.` },
        { t: 'table', head: ['Activity', 'It is', 'Key fields'], rows: [
          ['Task', 'A to-do with a due date', 'Subject, Status, Priority, Due Date, Assigned To'],
          ['Event', 'A calendar item with times', 'Subject, Start/End, Location, Related To'],
        ]},
        { t: 'p', x: `WhoId = the person (Contact/Lead); WhatId = the record (Account/Opportunity). The Activity Timeline on a record shows past (gray), upcoming (blue) and overdue (red) activities.` },
        { t: 'selfcheck', q: `Overdue tasks appear in what color in the activity timeline?`, a: `Red.` },
      ]
    },
    {
      title: 'Activity Configuration', mins: 8,
      blocks: [
        { t: 'num', items: [
          `Setup → Activity Settings: enable Activity Metrics, recurring events, drag-and-drop`,
          `Add rollup fields: Tasks Open, Tasks Completed, Events This Month, Last Activity Date`,
          `Setup → Activity Definitions: create Discovery Call, Demo, Proposal Sent, Contract Review, Follow-Up`,
        ]},
        { t: 'callout', kind: 'tip', x: `Activity rollups on Opportunity give managers a pulse on rep engagement.` },
      ]
    },
    {
      title: 'Chatter & Email', mins: 12,
      blocks: [
        { t: 'p', x: `Chatter is Salesforce's internal social layer. Every record has a feed for posts, @mentions, file sharing and following.` },
        { t: 'table', head: ['Group type', 'Visibility'], rows: [
          ['Public', 'Anyone in the org can join'],
          ['Private', 'Invitation only'],
          ['Unlisted', 'Hidden, invite-only'],
        ]},
        { t: 'p', x: `Email: Salesforce Inbox logs, tracks opens/clicks, uses templates and schedules sends. Gmail/Outlook integrations sync and log emails with one click.` },
        { t: 'selfcheck', q: `Follow key accounts so you're notified when something changes. True or false?`, a: `True — Chatter following pushes record updates into the feed.` },
      ]
    },
    {
      title: 'Activity Automation', mins: 12,
      blocks: [
        { t: 'p', x: `ActivityService is the logic layer that TaskActivityTrigger delegates to.` },
        { t: 'code', lang: 'apex', x: `public class ActivityService {
    public static void createFollowUpTask(Id oppId, String subject) {
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Id = :oppId];
        insert new Task(
            Subject = subject,
            Status = 'Not Started',
            Priority = 'Normal',
            WhatId = oppId,
            OwnerId = opp.OwnerId,
            ActivityDate = Date.today().addDays(3)
        );
    }
}` },
        { t: 'p', x: `Deal_Close_Chatter_Notification posts to the record feed when a deal closes — a perfect record-triggered Flow example.` },
        { t: 'selfcheck', q: `Which trigger in this repo generates a follow-up task when the parent activity completes?`, a: `TaskActivityTrigger → ActivityService.` },
      ]
    },
  ],
  quiz: {
    title: 'Phase 6 Quiz · Sales Collaboration', mins: 5,
    questions: [
      { q: `A meeting with start/end times is stored as…`,
        opts: [`A Task`, `An Event`, `A Chatter post`, `An Email`], a: 1, why: `Events are calendar items with start/end; Tasks are to-dos.` },
      { q: `A phone discovery call with no deadline is best logged as…`,
        opts: [`A Task`, `An Event with times`, `A Campaign member`, `A Lead`], a: 0, why: `Tasks handle calls/emails that need a due date but not a scheduled time.` },
      { q: `WhoId vs WhatId: WhoId typically references…`,
        opts: [`The record (Account/Opportunity)`, `The person (Contact/Lead)`, `The User's role`, `A Campaign`], a: 1, why: `WhoId = person; WhatId = the related record.` },
      { q: `Completing "Discovery Call" should auto-create "Send follow-up email". Best tool?`,
        opts: [`Validation rule`, `Record-Triggered Flow on Task`, `Report`, `Queue`], a: 1, why: `A flow triggers when the task's status flips to Complete and creates the follow-up.` },
      { q: `Which Chatter group type is invite-only and hidden?`,
        opts: [`Public`, `Private`, `Unlisted`, `Open`], a: 2, why: `Unlisted = hidden + invite-only; Private = visible but by invitation.` },
    ]
  }
},

/* ─────────────────────────── PHASE 7 ─────────────────────────── */
{
  id: 'proc', n: 7, title: 'Processes & Automation', icon: '⚙️', color: '#F97316',
  tagline: 'Approvals, Flows & automation best practice',
  guide: '07-processes-automation.md',
  art: [
    { label: 'ProcessAutomationService', href: 'force-app/main/default/classes/ProcessAutomationService.cls' },
    { label: 'Opportunity_Discount_Approval', href: 'force-app/main/default/approvalProcesses/Opportunity_Discount_Approval.approvalProcess-meta.xml' },
    { label: 'Auto_Close_Stale_Opportunities flow', href: 'force-app/main/default/flows/Auto_Close_Stale_Opportunities.flow-meta.xml' },
    { label: 'Weekly_Pipeline_Summary_Email flow', href: 'force-app/main/default/flows/Weekly_Pipeline_Summary_Email.flow-meta.xml' },
  ],
  objectives: [
    'Design approval processes for discounts & exceptions',
    'Configure assignment rules for leads & cases',
    'Build record-triggered and scheduled flows',
    'Migrate Process Builder / Workflow to Flow',
  ],
  lessons: [
    {
      title: 'Approval Processes', mins: 12,
      blocks: [
        { t: 'p', x: `Approval processes route records through a chain of approvers. Classic use case: big discounts need sign-off.` },
        { t: 'table', head: ['Setting', 'Example'], rows: [
          ['Entry Criteria', 'Amount > $50,000 AND Discount > 20%'],
          ['Step 1', 'Sales Manager (role approver)'],
          ['Step 2', 'VP Sales if Amount > $100k or Discount > 30%'],
          ['Final approval action', 'Set Status = Approved'],
          ['Final rejection action', 'Set Status = Rejected'],
        ]},
        { t: 'p', x: `This repo ships Opportunity_Discount_Approval, and ProcessAutomationService reads pending instances via the ProcessInstance Apex API.` },
        { t: 'selfcheck', q: `Where do you configure the discount threshold that triggers approval?`, a: `In the approval process Entry Criteria — e.g. AMOUNT > 50000 AND DISCOUNT_PERCENTAGE > 20.` },
      ]
    },
    {
      title: 'Assignment Rules', mins: 8,
      blocks: [
        { t: 'code', lang: 'text', x: `Rule 1 "Enterprise": AnnualRevenue > $1M    → Enterprise Queue
Rule 2 "Technology":  Industry = Technology → Tech Queue
Rule 3 "West Coast":  State IN (CA,WA,OR)    → West Coast Team
Default                                → Sales General Queue` },
        { t: 'p', x: `Assignment rules work for Leads AND Cases. The repo's Lead.assignmentRules routes by industry. Case rules use Priority/Product/Subject-containment.` },
        { t: 'selfcheck', q: `If no rule entry matches a lead, what happens?`, a: `The default rule entry runs (usually a general queue).` },
      ]
    },
    {
      title: 'Record-Triggered Flows', mins: 14,
      blocks: [
        { t: 'p', x: `Flows are the modern successor to Workflow Rules and Process Builder.` },
        { t: 'code', lang: 'text', x: `Flow: Auto-set close date on stage change (Before Save)
  IF Prospecting           → CloseDate = TODAY + 90
  IF Qualification         → CloseDate = TODAY + 60
  IF Proposal/Price Quote  → CloseDate = TODAY + 30
  IF Negotiation/Review    → CloseDate = TODAY + 14` },
        { t: 'p', x: `Auto_Create_Child_Records_On_Account is an After-Save flow creating default contacts + a welcome task. Deal_Close_Chatter_Notification posts to the feed on won deals.` },
        { t: 'callout', kind: 'warn', x: `Use Before-Save flows when possible (no extra DML). Use After-Save when you need to create child records or launch actions.` },
        { t: 'selfcheck', q: `A flow typing the same close-date logic on a before-save decision: where does the decision element run?`, a: `Before the record is committed — the flow updates fields in memory, no extra DML.` },
      ]
    },
    {
      title: 'Scheduled Flows & Migration', mins: 10,
      blocks: [
        { t: 'p', x: `Scheduled flows run on a schedule (e.g., every Monday 8 AM) to do batch work.` },
        { t: 'code', lang: 'text', x: `Flow: Auto-Close Stale Opportunities (scheduled)
  Criteria: Stage NOT IN (Won, Lost) AND LastActivityDate < TODAY-30
  Action:   Stage = Closed Lost, note in Description` },
        { t: 'table', head: ['Process Builder', 'Flow Builder'], rows: [
          ['Record Update', 'Update Records element'],
          ['Send Email', 'Send Email action'],
          ['Post to Chatter', 'Post to Chatter action'],
          ['Submit for Approval', 'Submit for Approval action'],
          ['Launch a Flow', 'Subflow element'],
        ]},
        { t: 'callout', kind: 'tip', x: `Migration: identify → recreate in Flow → test in sandbox → deactivate PB → activate Flow.` },
      ]
    },
  ],
  quiz: {
    title: 'Phase 7 Quiz · Processes & Automation', mins: 5,
    questions: [
      { q: `A discount beyond 20% needs manager sign-off. Best feature?`,
        opts: [`Validation rule`, `Approval process`, `Scheduled flow`, `Report`], a: 1, why: `Approval processes are human-in-the-loop workflows with step-by-step approvers.` },
      { q: `A flow that updates a field in memory before the record saves should be…`,
        opts: [`After-Save`, `Before-Save`, `Scheduled`, `Screen`], a: 1, why: `Before-Save flows avoid extra DML — ideal for field updates.` },
      { q: `To auto-close stale opportunities every Monday you'd build a…`,
        opts: [`Screen flow`, `Scheduled flow`, `Validation rule`, `Approval step`], a: 1, why: `Scheduled flows run on a recurring schedule for batch maintenance.` },
      { q: `Which replacement element covers Process Builder's "Record Update"?`,
        opts: [`Update Records element`, `Post to Chatter action`, `Subflow`, `Decision`], a: 0, why: `The Update Records element is the modern equivalent.` },
      { q: `No rule entry matches an inbound lead. Then…`,
        opts: [`It's orphaned with no owner`, `The default rule entry applies`, `It's auto-converted`, `It becomes a Case`], a: 1, why: `Assignment rules always have a default entry for the catch-all path.` },
    ]
  }
},

/* ─────────────────────────── PHASE 8 ─────────────────────────── */
{
  id: 'forecast', n: 8, title: 'Forecasting & Territories', icon: '🎯', color: '#8B5CF6',
  tagline: 'Weighted forecast, quotas, territory routing',
  guide: '08-forecasting-territories.md',
  art: [
    { label: 'ForecastingService', href: 'force-app/main/default/classes/ForecastingService.cls' },
    { label: 'OpportunityForecastTrigger', href: 'force-app/main/default/triggers/OpportunityForecastTrigger.trigger-meta.xml' },
    { label: 'Quota__c', href: 'force-app/main/default/objects/Quota__c.object-meta.xml' },
    { label: 'Territory__c', href: 'force-app/main/default/objects/Territory__c.object-meta.xml' },
  ],
  objectives: [
    'Explain forecast categories & hierarchy',
    'Configure and report on forecasts',
    'Set up quotas & compute attainment',
    'Build territory models and alignment',
  ],
  lessons: [
    {
      title: 'Forecast Categories', mins: 8,
      blocks: [
        { t: 'table', head: ['Category', 'Meaning', 'Typical stages'], rows: [
          ['Pipeline', 'Early-stage deals', 'Prospecting, Qualification'],
          ['Best Case', 'Deals likely to close', 'Needs Analysis, Proposal'],
          ['Commit', 'Deals expected to close', 'Negotiation, Verbal'],
          ['Closed', 'Won deals', 'Closed Won'],
          ['Omitted', 'Excluded', 'Closed Lost, On Hold'],
        ]},
        { t: 'callout', kind: 'tip', x: `Collaboration Forecasts roll up the hierarchy: reps enter amounts, managers see everything below them, execs see the org.` },
      ]
    },
    {
      title: 'Quotas', mins: 10,
      blocks: [
        { t: 'p', x: `Quotas define revenue targets per user/team and period. This repo models them with the custom Quota__c object (User__c, Amount__c, Period_Start/End).` },
        { t: 'code', lang: 'text', x: `Attainment % = (Actual Revenue / Quota Amount) × 100` },
        { t: 'code', lang: 'apex', x: `// ForecastingService — quota attainment per user
for (AggregateResult ar : [
    SELECT OwnerId, SUM(Amount) rev
    FROM Opportunity
    WHERE StageName = 'Closed Won'
      AND CloseDate >= :quarterStart AND CloseDate <= :quarterEnd
    GROUP BY OwnerId
]) { ... }

for (Quota__c q : [SELECT User__c, Amount__c FROM Quota__c WHERE User__c IN :userIds]) {
    Decimal rev = revenueByUser.get(q.User__c);
    attainment.put(q.User__c, (rev / q.Amount__c) * 100);
}` },
        { t: 'selfcheck', q: `A rep's quota is $500k and revenue is $350k. Attainment?`, a: `(350k / 500k) × 100 = 70%.` },
      ]
    },
    {
      title: 'Territory Management', mins: 12,
      blocks: [
        { t: 'p', x: `Territories assign accounts to reps based on rules (geographic, industry, named, product).` },
        { t: 'code', lang: 'text', x: `Global Model
├── North America
│   ├── East Region (Northeast, Southeast)
│   └── West Region (West Coast, Mountain)
├── EMEA  (UK, DACH)
└── APAC  (Australia, Japan)` },
        { t: 'list', items: [
          `Create a Territory Model (draft)`,
          `Add territories + assignment rules`,
          `Run alignment to auto-assign accounts`,
          `Review, adjust, then activate the model`,
        ]},
        { t: 'selfcheck', q: `Where do you place BillingState = CA, WA, OR with owner West Coast Team?`, a: `In a territory assignment rule under the West Region of your territory model.` },
      ]
    },
  ],
  quiz: {
    title: 'Phase 8 Quiz · Forecasting & Territories', mins: 5,
    questions: [
      { q: `A deal in Negotiation/Review typically maps to which forecast category?`,
        opts: [`Pipeline`, `Commit`, `Omitted`, `Closed`], a: 1, why: `Commit = deals expected to close (negotiation, verbal agreement).` },
      { q: `Quota attainment $450k on a $500k quota is…`,
        opts: [`90%`, `85%`, `110%`, `50%`], a: 0, why: `450/500 × 100 = 90%.` },
      { q: `Forecast roll-up is based on…`,
        opts: [`Role hierarchy`, `Report folders`, `Public groups`, `Price books`], a: 0, why: `Forecast hierarchies mirror the role hierarchy: managers see their team's forecast.` },
      { q: `Which field type drives most territory rules?`,
        opts: [`Currency`, `Geographic fields (BillingState/Country)`, `Formula`, `Description`], a: 1, why: `Territory rules usually evaluate location, industry or named accounts.` },
      { q: `A scheduled run evaluates "attainment < 50% with <30 days left" and alerts the manager. This is…`,
        opts: [`A Flow that uses Quota__c + Opportunity data`, `A validation rule`, `An approval step`, `A dashboard filter`], a: 0, why: `Scheduled flows combine quota records and opportunity totals to alert managers.` },
    ]
  }
},

/* ─────────────────────────── PHASE 9 ─────────────────────────── */
{
  id: 'report', n: 9, title: 'Reporting & Dashboards', icon: '📈', color: '#14B8A6',
  tagline: 'Report types, dashboards & KPI design',
  guide: '09-reporting.md',
  art: [
    { label: 'ReportingService', href: 'force-app/main/default/classes/ReportingService.cls' },
    { label: '7 reports', href: 'force-app/main/default/reports/' },
    { label: '4 dashboards', href: 'force-app/main/default/dashboards/' },
    { label: 'Report-ready SOQL (scripts/soql)', href: 'scripts/soql/' },
  ],
  objectives: [
    'Create standard & custom report types',
    'Build reports with grouping, filters & formulas',
    'Design dashboards that tell a story',
    'Schedule & share reports',
  ],
  lessons: [
    {
      title: 'Report Types', mins: 8,
      blocks: [
        { t: 'p', x: `A Report Type defines which objects and fields a report can include.` },
        { t: 'table', head: ['Type', 'Objects'], rows: [
          ['Accounts & Contacts', 'Account + Contact'],
          ['Opportunities with Account', 'Opportunity + Account'],
          ['Activities', 'Task + Event'],
          ['Campaigns & Leads', 'Campaign + CampaignMember + Lead'],
        ]},
        { t: 'p', x: `Custom: Setup → Report Types → New. Primary = main object; secondary/tertiary = related objects (inner join — records must have related rows).` },
      ]
    },
    {
      title: 'Report Builder', mins: 12,
      blocks: [
        { t: 'table', head: ['Format', 'Use'], rows: [
          ['Tabular', 'Simple table, no grouping'],
          ['Summary', 'Grouped by one or more fields'],
          ['Matrix', 'Grouped by rows AND columns (pivot)'],
          ['Joined', 'Combine multiple reports in one view'],
        ]},
        { t: 'list', items: [
          `Grouping: row = StageName, column = close quarter`,
          `Filters: field, date (THIS_QUARTER), logic (1 AND 2), cross-filter (haves/not haves), relative (LAST_30_DAYS)`,
          `Formulas: Row Count, custom summary, bucket fields`,
          `Bucket fields categorize without new fields (Small/Medium/Large/Enterprise deals)` ,
        ]},
        { t: 'selfcheck', q: `You want to pivot opportunities by stage across quarters. Which format?`, a: `Matrix — groups by rows and columns.` },
      ]
    },
    {
      title: 'Essential Sales Reports', mins: 10,
      blocks: [
        { t: 'code', lang: 'text', x: `Pipeline report
  Type: Opportunities with Account
  Group: StageName · Column: Owner
  Filter: Stage NOT IN (Won, Lost)
  Formula: Weighted = Amount × Probability` },
        { t: 'p', x: `Win/Loss adds a Won vs Lost bucket and a win-rate formula. Lead Conversion groups by Lead Source and filters IsConverted = true. All of these exist as real reports in this repo.` },
        { t: 'selfcheck', q: `Which filter would isolate opportunities that HAVE activities?`, a: `A cross-filter (Has Activities) on a report type that includes Tasks/Events.` },
      ]
    },
    {
      title: 'Dashboards', mins: 12,
      blocks: [
        { t: 'table', head: ['Component', 'Best for'], rows: [
          ['Chart', 'Trends & comparisons'],
          ['Metric', 'A single KPI number'],
          ['Gauge', 'Progress toward a goal'],
          ['Table', 'Detailed data rows'],
          ['LWC / Visualforce', 'Custom widgets'],
        ]},
        { t: 'list', items: [
          `Executive view: 4–6 top KPIs only`,
          `Manager view: team performance with drill-down`,
          `Rep view: personal pipeline & activities`,
          `Dynamic dashboards let each viewer be the "running user" — great for manager → rep self-service`,
        ]},
        { t: 'callout', kind: 'tip', x: `Add dashboard filters (Region, Time Period) to slice data without building 10 dashboards.` },
      ]
    },
  ],
  quiz: {
    title: 'Phase 9 Quiz · Reporting & Dashboards', mins: 5,
    questions: [
      { q: `A pivot-style report grouped by rows AND columns is a…`,
        opts: [`Tabular report`, `Matrix report`, `Joined report`, `Summary report`], a: 1, why: `Matrix = grouped by rows (Stage) and columns (Quarter).` },
      { q: `Which report structure lets two separate reports be combined?`,
        opts: [`Joined report`, `Bucket field`, `Cross filter`, `Scheduled report`], a: 0, why: `Joined reports blend multiple report blocks in one view.` },
      { q: `You want to group $0–25k, $25–100k, $100k+ without new fields. Use a…`,
        opts: [`Bucket field`, `Formula field`, `Roll-up summary`, `Picklist`], a: 0, why: `Bucket fields categorize numeric values into ranges.` },
      { q: `A gauge showing progress toward target revenue is best built as…`,
        opts: [`A dashboard gauge component`, `A tabular report`, `A joined report`, `A canvas app`], a: 0, why: `Gauge components visualize progress toward a goal.` },
      { q: `Which report type includes Campaign, CampaignMember and Lead?`,
        opts: [`Campaigns & Leads`, `Opportunities with Account`, `Activities`, `Leads`], a: 0, why: `Campaigns & Leads spans the campaign funnel.` },
    ]
  }
},

/* ─────────────────────────── PHASE 10 ─────────────────────────── */
{
  id: 'adv', n: 10, title: 'Advanced & Integrations', icon: '🧩', color: '#6366F1',
  tagline: 'REST/API patterns, platform events, metadata',
  guide: '10-advanced.md',
  art: [
    { label: 'IntegrationService', href: 'force-app/main/default/classes/IntegrationService.cls' },
    { label: 'Integration_Log__c', href: 'force-app/main/default/objects/Integration_Log__c.object-meta.xml' },
    { label: 'Integration_Event__e', href: 'force-app/main/default/platformEvents/Integration_Event__e.platformEvent-meta.xml' },
    { label: 'API_Configuration__mdt', href: 'force-app/main/default/customMetadata/' },
  ],
  objectives: [
    'Understand CPQ concepts',
    'Call external APIs from Apex (REST)',
    'Publish & subscribe platform events',
    'Use Change Data Capture for sync',
    'Plan sandboxes & deployment pipelines',
  ],
  lessons: [
    {
      title: 'CPQ & Einstein', mins: 10,
      blocks: [
        { t: 'p', x: `CPQ (Configure-Price-Quote) extends standard quotes with product bundles, configuration/pricing rules and automated contract generation.` },
        { t: 'list', items: [
          `Einstein Opportunity Scoring: 1–99 score predicting deal outcome`,
          `Einstein Activity Capture: auto-log emails & calendar events`,
          `Einstein Lead Scoring: conversion-probability for leads`,
          `Einstein Forecasting: adjusted forecasts with confidence intervals`,
        ]},
        { t: 'selfcheck', q: `Which Einstein feature predicts whether a specific deal will close?`, a: `Einstein Opportunity Scoring.` },
      ]
    },
    {
      title: 'REST from Apex', mins: 14,
      blocks: [
        { t: 'code', lang: 'apex', x: `public class ExternalApiService {
    public static String call(String endpoint, String method, String body) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + getToken());
        req.setBody(body);
        req.setTimeout(10000);

        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) return res.getBody();
        throw new CalloutException('API error: ' + res.getStatusCode());
    }
}` },
        { t: 'p', x: `Secure endpoints with Named Credentials: ` + '`request.setEndpoint(\'callout:My_Credential/api/data\')`' + ` — never hard-code tokens. IntegrationService reads API_Configuration__mdt for endpoints, headers and timeouts, and logs every call to Integration_Log__c with retry logic.` },
        { t: 'selfcheck', q: `How do you keep API tokens out of source code?`, a: `Named Credentials (OAuth stored at runtime) — callout:my_Credential/…` },
      ]
    },
    {
      title: 'Platform Events', mins: 12,
      blocks: [
        { t: 'code', lang: 'apex', x: `// Publish
DealUpdate__e evt = new DealUpdate__e(
    OpportunityId__c = opp.Id,
    NewStage__c = opp.StageName,
    Amount__c = opp.Amount
);
EventBus.publish(evt);` },
        { t: 'p', x: `Subscribers react via a trigger on the event object. Events decouple producers from consumers — ideal for async integrations. This repo ships Integration_Event__e published by IntegrationService.` },
        { t: 'selfcheck', q: `Which API lets an external client subscribe to platform events in real time?`, a: `Streaming API (CometD) — subscribe to /event/<Channel>` },
      ]
    },
    {
      title: 'CDC, Sandboxes & Deployments', mins: 12,
      blocks: [
        { t: 'p', x: `Change Data Capture (CDC) publishes change events with fields like ChangeType (CREATED/UPDATED/DELETED), ChangedFields and CommitUser.` },
        { t: 'table', head: ['Sandbox', 'Data'], rows: [
          ['Developer', 'Metadata only'],
          ['Developer Pro', 'Metadata + some data'],
          ['Partial Copy', 'Metadata + sample data'],
          ['Full', 'Complete copy'],
        ]},
        { t: 'code', lang: 'text', x: `Developer → Developer Pro → Partial Copy → Production
   (dev)        (integration)      (UAT)        (release)` },
        { t: 'callout', kind: 'warn', x: `Never develop directly in Production. Keep metadata in Git, test in lower environments, use scratch orgs for features, automate with CI/CD.` },
      ]
    },
  ],
  quiz: {
    title: 'Phase 10 Quiz · Advanced & Integrations', mins: 5,
    questions: [
      { q: `Where should credentials for an external API live?`,
        opts: [`Hard-coded in Apex`, `A Named Credential`, `A Picklist`, `An attachment`], a: 1, why: `Named Credentials store auth at runtime and support callout:my_Credential endpoints.` },
      { q: `Which platform event is included in this repo?`,
        opts: [`Integration_Event__e`, `DealUpdate__e`, `Order_Change__e`, `SimpleCampaignEvent`], a: 0, why: `IntegrationService publishes Integration_Event__e after external calls.` },
      { q: `CDC ChangeType = UPDATED means…`,
        opts: [`A record was created`, `A record was modified`, `A record was deleted`, `A record was queried`], a: 1, why: `CREATED/UPDATED/DELETED/UNDELETE describe the change.` },
      { q: `To test a feature with production-like volume you'd use…`,
        opts: [`A Developer sandbox`, `A Full copy sandbox`, `A scratch org`, `Production directly`], a: 1, why: `Full sandboxes mirror production data for performance/UAT.` },
      { q: `Apex consumes REST endpoints and logs every call. Which object holds the audit trail?`,
        opts: [`Integration_Log__c`, `Account`, `Quota__c`, `Certification_Question__c`], a: 0, why: `Integration_Log__c stores system, direction, status, response code and error details.` },
    ]
  }
},

/* ─────────────────────────── PHASE 11 ─────────────────────────── */
{
  id: 'cert', n: 11, title: 'Certification Prep', icon: '🎓', color: '#EF4444',
  tagline: 'Admin & Sales Cloud Consultant blueprint',
  guide: '11-certification-prep.md',
  art: [
    { label: 'CertificationPrepService', href: 'force-app/main/default/classes/CertificationPrepService.cls' },
    { label: 'Certification_Question__c', href: 'force-app/main/default/objects/Certification_Question__c.object-meta.xml' },
    { label: 'Certification_Study_Plan__c', href: 'force-app/main/default/objects/Certification_Study_Plan__c.object-meta.xml' },
    { label: 'Capstone project', href: 'salesCloud%20Roadmap/11-certification-prep.md' },
  ],
  objectives: [
    'Know the exam blueprints & passing scores',
    'Map phase topics to exam domains',
    'Practice exam-style scenario questions',
    'Memorize key formulas & governor limits',
    'Build the end-to-end capstone',
  ],
  lessons: [
    {
      title: 'Exam Blueprints', mins: 8,
      blocks: [
        { t: 'table', head: ['', 'Administrator (ADM-201)', 'Sales Cloud Consultant (CON-401)'], rows: [
          ['Questions', '60 MCQ', '60 MCQ'],
          ['Time', '105 min', '105 min'],
          ['Passing', '65%', '65%'],
          ['Prereq', '—', 'Administrator credential'],
        ]},
        { t: 'p', x: `Admin topics: Configuration & Setup (20%), Object Manager & LEX (20%), Security (15%), Automation (13%), Standard/Custom Objects (14%), Data & Analytics (11%), User Management (7%).` },
        { t: 'p', x: `Consultant topics are scenario-based: Lead Mgmt (12%), Opportunity (14%), Account/Contact (13%), Implementation (14%), Security (12%), Sales Cloud Apps (12%), Analytics (11%).` },
      ]
    },
    {
      title: 'Scenario Practice', mins: 14,
      blocks: [
        { t: 'p', x: `Consultant questions are role-play. Practice the "Salesforce way": pick the most declarative, scalable, standard tool.` },
        { t: 'selfcheck', q: `Leads from a website should auto-route by industry to queues. Feature?`, a: `Lead Assignment Rules — designed exactly for criteria-based routing.` },
        { t: 'selfcheck', q: `Reps can't see the Annual Revenue field (it's on the layout). Check first?`, a: `Field-Level Security — FLS hides fields even when they're on the layout.` },
        { t: 'selfcheck', q: `Track which campaigns influenced closed deals?`, a: `Campaign Influence models (First/Last/Even/Time-Decay attribution).` },
      ]
    },
    {
      title: 'Formulas & Limits to Know', mins: 12,
      blocks: [
        { t: 'table', head: ['Formula', 'Use'], rows: [
          ['ISPICKVAL(f,\'V\')', 'Picklist equality'],
          ['ISCHANGED(f) / PRIORVALUE(f)', 'Detect / read previous value'],
          ['ISNEW()', 'New record?'],
          ['ISBLANK(f)', 'Empty?'],
          ['CONTAINS(f,\'text\')', 'Substring check'],
          ['AND/OR/NOT/IF', 'Boolean logic'],
        ]},
        { t: 'table', head: ['Governor', 'Value'], rows: [
          ['SOQL queries per txn', '100'],
          ['SOQL rows returned', '50,000'],
          ['DML statements per txn', '150'],
          ['DML rows per txn', '10,000'],
          ['Roll-up summary fields / object', '10'],
          ['Master-detail / object', '2'],
          ['Custom fields / object', '500'],
        ]},
      ]
    },
    {
      title: 'The Capstone Project', mins: 20,
      blocks: [
        { t: 'p', x: `Rebuild the whole roadmap for a fictional B2B company ("TechNova Solutions") from scratch.` },
        { t: 'list', items: [
          `Lead capture from web/events/referrals + industry routing + scoring`,
          `Account parent-child hierarchy, teams, contact roles`,
          `3 sales processes (New Business, Renewal, Expansion) + price books`,
          `Campaigns with influence + ROI reporting`,
          `Approval for discounts > 20%, flows for close dates, scheduled stale cleanup`,
          `Pipeline, win-rate, quota attainment & campaign dashboards`,
          `Permission sets + test classes with 75%+ coverage`,
        ]},
        { t: 'callout', kind: 'tip', x: `Use Certification_Question__c as a mini question bank and CertificationPrepService as your practice quiz engine.` },
      ]
    },
  ],
  quiz: {
    title: 'Phase 11 Quiz · Certification Prep', mins: 5,
    questions: [
      { q: `Passing score for ADM-201?`,
        opts: [`50%`, `60%`, `65%`, `75%`], a: 2, why: `Administrator and Sales Cloud Consultant both require 65% (60 questions, 105 minutes).` },
      { q: `A manager can't see the Annual Revenue field though it's on the layout. First check?`,
        opts: [`Profile tab visibility`, `Field-Level Security`, `Page layout order`, `CRUD permissions`], a: 1, why: `FLS is the classic A1 answer — field hidden despite layout presence.` },
      { q: `Which is NOT a forecast category?`,
        opts: [`Pipeline`, `Best Case`, `Commit`, `Execute`], a: 3, why: `Categories: Pipeline, Best Case, Commit, Closed, Omitted.` },
      { q: `When two validation rules disagree, which one wins?`,
        opts: [`The first alphabetically`, `They're all enforced — each blocks its condition`, `The last created`, `The one on the master object`], a: 1, why: `All validation rules run; any true (error) condition blocks the save.` },
      { q: `A scenario states "which solution will scale with the org's growth?" Best answer style:`,
        opts: [`A hard-coded Apex workaround`, `The standard declarative feature`, `A custom LWC for everything`, `Skipping automation`], a: 1, why: `Consultant questions reward standard, declarative, maintainable solutions.` },
    ]
  }
},

];

/* Value sub-question for aggregate purpose? no-op */
ACADEMY.forEach(m => {
  m.total = m.lessons.length;
  m.quizTotal = m.quiz.questions.length;
});