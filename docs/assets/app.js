/* =============================================================================
 * Sales Cloud RoadMap — Interactive Architecture UI
 * Renders layered overview, data model, trigger→service wiring, sales flow,
 * integrations, and the phase map. Everything is generated client-side from
 * the DATA registry below, so the UI always describes the real repo.
 * ============================================================================= */

/* -------------------------------------------------------------------------
 * DATA — single source of truth for every interactive component.
 * ------------------------------------------------------------------------- */

const PHASES = [
  { n: 1, t: 'Fundamentals', topic: 'Platform, data model, security', guide: '01-fundamentals.md', art: ['PermSet Sales_Cloud_User', 'Custom fields (Account/Contact/Lead/Opportunity)', 'SalesCloudFundamentalsTest'] },
  { n: 2, t: 'Lead Management', topic: 'Capture, scoring, assignment, conversion', guide: '02-lead-management.md', art: ['LeadTrigger', 'LeadScoringService', 'Assignment Rules', 'Lead_Scoring_Flow / Nurture flows'] },
  { n: 3, t: 'Accounts & Contacts', topic: 'Hierarchy, roll-ups, teams, health score', guide: '03-accounts-contacts.md', art: ['AccountService', 'AccountTrigger', 'OpportunityTrigger', 'Auto_Create_Child_Records_On_Account'] },
  { n: 4, t: 'Opportunity Management', topic: 'Stages, pipeline, products, quotes', guide: '04-opportunity-management.md', art: ['OpportunityService', 'OpportunityStageTrigger', 'Validation Rules', 'Auto_Assign_Tasks_New_Opportunity'] },
  { n: 5, t: 'Campaigns & Marketing', topic: 'Campaign influence model, ROI', guide: '05-campaigns.md', art: ['CampaignService', 'OpportunityCampaignTrigger', 'CampaignMemberStatusTrigger', 'Opportunity.Campaign fields'] },
  { n: 6, t: 'Collaboration', topic: 'Activities, follow-ups, Chatter, email', guide: '06-collaboration.md', art: ['ActivityService', 'TaskActivityTrigger', 'Deal_Close_Chatter_Notification'] },
  { n: 7, t: 'Processes & Automation', topic: 'Approvals, Flows, best practices', guide: '07-processes-automation.md', art: ['ProcessAutomationService', 'Approval Process', 'Auto_Close_Stale_Opportunities', 'Weekly_Pipeline_Summary_Email'] },
  { n: 8, t: 'Forecasting & Territories', topic: 'Forecast hierarchy, territory model', guide: '08-forecasting-territories.md', art: ['ForecastingService', 'OpportunityForecastTrigger', 'Quota__c', 'Territory__c'] },
  { n: 9, t: 'Reporting & Dashboards', topic: 'Report types, dashboards, KPIs', guide: '09-reporting.md', art: ['ReportingService', '7 Reports', '4 Dashboards'] },
  { n: 10, t: 'Advanced & Integrations', topic: 'API, platform events, metadata', guide: '10-advanced.md', art: ['IntegrationService', 'Integration_Log__c', 'Integration_Event__e', 'API_Configuration__mdt'] },
  { n: 11, t: 'Certification Prep', topic: 'Admin & Sales Cloud Consultant exam', guide: '11-certification-prep.md', art: ['CertificationPrepService', 'Certification_Question__c', 'Certification_Study_Plan__c'] },
];

const TRIGGERS = [
  { id: 'leadTrigger', name: 'LeadTrigger', events: 'before/after insert · after update', svc: 'leadScoring' },
  { id: 'accountTrigger', name: 'AccountTrigger', events: 'after insert', svc: 'accountService' },
  { id: 'opportunityTrigger', name: 'OpportunityTrigger', events: 'after insert/update', svc: 'accountService' },
  { id: 'opportunityStageTrigger', name: 'OpportunityStageTrigger', events: 'before insert/update', svc: 'opportunityService' },
  { id: 'opportunityCampaignTrigger', name: 'OpportunityCampaignTrigger', events: 'after insert/update', svc: 'campaignService' },
  { id: 'campaignMemberStatusTrigger', name: 'CampaignMemberStatusTrigger', events: 'after insert', svc: 'campaignService' },
  { id: 'taskActivityTrigger', name: 'TaskActivityTrigger', events: 'after insert/update', svc: 'activityService' },
  { id: 'opportunityForecastTrigger', name: 'OpportunityForecastTrigger', events: 'before insert/update', svc: 'forecastingService' },
];

const SERVICES = [
  { id: 'leadScoring', name: 'LeadScoringService', duty: 'Scoring, ratings, nurture status' },
  { id: 'accountService', name: 'AccountService', duty: 'Hierarchy, roll-ups, health score' },
  { id: 'opportunityService', name: 'OpportunityService', duty: 'Close dates, stale-close, analytics' },
  { id: 'campaignService', name: 'CampaignService', duty: 'Members, metrics, ROI' },
  { id: 'activityService', name: 'ActivityService', duty: 'Follow-ups, activity metrics' },
  { id: 'processAutomation', name: 'ProcessAutomationService', duty: 'Approvals, emails, automation' },
  { id: 'forecastingService', name: 'ForecastingService', duty: 'Forecast, quotas, territories' },
  { id: 'reportingService', name: 'ReportingService', duty: 'KPIs behind dashboards' },
  { id: 'integrationService', name: 'IntegrationService', duty: 'Logging, retries, webhooks' },
  { id: 'certificationPrep', name: 'CertificationPrepService', duty: 'Question bank, quiz, study plans' },
];

