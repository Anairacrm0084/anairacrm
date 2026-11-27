import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../../lib/server/rateLimit.js';
import {adminDb} from '../../../../../../lib/server/provider';
export const runtime='nodejs';
export const dynamic='force-dynamic';
export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'camp-calendar-quote',limit:30,windowSeconds:60});
  const b=await req.json();
  for(const key of ['hotel_id','room_type_id','rate_plan_id','check_in','check_out']){
   if(!b?.[key])return NextResponse.json({ok:false,error:`${key} is required`},{status:400});
  }
  const {data,error}=await adminDb().rpc('anaira_calculate_camp_calendar_quote',{
   p_restaurant_id:b.hotel_id,p_unit_type_id:b.room_type_id,p_rate_plan_id:b.rate_plan_id,
   p_check_in:b.check_in,p_check_out:b.check_out,
   p_adults:Math.max(1,Number(b.adults||1)),p_children:Math.max(0,Number(b.children||0))
  });
  if(error)throw error;
  return NextResponse.json({...data,ok:true},{headers:{'cache-control':'no-store'}});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Camp rate calculation failed'},{status:400,headers:{'cache-control':'no-store'}})}
}
