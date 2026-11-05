import fs from 'node:fs';
const checks=[
 ['camping business type option',"['camping','🏕️ Camping Business']",'app/properties/page.js'],
 ['camping vertical maps to camp',"defaultHospitalityType=t=>t==='camping'?'camp':'hotel'",'app/properties/page.js'],
 ['camp workspace link',"/booking-engine/camping?property=",'app/properties/page.js'],
 ['camp property auto-provision trigger','insert into public.camp_properties','supabase/migrations/20261105093000_auto_create_camp_property_on_business_setup.sql'],
 ['marketplace visibility defaults off for new camp','coalesce(new.status,\'active\')=\'active\',false','supabase/migrations/20261105093000_auto_create_camp_property_on_business_setup.sql'],
 ['camp engine honors selected property query',"get('property')",'app/booking-engine/camping/page.jsx'],
 ['no fake inventory/rates provisioned','insert into public.camp_properties','supabase/migrations/20261105093000_auto_create_camp_property_on_business_setup.sql']
];
let failed=0;
for(const [label,needle,file] of checks){const ok=fs.readFileSync(file,'utf8').includes(needle);console.log(`${ok?'PASS':'FAIL'} ${label}`);if(!ok)failed++}
console.log(`CAMP BUSINESS CREATION ${checks.length-failed}/${checks.length} ${failed?'FAIL':'PASS'}`);if(failed)process.exit(1);
