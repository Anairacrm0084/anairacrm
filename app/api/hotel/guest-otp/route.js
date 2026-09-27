import {createHash, randomInt} from 'crypto';
import {createClient} from '@supabase/supabase-js';

export const runtime = 'nodejs';

const supabaseAdmin = () => createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {auth:{autoRefreshToken:false,persistSession:false}}
);

const normalizeEmail = v => String(v||'').trim().toLowerCase();
const normalizePhone = v => String(v||'').replace(/\D/g,'');
const hash = v => createHash('sha256').update(String(v)).digest('hex');
const maskEmail = v => { const [u,d] = v.split('@'); return `${(u||'').slice(0,2)}***@${d||''}`; };
const maskPhone = v => { const n=normalizePhone(v); return `${'*'.repeat(Math.max(0,n.length-4))}${n.slice(-4)}`; };
const appError = (message,status=400) => Response.json({ok:false,error:message},{status});

const getOtpSecret = () => {
  const explicit = String(process.env.ANAIRA_SECRET_KEY || '').trim();
  if (explicit) return explicit;
  const serviceRole = String(process.env.SUPABASE_SERVICE_ROLE_KEY || '').trim();
  if (serviceRole) return hash(`anaira-guest-otp:${serviceRole}`);
  return '';
};

async function sendEmail(to, otp){
  if(!process.env.RESEND_API_KEY || !process.env.RESEND_FROM) throw new Error('Email OTP provider is not configured. Add RESEND_API_KEY and RESEND_FROM.');
  const r=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${process.env.RESEND_API_KEY}`,'content-type':'application/json'},body:JSON.stringify({from:process.env.RESEND_FROM,to:[to],subject:'Your hotel booking verification code',text:`Your Anaira hotel booking verification code is ${otp}. It expires in 10 minutes. Do not share this code.`})});
  const j=await r.json().catch(()=>({})); if(!r.ok) throw new Error(j.message||'Email OTP delivery failed'); return {provider:'resend',id:j.id};
}

async function sendSms(to, otp){
  if(!process.env.TWILIO_ACCOUNT_SID || !process.env.TWILIO_AUTH_TOKEN || !process.env.TWILIO_FROM) throw new Error('SMS OTP provider is not configured. Add TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN and TWILIO_FROM.');
  const auth=Buffer.from(`${process.env.TWILIO_ACCOUNT_SID}:${process.env.TWILIO_AUTH_TOKEN}`).toString('base64');
  const r=await fetch(`https://api.twilio.com/2010-04-01/Accounts/${process.env.TWILIO_ACCOUNT_SID}/Messages.json`,{method:'POST',headers:{Authorization:`Basic ${auth}`,'content-type':'application/x-www-form-urlencoded'},body:new URLSearchParams({From:process.env.TWILIO_FROM,To:to,Body:`Your Anaira hotel booking OTP is ${otp}. It expires in 10 minutes. Do not share it.`})});
  const j=await r.json().catch(()=>({})); if(!r.ok) throw new Error(j.message||'SMS OTP delivery failed'); return {provider:'twilio',id:j.sid};
}

