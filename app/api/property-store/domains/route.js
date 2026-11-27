import {NextResponse} from 'next/server';
import crypto from 'node:crypto';
import {resolveTxt,resolveCname} from 'node:dns/promises';
import {db,adminDb} from '../../../../lib/server/provider';

export const runtime='nodejs';
const fail=(message,status=400)=>NextResponse.json({ok:false,error:message},{status});
const cleanDomain=value=>String(value||'').trim().toLowerCase().replace(/^https?:\/\//,'').replace(/\/$/,'').replace(/:\d+$/,'').replace(/\.$/,'');
const validDomain=value=>/^(?=.{4,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/.test(value);

async function actor(req,restaurantId){
 const auth=req.headers.get('authorization')||'';
 if(!auth.startsWith('Bearer '))throw Object.assign(new Error('Authentication required'),{status:401});
 const token=auth.slice(7).trim();
 const client=db(token);
 const {data:{user},error}=await client.auth.getUser(token);
 if(error||!user)throw Object.assign(new Error('Invalid or expired session'),{status:401});
 const [{data:profile,error:pe},{data:membership,error:me}]=await Promise.all([
  client.from('profiles').select('id,restaurant_id,role,is_super_admin').eq('id',user.id).maybeSingle(),
  client.from('anaira_business_memberships').select('business_id,status').eq('business_id',restaurantId).eq('user_id',user.id).eq('status','active').maybeSingle()
 ]);
 if(pe)throw pe;if(me)throw me;
 const isAdmin=profile?.is_super_admin===true||profile?.role==='super_admin';
 const ownsPrimary=profile?.restaurant_id===restaurantId;
 const hasMembership=membership?.business_id===restaurantId;
 if(!isAdmin&&!ownsPrimary&&!hasMembership)throw Object.assign(new Error('Property access denied'),{status:403});
 return {client:adminDb(),user,isAdmin,profile};
}

export async function GET(req){
 try{
  const url=new URL(req.url),restaurantId=url.searchParams.get('restaurant_id');
  if(!restaurantId)return fail('restaurant_id is required',400);
  const {client}=await actor(req,restaurantId);
  const {data,error}=await client.from('anaira_property_store_domains').select('id,store_id,restaurant_id,domain,domain_type,verification_method,verification_status,domain_status,cname_target,is_primary,verified_at,activated_at,last_checked_at,created_at').eq('restaurant_id',restaurantId).order('created_at',{ascending:false});
  if(error)throw error;
  return NextResponse.json({ok:true,domains:data||[],instructions:{txt_host:'_anaira-verification',txt_value_prefix:'anaira-verification=',cname_target:process.env.ANAIRA_STORE_CNAME_TARGET||process.env.VERCEL_PROJECT_PRODUCTION_URL||null}});
 }catch(e){return fail(e.message||'Unable to load domains',e.status||500)}
}

export async function POST(req){
 try{
  const body=await req.json(),restaurantId=String(body.restaurant_id||'').trim(),kind=String(body.domain_type||'custom');
  if(!restaurantId)return fail('restaurant_id is required');
  if(!['custom','anaira_subdomain'].includes(kind))return fail('Unsupported domain type');
  const {client,user}=await actor(req,restaurantId);
  const {data:store,error:se}=await client.from('anaira_platform_stores').select('id,slug,store_name,restaurant_id,store_type,is_platform_store').eq('restaurant_id',restaurantId).eq('store_type','hotel').eq('is_platform_store',false).maybeSingle();
  if(se)throw se;if(!store)return fail('Property Store has not been provisioned yet. Open Store Builder and save the store first.',409);
  let domain;
  if(kind==='anaira_subdomain'){
   const base=cleanDomain(process.env.ANAIRA_STORE_DOMAIN||'');
   if(!base||!validDomain(base))return fail('Set ANAIRA_STORE_DOMAIN to your verified Anaira store base domain before creating subdomains.',503);
   const slug=String(body.subdomain||store.slug||'').toLowerCase().replace(/[^a-z0-9-]+/g,'-').replace(/^-+|-+$/g,'').slice(0,55);
   if(!slug)return fail('A valid subdomain slug is required');
   domain=`${slug}.${base}`;
  }else{
   domain=cleanDomain(body.domain);
   if(!validDomain(domain)||domain.includes('..'))return fail('Enter a valid hostname without protocol or path');
  }
  const token=crypto.randomBytes(24).toString('hex');
  const managed=kind==='anaira_subdomain';
  const payload={store_id:store.id,restaurant_id:restaurantId,domain,domain_type:kind,verification_method:managed?'managed_subdomain':'dns_txt',verification_token:token,verification_status:'pending',domain_status:'pending',cname_target:process.env.ANAIRA_STORE_CNAME_TARGET||process.env.VERCEL_PROJECT_PRODUCTION_URL||null,is_primary:body.is_primary===true,verified_at:null,created_by:user.id,updated_by:user.id,updated_at:new Date().toISOString()};
  const {data,error}=await client.from('anaira_property_store_domains').insert(payload).select('id,domain,domain_type,verification_status,domain_status,cname_target,is_primary,verified_at').single();
  if(error)throw error;
  return NextResponse.json({ok:true,domain:data,dns:managed?null:{type:'TXT',host:`_anaira-verification.${domain}`,value:`anaira-verification=${token}`},note:managed?'Subdomain request saved. Platform wildcard DNS and hosting configuration must be verified by Super Admin before activation.':'Add the TXT record, verify ownership, attach the hostname to your Vercel project, then activate it.'},{status:201});
 }catch(e){return fail(e.message||'Unable to add domain',e.status||500)}
}

export async function PATCH(req){
 try{
  const body=await req.json(),restaurantId=String(body.restaurant_id||'').trim(),id=String(body.id||'').trim(),action=String(body.action||'');
  if(!restaurantId||!id||!action)return fail('restaurant_id, id and action are required');
  const {client,user}=await actor(req,restaurantId);
  const {data:domain,error:de}=await client.from('anaira_property_store_domains').select('*').eq('id',id).eq('restaurant_id',restaurantId).single();
  if(de)throw de;
  if(action==='verify'){
   let verified=false;
   if(domain.domain_type==='anaira_subdomain'){
    const expected=cleanDomain(domain.cname_target||process.env.ANAIRA_STORE_CNAME_TARGET||process.env.VERCEL_PROJECT_PRODUCTION_URL||'');
    if(!expected)return fail('Set ANAIRA_STORE_CNAME_TARGET or VERCEL_PROJECT_PRODUCTION_URL before verifying managed subdomains.',503);
    let targets=[];try{targets=await resolveCname(domain.domain)}catch{}
    verified=(targets||[]).some(target=>cleanDomain(target)===expected);
   }else{
    let records=[];try{records=await resolveTxt(`_anaira-verification.${domain.domain}`)}catch{}
    const expected=`anaira-verification=${domain.verification_token}`;
    verified=(records||[]).some(parts=>parts.join('')===expected);
   }
   const {data,error}=await client.from('anaira_property_store_domains').update({verification_status:verified?'verified':'failed',domain_status:'pending',verified_at:verified?new Date().toISOString():null,last_checked_at:new Date().toISOString(),updated_by:user.id,updated_at:new Date().toISOString()}).eq('id',id).eq('restaurant_id',restaurantId).select('id,domain,verification_status,domain_status,verified_at').single();
   if(error)throw error;
   return NextResponse.json({ok:verified,domain:data,error:verified?null:(domain.domain_type==='anaira_subdomain'?'The managed subdomain CNAME does not point to the configured Anaira hosting target yet.':'TXT verification record was not found or did not match. DNS propagation may take time.')},{status:verified?200:422});
  }
  if(action==='activate'){
   if(domain.verification_status!=='verified')return fail('Verify domain ownership before activation',409);
   if(body.is_primary===true){const {error:primaryError}=await client.from('anaira_property_store_domains').update({is_primary:false,updated_at:new Date().toISOString()}).eq('store_id',domain.store_id).eq('restaurant_id',restaurantId);if(primaryError)throw primaryError;}
   const {data,error}=await client.from('anaira_property_store_domains').update({domain_status:'active',is_primary:body.is_primary===true,activated_at:new Date().toISOString(),updated_by:user.id,updated_at:new Date().toISOString()}).eq('id',id).eq('restaurant_id',restaurantId).select('id,domain,domain_status,is_primary,activated_at').single();
   if(error)throw error;return NextResponse.json({ok:true,domain:data});
  }
  if(action==='disable'){
   const {data,error}=await client.from('anaira_property_store_domains').update({domain_status:'disabled',updated_by:user.id,updated_at:new Date().toISOString()}).eq('id',id).eq('restaurant_id',restaurantId).select('id,domain,domain_status').single();
   if(error)throw error;return NextResponse.json({ok:true,domain:data});
  }
  throw new Error('Unsupported domain action');
 }catch(e){return fail(e.message||'Domain action failed',e.status||500)}
}

export async function DELETE(req){
 try{
  const url=new URL(req.url),restaurantId=url.searchParams.get('restaurant_id'),id=url.searchParams.get('id');
  if(!restaurantId||!id)return fail('restaurant_id and id are required');
  const {client}=await actor(req,restaurantId);
  const {error}=await client.from('anaira_property_store_domains').delete().eq('restaurant_id',restaurantId).eq('id',id);
  if(error)throw error;return NextResponse.json({ok:true});
 }catch(e){return fail(e.message||'Domain delete failed',e.status||500)}
}
