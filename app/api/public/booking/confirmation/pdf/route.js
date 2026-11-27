import {NextResponse} from 'next/server';
import {createHash} from 'crypto';
import {adminDb} from '../../../../../../lib/server/provider';
import {enforceRateLimit} from '../../../../../../lib/server/rateLimit.js';

export const runtime='nodejs';
export const dynamic='force-dynamic';
const hash=value=>createHash('sha256').update(String(value)).digest('hex');
const digits=value=>String(value||'').replace(/\D/g,'');
const email=value=>String(value||'').trim().toLowerCase();
const ascii=value=>String(value??'').normalize('NFKD').replace(/[^\x20-\x7E]/g,' ').replace(/\s+/g,' ').trim();
const esc=value=>ascii(value).replace(/\\/g,'\\\\').replace(/\(/g,'\\(').replace(/\)/g,'\\)');
function makePdf(lines){
 const commands=['q','0.07 0.19 0.14 rg','0 700 595 142 re f','Q','q','0.82 0.66 0.32 rg','0 696 595 4 re f','Q','BT','/F1 19 Tf','1 1 1 rg','50 790 Td','(ANAIRA STAYS) Tj','0 -25 Td','/F1 10 Tf','(BOOKING CONFIRMATION) Tj','ET','BT','/F1 10 Tf','0.12 0.22 0.17 rg','50 660 Td'];
 for(const line of lines){commands.push(`(${esc(line)}) Tj`,'0 -22 Td');}
 commands.push('ET'); const stream=commands.join('\n');
 const objects=['<< /Type /Catalog /Pages 2 0 R >>','<< /Type /Pages /Kids [3 0 R] /Count 1 >>','<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>','<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',`<< /Length ${Buffer.byteLength(stream)} >>\nstream\n${stream}\nendstream`];
 let output='%PDF-1.4\n'; const offsets=[0]; for(let i=0;i<objects.length;i++){offsets.push(Buffer.byteLength(output));output+=`${i+1} 0 obj\n${objects[i]}\nendobj\n`;}
 const xref=Buffer.byteLength(output);output+=`xref\n0 ${objects.length+1}\n0000000000 65535 f \n`;for(let i=1;i<offsets.length;i++)output+=`${String(offsets[i]).padStart(10,'0')} 00000 n \n`;output+=`trailer\n<< /Size ${objects.length+1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;return Buffer.from(output,'binary');
}
export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'public-booking:confirmation-pdf',limit:8,windowSeconds:60});
  const b=await req.json();
  for(const k of ['restaurant_id','booking_code','verification_id','verification_channel']) if(!b?.[k]) return NextResponse.json({ok:false,error:`${k} is required`},{status:400});
  if(!['phone','email'].includes(b.verification_channel)) return NextResponse.json({ok:false,error:'Invalid verification channel.'},{status:400});
  const db=adminDb();
  const {data:r,error:re}=await db.from('camp_reservations').select('id,restaurant_id,reservation_code,guest_name,guest_phone,guest_email,unit_type_id,rate_plan_id,check_in,check_out,adults,children,total_amount,paid_amount,balance_amount,status,payment_status,payment_method,created_at').eq('restaurant_id',b.restaurant_id).eq('reservation_code',String(b.booking_code).trim()).maybeSingle();
  if(re) throw re; if(!r) return NextResponse.json({ok:false,error:'Camping booking not found.'},{status:404});
  const destination=b.verification_channel==='email'?email(b.email):digits(b.phone);
  const expected=b.verification_channel==='email'?email(r.guest_email):digits(r.guest_phone);
  if(!destination||destination!==expected) return NextResponse.json({ok:false,error:'Verified guest contact does not match this booking.'},{status:403});
  const {data:v,error:ve}=await db.from('anaira_guest_otp_challenges').select('id,destination_hash,verified_at,channel,tenant_id').eq('id',b.verification_id).eq('tenant_id',r.restaurant_id).eq('channel',b.verification_channel).maybeSingle();
  if(ve) throw ve;
  if(!v?.verified_at||v.destination_hash!==hash(`${b.verification_channel}:${destination}`)||new Date(v.verified_at).getTime()<Date.now()-30*60*1000) return NextResponse.json({ok:false,error:'Guest verification is missing or expired.'},{status:403});
  if(String(r.status).toLowerCase()!=='confirmed') return NextResponse.json({ok:false,error:'Booking is not confirmed yet.'},{status:409});
  const [{data:property,error:pe},{data:unit,error:ue},{data:rate,error:rateError}]=await Promise.all([
   db.from('camp_properties').select('name,address,city,state,country').eq('restaurant_id',r.restaurant_id).maybeSingle(),
   db.from('camp_unit_types').select('name,code').eq('id',r.unit_type_id).eq('restaurant_id',r.restaurant_id).maybeSingle(),
   db.from('camp_rate_plans').select('name').eq('id',r.rate_plan_id).eq('restaurant_id',r.restaurant_id).maybeSingle()
  ]);
  if(pe) throw pe;if(ue) throw ue;if(rateError) throw rateError;
  const total=Number(r.total_amount||0),paid=Number(r.paid_amount||0),balance=Number(r.balance_amount??Math.max(0,total-paid));
  const lines=[
   `Booking reference : ${r.reservation_code}`,`Reservation ID    : ${r.id}`,`Booking status    : ${String(r.status).toUpperCase()}`,
   `Property          : ${property?.name||'Camping property'}`,`Accommodation     : ${unit?.name||'Camping accommodation'}${unit?.code?` (${unit.code})`:''}`,
   `Rate plan         : ${rate?.name||'-'}`,`Guest             : ${r.guest_name||'-'}`,`Mobile            : ${r.guest_phone||'-'}`,`Email             : ${r.guest_email||'-'}`,
   `Address           : ${[property?.address,property?.city,property?.state,property?.country].filter(Boolean).join(', ')||'-'}`,
   `Check-in          : ${r.check_in||'-'}`,`Check-out         : ${r.check_out||'-'}`,`Adults / Children : ${r.adults||0} / ${r.children||0}`,
   `Total amount      : INR ${total.toFixed(2)}`,`Paid amount       : INR ${paid.toFixed(2)}`,`Balance amount    : INR ${balance.toFixed(2)}`,
   `Payment status    : ${r.payment_status||'pending'}`,`Payment method    : ${r.payment_method||'-'}`,
   `Created           : ${r.created_at?new Date(r.created_at).toLocaleString('en-IN',{timeZone:'Asia/Kolkata'}):'-'}`,'','Please present this booking reference at check-in.','This is a booking confirmation, not a tax invoice.'
  ];
  const pdf=makePdf(lines);const filename=`ANAIRA-Booking-${ascii(r.reservation_code).replace(/[^a-zA-Z0-9_-]/g,'-')}.pdf`;
  return new Response(pdf,{status:200,headers:{'content-type':'application/pdf','content-disposition':`attachment; filename="${filename}"`,'cache-control':'no-store'}});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Booking confirmation PDF failed.'},{status:400});}
}
