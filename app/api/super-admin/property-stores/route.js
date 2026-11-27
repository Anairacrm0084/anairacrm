import {NextResponse} from 'next/server';
import {db,adminDb} from '../../../../lib/server/provider';

export const runtime='nodejs';
const fail=(message,status=400)=>NextResponse.json({ok:false,error:message},{status});
async function admin(req){
 const h=req.headers.get('authorization')||'';if(!h.startsWith('Bearer '))throw Object.assign(new Error('Authentication required'),{status:401});
 const token=h.slice(7).trim(),client=db(token);
 const {data:{user},error}=await client.auth.getUser(token);if(error||!user)throw Object.assign(new Error('Invalid or expired session'),{status:401});
 const {data:p,error:pe}=await client.from('profiles').select('id,role,is_super_admin').eq('id',user.id).maybeSingle();if(pe)throw pe;
 if(!p?.is_super_admin&&p?.role!=='super_admin')throw Object.assign(new Error('Super Admin access required'),{status:403});
 return {client:adminDb(),user};
}
export async function GET(req){
 try{
  const {client}=await admin(req),u=new URL(req.url),type=u.searchParams.get('hospitality_type');
  let q=client.from('anaira_platform_stores').select('id,restaurant_id,store_type,store_name,slug,enabled,published,domain,hospitality_type,marketplace_approval_status,marketplace_approved_at,created_at').eq('is_platform_store',false).eq('store_type','hotel').not('restaurant_id','is',null).order('created_at',{ascending:false}).limit(500);
  if(type)q=q.eq('hospitality_type',type);
  const {data:stores,error}=await q;if(error)throw error;
  const ids=[...new Set((stores||[]).map(x=>x.restaurant_id).filter(Boolean))];
  if(!ids.length)return NextResponse.json({ok:true,stores:[]});
  const [props,settings]=await Promise.all([
   client.from('restaurants').select('id,name,city,state,country,status,hospitality_type').in('id',ids),
   client.from('anaira_store_settings').select('store_id,restaurant_id,published,slug,seo_title').in('restaurant_id',ids)
  ]);
  if(props.error)throw props.error;if(settings.error)throw settings.error;
  const pMap=new Map((props.data||[]).map(x=>[x.id,x])),sMap=new Map((settings.data||[]).map(x=>[`${x.restaurant_id}:${x.store_id}`,x]));
  return NextResponse.json({ok:true,stores:(stores||[]).map(s=>{const direct=sMap.get(`${s.restaurant_id}:${s.id}`)||null;const market={approval_status:s.marketplace_approval_status,approved_at:s.marketplace_approved_at,marketplace_visible:s.published};return {...s,property:pMap.get(s.restaurant_id)||null,direct_store:direct,marketplace:market,lifecycle:!s.enabled?'suspended':(direct?.published||s.published)?'published':'draft'}})});
 }catch(e){return fail(e.message||'Unable to load property stores',e.status||500)}
}
export async function PATCH(req){
 try{
  const {client,user}=await admin(req),body=await req.json(),storeId=String(body.store_id||''),action=String(body.action||'');
  if(!storeId||!['approve_marketplace','reject_marketplace','publish_marketplace','unpublish_marketplace','publish_direct','unpublish_direct','suspend','resume'].includes(action))return fail('store_id and a supported action are required');
  const {data:store,error:se}=await client.from('anaira_platform_stores').select('id,restaurant_id,store_type,is_platform_store,enabled,published,marketplace_approval_status').eq('id',storeId).single();if(se)throw se;
  if(store.is_platform_store||store.store_type!=='hotel'||!store.restaurant_id)return fail('Only tenant hospitality property stores can be managed here',409);
  const now=new Date().toISOString();
  if(action==='approve_marketplace'||action==='reject_marketplace'){
   const status=action==='approve_marketplace'?'approved':'rejected';
   const {error}=await client.from('anaira_platform_stores').update({marketplace_approval_status:status,marketplace_approved_at:status==='approved'?now:null,marketplace_approved_by:status==='approved'?user.id:null,updated_at:now}).eq('id',storeId);if(error)throw error;
  }else if(action==='publish_marketplace'){
   if(!store.enabled)return fail('Resume this property store before publishing it to the marketplace',409);
   if(store.marketplace_approval_status!=='approved')return fail('Approve this property for the marketplace before publishing it',409);
   const {error}=await client.from('anaira_platform_stores').update({published:true,updated_at:now}).eq('id',storeId);if(error)throw error;
  }else if(action==='unpublish_marketplace'){
   const {error}=await client.from('anaira_platform_stores').update({published:false,updated_at:now}).eq('id',storeId);if(error)throw error;
  }else if(action==='publish_direct'||action==='unpublish_direct'){
   if(action==='publish_direct'&&!store.enabled)return fail('Resume this property store before publishing its direct storefront',409);
   const {data:settings,error:se2}=await client.from('anaira_store_settings').select('id').eq('store_id',storeId).eq('restaurant_id',store.restaurant_id).maybeSingle();if(se2)throw se2;if(!settings)return fail('Property store settings are missing. Open Store Builder and save the store first.',409);
   const {error}=await client.from('anaira_store_settings').update({published:action==='publish_direct',updated_at:now}).eq('store_id',storeId).eq('restaurant_id',store.restaurant_id);if(error)throw error;
  }else if(action==='suspend'||action==='resume'){
   const {error}=await client.from('anaira_platform_stores').update({enabled:action==='resume',updated_at:now}).eq('id',storeId);if(error)throw error;
  }
  await client.from('anaira_business_domain_events_v16').insert({business_id:store.restaurant_id,business_type:'hospitality',module_key:'property_store',entity_id:storeId,event_type:'admin_'+action,actor_id:user.id,payload:{action}});
  return NextResponse.json({ok:true,action,store_id:storeId});
 }catch(e){return fail(e.message||'Property store action failed',e.status||500)}
}
