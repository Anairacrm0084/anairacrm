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
    // A public guest submission must NOT approve the reservation or consume
    // inventory. Property admin approval is the only path that commits sold_units.
    if(camp.status!=='payment_pending'){
      if(camp.status==='confirmed') return NextResponse.json({ok:true,state:'already_confirmed',booking_code:camp.reservation_code,reservation_id:camp.id,status:'confirmed',payment_status:camp.payment_status});
      throw new Error('This camping booking is no longer awaiting property approval.');
    }
    const method=b.payment_method==='pay_at_hotel'?'pay_at_camp':b.payment_method;
    const hasProof=method==='bank_transfer'||method==='qr_upi';
    const {error:updateError}=await db.from('camp_reservations').update({
      payment_method:method,
      payment_reference:b.reference||null,
      payment_proof_url:b.proof_url||null,
      payment_status:hasProof?'proof_submitted':'pending',
      balance_amount:camp.total_amount,
      updated_at:new Date().toISOString()
    }).eq('id',camp.id).eq('restaurant_id',camp.restaurant_id).eq('status','payment_pending');
    if(updateError) throw updateError;
    await db.from('camp_booking_transactions').update({
      state:hasProof?'payment_proof_submitted':'payment_pending',
      updated_at:new Date().toISOString(),
      payload:{payment_method:method,payment_reference:b.reference||null,payment_proof_url:b.proof_url||null,approval_required:true}
    }).eq('reservation_id',camp.id);
    return NextResponse.json({
      ok:true,state:'pending_approval',status:'payment_pending',
      payment_status:hasProof?'proof_submitted':'pending',
      booking_code:camp.reservation_code,reservation_id:camp.id
    });
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
