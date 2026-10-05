import crypto from 'node:crypto';
import {db} from '../../../../../../lib/server/provider';
export const runtime='nodejs';

function verify(req,raw,provider){
  const secret=process.env[`CRM_WEBHOOK_SECRET_${String(provider).toUpperCase()}`]||process.env.CRM_WEBHOOK_SECRET;
  if(!secret) throw new Error('CRM webhook secret is not configured.');
  const supplied=req.headers.get('x-anaira-webhook-signature')||'';
  const expected=crypto.createHmac('sha256',secret).update(raw).digest('hex');
  if(!supplied || !crypto.timingSafeEqual(Buffer.from(supplied),Buffer.from(expected))) throw new Error('Invalid webhook signature.');
}

export async function POST(req,{params}){
  try{
    const provider=String((await params)?.provider||'unknown').toLowerCase();
    const raw=await req.text();
    verify(req,raw,provider);
    const body=JSON.parse(raw||'{}');
    const identity=String(req.headers.get('x-anaira-provider-identity')||body.phone_number_id||body.account_sid||body.sender||'');
    const s=db();
    let tenantId=String(req.headers.get('x-anaira-tenant-id')||'');
    if(!tenantId && identity){const {data}=await s.from('crm_provider_configs').select('tenant_id').eq('provider',provider).eq('sender_identity',identity).eq('enabled',true).limit(1).maybeSingle();tenantId=data?.tenant_id||'';}
    if(!tenantId) throw new Error('Tenant could not be resolved for provider webhook.');
    const eventId=String(body.event_id||body.id||body.message_id||body.sid||crypto.createHash('sha256').update(raw).digest('hex'));
    const eventType=String(body.event_type||body.type||body.event||'status');
    const ins=await s.from('crm_provider_webhook_events').upsert({tenant_id:tenantId,provider,external_event_id:eventId,event_type:eventType,payload:body,status:'received'},{onConflict:'provider,external_event_id'}).select('id').maybeSingle();
    if(ins.error)throw ins.error;
    const channelCfg=await s.from('crm_provider_configs').select('channel').eq('tenant_id',tenantId).eq('provider',provider).eq('enabled',true).limit(1).maybeSingle();
    if(channelCfg.data?.channel==='whatsapp'){
      const providerMessageId=String(body.provider_message_id||body.message_id||body.message?.id||'');
      const status=String(body.status||body.event_type||body.type||'').toLowerCase();
      if(providerMessageId && ['sent','delivered','read','failed'].includes(status)){
        const patch={status}; if(status==='sent')patch.sent_at=new Date().toISOString(); if(status==='delivered')patch.delivered_at=new Date().toISOString(); if(status==='read')patch.read_at=new Date().toISOString(); if(status==='failed')patch.failed_at=new Date().toISOString();
        await s.from('crm_whatsapp_messages').update(patch).eq('tenant_id',tenantId).eq('provider_message_id',providerMessageId);
        await s.from('crm_whatsapp_delivery_events').upsert({tenant_id:tenantId,property_id:body.property_id||null,message_id:null,provider_message_id:providerMessageId,event_type:status,payload:body},{onConflict:'tenant_id,provider_message_id,event_type'});
      }
    }
    return Response.json({ok:true,duplicate:false,event_id:eventId,stored:!!ins.data});
  }catch(e){return Response.json({ok:false,error:e.message},{status:400});}
}
