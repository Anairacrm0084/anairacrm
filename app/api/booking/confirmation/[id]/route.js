import {NextResponse} from 'next/server';
import {loadBookingConfirmation} from '../../../../../lib/server/bookingConfirmation';

export const runtime='nodejs';
export const dynamic='force-dynamic';

export async function GET(req,{params}){
  try{
    const {id}=await params;
    const url=new URL(req.url);
    const restaurantId=url.searchParams.get('restaurant_id');
    const source=url.searchParams.get('source')||'hms';
    if(!['hms','camp','stay'].includes(source)) return NextResponse.json({ok:false,error:'Unsupported booking source.'},{status:400});
    const booking=await loadBookingConfirmation(req,id,restaurantId,source);
    return NextResponse.json({ok:true,booking},{headers:{'Cache-Control':'no-store'}});
  }catch(error){
    return NextResponse.json({ok:false,error:error?.message||'Unable to load booking confirmation.'},{status:400});
  }
}