const FLOWS = [
  { id: 'flowScoring', name: 'Lead_Scoring_Flow', phase: 2, kind: 'Screen Flow' },
  { id: 'flowNurture', name: 'Auto_Update_Nurture_Status', phase: 2, kind: 'Record-Triggered' },
  { id: 'flowLeadFollowUp', name: 'Auto_Create_FollowUp_Task_On_Lead_Assignment', phase: 2, kind: 'Record-Triggered' },
  { id: 'flowChildRecords', name: 'Auto_Create_Child_Records_On_Account', phase: 3, kind: 'Record-Triggered' },
  { id: 'flowAssignTasks', name: 'Auto_Assign_Tasks_New_Opportunity', phase: 4, kind: 'Record-Triggered' },
  { id: 'flowChatter', name: 'Deal_Close_Chatter_Notification', phase: 6, kind: 'Record-Triggered' },
  { id: 'flowStale', name: 'Auto_Close_Stale_Opportunities', phase: 7, kind: 'Scheduled' },
  { id: 'flowEmail', name: 'Weekly_Pipeline_Summary_Email', phase: 7, kind: 'Scheduled' },
];

const SURFACE = [
  { id: 'permSet', name: 'Sales_Cloud_User', type: 'Permission Set', phase: 1, desc: 'Granular field + object access (FLS) for Sales Cloud users.' },
  { id: 'approval', name: 'Opportunity_Discount_Approval', type: 'Approval Process', phase: 7, desc: 'Human-in-the-loop sign-off when a discount exceeds the threshold.' },
  { id: 'assignment', name: 'Lead Assignment Rules', type: 'Assignment Rule', phase: 2, desc: 'Routes inbound leads to industry queues (Tech, Enterprise, West Coast...).' },
  { id: 'validation', name: '6 Validation Rules', type: 'Validation', phase: 4, desc: 'Stage-skip guard, closed-deal lock, amount-for-high-probability, close-date required, lead contact info, qualification date.' },
];

const OBJECTS = [
  { group: 'Standard', name: 'Account', icon: '🏢', desc: 'Companies you sell to. Custom fields power hierarchy and health.', fields: ['Industry_Segment__c', 'Health_Score__c', 'Account_Level__c', 'Ultimate_Parent__c', 'Total_Revenue_Won__c', 'Pipeline_Value__c', 'Number_of_Contacts__c', 'Total_Opportunities__c', 'Customer_Since__c', 'Last_Contact_Date__c', 'Last_Won_Opportunity_Date__c'] },
  { group: 'Standard', name: 'Contact', icon: '👤', desc: 'Individual people at those companies, with roles & engagement.', fields: ['Role__c', 'Engagement_Score__c'] },
  { group: 'Standard', name: 'Lead', icon: '🎯', desc: 'Unqualified prospects. Scoring + nurture + qualification before conversion.', fields: ['Lead_Score__c', 'Nurture_Status__c', 'Qualification_Date__c'] },
  { group: 'Standard', name: 'Opportunity', icon: '💼', desc: 'Deals in the pipeline. Stage drives probability, weighted forecast & categories.', fields: ['Discount_Percentage__c', 'Approval_Status__c', 'Territory__c', 'Forecast_Category__c', 'Forecast_Amount__c', 'Weighted_Forecast__c'] },
  { group: 'Standard', name: 'Campaign', icon: '📣', desc: 'Marketing initiatives. Members, responds and revenue feed ROI.', fields: ['Total_Members__c', 'Responded_Members__c', 'Conversion_Rate__c', 'Total_Revenue_Generated__c', 'ROI__c', 'Cost_Per_Lead__c', 'Budget_Used__c'] },
  { group: 'Standard', name: 'CampaignMember', icon: '🧲', desc: 'Junction between Campaign and Contact/Lead (many-to-many).', fields: ['Status (Sent / Responded / Converted)'] },
  { group: 'Standard', name: 'Task', icon: '✅', desc: 'To-dos. WhoId = person, WhatId = record. Auto follow-ups on completion.', fields: ['Activity_Type__c', 'Call_Duration_Minutes__c', 'Outcome__c'] },
  { group: 'Standard', name: 'Event', icon: '📅', desc: 'Calendar meetings with start/end and attendees.', fields: ['Meeting_Type__c', 'Meeting_Notes__c', 'Attendee_Count__c'] },
  { group: 'Standard', name: 'User', icon: '🪪', desc: 'The reps & managers. Territory and quota roll up per user.', fields: ['Sales_Territory__c', 'Forecast_Quota__c'] },
  { group: 'Standard', name: 'Product2 / Pricebook', icon: '📦', desc: 'Catalog + price books + line items (products on an opportunity).', fields: ['OpportunityLineItem: qty × price → Amount'] },
  { group: 'Custom', name: 'Quota__c', icon: '📊', desc: 'Sales targets: user + amount + quarter period.', fields: ['User__c', 'Amount__c', 'Period_Start__c', 'Period_End__c', 'Attainment__c', 'Actual_Revenue__c'] },
  { group: 'Custom', name: 'Territory__c', icon: '🗺️', desc: 'Region definitions with a managing rep.', fields: ['Region__c', 'Territory_Manager__c', 'Active__c'] },
  { group: 'Custom', name: 'Integration_Log__c', icon: '🧾', desc: 'Audit trail for every inbound/outbound API call.', fields: ['System_Name__c', 'Integration_Type__c', 'Direction__c', 'Status__c', 'Request/Response_Body__c', 'Response_Code__c', 'Retry_Count__c', 'Error_Message__c', 'Record_Id__c'] },
  { group: 'Custom', name: 'Certification_Question__c', icon: '❓', desc: 'Mini question bank for study & quizzing.', fields: ['Question_Text__c', 'Option_A..D__c', 'Correct_Answer__c', 'Explanation__c', 'Topic__c', 'Difficulty__c'] },
  { group: 'Custom', name: 'Certification_Study_Plan__c', icon: '📚', desc: 'Per-user study plans with target dates and status.', fields: ['User__c', 'Certification_Type__c', 'Target_Date__c', 'Status__c'] },
  { group: 'Platform', name: 'Integration_Event__e', icon: '⚡', desc: 'Platform event for decoupled, async integration hand-offs.', fields: ['Payload / custom fields'] },
  { group: 'Platform', name: 'API_Configuration__mdt', icon: '🔧', desc: 'Custom metadata: read-only endpoint config consumed by IntegrationService.', fields: ['Endpoint, Headers, Timeout'] },
];

