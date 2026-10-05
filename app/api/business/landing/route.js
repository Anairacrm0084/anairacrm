import {NextResponse} from 'next/server';
import {supabaseAdmin} from '../../../../lib/supabaseAdmin';

async function access(req, businessId, requirePrivate=false){
  const admin=supabaseAdmin();
  const {data:business,error:be}=await admin.from('restaurants').select('id,name,business_type,phone,email,whatsapp,address,city,state,country,postal_code,landmark,website,description,logo,cover_image,gst,gst_enabled,gst_rate').eq('id',businessId).maybeSingle();
  if(be) throw be;
  if(!business) return {admin,business:null,allowed:false};
  const {data:landing,error:le}=await admin.from('anaira_business_landing_pages').select('*').eq('business_id',businessId).maybeSingle();
  if(le) throw le;
  if(landing?.published===true && !requirePrivate) return {admin,business,landing,allowed:true};
  const auth=req.headers.get('authorization')||'';
  if(!auth.startsWith('Bearer ')) return {admin,business,landing,allowed:false};
  const token=auth.slice(7).trim();
  const {data:u,error:ue}=await admin.auth.getUser(token);
  if(ue||!u?.user) return {admin,business,landing,allowed:false};
  const {data:p,error:pe}=await admin.from('profiles').select('id,restaurant_id,is_super_admin').eq('id',u.user.id).maybeSingle();
  if(pe) throw pe;
  const {data:m}=await admin.from('anaira_business_memberships').select('business_id,status').eq('business_id',businessId).eq('user_id',u.user.id).eq('status','active').maybeSingle();
  const allowed=Boolean(p?.is_super_admin || p?.restaurant_id===businessId || m?.business_id===businessId);
  return {admin,business,landing,allowed};
}

export async function GET(req){
  try{
    const url=new URL(req.url); const businessId=url.searchParams.get('business')||url.searchParams.get('id'); const type=url.searchParams.get('type')||'';
    if(!businessId) return NextResponse.json({error:'business is required'},{status:400});
    const a=await access(req,businessId,false);
    if(!a.business) return NextResponse.json({error:'Business not found'},{status:404});
    if(!a.allowed) return NextResponse.json({error:'Business access denied or website is not published'},{status:403});
    const [records,media,offers]=await Promise.all([
      a.admin.from('anaira_business_records').select('*').eq('business_id',businessId).order('sort_order').order('created_at'),
      a.admin.from('anaira_business_media').select('*').eq('business_id',businessId).eq('active',true).order('sort_order'),
      a.admin.from('anaira_business_offers').select('*').eq('business_id',businessId).eq('active',true).order('created_at',{ascending:false})
    ]);
    const payload={business:a.business,landing:a.landing,records:records.data||[],media:media.data||[],offers:offers.data||[]};
    if(type==='salon'||a.business.business_type==='salon'){
      const [services,staff,memberships,packages]=await Promise.all([
        a.admin.from('anaira_salon_services').select('*').eq('business_id',businessId).eq('status','active').order('created_at',{ascending:false}),
        a.admin.from('anaira_salon_staff').select('*').eq('business_id',businessId).eq('status','active').order('created_at',{ascending:false}),
        a.admin.from('anaira_salon_memberships').select('*').eq('business_id',businessId).eq('status','active').order('created_at',{ascending:false}),
        a.admin.from('anaira_salon_packages').select('*').eq('business_id',businessId).eq('status','active').order('created_at',{ascending:false})
      ]);
      const normalize=(row)=>({ ...row, ...(row?.data||{}), image_url: row?.image_url || row?.data?.image_url || null, gallery: row?.gallery || row?.data?.gallery || [] });
      payload.services=(services.data||[]).map(normalize).map(x=>({...x,name:x.name||x.title,price:x.price??0,duration_minutes:x.duration_minutes??x.duration??0,description:x.description||''}));
      payload.staff=(staff.data||[]).map(normalize).map(x=>({...x,name:x.name||x.title,photo_url:x.photo_url||x.image_url||null,role:x.role||'Stylist',bio:x.bio||''}));
      payload.memberships=(memberships.data||[]).map(normalize).map(x=>({...x,name:x.name||x.title,price:x.price??0,billing_interval:x.billing_interval||'monthly',benefits:Array.isArray(x.benefits)?x.benefits:[]}));
      payload.packages=(packages.data||[]).map(normalize).map(x=>({...x,name:x.name||x.title,price:x.price??0,expiry_days:x.expiry_days??30,included_services:Array.isArray(x.included_services)?x.included_services:[]}));
    }
    return NextResponse.json(payload,{headers:{'Cache-Control':'no-store'}});
  }catch(e){return NextResponse.json({error:e?.message||'Unable to load business website'},{status:500});}
}
