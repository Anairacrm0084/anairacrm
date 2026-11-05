import {NextResponse} from 'next/server';
import crypto from 'node:crypto';
import {db} from '../../../../../lib/server/provider';
import {idempotencyKey} from '../../../../../lib/server/distribution/runtime';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {verifyDistributionWebhook} from '../../../../../lib/server/webhookSecurity.js';
import {OTA_PROPERTY_BUSINESS_TYPES} from '../../../../../lib/server/distribution/property-guard';
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
    .select('id,restaurant_id,provider_account_ref,config,webhook_signature_required,webhook_enabled,status')
    .eq('platform_id',platform.id).eq('webhook_enabled',true).in('status',['configured','connected']);
  if(ce) throw ce;
  const {data:eligibleBusinesses,error:eligibleError}=await s.from('restaurants').select('id').in('business_type',OTA_PROPERTY_BUSINESS_TYPES);
  if(eligibleError) throw eligibleError;
  const eligibleIds=new Set((eligibleBusinesses||[]).map(x=>x.id));
  const candidates=(connections||[]).filter(c=>eligibleIds.has(c.restaurant_id));
  if(!candidates.length) return NextResponse.json({ok:false,error:'No active webhook connection is configured for this provider.'},{status:503});
  // A provider may have many tenant connections. Never fan one OTA booking out
  // to every property: resolve exactly one connection using its provider account
  // or property reference, and reject ambiguous payloads.
  const accountRef=String(body.provider_account_ref||body.account_id||body.hotel_id||body.property_id||body.listing_id||body.property?.id||'').trim();
  let targetConnections=candidates;
  if(candidates.length>1){
    if(!accountRef) return NextResponse.json({ok:false,error:'Webhook payload is missing the provider account/property reference needed to route it safely.'},{status:409});
    targetConnections=candidates.filter(c=>{
      const cfg=c.config&&typeof c.config==='object'?c.config:{};
      const refs=[c.provider_account_ref,cfg.provider_account_ref,cfg.provider_property_id,cfg.external_property_id,cfg.listing_id,cfg.hotel_id].filter(Boolean).map(String);
      return refs.includes(accountRef);
    });
    if(targetConnections.length!==1) return NextResponse.json({ok:false,error:targetConnections.length?'Webhook account reference matches multiple Anaira properties.':'No Anaira property is mapped to this provider account reference.'},{status:409});
  }
  const connection=targetConnections[0];
  if(connection.webhook_signature_required!==false){
    try{verifyDistributionWebhook({req,raw,provider,connection});}
    catch(e){return NextResponse.json({ok:false,error:e?.message||'Invalid webhook signature.'},{status:Number(e?.status||401)});}
  }

  const externalId=String(body.event_id||body.id||body.reservation_id||crypto.createHash('sha256').update(raw).digest('hex'));
  const idem=idempotencyKey([provider,connection.id,externalId]);
  const {data:existing}=await s.from('anaira_distribution_webhook_events').select('id,status').eq('idempotency_key',idem).maybeSingle();
  if(existing?.status==='processed'||existing?.status==='queued') return NextResponse.json({ok:true,duplicate:true,event_id:externalId});
  const eventType=String(body.event_type||body.type||'reservation');
  const {error:insertError}=await s.from('anaira_distribution_webhook_events').upsert({platform_id:platform.id,provider_code:provider,external_event_id:externalId,idempotency_key:idem,event_type:eventType,payload:body,status:'received',received_at:new Date().toISOString()},{onConflict:'idempotency_key'});
  if(insertError) throw insertError;
  let queued=0;
  for(const c of targetConnections){
    const tenantIdem=idempotencyKey([idem,c.restaurant_id]);
    const {error}=await s.from('ota_sync_events').upsert({restaurant_id:c.restaurant_id,connection_id:c.id,channel_id:null,event_type:'reservation',direction:'inbound',status:'queued',payload:{direction:'inbound',provider,event_type:eventType,external_event_id:externalId,data:body,webhook_id:idem},idempotency_key:tenantIdem,max_attempts:8,next_attempt_at:new Date().toISOString()},{onConflict:'idempotency_key'});
    if(error) throw error;
    queued++;
  }
  await s.from('anaira_distribution_webhook_events').update({status:'queued',processed_at:null}).eq('idempotency_key',idem);
  return NextResponse.json({ok:true,received:true,verified:connection.webhook_signature_required!==false,event_id:externalId,queued_connections:queued,restaurant_id:connection.restaurant_id});
 }catch(e){
  const status=Number(e?.status||500);
  const headers=status===429?{'Retry-After':String(e.retryAfter||60)}:{};
  return NextResponse.json({ok:false,error:e?.message||'Webhook processing failed'},{status,headers});
 }
}