const RELS = [
  { a: 'Account', b: 'Contact', type: '1 — N', note: 'Required parent for child records' },
  { a: 'Account', b: 'Opportunity', type: '1 — N', note: 'Roll-up metrics onto Account' },
  { a: 'Contact', b: 'CampaignMember', type: '1 — N', note: 'Join a campaign' },
  { a: 'Campaign', b: 'CampaignMember', type: '1 — N', note: 'Track member status' },
  { a: 'Lead', b: 'Account / Contact / Opportunity', type: 'convert', note: 'Lead conversion creates all three' },
  { a: 'Opportunity', b: 'OpportunityLineItem', type: '1 — N', note: 'Products on a deal' },
  { a: 'PricebookEntry', b: 'OpportunityLineItem', type: '1 — N', note: 'Pricing line items' },
  { a: 'Product2', b: 'PricebookEntry', type: '1 — N', note: 'Catalog → price book' },
  { a: 'WhoId', b: 'Contact / Lead', type: 'N — 1', note: 'Task / Event person' },
  { a: 'WhatId', b: 'Account / Opportunity', type: 'N — 1', note: 'Task / Event record' },
  { a: 'User', b: 'Quota__c', type: '1 — N', note: 'User__c lookup' },
  { a: 'User', b: 'Territory__c', type: '1 — N', note: 'Territory_Manager__c lookup' },
  { a: 'User', b: 'Certification_Study_Plan__c', type: '1 — N', note: 'Owner of a study plan' },
  { a: 'Any object', b: 'Integration_Log__c', type: '0..1 — N', note: 'Record_Id__c generic reference' },
];

const FLOW_STEPS = [
  { t: 'Lead captured', d: 'Web form creates a Lead; validation demands email or phone.', icon: '🪤' },
  { t: 'Scoring & rating', d: 'LeadTrigger → LeadScoringService sets score, rating and nurture status.', icon: '🔢' },
  { t: 'Queue routing', d: 'Assignment rules hand the lead to the right industry queue.', icon: '🎢' },
  { t: 'Conversion', d: 'Qualified lead becomes Account + Contact + Opportunity.', icon: '🔄' },
  { t: 'Stage management', d: 'OpportunityStageTrigger sets close dates and opens tasks per stage.', icon: '🎚️' },
  { t: 'Campaign influence', d: 'Won deals attach account contacts to campaigns (ROI attribution).', icon: '📣' },
  { t: 'Processes', d: 'Big discounts route through Approval; stale deals auto-close.', icon: '⚙️' },
  { t: 'Activity & Chatter', d: 'Completed tasks spawn follow-ups and high-value Chatter posts.', icon: '💬' },
  { t: 'Win / lose', d: 'Stage flips to Closed Won / Closed Lost.', icon: '🏁' },
  { t: 'Revenue roll-up', d: 'AccountService refreshes revenue + health on the Account.', icon: '🔁' },
  { t: 'Forecast & quota', d: 'ForecastingService computes weighted forecast & attainment.', icon: '🎯' },
  { t: 'Reporting', d: 'ReportingService KPIs feed the 4 dashboards and 7 reports.', icon: '📈' },
];

const INTEG_STEPS = [
  { t: 'External system', d: 'ERP / webhook / REST client initiates a call.', icon: '🖥️' },
  { t: 'IntegrationService', d: 'Normalizes the payload; reads API_Configuration__mdt.', icon: '🧩' },
  { t: 'Success?', d: 'On success → log + notify via platform event.', icon: '✔️' },
  { t: 'Retry logic', d: 'On failure → retry until Retry_Count__c hits the cap.', icon: '🔁' },
  { t: 'Max retries', d: 'Past the cap → custom IntegrationException is raised.', icon: '⛔' },
  { t: 'Audit trail', d: 'Every call lands in Integration_Log__c for ops review.', icon: '🧾' },
];

