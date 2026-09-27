import {db} from '../../../../../lib/server/provider';
import {processQueuedWebhookEvents} from '../../../../../lib/server/review-engine';
export const runtime='nodejs';
function decodeData(v){try{return JSON.parse(Buffer.from(String(v||''),'base64').toString('utf8'))}catch{return {}}}
export async function POST(req){try{
  const expected=process.env.GOOGLE_PUBSUB_WEBHOOK_SECRET;if(!expected)throw new Error('GOOGLE_PUBSUB_WEBHOOK_SECRET is not configured');
  const url=new URL(req.url);const supplied=req.headers.get('x-anaira-webhook-secret')||url.searchParams.get('token');if(supplied!==expected)throw new Error('Unauthorized Google Pub/Sub webhook');
  const payload=await req.json();const msg=payload.message||{};const eventKey=String(msg.messageId||msg.attributes?.eventId||msg.data||JSON.stringify(payload));const s=db();
  const {data:existing}=await s.from('crm_review_webhook_events').select('id,status').eq('provider','google_business_profile').eq('event_key',eventKey).maybeSingle();if(existing)return Response.json({ok:true,duplicate:true});
  const decoded=decodeData(msg.data);const locationId=decoded.location?.split('/').pop()||decoded.locationId||decoded.resourceName?.match(/locations\/([^/]+)/)?.[1]||null;let tenantId=null;
  if(locationId){const {data:src}=await s.from('crm_review_sources').select('tenant_id,id').eq('source','google').eq('location_id',locationId).maybeSingle();tenantId=src?.tenant_id||null;if(src)await s.from('crm_review_provider_sync').update({next_sync_at:new Date().toISOString(),status:'webhook_received'}).eq('source_id',src.id).eq('tenant_id',tenantId);}
  await s.from('crm_review_webhook_events').insert({tenant_id:tenantId,provider:'google_business_profile',event_key:eventKey,event_type:msg.attributes?.eventType||decoded.eventType||'review_event',payload:{...payload,decoded},status:'queued'});
  const processed=await processQueuedWebhookEvents({limit:1});
  return Response.json({ok:true,accepted:true,tenantId,locationId,processed});
}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
