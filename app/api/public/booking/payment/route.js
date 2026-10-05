import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {supabase} from '../../../../../lib/supabase';
export const runtime='nodejs';
export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'public-booking:payment',limit:10,windowSeconds:60});
  const b=await req.json();
  for(const k of ['booking_code','phone','payment_method']) if(!b?.[k]) return NextResponse.json({ok:false,error:`${k} is required`},{status:400});
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
