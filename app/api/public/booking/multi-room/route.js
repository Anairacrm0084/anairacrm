import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {adminDb} from '../../../../../lib/server/provider';
export const runtime='nodejs';
export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'multi-room',limit:10,windowSeconds:60});const b=await req.json();if(!b?.hotel_id||!b?.guest_name||!b?.phone||!b?.check_in||!b?.check_out||!Array.isArray(b.rooms)||!b.rooms.length)return NextResponse.json({ok:false,error:'Hotel, guest, dates and at least one room are required'},{status:400});const {data,error}=await adminDb().rpc('anaira_create_multi_room_booking_transaction',{p_tenant_id:b.hotel_id,p_guest_name:b.guest_name,p_guest_phone:b.phone,p_guest_email:b.email||null,p_check_in:b.check_in,p_check_out:b.check_out,p_rooms:b.rooms,p_coupon_code:b.coupon_code||null,p_idempotency_key:b.idempotency_key||null,p_source:b.source||'anaira-direct',p_verification_id:b.verification_id||null});if(error)throw error;return NextResponse.json(data||{ok:true});}catch(e){return NextResponse.json({ok:false,error:e?.message||'Multi-room booking failed'},{status:400})}}
