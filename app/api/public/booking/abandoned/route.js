import {NextResponse} from 'next/server';
import {adminDb} from '../../../../../lib/server/provider.js';
import {enforceRateLimit,rateLimitResponse} from '../../../../../lib/server/rateLimit.js';

export const runtime='nodejs';

const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const text=(value,max=200)=>typeof value==='string'?value.trim().slice(0,max):null;
const object=(value)=>value&&typeof value==='object'&&!Array.isArray(value)?value:{};

export async function POST(req){
 try{
  const b=await req.json();
  if(!b||typeof b!=='object'||!UUID.test(String(b.restaurant_id||''))||typeof b.session_id!=='string'||! /^[A-Za-z0-9:_-]{8,128}$/.test(b.session_id)){
   return NextResponse.json({ok:false,error:'A valid property and booking session are required.'},{status:400});
  }
  await enforceRateLimit(req,{scope:'public-booking:abandoned-session',limit:20,windowSeconds:60});
  const db=adminDb();
  const {data:tenant,error:tenantError}=await db.from('restaurants').select('id,status').eq('id',b.restaurant_id).maybeSingle();
  if(tenantError) throw tenantError;
  if(!tenant||tenant.status!=='active') return NextResponse.json({ok:false,error:'This property is not available.'},{status:404});

  const adults=Math.min(20,Math.max(1,Number.parseInt(b.adults,10)||1));
  const children=Math.min(20,Math.max(0,Number.parseInt(b.children,10)||0));
  const payload={
   restaurant_id:b.restaurant_id,
   session_id:b.session_id,
   guest_name:text(b.guest_name,120),
   guest_email:text(b.guest_email,254),
   guest_phone:text(b.guest_phone,32),
   check_in:text(b.check_in,10),
   check_out:text(b.check_out,10),
   adults,
   children,
   room_type_id:UUID.test(String(b.room_type_id||''))?b.room_type_id:null,
   rate_plan_id:UUID.test(String(b.rate_plan_id||''))?b.rate_plan_id:null,
   quote:object(b.quote),
   last_step:text(b.last_step,40),
   recovered:false,
   metadata:object(b.metadata)
  };
  const {data,error}=await db.from('booking_abandoned_sessions')
   .upsert(payload,{onConflict:'restaurant_id,session_id'})
   .select('id,session_id,recovered,last_step,updated_at')
   .single();
  if(error) throw error;
  return NextResponse.json({ok:true,...data},{headers:{'Cache-Control':'no-store'}});
 }catch(e){
  if(Number(e?.status)===429) return rateLimitResponse(e,NextResponse);
  return NextResponse.json({ok:false,error:'Unable to save booking progress right now.'},{status:500,headers:{'Cache-Control':'no-store'}});
 }
}
