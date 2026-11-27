import {NextResponse} from 'next/server';
import {enforceRateLimit} from '../../../../../../lib/server/rateLimit.js';
import {supabase} from '../../../../../../lib/supabase';

export const runtime='nodejs';

const clean=value=>String(value??'').normalize('NFKD').replace(/[^\x20-\x7E]/g,' ').replace(/\s+/g,' ').trim();
const esc=value=>clean(value).replace(/\\/g,'\\\\').replace(/\(/g,'\\(').replace(/\)/g,'\\)');

function makePdf(booking, bookingCode){
 const lines=[
  'ANAIRA STAYS — BOOKING CONFIRMATION',
  '',
  `Booking reference: ${booking.booking_code||booking.booking_reference||bookingCode}`,
  `Reservation ID: ${booking.reservation_id||booking.hms_reservation_id||booking.id||'-'}`,
  `Booking status: ${String(booking.status||booking.booking_status||'received').toUpperCase()}`,
  `Payment status: ${String(booking.payment_status||'not updated').toUpperCase()}`,
  '',
  `Property: ${booking.property_name||booking.hotel_name||booking.restaurant_name||'ANAIRA Property'}`,
  `Accommodation: ${booking.accommodation_name||booking.room_name||booking.unit_name||booking.room_type_name||'-'}`,
  `Guest: ${booking.guest_name||booking.customer_name||'-'}`,
  `Mobile: ${booking.guest_phone||booking.phone||'-'}`,
  `Email: ${booking.guest_email||booking.email||'-'}`,
  '',
  `Check-in: ${booking.check_in||booking.checkin_date||'-'}`,
  `Check-out: ${booking.check_out||booking.checkout_date||'-'}`,
  `Adults: ${booking.adults??booking.total_adults??'-'}`,
  `Children: ${booking.children??booking.total_children??'-'}`,
  `Total amount: INR ${Number(booking.total_amount||booking.grand_total||booking.amount||0).toFixed(2)}`,
  `Paid amount: INR ${Number(booking.paid_amount||booking.amount_paid||0).toFixed(2)}`,
  `Balance amount: INR ${Number(booking.balance_amount||booking.balance_due||0).toFixed(2)}`,
  '',
  'Please keep this booking reference and present it at check-in.',
  'This document is a booking confirmation/summary, not a tax invoice.'
 ];
 const commands=['q','0.07 0.19 0.14 rg','0 700 595 142 re f','Q','q','0.82 0.66 0.32 rg','0 696 595 4 re f','Q','BT','/F1 18 Tf','1 1 1 rg','50 790 Td','(ANAIRA STAYS) Tj','0 -24 Td','/F1 10 Tf','(BOOKING CONFIRMATION) Tj','ET','BT','/F1 9 Tf','0.12 0.22 0.17 rg','50 660 Td'];
 for(const line of lines){if(line)commands.push(`(${esc(line)}) Tj`);commands.push('0 -20 Td');}
 commands.push('ET');
 const stream=commands.join('\n');
 const objects=['<< /Type /Catalog /Pages 2 0 R >>','<< /Type /Pages /Kids [3 0 R] /Count 1 >>','<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>','<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',`<< /Length ${Buffer.byteLength(stream)} >>\nstream\n${stream}\nendstream`];
 let output='%PDF-1.4\n';const offsets=[0];for(let i=0;i<objects.length;i++){offsets.push(Buffer.byteLength(output));output+=`${i+1} 0 obj\n${objects[i]}\nendobj\n`;}
 const xref=Buffer.byteLength(output);output+=`xref\n0 ${objects.length+1}\n0000000000 65535 f \n`;for(let i=1;i<offsets.length;i++)output+=`${String(offsets[i]).padStart(10,'0')} 00000 n \n`;output+=`trailer\n<< /Size ${objects.length+1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;return Buffer.from(output,'binary');
}

export async function POST(req){
 try{
  await enforceRateLimit(req,{scope:'public-booking:confirmation-pdf',limit:6,windowSeconds:60});
  const body=await req.json();
  const bookingCode=String(body?.booking_code||'').trim();
  const phone=String(body?.phone||'').trim();
  if(!bookingCode||!phone)return NextResponse.json({ok:false,error:'Booking reference and verified mobile number are required.'},{status:400});
  const {data,error}=await supabase.rpc('anaira_public_booking_lookup',{p_booking_code:bookingCode,p_guest_phone:phone});
  if(error)throw error;
  const booking=data?.booking;
  if(!booking?.id&&!booking?.booking_code&&!booking?.booking_reference)throw new Error('Booking not found. Check the booking reference and mobile number.');
  const pdf=makePdf(booking,bookingCode);
  const safeCode=clean(booking.booking_code||booking.booking_reference||bookingCode).replace(/[^a-zA-Z0-9_-]/g,'-')||'booking';
  return new Response(pdf,{status:200,headers:{'content-type':'application/pdf','content-disposition':`attachment; filename="ANAIRA-Booking-${safeCode}.pdf"`,'cache-control':'no-store','x-content-type-options':'nosniff'}});
 }catch(error){return NextResponse.json({ok:false,error:error?.message||'Booking confirmation PDF failed.'},{status:400});}
}
