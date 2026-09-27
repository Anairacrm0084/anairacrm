export async function sendReviewRequest(job,customer){
  const phone=customer?.phone,email=customer?.email;const body=job.message||`We'd love your feedback: ${job.review_url}`;
  if(job.channel==='whatsapp'){
    const token=process.env.WHATSAPP_ACCESS_TOKEN,id=process.env.WHATSAPP_PHONE_NUMBER_ID;if(!token||!id)throw new Error('WhatsApp Cloud API credentials not configured');if(!phone)throw new Error('Customer phone is missing');
    const r=await fetch(`https://graph.facebook.com/v22.0/${id}/messages`,{method:'POST',headers:{Authorization:`Bearer ${token}`,'content-type':'application/json'},body:JSON.stringify({messaging_product:'whatsapp',to:phone.replace(/\D/g,''),type:'text',text:{body}})});const j=await r.json();if(!r.ok)throw new Error(j.error?.message||'WhatsApp send failed');return {provider:'meta_whatsapp',provider_message_id:j.messages?.[0]?.id||null,response:j};
  }
  if(job.channel==='sms'){
    if(!phone)throw new Error('Customer phone is missing');if(process.env.TWILIO_ACCOUNT_SID&&process.env.TWILIO_AUTH_TOKEN&&process.env.TWILIO_FROM){const auth=Buffer.from(`${process.env.TWILIO_ACCOUNT_SID}:${process.env.TWILIO_AUTH_TOKEN}`).toString('base64');const r=await fetch(`https://api.twilio.com/2010-04-01/Accounts/${process.env.TWILIO_ACCOUNT_SID}/Messages.json`,{method:'POST',headers:{Authorization:`Basic ${auth}`,'content-type':'application/x-www-form-urlencoded'},body:new URLSearchParams({From:process.env.TWILIO_FROM,To:phone,Body:body})});const j=await r.json();if(!r.ok)throw new Error(j.message||'Twilio SMS failed');return {provider:'twilio',provider_message_id:j.sid,response:j};}
    throw new Error('SMS provider credentials not configured');
  }
  if(job.channel==='email'){
    if(!email)throw new Error('Customer email is missing');if(!process.env.RESEND_API_KEY||!process.env.RESEND_FROM)throw new Error('Resend email credentials not configured');const r=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${process.env.RESEND_API_KEY}`,'content-type':'application/json'},body:JSON.stringify({from:process.env.RESEND_FROM,to:[email],subject:'We value your feedback',text:body})});const j=await r.json();if(!r.ok)throw new Error(j.message||'Resend email failed');return {provider:'resend',provider_message_id:j.id,response:j};
  }
  throw new Error(`Unsupported channel: ${job.channel}`);
}