/* Artifact detail library — every chip/card maps to one of these. */
const DETAILS = {};
[
  ...TRIGGERS.map(t => ({ id: t.id, title: t.name, type: 'Trigger', phase: TRIGGER_PHASE(t.name), icon: t.id === 'leadTrigger' ? '⚡' : '⚡', desc: `${t.events}. Thin event detection that delegates to the service layer.`, files: [`force-app/main/default/triggers/${t.name}.trigger`], related: [t.svc], concepts: ['before/after triggers', 'Trigger.new / Trigger.old', 'bulkification'] })),
  ...SERVICES.map(s => ({ id: s.id, title: s.name, type: 'Apex Service', phase: SERVICE_PHASE(s.id), icon: '🧠', desc: s.duty, files: [`force-app/main/default/classes/${s.name}.cls`, `force-app/main/default/classes/${testFor(s)}.cls`], related: [], concepts: ['with sharing', 'bulk-safe loops', 'unit-testable logic'] })),
].forEach(o => { if (o) DETAILS[o.id] = o; });

function TRIGGER_PHASE(name) {
  return { LeadTrigger: 2, AccountTrigger: 3, OpportunityTrigger: 3, OpportunityStageTrigger: 4, OpportunityCampaignTrigger: 5, CampaignMemberStatusTrigger: 5, TaskActivityTrigger: 6, OpportunityForecastTrigger: 8 }[name] || 4;
}
function SERVICE_PHASE(id) {
  return { leadScoring: 2, accountService: 3, opportunityService: 4, campaignService: 5, activityService: 6, processAutomation: 7, forecastingService: 8, reportingService: 9, integrationService: 10, certificationPrep: 11 }[id] || 1;
}
function testFor(s) {
  const map = { leadScoring: 'LeadManagementTest', accountService: 'AccountContactManagementTest', opportunityService: 'OpportunityManagementTest', campaignService: 'CampaignManagementTest', activityService: 'ActivityManagementTest', processAutomation: 'ProcessAutomationTest', forecastingService: 'ForecastingTerritoryTest', reportingService: 'ReportingServiceTest', integrationService: 'IntegrationServiceTest', certificationPrep: 'CertificationPrepServiceTest' };
  return map[s.id];
}
SERVICES.forEach(s => { s.test = testFor(s); });

/* Static metadata entries */
const META_DETAILS = {
  flowScoring: { title: 'Lead_Scoring_Flow', type: 'Screen Flow · Phase 2', desc: 'Interactive scoring screen reps can run to evaluate a lead manually.', files: ['force-app/main/default/flows/Lead_Scoring_Flow.flow-meta.xml'] },
  flowNurture: { title: 'Auto_Update_Nurture_Status', type: 'Record-Triggered Flow · Phase 2', desc: 'Re-derives nurture status when lead criteria change.', files: ['force-app/main/default/flows/Auto_Update_Nurture_Status.flow-meta.xml'] },
  flowLeadFollowUp: { title: 'Auto_Create_FollowUp_Task_On_Lead_Assignment', type: 'Record-Triggered Flow · Phase 2', desc: 'Schedules a follow-up task when a lead is assigned to a rep.', files: ['force-app/main/default/flows/Auto_Create_FollowUp_Task_On_Lead_Assignment.flow-meta.xml'] },
  flowChildRecords: { title: 'Auto_Create_Child_Records_On_Account', type: 'Record-Triggered Flow · Phase 3', desc: 'Bootstraps default contacts when an account is created.', files: ['force-app/main/default/flows/Auto_Create_Child_Records_On_Account.flow-meta.xml'] },
  flowAssignTasks: { title: 'Auto_Assign_Tasks_New_Opportunity', type: 'Record-Triggered Flow · Phase 4', desc: 'Assigns discovery tasks to the opportunity owner.', files: ['force-app/main/default/flows/Auto_Assign_Tasks_New_Opportunity.flow-meta.xml'] },
  flowChatter: { title: 'Deal_Close_Chatter_Notification', type: 'Record-Triggered Flow · Phase 6', desc: 'Posts to the record feed when a deal closes.', files: ['force-app/main/default/flows/Deal_Close_Chatter_Notification.flow-meta.xml'] },
  flowStale: { title: 'Auto_Close_Stale_Opportunities', type: 'Scheduled Flow · Phase 7', desc: 'Closes opportunities with no activity for N days.', files: ['force-app/main/default/flows/Auto_Close_Stale_Opportunities.flow-meta.xml'] },
  flowEmail: { title: 'Weekly_Pipeline_Summary_Email', type: 'Scheduled Flow · Phase 7', desc: 'Emails reps their pipeline summary each week.', files: ['force-app/main/default/flows/Weekly_Pipeline_Summary_Email.flow-meta.xml'] },
  permSet: { title: 'Sales_Cloud_User', type: 'Permission Set · Phase 1', desc: 'Object CRUD + field-level security for Sales Cloud users.', files: ['force-app/main/default/permissionsets/Sales_Cloud_User.permissionset-meta.xml'] },
  approval: { title: 'Opportunity_Discount_Approval', type: 'Approval Process · Phase 7', desc: 'Step-based manager approval when discount exceeds the cap. Read at runtime by ProcessAutomationService via ProcessInstance.', files: ['force-app/main/default/approvalProcesses/Opportunity_Discount_Approval.approvalProcess-meta.xml'] },
  assignment: { title: 'Lead Assignment Rules', type: 'Assignment Rule · Phase 2', desc: 'Routes leads by industry to dedicated queues.', files: ['force-app/main/default/assignmentRules/Lead.assignmentRules-meta.xml'] },
  validation: { title: 'Validation Rules', type: 'Validation · Phases 2 & 4', desc: 'Enforce data quality: stage-skip guard, closed-deal lock, amount-for-high-probability, close-date, lead contact info, qualification date.', files: ['force-app/main/default/objects/Opportunity/validationRules/', 'force-app/main/default/objects/Lead/validationRules/'] },
};
Object.assign(DETAILS, META_DETAILS);

