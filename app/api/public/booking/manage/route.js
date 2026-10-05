import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {supabase} from '../../../../../lib/supabase';
export const runtime='nodejs';
export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'public-booking:manage',limit:20,windowSeconds:60});
  const b=await req.json(); const action=b?.action||'lookup';
  if(!b?.booking_code||!b?.phone) return NextResponse.json({ok:false,error:'Booking code and phone are required.'},{status:400});
  if(action==='lookup'){
    const {data,error}=await supabase.rpc('anaira_public_booking_lookup',{p_booking_code:b.booking_code,p_guest_phone:b.phone});
    if(error) throw error; return NextResponse.json(data);
  }
  if(action==='cancel'){
    const {data,error}=await supabase.rpc('anaira_public_booking_cancel',{p_booking_code:b.booking_code,p_guest_phone:b.phone,p_reason:b.reason||'Guest requested cancellation'});
    if(error) throw error; return NextResponse.json(data);
  }
  if(action==='modify'){
    const {data,error}=await supabase.rpc('anaira_public_booking_modify',{
      p_booking_code:b.booking_code,p_guest_phone:b.phone,p_new_check_in:b.new_check_in,p_new_check_out:b.new_check_out,
      p_reason:b.notes||null,p_idempotency_key:b.idempotency_key||`guest-modify:${b.booking_code}:${b.new_check_in}:${b.new_check_out}`
    });
    if(error) throw error; return NextResponse.json(data);
  }
  if(action==='invoice'){
    const {data,error}=await supabase.rpc('anaira_public_booking_invoice',{p_booking_code:b.booking_code,p_guest_phone:b.phone});
    if(error) throw error; return NextResponse.json(data);
  }
  return NextResponse.json({ok:false,error:'Unsupported action'},{status:400});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Booking action failed'},{status:400})}
}
