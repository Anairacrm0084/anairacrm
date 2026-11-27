import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {supabase} from '../../../../../lib/supabase';
import {adminDb} from '../../../../../lib/server/provider';
import {createHash} from 'crypto';
export const runtime='nodejs';
const hash=value=>createHash('sha256').update(String(value)).digest('hex');
const digits=value=>String(value||'').replace(/\D/g,'');
const email=value=>String(value||'').trim().toLowerCase();
export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'public-booking:payment',limit:10,windowSeconds:60});
  const b=await req.json();
  for(const k of ['booking_code','payment_method']) if(!b?.[k]) return NextResponse.json({ok:false,error:`${k} is required`},{status:400});
  if(String(b.hospitality_type||'').toLowerCase()==='camp'){
    if(!b.restaurant_id||!b.verification_id||!['phone','email'].includes(b.verification_channel)) return NextResponse.json({ok:false,error:'Property and verified guest contact are required.'},{status:400});
    if(b.payment_method!=='pay_at_hotel'&&!b.proof_url) return NextResponse.json({ok:false,error:'Payment receipt/screenshot is required.'},{status:400});
    const db=adminDb();
    const {data:camp,error:campError}=await db.from('camp_reservations').select('id,restaurant_id,reservation_code,guest_phone,guest_email,status').eq('restaurant_id',b.restaurant_id).eq('reservation_code',String(b.booking_code).trim()).maybeSingle();
    if(campError) throw campError;
    if(!camp) throw new Error('Camping booking not found.');
    const destination=b.verification_channel==='email'?email(b.email):digits(b.phone);
    const expected=b.verification_channel==='email'?email(camp.guest_email):digits(camp.guest_phone);
    if(!destination||destination!==expected) throw new Error('Verified guest contact does not match this booking.');
    const {data:challenge,error:challengeError}=await db.from('anaira_guest_otp_challenges').select('id,tenant_id,channel,destination_hash,verified_at').eq('id',b.verification_id).eq('tenant_id',camp.restaurant_id).eq('channel',b.verification_channel).maybeSingle();
    if(challengeError) throw challengeError;
    if(!challenge?.verified_at||challenge.destination_hash!==hash(`${b.verification_channel}:${destination}`)||new Date(challenge.verified_at).getTime()<Date.now()-30*60*1000) throw new Error('Guest OTP verification is missing or expired. Please verify again.');
    const method=b.payment_method==='pay_at_hotel'?'pay_at_camp':b.payment_method;
    const {data:finalized,error}=await db.rpc('anaira_finalize_public_camp_booking',{p_reservation_id:camp.id,p_payment_method:method,p_reference:b.reference||null,p_proof_url:b.proof_url||null,p_notes:b.notes||null});
    if(error) throw error;
    return NextResponse.json({ok:true,state:'confirmed',booking_code:camp.reservation_code,reservation_id:camp.id,...(finalized||{})});
  }
  if(!b.phone) return NextResponse.json({ok:false,error:'phone is required'},{status:400});
  const {data:lookup,error:le}=await supabase.rpc('anaira_public_booking_lookup',{p_booking_code:b.booking_code,p_guest_phone:b.phone});
  if(le) throw le;
  const booking=lookup?.booking;
  if(!booking?.id) throw new Error('Booking not found');
  const {data,error}=await supabase.rpc('anaira_submit_hotel_payment',{
   p_reservation_id:booking.id,p_payment_method:b.payment_method,
   p_reference:b.reference||null,p_proof_url:b.proof_url||null,p_notes:b.notes||null
  });
  if(error) throw error;
  return NextResponse.json(data||{ok:true,booking_code:booking.booking_code});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Payment submission failed'},{status:400})}
}
