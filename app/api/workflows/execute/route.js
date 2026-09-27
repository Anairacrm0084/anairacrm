import {NextResponse} from 'next/server';
import {supabaseAdmin} from '../../../../lib/supabaseAdmin';
const handlers={
 'delivery.transition': async(admin,b)=>admin.rpc('anaira_delivery_transition_safe',{p_order_id:b.entity_id,p_next_status:b.next_status,p_rider_id:b.rider_id||null}),
 'restaurant_reservation.assign_table': async(admin,b)=>admin.rpc('anaira_reserve_table',{p_reservation_id:b.entity_id,p_table_id:b.table_id}),
 'pms.room_state': async(admin,b)=>admin.rpc('anaira_pms_set_room_state',{p_room_id:b.entity_id,p_status:b.status,p_housekeeping_status:b.housekeeping_status||null}),
 'payment.verified_status': async(admin,b)=>admin.rpc('anaira_mark_payment_verified',{p_payment_intent_id:b.entity_id,p_status:b.status,p_provider_payment_id:b.provider_payment_id||null,p_event_id:b.event_id||null,p_provider:b.provider||null,p_payload:b.payload||{}}),
};
export async function POST(request){try{const b=await request.json();if(!b?.workflow_key||!handlers[b.workflow_key])return NextResponse.json({error:'Unsupported workflow',workflow_key:b?.workflow_key},{status:400});const admin=supabaseAdmin();const r=await handlers[b.workflow_key](admin,b);if(r.error)return NextResponse.json({error:r.error.message},{status:409});return NextResponse.json({ok:true,result:r.data});}catch(e){return NextResponse.json({error:e.message},{status:500})}}
