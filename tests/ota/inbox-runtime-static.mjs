import fs from 'node:fs';
import assert from 'node:assert/strict';
const read=p=>fs.readFileSync(new URL(p,import.meta.url),'utf8');
const manager=read('../../app/ota/OTAManager.jsx');
const worker=read('../../app/api/distribution/sync/worker/route.js');
const webhook=read('../../app/api/distribution/webhook/[provider]/route.js');
const processRoute=read('../../app/api/distribution/inbox/process/route.js');
const migration=read('../../supabase/migrations/20261105111000_ota_pms_import_and_cancellation.sql');
for(const [name,condition] of [
 ['Super Admin property selector',manager.includes('Super Admin · Select property')],
 ['Incoming OTA inbox UI',manager.includes('Incoming OTA reservations')],
 ['PMS import action',manager.includes("processInbox(row,'import')")],
 ['PMS modification action',manager.includes("processInbox(row,'modify')")],
 ['Tenant-authenticated inbox route',processRoute.includes('requireTenant(req,restaurantId)')],
 ['Service-role RPC isolation',processRoute.includes("s.rpc('anaira_process_ota_reservation'")],
 ['Provider-account webhook routing',webhook.includes('provider account/property reference')],
 ['Ambiguous webhook rejection',webhook.includes("{status:409}")],
 ['Inbound room mapping',worker.includes("from('ota_room_mappings')")],
 ['Automatic OTA cancellation processing',worker.includes("p_action:'cancel'")],
 ['Idempotent inbox identity',migration.includes('external_reference')&&migration.includes('for update')],
 ['Inventory availability guard',migration.includes('No available room inventory')],
 ['Reservation modification lifecycle',migration.includes("if p_action='modify'")],
 ['Service-role-only function grant',migration.includes('to service_role')&&migration.includes('from public,anon,authenticated')]
]){assert.ok(condition,`FAIL: ${name}`)}
console.log(JSON.stringify({status:'PASS',checks:14,scope:'static OTA inbox/PMS lifecycle checks; no live OTA credentials or provider sandbox used'},null,2));
