import { NextResponse } from 'next/server';
import { supabase } from '../../../../../../lib/supabase';

function esc(s=''){return String(s).replace(/\\/g,'\\\\').replace(/\(/g,'\\(').replace(/\)/g,'\\)');}
function pdfText(lines){
  const content=['BT','/F1 16 Tf','50 790 Td'];
  lines.forEach((line,i)=>{if(i>0) content.push('0 -20 Td');content.push(`(${esc(line)}) Tj`);});
  content.push('ET');
  const body=content.join('\n');
  const objs=[`<< /Type /Catalog /Pages 2 0 R >>`,`<< /Type /Pages /Kids [3 0 R] /Count 1 >>`,`<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>`,`<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>`,`<< /Length ${Buffer.byteLength(body)} >>\nstream\n${body}\nendstream`];
  let out='%PDF-1.4\n'; const offsets=[0];
  for(let i=0;i<objs.length;i++){offsets.push(Buffer.byteLength(out));out+=`${i+1} 0 obj\n${objs[i]}\nendobj\n`;}
  const xref=Buffer.byteLength(out);out+=`xref\n0 ${objs.length+1}\n0000000000 65535 f \n`;for(let i=1;i<offsets.length;i++)out+=`${String(offsets[i]).padStart(10,'0')} 00000 n \n`;out+=`trailer\n<< /Size ${objs.length+1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;
  return Buffer.from(out,'binary');
}
export const runtime='nodejs';
export async function POST(req){
 try{
  const b=await req.json(); if(!b?.booking_code||!b?.phone) return NextResponse.json({ok:false,error:'Booking code and phone are required'},{status:400});
  const {data,error}=await supabase.rpc('anaira_public_booking_invoice',{p_booking_code:b.booking_code,p_guest_phone:b.phone}); if(error) throw error;
  const inv=data?.invoice||{}; const lines=[
   'ANAIRA HOSPITALITY — TAX INVOICE',`Invoice: ${inv.invoice_number||'—'}`,`Booking: ${inv.booking_id||b.booking_code}`,
   `Guest: ${inv.billing_name||'—'}`,`Email: ${inv.billing_email||'—'}`,`Phone: ${inv.billing_phone||'—'}`,
   `Property: ${inv.property_name||'—'}`,`Property GSTIN: ${inv.property_gstin||'—'}`,
   `Taxable amount: INR ${Number(inv.taxable_amount||0).toFixed(2)}`,`CGST: INR ${Number(inv.cgst_amount||0).toFixed(2)}`,
   `SGST: INR ${Number(inv.sgst_amount||0).toFixed(2)}`,`IGST: INR ${Number(inv.igst_amount||0).toFixed(2)}`,
   `TOTAL: INR ${Number(inv.total_amount||0).toFixed(2)}`,`Issued: ${inv.issued_at||new Date().toISOString()}`,
   'This document is generated from the canonical Anaira booking invoice snapshot.'
  ];
  const pdf=pdfText(lines); return new Response(pdf,{status:200,headers:{'content-type':'application/pdf','content-disposition':`attachment; filename="${inv.invoice_number||b.booking_code}.pdf"`,'cache-control':'no-store'}});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Invoice PDF generation failed'},{status:400});}
}