/* ------------------------- state ------------------------- */
const state = { tab: 'overview', sim: null };

/* ------------------------- view container ------------------------- */
const view = document.getElementById('view');

/* ------------------------- tab rendering ------------------------- */

function renderTab() {
  view.innerHTML = '';
  const t = state.tab;
  if (t === 'overview') buildOverview();
  if (t === 'data') buildDataModel();
  if (t === 'wire') buildWiring();
  if (t === 'flow') buildFlow();
  if (t === 'integ') buildIntegrations();
  if (t === 'phases') buildPhases();
  requestAnimationFrame(() => { if (t === 'wire') connectWiring(); });
}

/* ---------- 1. Overview ---------- */
const LAYERS = [
  { icon: '🎨', name: 'Presentation', sub: 'Lightning Experience · Reports · Dashboards · Quiz UI', id: 'pres', comps: [
    { cid: 'report', label: '7 Reports', aid: 'reports' },
    { cid: 'dash', label: '4 Dashboards', aid: 'dashboards' },
    { cid: 'ps', label: 'Sales_Cloud_User', aid: 'permSet' },
  ]},
  { icon: '⚙️', name: 'Automation Layer', sub: 'Flows · Validation · Assignment · Approvals', id: 'auto', comps: FLOWS.map(f => ({ cid: f.id, label: f.name, aid: f.id })).concat([
    { cid: 'vr', label: 'Validation Rules', aid: 'validation' },
    { cid: 'ar', label: 'Assignment Rules', aid: 'assignment' },
    { cid: 'ap', label: 'Discount Approval', aid: 'approval' },
  ])},
  { icon: '🧩', name: 'Apex Layer', sub: '8 triggers delegating to 10 service classes', id: 'apex', comps: [
    { cid: 'trig', label: '8 Triggers', aid: 'leadTrigger' },
    { cid: 'svc', label: '10 Service Classes', aid: 'leadScoring' },
    { cid: 'pe', label: 'Integration_Event__e', aid: 'event' },
    { cid: 'mdt', label: 'API_Configuration__mdt', aid: 'mdt' },
  ]},
  { icon: '🗃️', name: 'Data Layer', sub: 'Standard + custom objects (75+ custom fields)', id: 'data', comps: OBJECTS.slice(0, 12).map(o => ({ cid: o.name, label: o.name, aid: 'obj-' + o.name })) },
];

function buildOverview() {
  view.innerHTML += `<div class="section-head"><h2>Layered Architecture</h2><p>Click a layer to expand, then click any component for details.</p></div>`;
  LAYERS.forEach((L, i) => {
    const layer = document.createElement('div');
    layer.className = 'layer';
    layer.innerHTML = `
      <div class="ltop">
        <div class="icon">${L.icon}</div>
        <div><h3>${L.name}</h3><div class="sub">${L.sub}</div></div>
        <span class="chev">▾</span>
      </div>
      <div class="lbody"></div>`;
    const body = layer.querySelector('.lbody');
    const chipsWrap = document.createElement('div');
    chipsWrap.className = 'chips';
    L.comps.forEach(c => {
      const chip = document.createElement('span');
      chip.className = 'chip';
      chip.textContent = c.label;
      chip.addEventListener('click', () => openDetail(c.aid));
      chipsWrap.appendChild(chip);
    });
    body.appendChild(chipsWrap);
    layer.querySelector('.ltop').addEventListener('click', () => layer.classList.toggle('open'));
    if (i === 0) layer.classList.add('open');
    view.appendChild(layer);
  });
}

/* ---------- 2. Data model ---------- */
function buildDataModel() {
  view.innerHTML = `<div class="section-head"><h2>Data Model</h2><p>Click an object or relationship to inspect it.</p></div>`;

  const wrap = document.createElement('div');
  wrap.className = 'two-col';
  wrap.innerHTML = `<div class="maintab">

      <div class="group-label">Custom fields on standard objects &amp; custom objects</div>
      <div class="grid"></div>
    </div>
    <div class="relspanel">
      <div class="card rels" style="cursor:default">
        <h4>Relationships</h4>
        <div></div>
      </div>
    </div>`;

  const grid = wrap.querySelector('.grid');
  const relBox = wrap.querySelector('.rels div');

  OBJECTS.forEach(o => {
    const card = mkCard(o.name, o.icon, o.desc, o, 'obj-' + o.name);
    card.dataset.er = o.name;
    grid.appendChild(card);
  });

  RELS.forEach(r => {
    const row = document.createElement('div');
    row.className = 'card';
    row.innerHTML = `<span class="ari">${r.a}</span><b>${r.type}</b><span class="ari">${r.b}</span>
                     <span class="desc" style="margin-top:4px">${r.note}</span>`;
    row.addEventListener('click', () => {
      grid.querySelectorAll('.card').forEach(c => c.classList.remove('dim', 'hot'));
      grid.querySelectorAll('.card[data-er]').forEach(c => {
        const n = c.dataset.er;
        if (r.a.split(' / ').includes(n) || r.b.split(' / ').includes(n)) c.classList.add('hot');
      });
    });
    relBox.appendChild(row);
  });

  view.appendChild(wrap);
}

