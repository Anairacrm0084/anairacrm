import {NextResponse} from 'next/server';
import {supabase} from '../../../../../lib/supabase';
export const runtime='nodejs';
const json=(body,status=200)=>NextResponse.json(body,{status,headers:{'Cache-Control':'no-store'}});
export async function GET(req){
 try{
  const u=new URL(req.url), checkIn=u.searchParams.get('check_in'), checkOut=u.searchParams.get('check_out');
  const destination=u.searchParams.get('destination')||null, adults=Math.max(1,Number(u.searchParams.get('adults')||1)), children=Math.max(0,Number(u.searchParams.get('children')||0));
  if(!checkIn||!checkOut||checkOut<=checkIn)return json({ok:false,error:'Valid check-in and check-out dates are required.'},400);
  const {data,error}=await supabase.rpc('anaira_marketplace_camp_search',{p_check_in:checkIn,p_check_out:checkOut,p_adults:adults,p_children:children,p_destination:destination});
  if(error)throw error;
  return json({ok:true,query:{check_in:checkIn,check_out:checkOut,destination,adults,children},results:Array.isArray(data)?data:[]});
 }catch(e){return json({ok:false,error:e?.message||'Camping search failed.'},400)}
}
