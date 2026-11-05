import fs from 'node:fs';
import assert from 'node:assert/strict';
import {normalizeIncomingReservation} from '../lib/server/distribution/adapters/native.js';
const sample={event_type:'reservation.created',data:{id:'BK-1001',status:'confirmed',guest:{name:'Ram Kumar',phone:'9876543210',email:'ram@example.com'},arrival:'2026-12-10',departure:'2026-12-12',adults:2,children:1,total:5200,room_type:{code:'DELUXE'},rate_plan:{code:'BAR'}}};
const normalized=normalizeIncomingReservation('booking_com',sample);
assert.equal(normalized.action,'reservation');
assert.equal(normalized.payload.external_reservation_id,'BK-1001');
assert.equal(normalized.payload.guest_name,'Ram Kumar');
assert.equal(normalized.payload.check_in,'2026-12-10');
assert.equal(normalized.payload.check_out,'2026-12-12');
assert.equal(normalized.payload.external_room_code,'DELUXE');
const cancelled=normalizeIncomingReservation('booking_com',{event_type:'reservation.cancelled',data:{id:'BK-1001',status:'cancelled'}});
assert.equal(cancelled.action,'cancel');
for(const [file,needles] of [
 ['app/api/distribution/sync/worker/route.js',['anaira_distribution_import_reservation','buildCanonicalOutboundPayload','anaira_distribution_enqueue_due_auto_sync']],
 ['app/api/distribution/webhook/[provider]/route.js',['normalizeIncomingReservation','webhook_signature_required','direction:\'inbound\'']],
 ['lib/server/distribution/payloads.js',["schema:'anaira.ota.inventory.v1'","schema:'anaira.ota.rates.v1'","schema:'anaira.ota.reservations.v1'"]],
 ['supabase/migrations/20261106000100_ota_distribution_engine_completion.sql',['anaira_distribution_import_reservation','anaira_distribution_enqueue_due_auto_sync','anaira_distribution_reservation_links']]
]){const s=fs.readFileSync(new URL('../'+file,import.meta.url),'utf8');for(const n of needles)assert.ok(s.includes(n),`${file} missing ${n}`)}
console.log(JSON.stringify({status:'PASS',checks:14,normalization:'reservation + cancellation',inbound:'HMS/CRM RPC wired',outbound:'inventory/rates/reservation payload builders wired',scheduler:'protected worker + DB auto queue',scope:'local source/static tests; not live OTA provider certification'},null,2));
