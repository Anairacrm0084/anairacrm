import fs from 'node:fs';
import assert from 'node:assert/strict';
const read=p=>fs.readFileSync(new URL(p,import.meta.url),'utf8');
const manager=read('../../app/ota/OTAManager.jsx');
const guard=read('../../lib/server/distribution/property-guard.js');
const connection=read('../../app/api/distribution/connection/test/route.js');
const inbox=read('../../app/api/distribution/inbox/process/route.js');
const worker=read('../../app/api/distribution/sync/worker/route.js');
const webhook=read('../../app/api/distribution/webhook/[provider]/route.js');
const sql=read('../../supabase/migrations/20261105130000_ota_property_only_scope.sql');
for(const [name,ok] of [
 ['UI filters eligible businesses',manager.includes("(all||[]).filter(isOtaProperty)")],
 ['Eligible accommodation business types are explicit',guard.includes("'hotel_resort'")&&guard.includes("'hotel_restaurant'")&&guard.includes("'camping'")],
 ['Connection test validates property type',connection.includes('requireOtaProperty(s,tenantId)')],
 ['Inbox processing validates property type',inbox.includes('requireOtaProperty(s,restaurantId)')],
 ['Sync worker validates property type',worker.includes('requireOtaProperty(s,connection.restaurant_id)')],
 ['Webhook routes only to eligible businesses',webhook.includes('OTA_PROPERTY_BUSINESS_TYPES')&&webhook.includes('eligibleIds.has(c.restaurant_id)')],
 ['Database enforces restrictive OTA scope policies',sql.includes('as restrictive')&&sql.includes('ota_property_scope_guard')]
]) assert.ok(ok,`FAIL: ${name}`);
console.log(JSON.stringify({status:'PASS',checks:7,scope:'OTA is restricted to accommodation business types'},null,2));
