import {NextResponse} from 'next/server';
import {createHash} from 'crypto';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {adminDb} from '../../../../../lib/server/provider';

export const runtime='nodejs';
const hash=value=>createHash('sha256').update(String(value)).digest('hex');
const normalizePhone=value=>String(value||'').replace(/\\D/g,'');
const normalizeEmail=value=>String(value||'').trim().toLowerCase();

export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'public-stay:finalize',limit:8,windowSeconds:60});
  const b=await req.json();
  if(!b?.reservation_id||!b?.verification_id||!b?.channel) return NextResponse.json({ok:false,error:'Reservation and verified guest contact are required.'},{status:400});
  const db=adminDb();
  const {data:r,error:re}=await db.from('anaira_stay_reservations').select('id,restaurant_id,guest_phone,guest_email,status').eq('id',b.reservation_id).maybeSingle();
  if(re) throw re;
  if(!r) return NextResponse.json({ok:false,error:'Reservation not found.'},{status:404});
  const channel=b.channel==='email'?'email':b.channel==='phone'?'phone':null;
  if(!channel) return NextResponse.json({ok:false,error:'Invalid verification channel.'},{status:400});
  const destination=channel==='email'?normalizeEmail(b.email):normalizePhone(b.phone);
  const expected=channel==='email'?normalizeEmail(r.guest_email):normalizePhone(r.guest_phone);
  if(!destination||destination!==expected) return NextResponse.json({ok:false,error:'Verified contact does not match the booking guest.'},{status:403});
  const {data:v,error:ve}=await db.from('anaira_guest_otp_challenges').select('id,verified_at,expires_at').eq('id',b.verification_id).eq('tenant_id',r.restaurant_id).eq('channel',channel).eq('destination_hash',hash(`${channel}:${destination}`)).maybeSingle();
  if(ve) throw ve;
  if(!v?.verified_at||new Date(v.verified_at).getTime()<Date.now()-30*60*1000||new Date(v.expires_at).getTime()<Date.now()) return NextResponse.json({ok:false,error:'Guest verification is missing or expired. Verify again.'},{status:403});
  const {data,error}=await db.rpc('anaira_finalize_public_stay_booking',{p_reservation_id:r.id,p_payment_method:b.payment_method,p_reference:b.reference||null,p_proof_url:b.proof_url||null,p_notes:b.notes||null});
  if(error) throw error;
  return NextResponse.json(data||{ok:true});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Booking finalization failed.'},{status:400});}
}