/* ---------- 3. Wiring: triggers → services ---------- */
function buildWiring() {
  view.innerHTML = `
    <div class="section-head"><h2>Triggers → Services</h2>
    <p>Hover a trigger to trace it to its service. Click anything for details.</p></div>
    <div class="wiring" id="wiring">
      <svg class="links" id="wlinks"></svg>
      <div class="wcol" id="wtrig"><h4>Triggers (event detection)</h4></div>
      <div class="wcol" id="wsvc"><h4>Services (business logic)</h4></div>
    </div>
    <div style="margin-top:20px">
      <div class="group-label">Declarative automation (invoked from flows / approval / scheduled jobs)</div>
      <div class="grid">${SURFACE.map(s => mkWiringSurface(s)).join('')}</div>
    </div>`;

  const wtrig = document.getElementById('wtrig');
  const wsvc = document.getElementById('wsvc');

  view.querySelectorAll('[data-open]').forEach(el => {
    el.addEventListener('click', () => openDetail(el.dataset.open));
  });

  TRIGGERS.forEach(t => {
    const c = mkCard(t.name, '⚡', t.events, t, t.id);
    c.dataset.svc = t.svc;
    c.addEventListener('mouseenter', () => hotLink(t.svc));
    c.addEventListener('mouseleave', () => unhotLink());
    wtrig.appendChild(c);
  });

  SERVICES.forEach(s => {
    const c = mkCard(s.name, '🛠️', s.duty, s, s.id);
    c.dataset.linksTo = 'service';
    c.addEventListener('mouseenter', () => hotLink(s.id));
    c.addEventListener('mouseleave', () => unhotLink());
    wsvc.appendChild(c);
  });
}

function mkWiringSurface(s) {
  return `<div class="card" data-open="${s.id}"><div class="name">${s.name}</div>
          <div class="badge b-type" style="margin-top:8px">${s.type}</div>
          <div class="desc">${s.desc}</div></div>`;
}

/* Draw the bezier links between trigger and service cards. */
function connectWiring() {
  const wiring = document.getElementById('wiring');
  const svg = document.getElementById('wlinks');
  const trig = document.getElementById('wtrig');
  if (!wiring || !svg) return;
  const cards = Array.from(trig.querySelectorAll('.card'));
  svg.setAttribute('width', wiring.offsetWidth);
  svg.setAttribute('height', wiring.offsetHeight);
  svg.innerHTML = '';

  cards.forEach(card => {
    const svcId = card.dataset.svc;
    const svcCard = Array.from(document.querySelectorAll('#wsvc .card'))
      .find(c => c.querySelector('.name').textContent.trim() === SERVICES.find(s => s.id === svcId).name);
    if (!svcCard) return;
    const r1 = card.getBoundingClientRect();
    const r2 = svcCard.getBoundingClientRect();
    const w  = wiring.getBoundingClientRect();
    const x1 = r1.right - w.left;
    const y1 = r1.top + r1.height / 2 - w.top;
    const x2 = r2.left - w.left;
    const y2 = r2.top + r2.height / 2 - w.top;
    const mx = (x1 + x2) / 2;
    const d = `M ${x1} ${y1} C ${mx} ${y1}, ${mx} ${y2}, ${x2} ${y2}`;
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', d);
    path.setAttribute('class', 'wlink');
    path.dataset.svc = svcId;
    svg.appendChild(path);
  });
}

function hotLink(svcId) {
  document.querySelectorAll('#wsvc .card').forEach(c => c.classList.remove('hot'));
  document.querySelectorAll('path.wlink').forEach(p => p.classList.remove('link-hot'));
  const target = Array.from(document.querySelectorAll('#wsvc .card'))
    .find(c => c.querySelector('.name').textContent.trim() === SERVICES.find(s => s.id === svcId)?.name);
  if (target) target.classList.add('hot');
  document.querySelectorAll(`path.wlink[data-svc="${svcId}"]`).forEach(p => p.classList.add('link-hot'));
}
function unhotLink() {
  document.querySelectorAll('#wsvc .card').forEach(c => c.classList.remove('hot'));
  document.querySelectorAll('path.wlink').forEach(p => p.classList.remove('link-hot'));
}

/* ---------- 4. Sales flow simulation ---------- */
function buildFlow() {
  state.sim = { step: -1, timer: null };
  view.innerHTML = `
    <div class="section-head"><h2>End-to-End Sales Process</h2>
    <p>Watch a deal travel from lead to dashboard. Click any step for detail.</p></div>
    <div class="toolbar">
      <button class="btn primary" id="playBtn">▶ Simulate deal</button>
      <button class="btn" id="resetBtn">↺ Reset</button>
      <span class="subtle" id="simHint">12 steps · 800ms each</span>
    </div>
    <div class="pipeline" id="pipe"></div>`;

  const pipe = document.getElementById('pipe');
  FLOW_STEPS.forEach((s, i) => {
    const step = document.createElement('div');
    step.className = 'step';
    step.dataset.i = i;
    step.innerHTML = `<div class="sn">STEP ${String(i + 1).padStart(2, '0')}</div>
      <div class="st">${s.icon} ${s.t}</div><div class="sd">${s.d}</div>`;
    step.addEventListener('click', () => openDetail('step' + i));
    pipe.appendChild(step);
    if (i < FLOW_STEPS.length - 1) pipe.insertAdjacentHTML('beforeend', '<span class="arrow">→</span>');
  });

  FLOW_STEPS.forEach((s, i) => { DETAILS['step' + i] = { title: FLOW_STEPS[i].t, type: 'Process step', phase: i + 1, desc: FLOW_STEPS[i].d, files: ['salesCloud Roadmap/ guides'], concepts: ['See ARCHITECTURE.md §4'] }; });

  document.getElementById('playBtn').addEventListener('click', playSim);
  document.getElementById('resetBtn').addEventListener('click', resetSim);
}

