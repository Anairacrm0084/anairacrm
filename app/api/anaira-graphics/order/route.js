import {NextResponse} from 'next/server';
import {supabaseAdmin} from '../../../../lib/supabaseAdmin';
const BUSINESS_ID=process.env.ANAIRA_GRAPHICS_BUSINESS_ID||'737d5047-39f0-480b-8279-c7b1262f9e6c';
const PHONE=/^[+\d][\d\s().-]{7,20}$/; const EMAIL=/^[^\s@]+@[^\s@]+\.[^\s@]+$/;
export async function POST(req){
 try{
  const body=await req.json(); const c=body?.customer||{}; const name=String(c.name||'').trim().slice(0,120); const phone=String(c.phone||'').trim().slice(0,40); const email=String(c.email||'').trim().toLowerCase().slice(0,160); const message=String(c.message||'').trim().slice(0,3000); const ids=Array.isArray(body?.items)?body.items:[];
  if(name.length<2) throw new Error('Name is required'); if(!PHONE.test(phone)) throw new Error('Please enter a valid phone number'); if(email&&!EMAIL.test(email)) throw new Error('Please enter a valid email'); if(!ids.length) throw new Error('Cart is empty');
  const s=supabaseAdmin(); const {data:rows,error}=await s.from('anaira_it_agency_portfolio').select('id,title,data,status').eq('business_id',BUSINESS_ID).eq('status','active').eq('data->>kind','service').in('id',ids.map(x=>String(x.id)));
  if(error) throw error; if((rows||[]).length!==ids.length) throw new Error('One or more selected services are no longer available');
  const byId=new Map(rows.map(x=>[x.id,x])); const lines=ids.map(x=>{const r=byId.get(String(x.id));const qty=Math.max(1,Math.min(99,Number(x.qty)||1));const price=Number(r.data?.price||0);return {id:r.id,title:r.title,qty,unit:r.data?.unit||'service',price,currency:r.data?.currency||'INR'};});
  const total=lines.reduce((n,x)=>n+x.price*x.qty,0);
  const existing=await s.from('crm_customers').select('id,full_name,email').eq('tenant_id',BUSINESS_ID).eq('phone',phone).maybeSingle(); if(existing.error) throw existing.error; let customerId=existing.data?.id;
  if(customerId){const {error:e}=await s.from('crm_customers').update({full_name:name,email:email||existing.data.email||null,notes:`Service order request: ${lines.map(x=>`${x.title} × ${x.qty}`).join(', ')}`,updated_at:new Date().toISOString()}).eq('id',customerId).eq('tenant_id',BUSINESS_ID);if(e)throw e;}
  else {const {data:created,error:e}=await s.from('crm_customers').insert({tenant_id:BUSINESS_ID,full_name:name,phone,email:email||null,customer_type:'lead',notes:`Service order request: ${lines.map(x=>`${x.title} × ${x.qty}`).join(', ')}`}).select('id').single();if(e)throw e;customerId=created.id;}
  const orderRef=`AGS-${Date.now().toString(36).toUpperCase()}`;
  const notes=JSON.stringify({order_ref:orderRef,items:lines,total,currency:'INR',message,source:'anaira_graphics_service_cart'});
  const {data:lead,error:le}=await s.from('crm_leads').insert({tenant_id:BUSINESS_ID,customer_id:customerId,lead_type:'service_order_request',source:'anaira_graphics_service_cart',stage:'new',notes}).select('id').single(); if(le) throw le;
  try{await s.rpc('anaira_record_crm_timeline',{p_tenant_id:BUSINESS_ID,p_customer_id:customerId,p_event_type:'service_order_requested',p_source_system:'anaira_graphics_service_cart',p_source_id:String(lead.id),p_title:`Service order ${orderRef}`,p_description:`${lines.map(x=>`${x.title} × ${x.qty}`).join(', ')}${total?` · ₹${total.toLocaleString('en-IN')}`:' · custom quote'}`,p_metadata:{order_ref:orderRef,items:lines,total,currency:'INR'}});}catch{}
  return NextResponse.json({ok:true,orderId:orderRef,leadId:lead.id,customerId,total});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Unable to place order request'},{status:400});}
}
