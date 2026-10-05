import {NextResponse} from 'next/server';
import crypto from 'node:crypto';
import {db} from '../../../../../lib/server/provider';
import {idempotencyKey} from '../../../../../lib/server/distribution/runtime';
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
    .select('id,restaurant_id,config,webhook_signature_required,webhook_enabled,status')
    .eq('platform_id',platform.id).eq('webhook_enabled',true).in('status',['configured','connected']);
  if(ce) throw ce;
  const candidates=connections||[];
  if(!candidates.length) return NextResponse.json({ok:false,error:'No active webhook connection is configured for this provider.'},{status:503});
  let verified=false;
  let verificationError=null;
  for(const connection of candidates){
    if(connection.webhook_signature_required===false){verified=true;break;}
    try{verifyDistributionWebhook({req,raw,provider,connection});verified=true;break}catch(e){verificationError=e;}
  }
  if(!verified){
    const status=Number(verificationError?.status||401);
    return NextResponse.json({ok:false,error:verificationError?.message||'Invalid webhook signature.'},{status});
  }

  const externalId=String(body.event_id||body.id||body.reservation_id||crypto.createHash('sha256').update(raw).digest('hex'));
  const idem=idempotencyKey([provider,externalId]);
  const {data:existing}=await s.from('anaira_distribution_webhook_events').select('id,status').eq('idempotency_key',idem).maybeSingle();
  if(existing?.status==='processed'||existing?.status==='queued') return NextResponse.json({ok:true,duplicate:true,event_id:externalId});
  const eventType=String(body.event_type||body.type||'reservation');
  const {error:insertError}=await s.from('anaira_distribution_webhook_events').upsert({platform_id:platform.id,provider_code:provider,external_event_id:externalId,idempotency_key:idem,event_type:eventType,payload:body,status:'received',received_at:new Date().toISOString()},{onConflict:'idempotency_key'});
  if(insertError) throw insertError;
  let queued=0;
  for(const c of candidates){
    const tenantIdem=idempotencyKey([idem,c.restaurant_id]);
    const {error}=await s.from('ota_sync_events').upsert({restaurant_id:c.restaurant_id,connection_id:c.id,channel_id:null,event_type:'reservation',status:'queued',payload:{provider,event_type:eventType,external_event_id:externalId,data:body,webhook_id:idem},idempotency_key:tenantIdem,max_attempts:8,next_attempt_at:new Date().toISOString()},{onConflict:'idempotency_key'});
    if(error) throw error;
    queued++;
  }
  await s.from('anaira_distribution_webhook_events').update({status:'queued',processed_at:null}).eq('idempotency_key',idem);
  return NextResponse.json({ok:true,received:true,verified:true,event_id:externalId,queued_connections:queued});
 }catch(e){
  const status=Number(e?.status||500);
  const headers=status===429?{'Retry-After':String(e.retryAfter||60)}:{};
  return NextResponse.json({ok:false,error:e?.message||'Webhook processing failed'},{status,headers});
 }
}
