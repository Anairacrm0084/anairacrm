import {NextResponse} from 'next/server';
import crypto from 'node:crypto';
import {resolveTxt} from 'node:dns/promises';
import {db,adminDb} from '../../../../lib/server/provider';

export const runtime='nodejs';
const fail=(message,status=400)=>NextResponse.json({ok:false,error:message},{status});
const cleanDomain=value=>String(value||'').trim().toLowerCase().replace(/^https?:\/\//,'').replace(/\/$/,'').replace(/:\d+$/,'').replace(/\.$/,'');
const validDomain=value=>/^(?=.{4,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/.test(value);
async function superAdmin(req){
 const h=req.headers.get('authorization')||'';if(!h.startsWith('Bearer '))throw Object.assign(new Error('Authentication required'),{status:401});
 const token=h.slice(7).trim(),client=db(token);
 const {data:{user},error}=await client.auth.getUser(token);if(error||!user)throw Object.assign(new Error('Invalid or expired session'),{status:401});
 const {data:profile,error:pe}=await client.from('profiles').select('id,role,is_super_admin').eq('id',user.id).maybeSingle();if(pe)throw pe;
 if(!profile?.is_super_admin&&profile?.role!=='super_admin')throw Object.assign(new Error('Super Admin access required'),{status:403});
 return {client:adminDb(),user};
}
export async function GET(req){
 try{
  const {client}=await superAdmin(req),u=new URL(req.url),status=u.searchParams.get('status');
  let q=client.from('anaira_property_store_domains').select('id,store_id,restaurant_id,domain,domain_type,verification_status,verification_token,domain_status,cname_target,is_primary,verified_at,activated_at,created_at').order('created_at',{ascending:false}).limit(500);
  if(status)q=q.eq('domain_status',status);
  const {data:domains,error}=await q;if(error)throw error;
  const {data:properties,error:pe}=await client.from('restaurants').select('id,name,city,status,hospitality_type').in('status',['active','inactive']).order('name').limit(1000);if(pe)throw pe;
  const ids=[...new Set((domains||[]).map(x=>x.restaurant_id).filter(Boolean))];
  const byId=new Map((properties||[]).map(x=>[x.id,x]));
  const selected=(domains||[]).map(d=>({...d,property:byId.get(d.restaurant_id)||null}));
  return NextResponse.json({ok:true,domains:selected,properties:properties||[]});
 }catch(e){return fail(e.message||'Unable to load store domains',e.status||500)}
}
export async function POST(req){
 try{
  const {client,user}=await superAdmin(req),body=await req.json();
  const restaurantId=String(body.restaurant_id||'').trim(),domain=cleanDomain(body.domain);
  if(!restaurantId)return fail('Select a property first');
  if(!validDomain(domain)||domain.includes('..'))return fail('Enter a valid hostname without protocol or path');
  const {data:platformRow,error:platformError}=await client.from('anaira_platform_settings').select('value').eq('key','anaira_platform_hostnames').maybeSingle();if(platformError)throw platformError;
  const reserved=['crm.anairapos.in','anaira.com','www.anaira.com',...String(process.env.ANAIRA_PLATFORM_HOSTNAMES||'').split(',').map(x=>x.trim().toLowerCase()),...(Array.isArray(platformRow?.value?.value)?platformRow.value.value:[])];
  if(reserved.map(x=>String(x||'').toLowerCase()).includes(domain))return fail('This hostname is reserved for the Anaira application/marketplace and cannot be assigned to a property.',409);
  const {data:store,error:se}=await client.from('anaira_platform_stores').select('id,restaurant_id,store_type,is_platform_store').eq('restaurant_id',restaurantId).eq('store_type','hotel').eq('is_platform_store',false).maybeSingle();
  if(se)throw se;if(!store)return fail('This property does not have a provisioned Property Store. Save its Store Builder settings first.',409);
  const token=crypto.randomBytes(24).toString('hex');
  const {data,error}=await client.from('anaira_property_store_domains').insert({store_id:store.id,restaurant_id:restaurantId,domain,domain_type:'custom',verification_method:'dns_txt',verification_token:token,verification_status:'pending',domain_status:'pending',cname_target:process.env.ANAIRA_STORE_CNAME_TARGET||process.env.VERCEL_PROJECT_PRODUCTION_URL||null,is_primary:body.is_primary===true,verified_at:null,created_by:user.id,updated_by:user.id,updated_at:new Date().toISOString()}).select('id,domain,domain_type,verification_status,domain_status,cname_target,is_primary,verified_at').single();
  if(error)throw error;
  return NextResponse.json({ok:true,domain:data,dns:{type:'TXT',host:`_anaira-verification.${domain}`,value:`anaira-verification=${token}`},note:'Add the TXT record, wait for DNS propagation, verify ownership, then activate the domain.'},{status:201});
 }catch(e){return fail(e.message||'Unable to add property domain',e.status||500)}
}
export async function PATCH(req){
 try{
  const {client,user}=await superAdmin(req),body=await req.json(),id=String(body.id||''),action=String(body.action||'');
  if(!id||!['activate','disable','verify'].includes(action))return fail('id and a supported action are required');
  if(action==='verify'){
   const {data:domain,error:de}=await client.from('anaira_property_store_domains').select('id,domain,verification_token').eq('id',id).single();if(de)throw de;
   let records=[];try{records=await resolveTxt(`_anaira-verification.${domain.domain}`)}catch{}
   const expected=`anaira-verification=${domain.verification_token}`;const verified=(records||[]).some(parts=>parts.join('')===expected);
   const {data,error}=await client.from('anaira_property_store_domains').update({verification_status:verified?'verified':'failed',domain_status:'pending',verified_at:verified?new Date().toISOString():null,last_checked_at:new Date().toISOString(),updated_by:user.id,updated_at:new Date().toISOString()}).eq('id',id).select('id,domain,verification_status,domain_status,verified_at').single();if(error)throw error;
   return NextResponse.json({ok:verified,domain:data,error:verified?null:'TXT verification record not found or does not match.'},{status:verified?200:422});
  }
  const update=action==='activate'?{domain_status:'active',activated_at:new Date().toISOString(),updated_by:user.id,updated_at:new Date().toISOString()}:{domain_status:'disabled',updated_by:user.id,updated_at:new Date().toISOString()};
  if(action==='activate'){
   const {data:row,error:re}=await client.from('anaira_property_store_domains').select('verification_status').eq('id',id).single();if(re)throw re;
   if(row.verification_status!=='verified')return fail('Domain ownership must be verified before activation',409);
  }
  const {data,error}=await client.from('anaira_property_store_domains').update(update).eq('id',id).select('id,domain,domain_status').single();if(error)throw error;
  return NextResponse.json({ok:true,domain:data});
 }catch(e){return fail(e.message||'Unable to update domain',e.status||500)}
}
