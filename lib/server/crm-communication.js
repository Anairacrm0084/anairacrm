export function consentPurpose(channel){return channel==='whatsapp'?'whatsapp':channel==='email'?'email':'sms'}
export async function sendCrmMessage(channel,customer,message,subject){
 const phone=customer.phone,email=customer.email;
 if(channel==='whatsapp'){
  const token=process.env.WHATSAPP_ACCESS_TOKEN,id=process.env.WHATSAPP_PHONE_NUMBER_ID;if(!token||!id)throw new Error('WhatsApp Cloud API credentials are not configured.');if(!phone)throw new Error('Guest phone is missing.');
  const r=await fetch(`https://graph.facebook.com/v22.0/${id}/messages`,{method:'POST',headers:{Authorization:`Bearer ${token}`,'content-type':'application/json'},body:JSON.stringify({messaging_product:'whatsapp',to:phone.replace(/\D/g,''),type:'text',text:{body:message}})});const j=await r.json().catch(()=>({}));if(!r.ok)throw new Error(j.error?.message||'WhatsApp send failed');return {provider:'meta_whatsapp',id:j.messages?.[0]?.id||null};
 }
 if(channel==='sms'){
  if(!phone)throw new Error('Guest phone is missing.');if(!process.env.TWILIO_ACCOUNT_SID||!process.env.TWILIO_AUTH_TOKEN||!process.env.TWILIO_FROM)throw new Error('SMS provider credentials are not configured.');
  const auth=Buffer.from(`${process.env.TWILIO_ACCOUNT_SID}:${process.env.TWILIO_AUTH_TOKEN}`).toString('base64');const r=await fetch(`https://api.twilio.com/2010-04-01/Accounts/${process.env.TWILIO_ACCOUNT_SID}/Messages.json`,{method:'POST',headers:{Authorization:`Basic ${auth}`,'content-type':'application/x-www-form-urlencoded'},body:new URLSearchParams({From:process.env.TWILIO_FROM,To:phone,Body:message})});const j=await r.json().catch(()=>({}));if(!r.ok)throw new Error(j.message||'SMS send failed');return {provider:'twilio',id:j.sid||null};
 }
 if(!email)throw new Error('Guest email is missing.');if(!process.env.RESEND_API_KEY||!process.env.RESEND_FROM)throw new Error('Email provider credentials are not configured.');const r=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${process.env.RESEND_API_KEY}`,'content-type':'application/json'},body:JSON.stringify({from:process.env.RESEND_FROM,to:[email],subject:subject||'Message from Anaira',text:message})});const j=await r.json().catch(()=>({}));if(!r.ok)throw new Error(j.message||'Email send failed');return {provider:'resend',id:j.id||null};
}
