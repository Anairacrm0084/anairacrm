import fs from 'node:fs';
import path from 'node:path';
const root=process.cwd();
const checks=[
 ['identity migration', 'supabase/migrations/20261004_universal_business_tenant_identity.sql'],
 ['business vertical field', 'business_vertical'],
 ['business locations table', 'anaira_business_locations'],
 ['business memberships table', 'anaira_business_memberships'],
 ['business create RPC', 'anaira_create_universal_business'],
 ['business switch RPC', 'anaira_switch_business'],
 ['owner profile assignment', "'business_admin'"],
 ['register page', 'app/register/page.js'],
 ['business onboarding page', 'app/business-onboarding/page.js'],
 ['login onboarding fallback', "'/business-onboarding'"],
 ['barber shop vertical', "['barber_shop','💈 Barber Shop']"],
 ['other business vertical', "['other','Other Business']"]
];
let pass=0;
for(const [label,needle] of checks){let ok=false; if(needle.includes('/')&&needle.endsWith('.js')) ok=fs.existsSync(path.join(root,needle)); else if(needle.endsWith('.sql')) ok=fs.existsSync(path.join(root,needle)); else {const files=[path.join(root,'supabase/migrations/20261004_universal_business_tenant_identity.sql'),path.join(root,'app/business-onboarding/page.js'),path.join(root,'app/login/page.js')]; ok=files.some(f=>fs.existsSync(f)&&fs.readFileSync(f,'utf8').includes(needle));} if(ok){console.log('PASS '+label);pass++;}else console.log('FAIL '+label)}
console.log(`UNIVERSAL BUSINESS IDENTITY ${pass}/${checks.length} ${pass===checks.length?'PASS':'FAIL'}`);
if(pass!==checks.length)process.exit(1);
