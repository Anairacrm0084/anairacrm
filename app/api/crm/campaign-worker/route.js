import { createClient } from '@supabase/supabase-js';
export const runtime='nodejs';
function db(){const u=process.env.NEXT_PUBLIC_SUPABASE_URL,k=process.env.SUPABASE_SERVICE_ROLE_KEY;if(!u||!k)throw new Error('Server Supabase credentials are not configured.');return createClient(u,k,{auth:{persistSession:false,autoRefreshToken:false}})}
async function send(job){
 const p=job.payload||{},channel=String(job.channel||'').toLowerCase();
 if(channel==='in_app')return {provider:'anaira',provider_message_id:job.id};
 if(channel==='whatsapp'){const token=process.env.WHATSAPP_ACCESS_TOKEN,phoneId=process.env.WHATSAPP_PHONE_NUMBER_ID;if(!token||!phoneId)throw new Error('WhatsApp provider credentials are not configured.');const res=await fetch(`https://graph.facebook.com/v22.0/${phoneId}/messages`,{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify({messaging_product:'whatsapp',to:String(p.phone||'').replace(/\D/g,''),type:'text',text:{body:p.body||p.message||''}})});const j=await res.json().catch(()=>({}));if(!res.ok)throw new Error(j.error?.message||'WhatsApp send failed');return {provider:'meta_whatsapp',provider_message_id:j.messages?.[0]?.id||null};}
 if(channel==='email'){if(!process.env.RESEND_API_KEY||!process.env.RESEND_FROM)throw new Error('Email provider credentials are not configured.');const res=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${process.env.RESEND_API_KEY}`,'Content-Type':'application/json'},body:JSON.stringify({from:process.env.RESEND_FROM,to:[p.email],subject:p.subject||'Message from Anaira',text:p.body||p.message||''})});const j=await res.json().catch(()=>({}));if(!res.ok)throw new Error(j.message||'Email provider rejected request');return {provider:'resend',provider_message_id:j.id||null};}
 if(channel==='sms'){if(!process.env.TWILIO_ACCOUNT_SID||!process.env.TWILIO_AUTH_TOKEN||!process.env.TWILIO_FROM)throw new Error('SMS provider credentials are not configured.');const auth=Buffer.from(`${process.env.TWILIO_ACCOUNT_SID}:${process.env.TWILIO_AUTH_TOKEN}`).toString('base64');const res=await fetch(`https://api.twilio.com/2010-04-01/Accounts/${process.env.TWILIO_ACCOUNT_SID}/Messages.json`,{method:'POST',headers:{Authorization:`Basic ${auth}`,'content-type':'application/x-www-form-urlencoded'},body:new URLSearchParams({From:process.env.TWILIO_FROM,To:p.phone,Body:p.body||p.message||''})});const j=await res.json().catch(()=>({}));if(!res.ok)throw new Error(j.message||'SMS provider rejected request');return {provider:'twilio',provider_message_id:j.sid||null};}
 throw new Error(`Unsupported campaign channel: ${channel}`);
}
export async function POST(req){
 try{
  const secret=process.env.CRON_SECRET;if(!secret||req.headers.get('authorization')!==`Bearer ${secret}`)throw new Error('Unauthorized cron request');
  const supabase=db();const {data:jobs,error}=await supabase.rpc('anaira_claim_campaign_jobs',{p_limit:25});if(error)throw error;
  let sent=0,failed=0;
  for(const job of jobs||[]){try{const r=await send(job);await supabase.from('crm_campaign_queue').update({status:'sent',sent_at:new Date().toISOString(),payload:{...(job.payload||{}),provider:r}}).eq('id',job.id);sent++;}catch(e){failed++;await supabase.from('crm_campaign_queue').update({status:Number(job.attempts||0)>=5?'failed':'queued',available_at:new Date(Date.now()+Math.min(3600000,2**Number(job.attempts||0)*60000)).toISOString(),last_error:e.message,attempts:Number(job.attempts||0)+1}).eq('id',job.id);}}
  return Response.json({ok:true,claimed:(jobs||[]).length,sent,failed});
 }catch(e){return Response.json({ok:false,error:e.message},{status:500});}
}
