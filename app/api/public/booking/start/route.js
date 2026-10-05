import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../lib/server/rateLimit.js';
import {adminDb} from '../../../../../lib/server/provider';

export const runtime='nodejs';

const HOTEL_RPC='anaira_start_verified_hotel_booking_transaction_v3';
const CAMP_RPC='anaira_start_public_camp_booking';
const STAY_RPC='anaira_start_public_stay_booking';

function bad(message){return NextResponse.json({ok:false,error:message},{status:400})}

export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'public-booking:start',limit:10,windowSeconds:60});
    const b=await req.json();
    const type=String(b?.hospitality_type||'hotel').toLowerCase();
    if(!['hotel','camp','homestay','guest_house','cottage'].includes(type)) return bad('Unsupported hospitality type.');
    for(const k of ['property_id','guest_name','guest_phone','check_in','check_out','unit_type_id','rate_plan_id']) if(!b?.[k]) return bad(`${k} is required`);
    if(!b?.verification_id) return bad('Phone or email verification is required.');

    const db=adminDb();
    let rpc,args;
    if(type==='hotel'){
      rpc=HOTEL_RPC;
      args={p_tenant_id:b.property_id,p_guest_name:b.guest_name,p_guest_phone:b.guest_phone,p_guest_email:b.guest_email||null,p_check_in:b.check_in,p_check_out:b.check_out,p_room_type_id:b.unit_type_id,p_rate_plan_id:b.rate_plan_id,p_adults:Number(b.adults||1),p_children:Number(b.children||0),p_coupon_code:b.coupon_code||null,p_addons:b.addons||{},p_idempotency_key:b.idempotency_key||null,p_source:b.source||'anaira-hotel-store',p_verification_id:b.verification_id,p_customer_id:b.customer_id||null,p_corporate_code:b.corporate_code||null,p_negotiated_code:b.negotiated_code||null};
    }else if(type==='camp'){
      rpc=CAMP_RPC;
      args={p_restaurant_id:b.property_id,p_guest_name:b.guest_name,p_guest_phone:b.guest_phone,p_guest_email:b.guest_email||null,p_check_in:b.check_in,p_check_out:b.check_out,p_unit_type_id:b.unit_type_id,p_rate_plan_id:b.rate_plan_id,p_adults:Number(b.adults||1),p_children:Number(b.children||0),p_idempotency_key:b.idempotency_key||null,p_source:b.source||'anaira-camping-store',p_verification_id:b.verification_id};
    }else{
      rpc=STAY_RPC;
      args={p_restaurant_id:b.restaurant_id||b.property_id,p_property_id:b.property_id,p_stay_type:type,p_guest_name:b.guest_name,p_guest_phone:b.guest_phone,p_guest_email:b.guest_email||null,p_check_in:b.check_in,p_check_out:b.check_out,p_unit_type_id:b.unit_type_id,p_rate_plan_id:b.rate_plan_id,p_adults:Number(b.adults||1),p_children:Number(b.children||0),p_idempotency_key:b.idempotency_key||null,p_source:b.source||`anaira-${type}-store`,p_verification_id:b.verification_id};
    }
    const {data,error}=await db.rpc(rpc,args);
    if(error) throw error;
    return NextResponse.json(Array.isArray(data)?data[0]:data);
  }catch(e){return NextResponse.json({ok:false,error:e?.message||'Booking creation failed'},{status:400})}
}
