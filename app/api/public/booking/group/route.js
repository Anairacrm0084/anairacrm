import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {supabase} from '../../../../../lib/supabase';
export const runtime='nodejs';
export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'group',limit:10,windowSeconds:60});const b=await req.json();if(!b?.restaurant_id||!b?.group_name||!b?.contact_name||!b?.check_in||!b?.check_out)return NextResponse.json({ok:false,error:'Property, group, contact and dates are required'},{status:400});const {data,error}=await supabase.from('booking_group_requests').insert({restaurant_id:b.restaurant_id,group_name:b.group_name,contact_name:b.contact_name,email:b.email||null,phone:b.phone||null,check_in:b.check_in,check_out:b.check_out,rooms_requested:Math.max(1,Number(b.rooms_requested||1)),guests:Math.max(1,Number(b.guests||1)),budget:b.budget||null,notes:b.notes||null,metadata:b.metadata||{}}).select('id,status').single();if(error)throw error;return NextResponse.json({ok:true,...data});}catch(e){return NextResponse.json({ok:false,error:e.message},{status:400})}}
