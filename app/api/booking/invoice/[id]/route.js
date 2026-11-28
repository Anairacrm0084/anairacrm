import {NextResponse} from 'next/server';
import {userDb} from '../../../../../lib/server/provider';

export const runtime='nodejs';
export const dynamic='force-dynamic';
const esc=v=>String(v??'').normalize('NFKD').replace(/[^\x20-\x7E]/g,' ').replace(/\\/g,'\\\\').replace(/\(/g,'\\(').replace(/\)/g,'\\)').replace(/\s+/g,' ').trim();
const money=v=>Number(v||0).toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2});
const date=v=>v?new Date(v).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric',timeZone:'Asia/Kolkata'}):'—';
function makePdf(inv){
 const m=inv.metadata||{};
 const rows=Array.isArray(inv.lines)?inv.lines:[];
 const commands=[
  'q','0.035 0.16 0.12 rg','0 730 595 112 re f','Q',
  'q','0.78 0.61 0.28 rg','0 726 595 4 re f','Q',
  'BT','/F2 22 Tf','1 1 1 rg','42 800 Td','(TAX INVOICE) Tj',
  '0 -25 Td','/F1 10 Tf','(ORIGINAL FOR RECIPIENT) Tj','ET',
  'BT','/F2 15 Tf','0.08 0.18 0.14 rg','42 690 Td',`(${esc(inv.property_name||'Hospitality Property')}) Tj`,
  '0 -18 Td','/F1 9 Tf',`(${esc(inv.property_address||'')}) Tj`,
  '0 -15 Td',`(GSTIN: ${esc(inv.property_gstin||'Not provided')}) Tj`,
  'ET',
  'q','0.95 0.96 0.94 rg','42 565 511 92 re f','Q',
  'BT','/F2 10 Tf','0.08 0.18 0.14 rg','54 635 Td',`(Invoice No: ${esc(inv.invoice_number)}) Tj`,
  '0 -18 Td',`(Booking Ref: ${esc(m.booking_reference||m.reservation_code||inv.booking_id)}) Tj`,
  '0 -18 Td',`(Invoice Date: ${esc(date(inv.issued_at))}) Tj`,
  '0 -18 Td',`(Stay: ${esc(date(m.check_in))} to ${esc(date(m.check_out))}) Tj`,
  'ET',
  'BT','/F2 10 Tf','0.08 0.18 0.14 rg','54 535 Td',`(BILL TO: ${esc(inv.billing_name||'Guest')}) Tj`,
  '0 -16 Td','/F1 9 Tf',`(Phone: ${esc(inv.billing_phone||'—')}   Email: ${esc(inv.billing_email||'—')}) Tj`,
  '0 -15 Td',`(Address: ${esc(m.guest_address||'—')}) Tj`,
  'ET',
  'q','0.035 0.16 0.12 rg','42 465 511 25 re f','Q',
  'BT','/F2 9 Tf','1 1 1 rg','52 474 Td','(DESCRIPTION) Tj','350 0 Td','(AMOUNT INR) Tj','ET'
 ];
 let y=445;
 for(const row of rows.slice(0,7)){
  commands.push('BT','/F1 9 Tf','0.12 0.16 0.14 rg',`52 ${y} Td`,`(${esc(row.description||'Accommodation')}) Tj`,
   '350 0 Td',`(${esc(money(row.amount))}) Tj`,'ET');
  y-=22;
 }
 y-=12;
 const totals=[
  ['Taxable value',inv.taxable_amount],['CGST',inv.cgst_amount],['SGST',inv.sgst_amount],['IGST',inv.igst_amount],['Invoice total',inv.total_amount],
  ['Amount received',m.paid_amount],['Balance due',m.balance_amount]
 ];
 for(const [label,value] of totals){
  if((label==='CGST'||label==='SGST'||label==='IGST')&&!Number(value||0))continue;
  const bold=label==='Invoice total'||label==='Balance due';
  commands.push('BT',bold?'/F2 10 Tf':'/F1 9 Tf','0.08 0.18 0.14 rg',`330 ${y} Td`,`(${esc(label)}) Tj`,'130 0 Td',`(${esc(money(value))}) Tj`,'ET');
  y-=19;
 }
 commands.push('q','0.78 0.61 0.28 RG','42 105 511 1 re S','Q',
  'BT','/F1 8 Tf','0.35 0.38 0.36 rg','42 88 Td',`(Payment status: ${esc(m.payment_status||'pending')}   Method: ${esc(m.payment_method||'—')}   Ref: ${esc(m.payment_reference||'—')}) Tj`,
  '0 -16 Td','(Computer-generated invoice. Please retain this document for your records.) Tj',
  'ET');
 const stream=commands.join('\n');
 const objs=['<< /Type /Catalog /Pages 2 0 R >>','<< /Type /Pages /Kids [3 0 R] /Count 1 >>','<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /Contents 6 0 R >>','<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>','<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>',`<< /Length ${Buffer.byteLength(stream)} >>\nstream\n${stream}\nendstream`];
 let out='%PDF-1.4\n';const offsets=[0];for(let i=0;i<objs.length;i++){offsets.push(Buffer.byteLength(out));out+=`${i+1} 0 obj\n${objs[i]}\nendobj\n`;}
 const xref=Buffer.byteLength(out);out+=`xref\n0 ${objs.length+1}\n0000000000 65535 f \n`;for(let i=1;i<offsets.length;i++)out+=`${String(offsets[i]).padStart(10,'0')} 00000 n \n`;out+=`trailer\n<< /Size ${objs.length+1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;
 return Buffer.from(out,'binary');
}
export async function POST(req,{params}){
 try{
  const token=String(req.headers.get('authorization')||'').replace(/^Bearer\s+/i,'');
  if(!token)return NextResponse.json({ok:false,error:'Authentication required.'},{status:401});
  const client=userDb(token);
  const {data:{user},error:authError}=await client.auth.getUser(token);
  if(authError||!user)return NextResponse.json({ok:false,error:'Your session has expired. Please sign in again.'},{status:401});
  const {id}=await params;
  const {data,error}=await client.rpc('anaira_issue_hms_reservation_invoice',{p_reservation_id:id});
  if(error)throw error;
  if(!data?.ok||!data?.invoice)throw new Error('Invoice could not be issued.');
  const inv=data.invoice;
  const pdf=makePdf(inv);
  const filename=`ANAIRA-Invoice-${String(inv.invoice_number||id).replace(/[^a-zA-Z0-9_-]/g,'-')}.pdf`;
  return new Response(pdf,{status:200,headers:{'content-type':'application/pdf','content-disposition':`inline; filename="${filename}"`,'cache-control':'no-store'}});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Invoice generation failed.'},{status:400});}
}