function playSim() {
  const steps = document.querySelectorAll('#pipe .step');
  resetSim();
  state.sim.step = -1;
  state.sim.timer = setInterval(() => {
    state.sim.step++;
    if (state.sim.step >= steps.length) { clearInterval(state.sim.timer); return; }
    steps[state.sim.step].classList.add('playing');
    if (state.sim.step > 0) steps[state.sim.step - 1].classList.remove('playing');
    steps.forEach((s, i) => { if (i < state.sim.step) s.classList.add('done'); });
  }, 800);
}
function resetSim() {
  clearInterval(state.sim.timer);
  document.querySelectorAll('#pipe .step').forEach(s => s.classList.remove('done', 'playing'));
}

/* ---------- 5. Integrations ---------- */
function buildIntegrations() {
  view.innerHTML = `
    <div class="section-head"><h2>Integration Architecture</h2>
    <p>Hit "Simulate REST call" and watch the traffic in the console below.</p></div>
    <div class="pipeline" id="ipipe"></div>
    <div class="toolbar">
      <button class="btn primary" id="simBtn">▶ Simulate REST call</button>
      <button class="btn" id="clrBtn">✖ Clear</button>
    </div>
    <div class="console" id="con"><div class="line">// integration console — ready</div></div>`;

  const pipe = document.getElementById('ipipe');
  INTEG_STEPS.forEach((s, i) => {
    const step = document.createElement('div');
    step.className = 'step';
    step.dataset.i = i;
    step.innerHTML = `<div class="sn">NODE ${String(i + 1).padStart(2, '0')}</div>
      <div class="st">${s.icon} ${s.t}</div><div class="sd">${s.d}</div>`;
    step.addEventListener('click', () => openDetail('istep' + i));
    pipe.appendChild(step);
    if (i < INTEG_STEPS.length - 1) pipe.insertAdjacentHTML('beforeend', '<span class="arrow">→</span>');
  });

  INTEG_STEPS.forEach((s, i) => { DETAILS['istep' + i] = { title: INTEG_STEPS[i].t, type: 'Integration node', phase: 10, desc: INTEG_STEPS[i].d, files: [], concepts: ['Http callout', 'JSON serialize/deserialize', 'Webhook ingest'] }; });

  const con = document.getElementById('con');
  const log = (html) => { con.insertAdjacentHTML('beforeend', '<div class="line">' + html + '</div>'); con.scrollTop = con.scrollHeight; };

  document.getElementById('simBtn').addEventListener('click', () => {
    log('<b>POST</b> https://api.example.com/orders');
    setTimeout(() => log('&nbsp;&nbsp;← HTTP 200 OK (12ms)'), 350);
    setTimeout(() => log('&nbsp;&nbsp;✔ logged to <b>Integration_Log__c</b>'), 620);
    setTimeout(() => log('&nbsp;&nbsp;⚡ published <b>Integration_Event__e</b>'), 900);
  });
  document.getElementById('clrBtn').addEventListener('click', () => { con.innerHTML = '<div class="line">// integration console — ready</div>'; });
}

/* ---------- 6. Phases ---------- */
function buildPhases() {
  view.innerHTML = `
    <div class="section-head"><h2>Learning Roadmap</h2>
    <p>Click a row to open its guide on GitHub. Click an artifact to inspect it.</p></div>
    <table class="phases" id="phaTab">
      <thead><tr><th>Phase</th><th>Topic</th><th>Focus</th><th>Artifacts</th></tr></thead>
      <tbody></tbody>
    </table>`;
  const tb = document.querySelector('#phaTab tbody');
  PHASES.forEach(p => {
    const tr = document.createElement('tr');
    const arts = p.art.map(a => `<span class="art">${a}</span>`).join('<br>');
    tr.innerHTML = `<td><b>${String(p.n).padStart(2, '0')}</b></td>
      <td class="subtle">${p.t}</td><td>${p.topic}</td><td>${arts}</td>`;
    tr.addEventListener('click', () => window.open(`https://github.com/AbdoAddouli/Salesforce-SalesCloud-RoadMap/blob/main/salesCloud%20Roadmap/${p.guide}`, '_blank'));
    tb.appendChild(tr);
  });
}

/* ---------- shared card factory ---------- */
function mkCard(title, icon, desc, meta, aid) {
  const c = document.createElement('div');
  c.className = 'card';
  c.innerHTML = `<div class="name">${icon} ${title}</div><div class="desc">${desc}</div>`;
  c.addEventListener('click', () => openDetail(aid));
  c.dataset.search = `${title} ${desc}`.toLowerCase();
  return c;
}

