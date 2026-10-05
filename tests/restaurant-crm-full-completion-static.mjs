import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const page=fs.readFileSync(path.join(root,'app/restaurant-crm/page.js'),'utf8');
const migs=fs.readdirSync(path.join(root,'supabase/migrations')).filter(x=>x.endsWith('.sql'));
const migration=migs.filter(x=>x.includes('20261003_restaurant_crm_full_completion'))[0];
const sql=migs.filter(x=>x.includes('20261003_restaurant_crm')).map(x=>fs.readFileSync(path.join(root,'supabase/migrations',x),'utf8')).join('\n');
const requiredPage=[
 'Customers','Visits','Reservations','Service','Preferences','Loyalty','marketing','Offers','intelligence','Timeline','Automation','Orders','Campaigns','AI',
 'anaira_restaurant_crm_action','create_task','create_complaint','create_food_preference','create_request','create_offer',
 'earn_loyalty','redeem_loyalty','queue_whatsapp','crm_campaigns','crm_message_log','crm_timeline_events'
];
const requiredSql=[
 'property_id','anaira_restaurant_crm_action',
 'create_task','create_complaint','resolve_complaint','create_food_preference','create_request',
 'create_offer','accept_offer','fulfil_offer','log_feedback','queue_whatsapp','add_timeline',
 'redeem_loyalty','earn_loyalty','complete_task','complete_request','escalate_request','create_sla_event','record_order_event','record_order_payment','prepare_campaign','queue_automation','generate_ai_insight','review_ai_insight','approve_ai_insight','execute_ai_insight','record_ai_outcome','record_offer_payment','record_campaign_event'
];
const missingPage=requiredPage.filter(x=>!page.includes(x));
const missingSql=requiredSql.filter(x=>!sql.includes(x));
console.log(`Restaurant CRM static closure: ${missingPage.length===0 && missingSql.length===0 ? 'PASS':'FAIL'}`);
if(missingPage.length) console.log('Missing page markers:',missingPage);
if(missingSql.length) console.log('Missing SQL markers:',missingSql);
process.exit(missingPage.length||missingSql.length?1:0);
