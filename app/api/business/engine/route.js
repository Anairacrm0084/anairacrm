import { NextResponse } from 'next/server';
import { supabaseAdmin } from '../../../../lib/supabaseAdmin';
import { getBusinessEngineConfig, BUSINESS_ENGINE_TYPES } from '../../../../lib/business/engineConfig';

function cleanType(v){ return String(v||'').trim().toLowerCase(); }
function norm(row){
  const d=row?.data && typeof row.data==='object' ? row.data : {};
  return {
    id:row?.id||null,
    name:row?.name||row?.title||d.name||d.title||'Item',
    description:row?.description||d.description||'',
    price:Number(row?.price ?? d.price ?? 0),
    currency:row?.currency||d.currency||'INR',
    duration_minutes:Number(row?.duration_minutes ?? d.duration_minutes ?? d.duration ?? 0)||null,
    image_url:row?.image_url||d.image_url||null,
    metadata:{...d,...(row?.metadata||{})}
  };
}
async function getContext(req){
  const url=new URL(req.url);
  const type=cleanType(url.searchParams.get('type'));
  const businessId=url.searchParams.get('business')||url.searchParams.get('id');
  if(!businessId) throw Object.assign(new Error('business is required'),{status:400});
  const cfg=getBusinessEngineConfig(type);
  const admin=supabaseAdmin();
  const {data:business,error}=await admin.from('restaurants').select('id,name,business_type,phone,email,address,city,state,country,website,description').eq('id',businessId).maybeSingle();
  if(error) throw error;
  if(!business) throw Object.assign(new Error('Business not found'),{status:404});
  const {data:workspace}=await admin.from('anaira_business_workspaces').select('*').eq('business_id',businessId).maybeSingle();
  return {admin,business,workspace,cfg,type:type||business.business_type||'other',businessId};
}
async function loadCatalog(admin,businessId,cfg,type){
  const {data:universal}=await admin.from('anaira_business_catalog_items').select('*').eq('business_id',businessId).eq('active',true).order('sort_order').order('created_at',{ascending:false}).limit(100);
  if(universal?.length) return universal.map(norm);
  if(cfg.catalogTable){
    try{
      const {data}=await admin.from(cfg.catalogTable).select('*').eq('business_id',businessId).order('created_at',{ascending:false}).limit(100);
      if(data?.length) return data.map(norm);
    }catch(_){}
  }
  const {data:records}=await admin.from('anaira_business_records').select('*').eq('business_id',businessId).eq('active',true).order('sort_order').order('created_at',{ascending:false}).limit(100);
  return (records||[]).map(norm);
}
export async function GET(req){
  try{
    const c=await getContext(req);
    const catalog=await loadCatalog(c.admin,c.businessId,c.cfg,c.type);
    const {data:landing}=await c.admin.from('anaira_business_landing_pages').select('*').eq('business_id',c.businessId).maybeSingle();
    return NextResponse.json({business:c.business,workspace:c.workspace,config:c.cfg,catalog,landing});
  }catch(e){return NextResponse.json({error:e.message||'Unable to load business engine'},{status:e.status||500});}
}
export async function POST(req){
  try{
    const body=await req.json();
    const u=new URL(req.url); u.searchParams.set('type',body.type||''); u.searchParams.set('business',body.business_id||'');
    const c=await getContext(new Request(u.toString(),{headers:req.headers}));
    const items=Array.isArray(body.items)?body.items:[];
    if(!body.customer?.name && !body.customer?.phone && !body.customer?.email) return NextResponse.json({error:'Customer name, phone or email is required'},{status:400});
    const subtotal=items.reduce((s,i)=>s+(Number(i.unit_price||i.price||0)*Number(i.quantity||1)),0);
    const discount=Math.max(0,Number(body.discount||0));
    const tax=Math.max(0,Number(body.tax||0));
    const total=Math.max(0,subtotal-discount+tax);
    const idem=String(body.idempotency_key||crypto.randomUUID());
    const {data:existing}=await c.admin.from('anaira_business_transactions').select('*').eq('business_id',c.businessId).eq('idempotency_key',idem).maybeSingle();
    if(existing) return NextResponse.json({transaction:existing,reused:true});
    const initialStatus=body.payment_method==='online' && total>0?'payment_pending':'pending';
    const {data:tx,error}=await c.admin.from('anaira_business_transactions').insert({
      business_id:c.businessId,business_type:c.type,transaction_type:c.cfg.transactionType,status:initialStatus,
      customer_name:body.customer?.name||null,customer_email:body.customer?.email||null,customer_phone:body.customer?.phone||null,
      scheduled_at:body.scheduled_at||null,scheduled_end_at:body.scheduled_end_at||null,currency:body.currency||'INR',
      subtotal,discount,tax,total,payment_status:total===0?'paid':'unpaid',payment_method:body.payment_method||'pay_later',
      metadata:{journey:c.cfg.journey,notes:body.notes||'',source:'universal-business-engine'},idempotency_key:idem
    }).select('*').single();
    if(error) throw error;
    if(items.length){
      const rows=items.map(i=>({transaction_id:tx.id,catalog_item_id:i.id||null,name:i.name||'Item',quantity:Number(i.quantity||1),unit_price:Number(i.unit_price??i.price??0),total_price:Number(i.quantity||1)*Number(i.unit_price??i.price??0),metadata:i.metadata||{}}));
      const {error:ie}=await c.admin.from('anaira_business_transaction_items').insert(rows);
      if(ie) throw ie;
    }
    await c.admin.from('anaira_business_transaction_events').insert({transaction_id:tx.id,event_type:'created',to_status:initialStatus,payload:{business_type:c.type,items_count:items.length}});
    if(total>0 && body.payment_method==='online'){
      const {data:pi,error:pe}=await c.admin.from('anaira_payment_intents').insert({
        restaurant_id:c.businessId,reference_type:'business_transaction',reference_id:tx.id,provider:'manual',
        amount:total,currency:body.currency||'INR',status:'created',idempotency_key:idem,metadata:{business_type:c.type}
      }).select('*').single();
      if(pe) throw pe;
      return NextResponse.json({transaction:tx,payment_intent:pi});
    }
    return NextResponse.json({transaction:tx});
  }catch(e){return NextResponse.json({error:e.message||'Unable to create transaction'},{status:e.status||500});}
}
export async function PATCH(req){
  try{
    const body=await req.json(); const id=body.transaction_id;
    if(!id) return NextResponse.json({error:'transaction_id is required'},{status:400});
    const admin=supabaseAdmin();
    const {data:tx,error}=await admin.from('anaira_business_transactions').select('*').eq('id',id).single();
    if(error||!tx) return NextResponse.json({error:'Transaction not found'},{status:404});
    const allowed={pending:['confirmed','cancelled'],payment_pending:['confirmed','cancelled','failed'],confirmed:['in_progress','cancelled'],in_progress:['completed','cancelled'],completed:[],cancelled:[],failed:[],expired:[],refunded:[]};
    const next=String(body.status||'');
    if(!allowed[tx.status]?.includes(next)) return NextResponse.json({error:`Invalid transition ${tx.status} -> ${next}`},{status:409});
    const patch={status:next};
    if(body.payment_status) patch.payment_status=body.payment_status;
    if(body.payment_method) patch.payment_method=body.payment_method;
    const {data:updated,error:ue}=await admin.from('anaira_business_transactions').update(patch).eq('id',id).select('*').single();
    if(ue) throw ue;
    await admin.from('anaira_business_transaction_events').insert({transaction_id:id,event_type:'status_changed',from_status:tx.status,to_status:next,payload:{source:'customer_engine'}});
    return NextResponse.json({transaction:updated});
  }catch(e){return NextResponse.json({error:e.message||'Unable to update transaction'},{status:e.status||500});}
}