/* ---------- detail drawer ---------- */
function openDetail(aid) {
  const d = DETAILS[aid];
  const drawer = document.getElementById('drawer');
  const body = document.getElementById('drawerBody');
  if (!d) { alert('No detail for: ' + aid); return; }
  const related = (d.related || []).map(r => `<span class="drel" data-aid="${r}">${prettyId(r)}</span>`).join('');
  body.innerHTML = `
    <div class="dhead">
      <div class="dicon">${d.icon || '📄'}</div>
      <div><h3>${d.title}</h3><div class="dtype">${d.type}${d.phase ? ' · Phase ' + d.phase : ''}</div></div>
      <button class="close" id="drawerClose">✕</button>
    </div>
    <p style="font-size:13px;line-height:1.6">${d.desc || ''}</p>
    ${related ? `<div class="dsec"><h4>Related</h4>${related}</div>` : ''}
    <div class="dsec"><h4>Concepts in this phase</h4><div class="dlists">${(d.concepts || []).map(c => `<code>${c}</code>`).join(' ') || '—'}</div></div>
    ${(d.files && d.files.length) ? `<div class="dsec"><h4>Files</h4>${d.files.map(f => `<div class="dfile">${f}</div>`).join('')}</div>` : ''}`;
  drawer.classList.add('show');
  document.getElementById('overlay').classList.add('show');
  body.querySelector('#drawerClose').addEventListener('click', closeDrawer);
  body.querySelectorAll('.drel').forEach(el => el.addEventListener('click', () => openDetail(el.dataset.aid)));
}
function closeDrawer() {
  document.getElementById('drawer').classList.remove('show');
  document.getElementById('overlay').classList.remove('show');
}
function prettyId(id) {
  if (id === 'leadScoring') return 'LeadScoringService';
  if (id === 'accountService') return 'AccountService';
  if (id === 'opportunityService') return 'OpportunityService';
  if (id === 'campaignService') return 'CampaignService';
  if (id === 'activityService') return 'ActivityService';
  if (id === 'processAutomation') return 'ProcessAutomationService';
  if (id === 'forecastingService') return 'ForecastingService';
  if (id === 'reportingService') return 'ReportingService';
  if (id === 'integrationService') return 'IntegrationService';
  if (id === 'certificationPrep') return 'CertificationPrepService';
  return id;
}

/* Register object + platform entries in DETAILS so chips resolve. */
OBJECTS.forEach(o => {
  DETAILS['obj-' + o.name] = {
    title: o.name, type: o.group + ' object', phase: o.group === 'Custom' ? 8 : 1,
    icon: o.icon, desc: o.desc,
    files: o.group === 'Custom' ? [`force-app/main/default/objects/${o.name}.object-meta.xml`] : ['Standard object'],
    concepts: o.fields.map(f => f),
  };
});
DETAILS.reports = { title: '7 Reports', type: 'Analytics · Phase 9', desc: 'Pipeline by Forecast Category, Revenue by Territory, Lead Conversion, Campaign ROI, Activity Summary, Account Health, Win Rate.', files: ['force-app/main/default/reports/'] };
DETAILS.dashboards = { title: '4 Dashboards', type: 'Analytics · Phase 9', desc: 'Sales Performance, Revenue Analytics, Quota Attainment, Pipeline Coverage.', files: ['force-app/main/default/dashboards/'] };
DETAILS.event = { title: 'Integration_Event__e', type: 'Platform Event · Phase 10', desc: 'Decoupled async signal published by IntegrationService after external calls.', files: ['force-app/main/default/platformEvents/Integration_Event__e.platformEvent-meta.xml'], concepts: ['EventBus.publish', 'trigger-less subscribers'] };
DETAILS.mdt = { title: 'API_Configuration__mdt', type: 'Custom Metadata · Phase 10', desc: 'Read-only endpoint configuration consumed by IntegrationService.', files: ['force-app/main/default/customMetadata/'], concepts: ['Custom Metadata Type', 'deployable config'] };

/* ---------- tabs & search wiring ---------- */
document.querySelectorAll('.tab').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    state.tab = btn.dataset.tab;
    renderTab();
    window.dispatchEvent(new CustomEvent('tabchange'));
  });
});

document.getElementById('overlay').addEventListener('click', closeDrawer);
window.addEventListener('keydown', e => {
  if (e.key === 'Escape') closeDrawer();
  if (e.key === '/' && document.activeElement.tagName !== 'INPUT') {
    e.preventDefault(); document.getElementById('q').focus();
  }
  if (e.key === 'Enter' && document.activeElement.id === 'q') {
    const tab = document.querySelector(`[data-tab="${state.tab}"]`);
    if (tab) tab.click(); // jump re-renders; keeps search simple
  }
});

/* Search — dims non-matching cards in the current tab. */
document.getElementById('q').addEventListener('input', e => {
  const q = e.target.value.trim().toLowerCase();
  const count = document.getElementById('searchCount');
  const cards = view.querySelectorAll('.card, .chip, .step');
  let hits = 0;
  cards.forEach(c => {
    const hay = (c.textContent || '').toLowerCase() + ' ' + (c.dataset.search || '');
    const match = !q || hay.includes(q);
    c.classList.toggle('off', !match);
    if (match) hits++;
  });
  if (!q) cards.forEach(c => c.classList.remove('off'));
  count.textContent = q ? `${hits} hits` : '';
});

/* Redraw wiring links when resized or switching tabs. */
let resizeT;
window.addEventListener('resize', () => {
  clearTimeout(resizeT);
  resizeT = setTimeout(() => { if (state.tab === 'wire') connectWiring(); }, 120);
});
window.addEventListener('tabchange', () => { if (state.tab === 'wire') requestAnimationFrame(connectWiring); });

/* Boot */
renderTab();