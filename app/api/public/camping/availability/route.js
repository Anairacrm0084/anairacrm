import {NextResponse} from 'next/server';
import {supabase} from '../../../../../lib/supabase';
export const runtime='nodejs';
const json=(body,status=200)=>NextResponse.json(body,{status,headers:{'Cache-Control':'no-store'}});
export async function GET(req){
 try{
  const u=new URL(req.url),restaurantId=u.searchParams.get('camp_id'),checkIn=u.searchParams.get('check_in'),checkOut=u.searchParams.get('check_out');
  const adults=Math.max(1,Number(u.searchParams.get('adults')||1)),children=Math.max(0,Number(u.searchParams.get('children')||0));
  if(!restaurantId||!checkIn||!checkOut||checkOut<=checkIn)return json({ok:false,error:'camp_id, check_in and check_out are required.'},400);
  const {data,error}=await supabase.rpc('anaira_public_camp_availability',{p_restaurant_id:restaurantId,p_check_in:checkIn,p_check_out:checkOut,p_adults:adults,p_children:children});
  if(error)throw error;return json({ok:true,camp_id:restaurantId,check_in:checkIn,check_out:checkOut,adults,children,units:data||[]});
 }catch(e){return json({ok:false,error:e?.message||'Camping availability lookup failed.'},400)}
}
