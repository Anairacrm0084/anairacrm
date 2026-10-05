import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const checks=[
 ['universal CRM config exists',fs.existsSync(path.join(root,'lib/server/crm-universal.js'))],
 ['universal CRM API exists',fs.existsSync(path.join(root,'app/api/crm/universal/config/route.js'))],
 ['universal CRM migration exists',fs.existsSync(path.join(root,'supabase/migrations/20261004_crm_universal_multi_business.sql'))],
 ['business profile table defined',fs.readFileSync(path.join(root,'supabase/migrations/20261004_crm_universal_multi_business.sql'),'utf8').includes('crm_business_profiles')],
 ['universal interactions table defined',fs.readFileSync(path.join(root,'supabase/migrations/20261004_crm_universal_multi_business.sql'),'utf8').includes('crm_universal_interactions')],
 ['universal service profiles defined',fs.readFileSync(path.join(root,'supabase/migrations/20261004_crm_universal_multi_business.sql'),'utf8').includes('crm_universal_service_profiles')],
 ['RLS enabled for universal interactions',fs.readFileSync(path.join(root,'supabase/migrations/20261004_crm_universal_multi_business.sql'),'utf8').includes('alter table public.crm_universal_interactions enable row level security')],
 ['record interaction RPC defined',fs.readFileSync(path.join(root,'supabase/migrations/20261004_crm_universal_multi_business.sql'),'utf8').includes('anaira_crm_record_universal_interaction')],
 ['barber vertical supported',fs.readFileSync(path.join(root,'lib/server/crm-universal.js'),'utf8').includes("['barber','Barber Shop']")],
 ['professional services supported',fs.readFileSync(path.join(root,'lib/server/crm-universal.js'),'utf8').includes("['agency','Agency / Professional Services']")],
 ['ecommerce supported',fs.readFileSync(path.join(root,'lib/server/crm-universal.js'),'utf8').includes("['ecommerce','E-commerce']")],
 ['generic customer context',fs.readFileSync(path.join(root,'lib/server/crm-universal.js'),'utf8').includes('buildCrmContext')]
];
let pass=0; for(const [n,ok] of checks){console.log(`${ok?'PASS':'FAIL'} ${n}`);if(ok)pass++;}
console.log(`CRM UNIVERSAL ${pass}/${checks.length} PASS`); process.exitCode=pass===checks.length?0:1;
