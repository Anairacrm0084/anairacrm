import fs from 'node:fs';
import assert from 'node:assert/strict';
const read=p=>fs.readFileSync(new URL(p,import.meta.url),'utf8');
const worker=read('../../app/api/distribution/sync/worker/route.js');
const rpc=read('../../supabase/migrations/20261105180000_ota_pms_replay_safety.sql');
const lifecycle=read('../../supabase/migrations/20261105111000_ota_pms_import_and_cancellation.sql');
for(const [name,ok] of [
  ['stale worker lease recovery',worker.includes(".eq('status','processing').lt('locked_at',staleBefore)")],
  ['atomic queued-job claim',worker.includes(".eq('id',job.id).eq('status','queued').select('id').maybeSingle()")],
  ['duplicate worker claim is skipped',worker.includes('if(!claim)continue')],
  ['linked OTA modifications reach PMS RPC',worker.includes("p_action:'modify'")],
  ['linked OTA cancellations reach PMS RPC',worker.includes("p_action:'cancel'")],
  ['failed cancellation remains retryable',worker.includes("priorInbox?.hms_reservation_id?'ready':'cancelled'")],
  ['RPC locks inbox row',lifecycle.includes('where id=p_inbox_id and restaurant_id=p_restaurant_id for update')],
  ['replay-safe import guard',rpc.includes("p_action='import' and v_inbox.hms_reservation_id is not null")],
  ['replay-safe cancellation guard',rpc.includes("p_action='cancel' and v_inbox.import_status='cancelled'")],
  ['migration patches only known RPC anchor',rpc.includes('Expected OTA lifecycle anchor was not found; refusing to patch RPC')]
]) assert.ok(ok,`FAIL: ${name}`);
console.log(JSON.stringify({status:'PASS',checks:10,scope:'static OTA replay/worker lifecycle checks; no live booking mutation'},null,2));
