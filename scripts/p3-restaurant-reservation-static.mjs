import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const sql=fs.readFileSync(path.join(root,'supabase/migrations/20260928_phase_p3_restaurant_crm_reservation_market_parity.sql'),'utf8');
const required=[
  'anaira_restaurant_reservation_events','anaira_restaurant_table_combinations','anaira_restaurant_reservation_preferences',
  'anaira_restaurant_experiences','anaira_restaurant_reservation_addons','anaira_restaurant_reservation_deposits',
  'anaira_restaurant_reservation_availability','anaira_create_restaurant_reservation_v2','anaira_update_restaurant_reservation_status',
  'anaira_platform_events','crm_interactions','row level security'
];
const checks=required.map(x=>[x,sql.toLowerCase().includes(x.toLowerCase())]);
const page=fs.readFileSync(path.join(root,'app/restaurant-reservation/[id]/page.js'),'utf8');
checks.push(['public reservation page uses reservation RPC',page.includes('anaira_create_restaurant_reservation_v2')]);
const failed=checks.filter(([,ok])=>!ok);
for(const [name,ok] of checks) console.log(`${ok?'PASS':'FAIL'} ${name}`);
console.log(`P3 static checks: ${checks.length-failed.length}/${checks.length} PASS`);
if(failed.length) process.exit(1);
