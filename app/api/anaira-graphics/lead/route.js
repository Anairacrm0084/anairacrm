import {NextResponse} from 'next/server';
import {supabaseAdmin} from '../../../../lib/supabaseAdmin';

const BUSINESS_ID=process.env.ANAIRA_GRAPHICS_BUSINESS_ID||'737d5047-39f0-480b-8279-c7b1262f9e6c';
const BUSINESS_NAME='Anaira Graphics & Digital Solution';
const BUSINESS_EMAIL='anairagraphicsdigitalsolution@gmail.com';
const PHONE=/^[+\d][\d\s().-]{7,20}$/;
const EMAIL=/^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(req){
  try{
    const body=await req.json();
    if(body?.website) return NextResponse.json({ok:true});
    const name=String(body?.name||'').trim().slice(0,120);
    const phone=String(body?.phone||'').trim().slice(0,40);
    const email=String(body?.email||'').trim().toLowerCase().slice(0,160);
    const service=String(body?.service||'').trim().slice(0,120);
    const message=String(body?.message||'').trim().slice(0,3000);
    if(name.length<2) throw new Error('Name is required');
    if(!PHONE.test(phone)) throw new Error('Please enter a valid phone number');
    if(email && !EMAIL.test(email)) throw new Error('Please enter a valid email');
    if(message.length<8) throw new Error('Please describe your requirement');

    const s=supabaseAdmin();
    let business=null;
    if(BUSINESS_ID){
      const r=await s.from('restaurants').select('id,name').eq('id',BUSINESS_ID).maybeSingle();
      if(r.error) throw r.error;
      business=r.data;
    }
    if(!business?.id){
      const r=await s.from('restaurants').select('id,name').eq('name',BUSINESS_NAME).eq('email',BUSINESS_EMAIL).limit(1).maybeSingle();
      if(r.error) throw r.error;
      business=r.data;
    }
    if(!business?.id) throw new Error('Anaira Graphics business tenant is not configured. Set ANAiRA_GRAPHICS_BUSINESS_ID after creating the dedicated business tenant.');
    const tenantId=business.id;

    let customerId=null;
    const existing=await s.from('crm_customers').select('id,full_name,phone,email').eq('tenant_id',tenantId).eq('phone',phone).maybeSingle();
    if(existing.error) throw existing.error;
    if(existing.data?.id){
      customerId=existing.data.id;
      const {error}=await s.from('crm_customers').update({full_name:name,phone,email:email||existing.data.email||null,notes:`Website enquiry: ${message}`,updated_at:new Date().toISOString()}).eq('id',customerId).eq('tenant_id',tenantId);
      if(error) throw error;
    }else{
      const {data:created,error}=await s.from('crm_customers').insert({tenant_id:tenantId,full_name:name,phone,email:email||null,customer_type:'lead',notes:`Website enquiry: ${message}`}).select('id').single();
      if(error) throw error;
      customerId=created.id;
    }

    const {data:lead,error:le}=await s.from('crm_leads').insert({tenant_id:tenantId,customer_id:customerId,lead_type:'website_enquiry',source:'anaira_graphics_public_website',stage:'new',notes:`Service: ${service||'General enquiry'}\n\n${message}`}).select('id').single();
    if(le) throw le;

    try{
      await s.rpc('anaira_record_crm_timeline',{p_tenant_id:tenantId,p_customer_id:customerId,p_event_type:'lead_created',p_source_system:'anaira_graphics_website',p_source_id:String(lead.id),p_title:'New website enquiry',p_description:`${service||'General enquiry'} — ${message}`,p_metadata:{source:'public_website',service:service||null,phone,email:email||null}});
    }catch{}

    return NextResponse.json({ok:true,leadId:lead.id,customerId});
  }catch(e){return NextResponse.json({ok:false,error:e?.message||'Unable to save enquiry'},{status:400});}
}
