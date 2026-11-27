import {loadBookingConfirmation} from '../../../../../../lib/server/bookingConfirmation';
export const runtime='nodejs';
export const dynamic='force-dynamic';

const ascii=value=>String(value??'').normalize('NFKD').replace(/[^\x20-\x7E]/g,' ').replace(/\s+/g,' ').trim();
const esc=value=>ascii(value).replace(/\\/g,'\\\\').replace(/\(/g,'\\(').replace(/\)/g,'\\)');
function makePdf(booking){
  const lines=[
    'ANAIRA STAYS  |  BOOKING CONFIRMATION',
    ' ',
    `Booking reference : ${booking.booking_code}`,
    `Reservation ID    : ${booking.reservation_id}`,
    `Booking status    : ${String(booking.status).toUpperCase()}`,
    `Property          : ${booking.property_name}`,
    `Accommodation     : ${booking.accommodation}${booking.accommodation_code?` (${booking.accommodation_code})`:''}`,
    `Stay category     : ${String(booking.stay_type).replaceAll('_',' ')}`,
    ' ',
    `Guest             : ${booking.guest_name}`,
    `Mobile            : ${booking.guest_phone||'-'}`,
    `Email             : ${booking.guest_email||'-'}`,
    `Check-in          : ${booking.check_in||'-'}`,
    `Check-out         : ${booking.check_out||'-'}`,
    `Adults / Children : ${booking.adults} / ${booking.children}`,
    ' ',
    `Total amount      : INR ${booking.total_amount.toFixed(2)}`,
    `Paid amount       : INR ${booking.paid_amount.toFixed(2)}`,
    `Balance amount    : INR ${booking.balance_amount.toFixed(2)}`,
    `Payment status    : ${booking.payment_status}`,
    `Confirmed on      : ${booking.created_at?new Date(booking.created_at).toLocaleString('en-IN',{timeZone:'Asia/Kolkata'}):new Date().toLocaleString('en-IN',{timeZone:'Asia/Kolkata'})}`,
    ' ',
    'Please present this confirmation reference at check-in.',
    'This is a booking confirmation, not a tax invoice.'
  ];
  const commands=[
    'q','0.07 0.19 0.14 rg','0 700 595 142 re f','Q',
    'q','0.82 0.66 0.32 rg','0 696 595 4 re f','Q',
    'BT','/F1 19 Tf','1 1 1 rg','50 790 Td','(ANAIRA STAYS) Tj',
    '0 -25 Td','/F1 10 Tf','(BOOKING CONFIRMATION) Tj','ET',
    'BT','/F1 10 Tf','0.12 0.22 0.17 rg','50 660 Td'
  ];
  for(const line of lines.slice(2)){
    if(line) commands.push(`(${esc(line)}) Tj`);
    commands.push('0 -22 Td');
  }
  commands.push('ET');
  const stream=commands.join('\n');
  const objects=[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    `<< /Length ${Buffer.byteLength(stream)} >>\nstream\n${stream}\nendstream`
  ];
  let output='%PDF-1.4\n'; const offsets=[0];
  for(let i=0;i<objects.length;i++){offsets.push(Buffer.byteLength(output));output+=`${i+1} 0 obj\n${objects[i]}\nendobj\n`;}
  const xref=Buffer.byteLength(output); output+=`xref\n0 ${objects.length+1}\n0000000000 65535 f \n`;
  for(let i=1;i<offsets.length;i++)output+=`${String(offsets[i]).padStart(10,'0')} 00000 n \n`;
  output+=`trailer\n<< /Size ${objects.length+1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;
  return Buffer.from(output,'binary');
}

export async function GET(req,{params}){
  try{
    const {id}=await params; const url=new URL(req.url);
    const restaurantId=url.searchParams.get('restaurant_id'); const source=url.searchParams.get('source')||'hms';
    if(!['hms','camp','stay'].includes(source)) return Response.json({ok:false,error:'Unsupported booking source.'},{status:400});
    const booking=await loadBookingConfirmation(req,id,restaurantId,source);
    if(String(booking.status).toLowerCase()!=='confirmed') return Response.json({ok:false,error:'Only confirmed bookings can download a confirmation PDF.'},{status:409});
    const pdf=makePdf(booking);
    const filename=`ANAIRA-Booking-${ascii(booking.booking_code).replace(/[^a-zA-Z0-9_-]/g,'-')||'confirmation'}.pdf`;
    return new Response(pdf,{status:200,headers:{'content-type':'application/pdf','content-disposition':`attachment; filename="${filename}"`,'cache-control':'no-store'}});
  }catch(error){return Response.json({ok:false,error:error?.message||'Booking confirmation PDF failed.'},{status:400});}
}
