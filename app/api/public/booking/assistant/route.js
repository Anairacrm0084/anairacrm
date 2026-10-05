import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {adminDb} from '../../../../../lib/server/provider';
import {getLanguage,getCurrency,formatBookingMoney} from '../../../../../lib/server/booking-localization.js';

export const runtime='nodejs';

const TYPES=new Set(['hotel','camp','homestay','guest_house','cottage']);
const dateRe=/\b(20\d{2}-\d{2}-\d{2})\b/g;

function parseIntent(message=''){
 const m=String(message).toLowerCase();
 if(/\b(cancel|cancellation)\b/.test(m)) return 'cancel';
 if(/\b(modif|change|reschedule)\b/.test(m)) return 'modify';
 if(/\b(price|rate|cost|compare|cheapest|best rate)\b/.test(m)) return 'quote';
 if(/\b(book|reserve|reservation)\b/.test(m)) return 'book';
 return 'search';
}

function extractDates(message=''){
 const dates=[...String(message).matchAll(dateRe)].map(x=>x[1]);
 return {check_in:dates[0]||null,check_out:dates[1]||null};
}

function extractType(message=''){
 const m=String(message).toLowerCase();
 if(/camp|camping|tent/.test(m)) return 'camp';
 if(/homestay/.test(m)) return 'homestay';
 if(/guest house|guesthouse/.test(m)) return 'guest_house';
 if(/cottage/.test(m)) return 'cottage';
 return 'hotel';
}

async function search(db,{check_in,check_out,destination,adults,children,hospitality_type}){
 const fn=hospitality_type==='camp'?'anaira_marketplace_camp_search':'anaira_marketplace_hms_hospitality_search';
 const args=hospitality_type==='camp'
  ? {p_check_in:check_in,p_check_out:check_out,p_adults:adults,p_children:children,p_destination:destination||null}
  : {p_hospitality_type:hospitality_type,p_check_in:check_in,p_check_out:check_out,p_adults:adults,p_children:children,p_destination:destination||null};
 const {data,error}=await db.rpc(fn,args); if(error) throw error;
 return Array.isArray(data)?data:[];
}


async function startBooking(db,b){
 const type=String(b.hospitality_type||'hotel').toLowerCase();
 for(const k of ['property_id','guest_name','guest_phone','check_in','check_out','unit_type_id','rate_plan_id','verification_id']) if(!b?.[k]) throw new Error(`${k} is required to create the booking.`);
 let rpc,args;
 if(type==='hotel'){
  rpc='anaira_start_verified_hotel_booking_transaction_v3';
  args={p_tenant_id:b.property_id,p_guest_name:b.guest_name,p_guest_phone:b.guest_phone,p_guest_email:b.guest_email||null,p_check_in:b.check_in,p_check_out:b.check_out,p_room_type_id:b.unit_type_id,p_rate_plan_id:b.rate_plan_id,p_adults:Math.max(1,Number(b.adults||1)),p_children:Math.max(0,Number(b.children||0)),p_coupon_code:b.coupon_code||null,p_addons:b.addons||{},p_idempotency_key:b.idempotency_key||null,p_source:b.source||'anaira-ai-assistant',p_verification_id:b.verification_id,p_customer_id:b.customer_id||null,p_corporate_code:b.corporate_code||null,p_negotiated_code:b.negotiated_code||null};
 }else if(type==='camp'){
  rpc='anaira_start_public_camp_booking';
  args={p_restaurant_id:b.property_id,p_guest_name:b.guest_name,p_guest_phone:b.guest_phone,p_guest_email:b.guest_email||null,p_check_in:b.check_in,p_check_out:b.check_out,p_unit_type_id:b.unit_type_id,p_rate_plan_id:b.rate_plan_id,p_adults:Math.max(1,Number(b.adults||1)),p_children:Math.max(0,Number(b.children||0)),p_idempotency_key:b.idempotency_key||null,p_source:b.source||'anaira-ai-assistant',p_verification_id:b.verification_id};
 }else{
  rpc='anaira_start_public_stay_booking';
  args={p_restaurant_id:b.restaurant_id||b.property_id,p_property_id:b.property_id,p_stay_type:type,p_guest_name:b.guest_name,p_guest_phone:b.guest_phone,p_guest_email:b.guest_email||null,p_check_in:b.check_in,p_check_out:b.check_out,p_unit_type_id:b.unit_type_id,p_rate_plan_id:b.rate_plan_id,p_adults:Math.max(1,Number(b.adults||1)),p_children:Math.max(0,Number(b.children||0)),p_idempotency_key:b.idempotency_key||null,p_source:b.source||`anaira-${type}-ai-assistant`,p_verification_id:b.verification_id};
 }
 const {data,error}=await db.rpc(rpc,args); if(error) throw error;
 return Array.isArray(data)?data[0]:data;
}

async function quote(db,b){
 if(!b.hotel_id||!b.room_type_id||!b.rate_plan_id) throw new Error('hotel_id, room_type_id and rate_plan_id are required for a quote.');
 const {data,error}=await db.rpc('anaira_calculate_hotel_premium_quote',{p_tenant_id:b.hotel_id,p_room_type_id:b.room_type_id,p_rate_plan_id:b.rate_plan_id,p_check_in:b.check_in,p_check_out:b.check_out,p_adults:Math.max(1,Number(b.adults||1)),p_children:Math.max(0,Number(b.children||0)),p_coupon_code:b.coupon_code||null,p_addons:Array.isArray(b.addons)?b.addons:[]});
 if(error) throw error;
 return data;
}

export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'public-booking:assistant',limit:30,windowSeconds:60});
  const body=await req.json().catch(()=>({}));
  const message=String(body.message||'').trim();
  if(!message) return NextResponse.json({ok:false,error:'message is required'},{status:400});
  const intent=body.intent||parseIntent(message);
  const dates=extractDates(message);
  const hospitality_type=TYPES.has(body.hospitality_type)?body.hospitality_type:extractType(message);
  const language=getLanguage(body.language||'en-IN');
  const currency=getCurrency(body.currency||'INR');
  const context={check_in:body.check_in||dates.check_in,check_out:body.check_out||dates.check_out,destination:body.destination||null,adults:Math.max(1,Number(body.adults||1)),children:Math.max(0,Number(body.children||0)),hospitality_type};
  if(['search','quote'].includes(intent)&&(!context.check_in||!context.check_out)) return NextResponse.json({ok:true,intent,needs:['check_in','check_out'],message:'Please provide check-in and check-out dates.',language,currency});
  const db=adminDb();
  if(intent==='search'){
   const results=await search(db,context);
   return NextResponse.json({ok:true,intent,context,results,language,currency});
  }
  if(intent==='quote'){
   const q=await quote(db,{...context,...body});
   return NextResponse.json({ok:true,intent,context,quote:q,display_total:q?.total!=null?formatBookingMoney(q.total,currency.code,language.code):null,language,currency});
  }
  if(intent==='book'){
   const booking=await startBooking(db,{...context,...body});
   return NextResponse.json({ok:true,intent,booking,requires_payment:true,next_step:'payment',context,language,currency});
  }
  if(intent==='cancel'||intent==='modify'){
   return NextResponse.json({ok:true,intent,requires_verification:true,next_step:'booking_manage',language,currency});
  }
  return NextResponse.json({ok:true,intent,context,language,currency});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Booking assistant failed'},{status:400});}
}
