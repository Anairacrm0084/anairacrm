import {NextResponse} from 'next/server';
import {adminDb} from '../../../../../lib/server/provider';

export const runtime='nodejs';
export const dynamic='force-dynamic';
const validHost=value=>/^(?=.{4,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/.test(value);
export async function GET(req){
 try{
  const host=String(new URL(req.url).searchParams.get('host')||'').trim().toLowerCase();
  if(!validHost(host))return NextResponse.json({ok:false,error:'Invalid hostname'},{status:400});
  const db=adminDb();
  const {data:domain,error:de}=await db.from('anaira_property_store_domains').select('id,store_id,restaurant_id,domain,domain_status,verification_status').eq('domain',host).eq('domain_status','active').eq('verification_status','verified').maybeSingle();
  if(de)throw de;
  if(!domain)return NextResponse.json({ok:true,route_path:null},{status:200});
  const [{data:store,error:se},{data:property,error:pe},{data:membership,error:me},{data:settings,error:ste}]=await Promise.all([
   db.from('anaira_platform_stores').select('id,restaurant_id,store_type,slug,store_name,is_platform_store,enabled,published').eq('id',domain.store_id).eq('restaurant_id',domain.restaurant_id).maybeSingle(),
   db.from('restaurants').select('id,status,hospitality_type').eq('id',domain.restaurant_id).maybeSingle(),
   db.from('anaira_store_memberships').select('enabled').eq('store_id',domain.store_id).eq('restaurant_id',domain.restaurant_id).maybeSingle(),
   db.from('anaira_store_settings').select('published').eq('store_id',domain.store_id).eq('restaurant_id',domain.restaurant_id).maybeSingle()
  ]);
  if(se)throw se;if(pe)throw pe;if(me)throw me;if(ste)throw ste;
  if(!store||store.is_platform_store||store.store_type!=='hotel'||!store.enabled||!property||property.status!=='active'||!membership?.enabled||!(store.published||settings?.published))return NextResponse.json({ok:true,route_path:null});
  const type=String(property.hospitality_type||'hotel').toLowerCase();
  const routePath=['homestay','guest_house','cottage'].includes(type)?`/stay/${type}/${property.id}`:`/property/${property.id}?stay_type=${encodeURIComponent(type)}`;
  return NextResponse.json({ok:true,route_path:routePath});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Domain resolution failed'},{status:503})}
}