export async function POST(req){
  try{
    const body=await req.json();
    const tenantId=String(body.tenant_id||'').trim(), channel=body.channel==='email'?'email':body.channel==='phone'?'phone':null;
    if(!tenantId||!channel) return appError('tenant_id and channel are required.');
    const destination=channel==='email'?normalizeEmail(body.email):normalizePhone(body.phone);
    if(channel==='email' && !/^\S+@\S+\.\S+$/.test(destination)) return appError('Enter a valid email address.');
    if(channel==='phone' && destination.length<8) return appError('Enter a valid mobile number.');
    const otpSecret=getOtpSecret();
    if(!otpSecret) return appError('OTP server secret is not configured. Set ANAIRA_SECRET_KEY or ensure SUPABASE_SERVICE_ROLE_KEY is available.',500);
    const db=supabaseAdmin();
    const {data:tenant,error:tenantError}=await db.from('hms_settings').select('restaurant_id').eq('restaurant_id',tenantId).maybeSingle();
    if(tenantError) throw tenantError;
    if(!tenant) return appError('Hotel configuration was not found.',404);
    const destinationHash=hash(`${channel}:${destination}`);
    const {data:recent}=await db.from('anaira_guest_otp_challenges').select('last_sent_at').eq('tenant_id',tenantId).eq('destination_hash',destinationHash).order('created_at',{ascending:false}).limit(1).maybeSingle();
    if(recent?.last_sent_at && Date.now()-new Date(recent.last_sent_at).getTime()<60000) return appError('Please wait 60 seconds before requesting another OTP.',429);
    const otp=String(randomInt(100000,1000000));
    const otpHash=hash(`${otpSecret}:${channel}:${destination}:${otp}`);
    const {data:challenge,error:insertError}=await db.from('anaira_guest_otp_challenges').insert({tenant_id:tenantId,channel,destination_hash:destinationHash,destination_masked:channel==='email'?maskEmail(destination):maskPhone(destination),otp_hash:otpHash,expires_at:new Date(Date.now()+10*60*1000).toISOString(),last_sent_at:new Date().toISOString()}).select('id,destination_masked,expires_at').single();
    if(insertError) throw insertError;
    try { if(channel==='email') await sendEmail(destination,otp); else await sendSms(destination,otp); }
    catch(e){ await db.from('anaira_guest_otp_challenges').delete().eq('id',challenge.id); throw e; }
    return Response.json({ok:true,verification_id:challenge.id,channel,destination_masked:challenge.destination_masked,expires_at:challenge.expires_at});
  }catch(e){return appError(e.message||'Unable to send OTP.',500)}
}

export async function PUT(req){
  try{
    const body=await req.json(); const verificationId=String(body.verification_id||'').trim(); const channel=body.channel==='email'?'email':body.channel==='phone'?'phone':null;
    if(!verificationId||!channel) return appError('verification_id and channel are required.');
    const otpSecret=getOtpSecret();
    if(!otpSecret) return appError('OTP server secret is not configured. Set ANAIRA_SECRET_KEY or ensure SUPABASE_SERVICE_ROLE_KEY is available.',500);
    const destination=channel==='email'?normalizeEmail(body.email):normalizePhone(body.phone); const code=String(body.otp||'').trim();
    if(!destination||!/^[0-9]{6}$/.test(code)) return appError('Enter the 6-digit OTP.');
    const db=supabaseAdmin(); const destinationHash=hash(`${channel}:${destination}`);
    const {data:row,error}=await db.from('anaira_guest_otp_challenges').select('*').eq('id',verificationId).eq('destination_hash',destinationHash).eq('channel',channel).maybeSingle();
    if(error) throw error; if(!row) return appError('Verification request not found.');
    if(row.verified_at) return Response.json({ok:true,verified:true,verification_id:row.id});
    if(new Date(row.expires_at).getTime()<Date.now()) return appError('OTP expired. Please request a new code.',410);
    if(row.attempts>=row.max_attempts) return appError('Too many incorrect attempts. Please request a new OTP.',429);
    const expected=hash(`${otpSecret}:${channel}:${destination}:${code}`);
    if(expected!==row.otp_hash){ await db.from('anaira_guest_otp_challenges').update({attempts:row.attempts+1}).eq('id',row.id); return appError('Invalid OTP.'); }
    const {error:updateError}=await db.from('anaira_guest_otp_challenges').update({verified_at:new Date().toISOString()}).eq('id',row.id); if(updateError) throw updateError;
    return Response.json({ok:true,verified:true,verification_id:row.id,destination_masked:row.destination_masked});
  }catch(e){return appError(e.message||'Unable to verify OTP.',500)}
}
