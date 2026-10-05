import {NextResponse} from 'next/server';
import {supabase} from '../../../../../lib/supabase';
export const runtime='nodejs';
export async function GET(req){try{const u=new URL(req.url);const hotel=u.searchParams.get('hotel_id');const date=u.searchParams.get('stay_date');if(!hotel||!date)return NextResponse.json({ok:false,error:'hotel_id and stay_date are required'},{status:400});const {data,error}=await supabase.from('booking_rate_parity_snapshots').select('*').eq('restaurant_id',hotel).eq('stay_date',date).order('observed_at',{ascending:false}).limit(200);if(error)throw error;return NextResponse.json({ok:true,hotel_id:hotel,stay_date:date,snapshots:data||[]});}catch(e){return NextResponse.json({ok:false,error:e.message},{status:400})}}
