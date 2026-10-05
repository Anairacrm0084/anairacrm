import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../../lib/server/rateLimit.js';
import {adminDb} from '../../../../../../lib/server/provider';
export const runtime='nodejs';
export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'premium-quote',limit:30,windowSeconds:60});
 const b=await req.json(); const required=['hotel_id','room_type_id','rate_plan_id','check_in','check_out']; for(const k of required) if(!b?.[k]) return NextResponse.json({ok:false,error:`${k} is required`},{status:400});
  const {data,error}=await adminDb().rpc('anaira_calculate_hotel_premium_quote',{p_tenant_id:b.hotel_id,p_room_type_id:b.room_type_id,p_rate_plan_id:b.rate_plan_id,p_check_in:b.check_in,p_check_out:b.check_out,p_adults:Math.max(1,Number(b.adults||2)),p_children:Math.max(0,Number(b.children||0)),p_coupon_code:b.coupon_code||null,p_addons:Array.isArray(b.addons)?b.addons:[]});
  if(error) throw error; return NextResponse.json({...((data&&typeof data==='object')?data:{ok:true}),runtime_context:{customer_id:b.customer_id||null,corporate_code:b.corporate_code||null,negotiated_code:b.negotiated_code||null}});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Quote failed'},{status:400})}
}
