import fs from 'node:fs';
const src=fs.readFileSync('app/CrmEnterprisePage.js','utf8');
const mig=fs.readdirSync('supabase/migrations').filter(x=>x.includes('partner_crm_full_runtime_closure'));
const required=['anaira_partner_onboard','anaira_partner_contract_action','anaira_partner_upsert_booking','anaira_partner_calculate_commission','anaira_partner_create_settlement','anaira_partner_settlement_action','anaira_partner_generate_statement','anaira_partner_reconcile'];
const actions=['Onboard','Create Contract','Approve Contract','Renew Contract','Calculate Commission','Create Booking','Create Settlement','Approve Settlement','Payout Settlement','Generate Statement','Reconcile Settlement','Open Partner Portal'];
const checks=[['partner module fields',required.every(x=>src.includes(x))||false],['partner actions',actions.every(x=>src.includes(x))],['partner migration present',mig.length>0],['KYC fields',src.includes('kyc_status')],['idempotency booking',src.includes('p_idempotency_key')],['statement runtime',src.includes('anaira_partner_generate_statement')],['reconciliation runtime',src.includes('anaira_partner_reconcile')]];
const failed=checks.filter(([,ok])=>!ok); console.log(JSON.stringify({total:checks.length,passed:checks.length-failed.length,failed:failed.map(x=>x[0])},null,2)); if(failed.length)process.exit(1);
