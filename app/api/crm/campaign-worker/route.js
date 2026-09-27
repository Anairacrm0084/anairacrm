import { createClient } from '@supabase/supabase-js';
export const runtime='nodejs';
function db(){const u=process.env.NEXT_PUBLIC_SUPABASE_URL,k=process.env.SUPABASE_SERVICE_ROLE_KEY;if(!u||!k)throw new Error('Server Supabase credentials are not configured.');return createClient(u,k,{auth:{persistSession:false,autoRefreshToken:false}})}
async function send(job){
 const p=job.payload||{}; const channel=String(job.channel||'').toLowerCase();
 if(channel==='in_app') return {provider:'anaira',provider_message_id:job.id};
 if(channel==='whatsapp'){
  const token=process.env.WHATSAPP_ACCESS_TOKEN,phoneId=process.env.WHATSAPP_PHONE_NUMBER_ID;if(!token||!phoneId)throw new Error('WhatsApp provider credentials are not configured.');
  const res=await fetch(`https://graph.facebook.com/v22.0/${phoneId}/messages`,{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify({messaging_product:'whatsapp',to:p.phone,type:'text',text:{body:p.body||p.message||''}})});const j=await res.json();if(!res.ok)throw new Error(j.error?.message||'WhatsApp send failed');return {provider:'whatsapp',provider_message_id:j.messages?.[0]?.id||null};
 }
 if(channel==='email'){
  const url=process.env.CRM_EMAIL_WEBHOOK_URL;if(!url)throw new Error('CRM_EMAIL_WEBHOOK_URL is not configured.');const res=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(p)});if(!res.ok)throw new Error('Email provider rejected request');return {provider:'email'};
 }
 if(channel==='sms'){
  const url=process.env.CRM_SMS_WEBHOOK_URL;if(!url)throw new Error('CRM_SMS_WEBHOOK_URL is not configured.');const res=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(p)});if(!res.ok)throw new Error('SMS provider rejected request');return {provider:'sms'};
 }
 throw new Error(`Unsupported campaign channel: ${channel}`);
}
export async function POST(req){try{const secret=process.env.CRON_SECRET;if(!secret||req.headers.get('authorization')!==`Bearer ${secret}`)throw new Error('Unauthorized cron request');const supabase=db();const {data:jobs,error}=await supabase.rpc('anaira_claim_campaign_jobs',{p_limit:25});if(error)throw error;let sent=0,failed=0;for(const job of jobs||[]){try{const r=await send(job);await supabase.from('crm_campaign_queue').update({status:'sent',sent_at:new Date().toISOString(),payload:{...(job.payload||{}),provider:r}}).eq('id',job.id);sent++;}catch(e){failed++;await supabase.from('crm_campaign_queue').update({status:job.attempts>=5?'failed':'queued',available_at:new Date(Date.now()+Math.min(3600000,2**job.attempts*60000)).toISOString(),last_error:e.message}).eq('id',job.id);}}return Response.json({ok:true,claimed:(jobs||[]).length,sent,failed});}catch(e){return Response.json({ok:false,error:e.message},{status:500});}}
