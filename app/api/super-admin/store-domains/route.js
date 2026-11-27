import {NextResponse} from 'next/server';
import {db,adminDb} from '../../../../lib/server/provider';

export const runtime='nodejs';
const fail=(message,status=400)=>NextResponse.json({ok:false,error:message},{status});
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
  let q=client.from('anaira_property_store_domains').select('id,store_id,restaurant_id,domain,domain_type,verification_status,domain_status,cname_target,is_primary,verified_at,activated_at,created_at').order('created_at',{ascending:false}).limit(500);
  if(status)q=q.eq('domain_status',status);
  const {data:domains,error}=await q;if(error)throw error;
  const ids=[...new Set((domains||[]).map(x=>x.restaurant_id).filter(Boolean))];
  let properties=[];
  if(ids.length){const {data,error:pe}=await client.from('restaurants').select('id,name,city,status').in('id',ids);if(pe)throw pe;properties=data||[];}
  const byId=new Map(properties.map(x=>[x.id,x]));
  return NextResponse.json({ok:true,domains:(domains||[]).map(d=>({...d,property:byId.get(d.restaurant_id)||null}))});
 }catch(e){return fail(e.message||'Unable to load store domains',e.status||500)}
}
export async function PATCH(req){
 try{
  const {client,user}=await superAdmin(req),body=await req.json(),id=String(body.id||''),action=String(body.action||'');
  if(!id||!['activate','disable'].includes(action))return fail('id and a supported action are required');
  const update=action==='activate'?{domain_status:'active',activated_at:new Date().toISOString(),updated_by:user.id,updated_at:new Date().toISOString()}:{domain_status:'disabled',updated_by:user.id,updated_at:new Date().toISOString()};
  if(action==='activate'){
   const {data:row,error:re}=await client.from('anaira_property_store_domains').select('verification_status').eq('id',id).single();if(re)throw re;
   if(row.verification_status!=='verified')return fail('Domain ownership must be verified before activation',409);
  }
  const {data,error}=await client.from('anaira_property_store_domains').update(update).eq('id',id).select('id,domain,domain_status').single();if(error)throw error;
  return NextResponse.json({ok:true,domain:data});
 }catch(e){return fail(e.message||'Unable to update domain',e.status||500)}
}
