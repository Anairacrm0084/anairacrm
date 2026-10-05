import fs from 'node:fs';
const page=fs.readFileSync('app/CrmEnterprisePage.js','utf8');
const mig=fs.readFileSync('supabase/migrations/20261003_whatsapp_crm_full_runtime_closure.sql','utf8');
const requiredPage=['Send WhatsApp','Retry Failed','Mark Read','Create Template','Opt Out','anaira_whatsapp_enqueue','anaira_whatsapp_apply_status','anaira_whatsapp_optout'];
const requiredMig=['crm_whatsapp_conversations','crm_whatsapp_messages','crm_whatsapp_jobs','crm_whatsapp_optouts','crm_whatsapp_delivery_events','anaira_whatsapp_enqueue','anaira_whatsapp_apply_status','anaira_whatsapp_optout','anaira_whatsapp_job_worker'];
const checks=[...requiredPage.map(x=>[`page:${x}`,page.includes(x)]),...requiredMig.map(x=>[`migration:${x}`,mig.includes(x)]),['whatsapp route',fs.existsSync('app/whatsapp-crm/page.js')],['provider send route',fs.existsSync('app/api/crm/whatsapp/send/route.js')]];
const bad=checks.filter(x=>!x[1]); console.log(JSON.stringify({total:checks.length,passed:checks.length-bad.length,failed:bad.map(x=>x[0])},null,2)); process.exitCode=bad.length?1:0;
