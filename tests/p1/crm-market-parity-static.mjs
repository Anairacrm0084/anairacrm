import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const required=[
 'supabase/migrations/20260928_phase_p1_crm_market_parity.sql',
 'docs/P1_CRM_MARKET_PARITY_STATUS.md',
 'app/customer-360/page.js','app/crm/page.js','app/workflows/page.js'
];
const checks=[
 ['identity links','crm_customer_identity_links'],
 ['sales pipelines','crm_sales_pipelines'],
 ['sales stages','crm_sales_stages'],
 ['opportunities','crm_opportunities'],
 ['service tickets','crm_service_tickets'],
 ['ticket events','crm_service_ticket_events'],
 ['workflow actions','crm_workflow_action_definitions'],
 ['merge audit','crm_customer_merge_events'],
 ['customer merge RPC','anaira_merge_crm_customer'],
 ['360 summary RPC','anaira_customer_360_summary']
];
const missing=required.filter(f=>!fs.existsSync(path.join(root,f)));
const sql=fs.readFileSync(path.join(root,'supabase/migrations/20260928_phase_p1_crm_market_parity.sql'),'utf8');
const failed=checks.filter(([,needle])=>!sql.includes(needle));
const result={phase:'P1',status:missing.length||failed.length?'FAIL':'FOUNDATION',required_files:required.length,missing,checks:checks.length,failed,generated_at:new Date().toISOString()};
fs.mkdirSync(path.join(root,'validation/reports'),{recursive:true});
fs.writeFileSync(path.join(root,'validation/reports/P1_CRM_MARKET_PARITY_STATIC.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify(result,null,2));
if(missing.length||failed.length) process.exit(1);
