import {NextResponse} from 'next/server';
import {db} from '../../../../../lib/server/provider';
import {requireCron} from '../../../../../lib/server/auth';
import {executeSync,parseCredentials} from '../../../../../lib/server/distribution/runtime';
import {normalizeInboundReservation} from '../../../../../lib/server/distribution/reservation-inbox.js';
import {requireOtaProperty} from '../../../../../lib/server/distribution/property-guard';
export const runtime='nodejs';
export async function POST(req){
 try{requireCron(req);const s=db();const now=new Date().toISOString();
  // Recover abandoned worker leases. A job is reclaimable only after its
  // processing lease is older than five minutes.
  const staleBefore=new Date(Date.now()-5*60*1000).toISOString();
  const {error:recoverError}=await s.from('ota_sync_events')
   .update({status:'queued',locked_at:null,locked_by:null,next_attempt_at:now,last_error:'Recovered stale processing lease'})
   .eq('status','processing').lt('locked_at',staleBefore);
  if(recoverError)throw recoverError;
  const {data:jobs,error}=await s.from('ota_sync_events').select('*').eq('status','queued').lte('next_attempt_at',now).order('created_at').limit(20);if(error)throw error;
  let processed=0,failed=0;
  for(const job of jobs||[]){
   const attempt=Number(job.attempt_count||0)+1;
   const {data:claim,error:claimError}=await s.from('ota_sync_events')
    .update({status:'processing',attempt_count:attempt,locked_at:now,locked_by:'distribution-worker'})
    .eq('id',job.id).eq('status','queued').select('id').maybeSingle();
   if(claimError)throw claimError;
   if(!claim)continue; // Another worker already owns this event.
   try{
    let connection=null; if(job.connection_id){connection=(await s.from('anaira_distribution_connections').select('id,restaurant_id,platform_id,status,base_url,auth_type,credentials_ciphertext,credentials_ref,config,adapter_code').eq('id',job.connection_id).single()).data;} if(!connection && job.channel_id){const channel=(await s.from('ota_channels').select('platform_id,restaurant_id').eq('id',job.channel_id).single()).data; if(channel) connection=(await s.from('anaira_distribution_connections').select('id,restaurant_id,platform_id,status,base_url,auth_type,credentials_ciphertext,credentials_ref,config,adapter_code').eq('restaurant_id',channel.restaurant_id).eq('platform_id',channel.platform_id).maybeSingle()).data;}
    if(!connection||!['configured','connected'].includes(connection.status)) throw new Error('Distribution connection is not connected.');
    await requireOtaProperty(s,connection.restaurant_id);
    const platformId=connection.platform_id; const platform=(await s.from('anaira_distribution_platforms').select('*').eq('id',platformId).single()).data;
    if(!platform) throw new Error('Distribution platform not found.');
    let result;
    if (job.direction === 'inbound' || job.payload?.direction === 'inbound') {
      if (job.event_type !== 'reservation') throw new Error(`Unsupported inbound OTA event: ${job.event_type}`);
      const normalized = normalizeInboundReservation(platform.provider_code, job.payload || {});
      const {data:priorInbox}=await s.from('anaira_ota_reservation_inbox').select('id,hms_reservation_id,import_status').eq('restaurant_id',connection.restaurant_id).eq('provider_code',platform.provider_code).eq('external_reference',normalized.external_reference).maybeSingle();
      const {data:channel}=await s.from('ota_channels').select('id').eq('restaurant_id',connection.restaurant_id).eq('provider',platform.provider_code).maybeSingle();
      let mappedRoom=null,mappedRate=null;
      if(channel?.id && normalized.external_room_code){
        const {data:m}=await s.from('ota_room_mappings').select('room_type_id').eq('channel_id',channel.id).eq('external_code',String(normalized.external_room_code)).not('room_type_id','is',null).maybeSingle();
        mappedRoom=m?.room_type_id||null;
      }
      if(channel?.id && normalized.external_rate_code){
        const {data:m}=await s.from('ota_rate_mappings').select('rate_plan_id').eq('channel_id',channel.id).eq('external_code',String(normalized.external_rate_code)).not('rate_plan_id','is',null).maybeSingle();
        mappedRate=m?.rate_plan_id||null;
      }
      const isCancelled=['cancelled','canceled'].includes(normalized.reservation_status);
      const isModified=normalized.reservation_status==='modified';
      if(isCancelled&&!priorInbox) throw new Error('OTA cancellation has no matching imported reservation in this property inbox.');
      // A linked cancellation stays retryable until the PMS RPC commits it.
      const nextStatus=isCancelled?(priorInbox?.hms_reservation_id?'ready':'cancelled'):(priorInbox?.hms_reservation_id?'ready':(mappedRoom?'ready':'needs_mapping'));
      const { data: inbox, error: inboxError } = await s.from('anaira_ota_reservation_inbox').upsert({
        restaurant_id: connection.restaurant_id, connection_id: connection.id, ...normalized,
        room_type_id:mappedRoom||undefined, rate_plan_id:mappedRate||undefined,
        import_status: nextStatus,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'restaurant_id,provider_code,external_reference' }).select('id,import_status,external_reference,hms_reservation_id').single();
      if (inboxError) throw inboxError;
      let lifecycleResult=null;
      if(isCancelled && inbox.hms_reservation_id){
        const {data:cancelled,error:cancelError}=await s.rpc('anaira_process_ota_reservation',{p_inbox_id:inbox.id,p_restaurant_id:connection.restaurant_id,p_action:'cancel'});
        if(cancelError) throw cancelError;
        lifecycleResult=cancelled;
      } else if(isModified && inbox.hms_reservation_id){
        const {data:modified,error:modifyError}=await s.rpc('anaira_process_ota_reservation',{p_inbox_id:inbox.id,p_restaurant_id:connection.restaurant_id,p_action:'modify'});
        if(modifyError) throw modifyError;
        lifecycleResult=modified;
      }
      result = { ok: true, direction: 'inbound', imported_to_inbox: true, inbox_id: inbox.id, import_status: inbox.import_status, hms_reservation_id: inbox.hms_reservation_id, mapped_room: Boolean(mappedRoom||priorInbox?.hms_reservation_id), mapped_rate: Boolean(mappedRate||priorInbox?.hms_reservation_id), lifecycle_action:isCancelled?'cancel':(isModified?'modify':null), lifecycle_processed:Boolean(lifecycleResult?.ok), lifecycle_result:lifecycleResult, external_reference: inbox.external_reference };
    } else {
      const credentials=parseCredentials(connection);
      result=await executeSync(connection,platform,credentials,job);
    }
    await s.from('ota_sync_events').update({status:'success',processed_at:new Date().toISOString(),completed_at:new Date().toISOString(),last_error:null,response_payload:result,error_message:null}).eq('id',job.id);processed++;
   }catch(e){
    if(job.direction==='inbound'||job.payload?.direction==='inbound'){
      try{
        const providerCode=String(job.payload?.provider||'').toLowerCase();
        const normalized=normalizeInboundReservation(providerCode,job.payload||{});
        await s.from('anaira_ota_reservation_inbox').update({last_error:e.message,import_status:'review',updated_at:new Date().toISOString()})
          .eq('restaurant_id',job.restaurant_id).eq('provider_code',providerCode).eq('external_reference',normalized.external_reference)
          .neq('import_status','imported');
      }catch{}
    }
    const max=Number(job.max_attempts||8);const dead=attempt>=max;const delay=Math.min(3600,Math.pow(2,Math.max(0,attempt-1))*30);
    await s.from('ota_sync_events').update({status:dead?'failed':'queued',error_message:e.message,last_error:e.message,next_attempt_at:new Date(Date.now()+delay*1000).toISOString(),locked_at:null,locked_by:null}).eq('id',job.id);failed++;
   }
  }
  return NextResponse.json({ok:true,processed,failed,count:(jobs||[]).length});
 }catch(e){return NextResponse.json({ok:false,error:e.message},{status:401})}
}
