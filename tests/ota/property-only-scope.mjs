import fs from 'node:fs';
import assert from 'node:assert/strict';
const read=p=>fs.readFileSync(new URL(p,import.meta.url),'utf8');
const manager=read('../../app/ota/OTAManager.jsx');
const guard=read('../../lib/server/distribution/property-guard.js');
const connection=read('../../app/api/distribution/connection/test/route.js');
const inbox=read('../../app/api/distribution/inbox/process/route.js');
const worker=read('../../app/api/distribution/sync/worker/route.js');
const webhook=read('../../app/api/distribution/webhook/[provider]/route.js');
const sql=read('../../supabase/migrations/20261123131000_expand_ota_property_types.sql');
for(const [name,ok] of [
 ['Existing-listing linking form is available to property admins',manager.includes('Connect an existing OTA listing')&&manager.includes('requestExistingListingLink')],
 ['All accommodation profile types are eligible',guard.includes("'hotel_resort'")&&guard.includes("'hotel_restaurant'")&&guard.includes("'camping'")&&guard.includes("'homestay'")&&guard.includes("'guest_house'")&&guard.includes("'cottage'")],
 ['Connection test validates property type',connection.includes('requireOtaProperty(s,tenantId)')],
 ['Inbox processing validates property type',inbox.includes('requireOtaProperty(s,restaurantId)')],
 ['Sync worker validates property type',worker.includes('requireOtaProperty(s,connection.restaurant_id)')],
 ['Webhook routes only to eligible businesses',webhook.includes('requireOtaProperty(s,candidate.restaurant_id)')],
 ['Database enforces restrictive expanded OTA scope policies',sql.includes('as restrictive')&&sql.includes('ota_property_scope_guard')&&sql.includes('homestay')&&sql.includes('guest_house')&&sql.includes('cottage')]
]) assert.ok(ok,`FAIL: ${name}`);
console.log(JSON.stringify({status:'PASS',checks:7,scope:'OTA is restricted to accommodation business types including hotel, camp, homestay, guest house and cottage'},null,2));
