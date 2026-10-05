import {NextResponse} from 'next/server';
import {supabaseAdmin} from '../../../../lib/supabaseAdmin';

async function sendAdminEmail({to,business,lead}){
 if(!to) return {status:'no_recipient'};
 const apiKey=process.env.RESEND_API_KEY;
 const from=process.env.RESEND_FROM||process.env.SEO_REPORT_FROM;
 if(!apiKey||!from) return {status:'provider_not_configured'};
 const subject=`New website enquiry — ${business.name}`;
 const text=[
  `New enquiry received for ${business.name}.`,
  '',
  `Customer: ${lead.name}`,
  `Phone: ${lead.phone}`,
  `Email: ${lead.email||'Not provided'}`,
  `Requirement: ${lead.requirement}`,
  `Source: Website`,
  '',
  `Business ID: ${business.id}`,
 ].join('\n');
 const r=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${apiKey}`,'Content-Type':'application/json'},body:JSON.stringify({from,to:[to],subject,text})});
 const j=await r.json().catch(()=>({}));
 if(!r.ok) return {status:'failed',error:j?.message||'Email delivery failed'};
 return {status:'sent',provider:'resend',provider_message_id:j?.id||null};
}

export async function POST(req){
 try{
  const body=await req.json();
  const businessId=String(body?.businessId||'').trim();
  const type=String(body?.type||'it_agency').trim();
  if(!businessId||!body?.name||!body?.phone||!body?.requirement) return NextResponse.json({error:'Name, phone and requirement are required.'},{status:400});
  const admin=supabaseAdmin();
  const {data:business,error:be}=await admin.from('restaurants').select('id,name,email,business_type').eq('id',businessId).maybeSingle();
  if(be) throw be;
  if(!business||business.business_type!==type) return NextResponse.json({error:'Business not found.'},{status:404});

  const lead={name:String(body.name).trim(),phone:String(body.phone).trim(),email:String(body.email||'').trim(),requirement:String(body.requirement).trim(),source:'website',status:'new'};
  const {data,error}=await admin.from('anaira_business_records').insert({business_id:businessId,business_type:type,module_key:'leads',title:lead.name,data:lead,status:'active'}).select().single();
  if(error) throw error;

  // Prefer the business email saved on the business record. If it is missing,
  // fall back to the active business-admin profile email for this tenant.
  let recipient=String(business.email||'').trim();
  if(!recipient){
   const {data:profiles}=await admin.from('profiles').select('email,role,is_super_admin').eq('restaurant_id',businessId).not('email','is',null).order('role',{ascending:true}).limit(10);
   recipient=profiles?.find(p=>['business_admin','owner','admin'].includes(String(p.role||'').toLowerCase()))?.email||profiles?.[0]?.email||'';
  }

  const delivery=await sendAdminEmail({to:recipient,business,lead});
  return NextResponse.json({ok:true,id:data.id,email:delivery});
 }catch(e){return NextResponse.json({error:e?.message||'Unable to create enquiry'},{status:500});}
}
