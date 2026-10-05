import {NextResponse} from 'next/server';
import {supabase} from '../../../../../lib/supabase';
export const runtime='nodejs';
export async function POST(req){try{const b=await req.json();if(!b?.booking_code||!b?.phone)return NextResponse.json({ok:false,error:'Booking code and phone are required'},{status:400});const {data,error}=await supabase.rpc('anaira_public_booking_update_preferences',{p_booking_code:b.booking_code,p_guest_phone:b.phone,p_preferences:b.preferences||{}});if(error)throw error;return NextResponse.json(data||{ok:true});}catch(e){return NextResponse.json({ok:false,error:e?.message||'Unable to update guest preferences'},{status:400})}}
