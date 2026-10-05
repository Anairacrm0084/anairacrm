import fs from 'node:fs';
const page=fs.readFileSync('app/CrmEnterprisePage.js','utf8');
const mig=fs.readFileSync('supabase/migrations/20261003_corporate_crm_full_runtime_closure.sql','utf8');
const requiredPage=['crm_corporate_contacts','crm_corporate_rate_agreements','crm_corporate_bookings','crm_corporate_invoices','crm_corporate_statements','crm_corporate_revenue_attribution','anaira_corporate_contract_action','anaira_corporate_record_ledger','anaira_corporate_generate_statement','anaira_corporate_record_revenue','Open Corporate Portal'];
const requiredMig=['crm_corporate_bookings','crm_corporate_invoices','crm_corporate_rate_agreements','crm_corporate_renewal_jobs','crm_corporate_statements','crm_corporate_revenue_attribution','anaira_corporate_contract_action','anaira_corporate_record_ledger','anaira_corporate_generate_statement','anaira_corporate_record_revenue','anaira_process_corporate_renewal_jobs','anaira_corporate_renewal_worker'];
const checks=[...requiredPage.map(x=>[`page:${x}`,page.includes(x)]),...requiredMig.map(x=>[`migration:${x}`,mig.includes(x)]),['portal route',fs.existsSync('app/corporate-portal/page.js')],['corporate route',fs.existsSync('app/corporate-crm/page.js')]];
const bad=checks.filter(x=>!x[1]); console.log(JSON.stringify({total:checks.length,passed:checks.length-bad.length,failed:bad.map(x=>x[0])},null,2)); process.exitCode=bad.length?1:0;
