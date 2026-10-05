import fs from 'node:fs';
const page=fs.readFileSync('app/CrmEnterprisePage.js','utf8');
const mig=fs.readFileSync('supabase/migrations/20261003_guest_relations_full_runtime_closure.sql','utf8');
const requiredPage=['Guest Relations & Service Recovery','Assign','Start SLA','Escalate','Resolve','Create Recovery','anaira_complaint_action','anaira_service_recovery_action'];
const requiredMig=['crm_guest_relation_events','anaira_guest_request_action','anaira_guest_request_sla_worker','anaira_complaint_action','anaira_service_recovery_action'];
const checks=[...requiredPage.map(x=>[`page:${x}`,page.includes(x)]),...requiredMig.map(x=>[`migration:${x}`,mig.includes(x)]),['guest route',fs.existsSync('app/guest-relations/page.js')],['requests route',fs.existsSync('app/guest-requests/page.js')]];
const bad=checks.filter(x=>!x[1]); console.log(JSON.stringify({total:checks.length,passed:checks.length-bad.length,failed:bad.map(x=>x[0])},null,2)); process.exitCode=bad.length?1:0;
