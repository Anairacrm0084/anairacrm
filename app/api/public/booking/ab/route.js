import {NextResponse} from 'next/server';
import {adminDb} from '../../../../../lib/server/provider';
export const runtime='nodejs';
export async function POST(req){try{const b=await req.json();if(!b?.hotel_id||!b?.experiment_key||!b?.session_id)return NextResponse.json({ok:false,error:'hotel_id, experiment_key and session_id are required'},{status:400});const {data,error}=await adminDb().rpc('anaira_booking_ab_assign',{p_restaurant_id:b.hotel_id,p_experiment_key:b.experiment_key,p_session_id:b.session_id});if(error)throw error;return NextResponse.json(data||{ok:true});}catch(e){return NextResponse.json({ok:false,error:e?.message||'Experiment assignment failed'},{status:400})}}
