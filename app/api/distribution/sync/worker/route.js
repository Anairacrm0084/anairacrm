import {NextResponse} from 'next/server';
import {db} from '../../../../../lib/server/provider';
import {requireCron} from '../../../../../lib/server/auth';
import {executeSync,parseCredentials} from '../../../../../lib/server/distribution/runtime';
import {buildCanonicalOutboundPayload} from '../../../../../lib/server/distribution/payloads';
export const runtime='nodejs';

async function runWorker(req){
 requireCron(req);
 const s=db(); const now=new Date().toISOString();
 const scheduled=await s.rpc('anaira_distribution_enqueue_due_auto_sync');
 if(scheduled.error) throw scheduled.error;
 const {data:jobs,error}=await s.from('ota_sync_events').select('*').eq('status','queued').lte('next_attempt_at',now).order('created_at').limit(20);
 if(error) throw error;
 let processed=0,failed=0,skipped=0; const results=[];
 for(const job of jobs||[]){
  const attempt=Number(job.attempt_count||0)+1;
  const lock=await s.from('ota_sync_events').update({status:'processing',attempt_count:attempt,locked_at:now,locked_by:'distribution-worker'}).eq('id',job.id).eq('status','queued').select('id').maybeSingle();
  if(lock.error||!lock.data){skipped++;continue;}
  try{
   let connection=null,channel=null;
   if(job.connection_id){const q=await s.from('anaira_distribution_connections').select('*').eq('id',job.connection_id).single();if(q.error)throw q.error;connection=q.data;}
   if(job.channel_id){const q=await s.from('ota_channels').select('*').eq('id',job.channel_id).single();if(q.error)throw q.error;channel=q.data;}
   if(!connection&&channel){const q=await s.from('anaira_distribution_connections').select('*').eq('restaurant_id',channel.restaurant_id).eq('platform_id',channel.platform_id).maybeSingle();if(q.error)throw q.error;connection=q.data;}
   if(!connection||!['configured','connected'].includes(connection.status)) throw new Error('Distribution connection is not connected.');
   const platformQ=await s.from('anaira_distribution_platforms').select('*').eq('id',connection.platform_id).single();if(platformQ.error)throw platformQ.error;
   const platform=platformQ.data;
   if(!platform?.active) throw new Error('Distribution platform is disabled.');
   if(job.direction==='inbound'||job.event_type==='reservation_import'){
    if(!channel) throw new Error('Inbound OTA reservation event has no target channel.');
    const inbound=job.payload?.normalized_reservation;
    if(!inbound?.payload) throw new Error('Inbound OTA event is missing its normalized reservation payload.');
    const imported=await s.rpc('anaira_distribution_import_reservation',{
     p_restaurant_id:job.restaurant_id,p_channel_id:channel.id,p_provider_code:platform.provider_code,
     p_action:inbound.action||'reservation',p_payload:inbound.payload
    });
    if(imported.error) throw imported.error;
    if(job.payload?.webhook_id){
     await s.from('anaira_distribution_webhook_events').update({status:'processed',processed_at:new Date().toISOString(),last_error:null,attempts:attempt}).eq('idempotency_key',job.payload.webhook_id);
    }
    await s.from('ota_sync_events').update({status:'success',processed_at:new Date().toISOString(),completed_at:new Date().toISOString(),last_error:null,error_message:null,response_payload:imported.data||{},locked_at:null,locked_by:null}).eq('id',job.id);
    processed++;results.push({id:job.id,direction:'inbound',result:imported.data});
   }else{
    if(!channel) throw new Error('Outbound OTA event has no channel.');
    const credentials=parseCredentials(connection);
    const payload=await buildCanonicalOutboundPayload(s,connection,channel,job);
    const result=await executeSync(connection,platform,credentials,{...job,payload});
    await s.from('ota_sync_events').update({status:'success',processed_at:new Date().toISOString(),completed_at:new Date().toISOString(),last_error:null,error_message:null,response_payload:result,locked_at:null,locked_by:null}).eq('id',job.id);
    await s.from('anaira_distribution_connections').update({last_sync_at:new Date().toISOString(),last_error:null,updated_at:new Date().toISOString()}).eq('id',connection.id);
    await s.from('ota_channels').update({last_sync_at:new Date().toISOString(),last_error:null}).eq('id',channel.id);
    processed++;results.push({id:job.id,direction:'outbound',result});
   }
  }catch(e){
   const max=Number(job.max_attempts||8);const dead=attempt>=max;const delay=Math.min(3600,Math.pow(2,Math.max(0,attempt-1))*30);const message=e?.message||'Distribution worker failed';
   await s.from('ota_sync_events').update({status:dead?'failed':'queued',error_message:message,last_error:message,next_attempt_at:new Date(Date.now()+delay*1000).toISOString(),locked_at:null,locked_by:null}).eq('id',job.id);
   if(job.payload?.webhook_id) await s.from('anaira_distribution_webhook_events').update({status:dead?'failed':'queued',last_error:message,attempts:attempt}).eq('idempotency_key',job.payload.webhook_id);
   if(job.channel_id) await s.from('ota_channels').update({last_error:message}).eq('id',job.channel_id);
   failed++;results.push({id:job.id,error:message,retry_at:new Date(Date.now()+delay*1000).toISOString()});
  }
 }
 return NextResponse.json({ok:true,auto_sync_enqueued:Number(scheduled.data||0),processed,failed,skipped,count:(jobs||[]).length,results});
}
export async function POST(req){try{return await runWorker(req)}catch(e){return NextResponse.json({ok:false,error:e?.message||'Distribution worker failed'},{status:Number(e?.status||401)})}}
export async function GET(req){try{return await runWorker(req)}catch(e){return NextResponse.json({ok:false,error:e?.message||'Distribution worker failed'},{status:Number(e?.status||401)})}}
