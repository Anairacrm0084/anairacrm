import {NextResponse} from 'next/server';
import {supabase} from '../../../../../lib/supabase';
export const runtime='nodejs';
export async function POST(req){
 try{
  const b=await req.json();
  if(!b?.booking_code||!b?.phone) return NextResponse.json({ok:false,error:'booking_code and phone are required'},{status:400});
  const {data,error}=await supabase.rpc('anaira_public_booking_invoice',{p_booking_code:b.booking_code,p_guest_phone:b.phone});
  if(error) throw error;
  return NextResponse.json(data||{ok:true});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Invoice lookup failed'},{status:400})}
}
