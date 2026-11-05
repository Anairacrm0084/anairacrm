import {NextResponse} from 'next/server';
import crypto from 'node:crypto';
import {db} from '../../../../../lib/server/provider';
import {idempotencyKey} from '../../../../../lib/server/distribution/runtime';
import {normalizeIncomingReservation} from '../../../../../lib/server/distribution/adapters/native.js';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {verifyDistributionWebhook} from '../../../../../lib/server/webhookSecurity.js';
export const runtime='nodejs';

export async function POST(req,{params}){
 try{
  const provider=String(params.provider||'').toLowerCase();
  const raw=await req.text();
  if(!raw) return NextResponse.json({ok:false,error:'Webhook body is required.'},{status:400});
  const s=db();
  await enforceRateLimit(req,{scope:`webhook:${provider}`,limit:120,windowSeconds:60,keyParts:[provider]});
  let body;try{body=JSON.parse(raw)}catch{return NextResponse.json({ok:false,error:'Webhook body must be valid JSON.'},{status:400});}
  const {data:platform,error:pe}=await s.from('anaira_distribution_platforms').select('id,provider_code,active').eq('provider_code',provider).single();
  if(pe||!platform||!platform.active) return NextResponse.json({ok:false,error:'Unknown or disabled distribution provider.'},{status:404});
  const {data:connections,error:ce}=await s.from('anaira_distribution_connections')
   .select('id,restaurant_id,platform_id,provider_account_ref,credentials_ciphertext,config,webhook_signature_required,webhook_enabled,status')
   .eq('platform_id',platform.id).eq('webhook_enabled',true).in('status',['configured','connected']);
  if(ce) throw ce;
  const candidates=connections||[];
  if(!candidates.length) return NextResponse.json({ok:false,error:'No active webhook connection is configured for this provider.'},{status:503});
  const envelope=body?.data||body?.payload||body?.event?.data||body?.reservation||body?.booking||body;
  const incomingAccount=String(envelope?.account_id||envelope?.property_id||envelope?.hotel_id||body?.account_id||body?.property_id||'').trim();
  let scoped=candidates;
  if(incomingAccount){
   scoped=candidates.filter(c=>String(c.provider_account_ref||c.config?.account_id||c.config?.property_id||'')===incomingAccount);
   if(!scoped.length) return NextResponse.json({ok:false,error:'Webhook account does not match a configured Anaira property connection.'},{status:403});
  }else if(candidates.length!==1){
   return NextResponse.json({ok:false,error:'Provider has multiple property connections. Include provider account_id/property_id so this webhook can be routed safely.'},{status:409});
  }
  const connection=scoped[0];
  if(connection.webhook_signature_required!==false) verifyDistributionWebhook({req,raw,provider,connection});
  const normalized=normalizeIncomingReservation(provider,body);
  const externalId=normalized.payload.external_reservation_id;
  const idem=idempotencyKey([provider,externalId,normalized.action,body?.event_id||body?.id||'']);
  const {data:existing}=await s.from('anaira_distribution_webhook_events').select('id,status').eq('idempotency_key',idem).maybeSingle();
  if(existing?.status==='processed'||existing?.status==='queued') return NextResponse.json({ok:true,duplicate:true,event_id:externalId,status:existing.status});
  const {data:inbox,error:insertError}=await s.from('anaira_distribution_webhook_events').upsert({
   platform_id:platform.id,provider_code:provider,external_event_id:String(body?.event_id||externalId),
   idempotency_key:idem,event_type:normalized.action,payload:body,status:'received',received_at:new Date().toISOString()
  },{onConflict:'idempotency_key'}).select('id').single();
  if(insertError) throw insertError;
  const {data:channel,error:channelError}=await s.from('ota_channels').select('id,property_id').eq('restaurant_id',connection.restaurant_id).eq('platform_id',platform.id).maybeSingle();
  if(channelError) throw channelError;
  if(!channel) throw new Error('No OTA channel instance exists for this connected property. Create the channel before sending reservation webhooks.');
  const queueKey=idempotencyKey(['inbound',idem,connection.restaurant_id]);
  const {error:queueError}=await s.from('ota_sync_events').upsert({
   restaurant_id:connection.restaurant_id,tenant_id:connection.restaurant_id,property_id:channel.property_id||null,
   connection_id:connection.id,channel_id:channel.id,event_type:'reservation_import',direction:'inbound',status:'queued',
   payload:{provider,webhook_id:idem,webhook_inbox_id:inbox.id,normalized_reservation:normalized},
   idempotency_key:queueKey,max_attempts:8,next_attempt_at:new Date().toISOString()
  },{onConflict:'idempotency_key'});
  if(queueError) throw queueError;
  await s.from('anaira_distribution_webhook_events').update({status:'queued'}).eq('id',inbox.id);
  return NextResponse.json({ok:true,received:true,verified:connection.webhook_signature_required!==false,event_id:externalId,queued:true,tenant_id:connection.restaurant_id});
 }catch(e){
  const status=Number(e?.status||500);const headers=status===429?{'Retry-After':String(e.retryAfter||60)}:{};
  return NextResponse.json({ok:false,error:e?.message||'Webhook processing failed'},{status,headers});
 }
}
