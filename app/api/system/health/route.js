import {NextResponse} from 'next/server';
import {supabaseAdmin} from '../../../../lib/supabaseAdmin';
export async function POST(request){try{const {restaurant_id}=await request.json();if(!restaurant_id)return NextResponse.json({error:'restaurant_id required'},{status:400});const admin=supabaseAdmin();const {data,error}=await admin.rpc('anaira_system_health_snapshot',{p_restaurant_id:restaurant_id});if(error)return NextResponse.json({error:error.message},{status:500});return NextResponse.json(data);}catch(e){return NextResponse.json({error:e.message},{status:500})}}
