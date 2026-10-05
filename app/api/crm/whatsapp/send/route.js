import {db,open} from '../../../../../lib/server/provider';
export const runtime='nodejs';
export async function POST(req){
  try{
    const body=await req.json();
    const tenantId=String(body.tenantId||''); const messageId=String(body.messageId||'');
    if(!tenantId||!messageId) return Response.json({ok:false,error:'tenantId and messageId are required.'},{status:400});
    const s=db();
    const {data:m,error:me}=await s.from('crm_whatsapp_messages').select('*').eq('tenant_id',tenantId).eq('id',messageId).single(); if(me) throw me;
    const {data:conv}=await s.from('crm_whatsapp_conversations').select('phone_number').eq('tenant_id',tenantId).eq('id',m.conversation_id).maybeSingle();
    const {data:c,error:ce}=await s.from('crm_provider_configs').select('*').eq('tenant_id',tenantId).eq('channel','whatsapp').eq('enabled',true).limit(1).maybeSingle(); if(ce) throw ce;
    if(!c) return Response.json({ok:false,status:'NOT_CONNECTED',error:'WhatsApp provider is not configured.'},{status:409});
    const cfg=c.config||{}; const provider=String(c.provider||'').toLowerCase();
    if(!['meta','meta_cloud','whatsapp_cloud_api','whatsapp'].includes(provider)) return Response.json({ok:false,status:'UNSUPPORTED_PROVIDER',error:`Unsupported WhatsApp provider: ${c.provider}`},{status:400});
    const token=c.secret_ref?open(c.secret_ref):String(cfg.access_token||''); const phoneId=String(c.sender_identity||cfg.phone_number_id||'');
    if(!token||!phoneId) return Response.json({ok:false,status:'NOT_CONNECTED',error:'WhatsApp access token or sender identity is missing.'},{status:409});
    const to=String(body.phone||conv?.phone_number||''); if(!to) return Response.json({ok:false,status:'INVALID_RECIPIENT',error:'Recipient phone is required.'},{status:400});
    const payload=m.message_type==='template'?{messaging_product:'whatsapp',to,type:'template',template:{name:cfg.template_name||m.body,language:{code:cfg.language_code||'en_US'}}}:{messaging_product:'whatsapp',to,type:'text',text:{body:m.body||''}};
    const r=await fetch(`https://graph.facebook.com/v20.0/${encodeURIComponent(phoneId)}/messages`,{method:'POST',headers:{authorization:`Bearer ${token}`,'content-type':'application/json'},body:JSON.stringify(payload)});
    const j=await r.json(); if(!r.ok) throw new Error(j?.error?.message||'WhatsApp provider send failed.');
    const providerMessageId=j?.messages?.[0]?.id||null;
    const {data:u,error:ue}=await s.from('crm_whatsapp_messages').update({status:'sent',provider_message_id:providerMessageId,sent_at:new Date().toISOString()}).eq('id',messageId).eq('tenant_id',tenantId).select().single(); if(ue) throw ue;
    await s.from('crm_message_log').update({status:'sent',provider_message_id:providerMessageId}).eq('tenant_id',tenantId).eq('id',body.messageLogId||'00000000-0000-0000-0000-000000000000');
    return Response.json({ok:true,status:'sent',provider_message_id:providerMessageId,message:u});
  }catch(e){return Response.json({ok:false,error:e.message},{status:400});}
}
