import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {supabase} from '../../../../../lib/supabase';
export const runtime='nodejs';
function cors(body,status=200){return NextResponse.json(body,{status,headers:{'Access-Control-Allow-Origin':'*','Access-Control-Allow-Methods':'GET,OPTIONS','Access-Control-Allow-Headers':'Content-Type','Cache-Control':'no-store'}})}
export async function OPTIONS(){return cors({ok:true})}
export async function GET(req){
 try{
  await enforceRateLimit(req,{scope:'public-booking:availability',limit:120,windowSeconds:60});
  const u=new URL(req.url);const restaurantId=u.searchParams.get('hotel_id');const checkIn=u.searchParams.get('check_in');const checkOut=u.searchParams.get('check_out');const adults=Math.max(1,Number(u.searchParams.get('adults')||2));const children=Math.max(0,Number(u.searchParams.get('children')||0));const hospitalityType=u.searchParams.get('hospitality_type')||u.searchParams.get('stay_type')||'hotel';
  if(!restaurantId||!checkIn||!checkOut||checkOut<=checkIn)return cors({ok:false,error:'hotel_id, check_in and check_out are required.'},400);
  const {data,error}=await supabase.rpc('anaira_public_hospitality_room_availability_by_id',{p_restaurant_id:restaurantId,p_check_in:checkIn,p_check_out:checkOut,p_adults:adults,p_children:children,p_hospitality_type:hospitalityType});if(error)throw error;
  return cors({ok:true,hotel_id:restaurantId,hospitality_type:hospitalityType,check_in:checkIn,check_out:checkOut,adults,children,rooms:data||[]});
 }catch(e){return cors({ok:false,error:e?.message||'Availability lookup failed.'},400)}
}
