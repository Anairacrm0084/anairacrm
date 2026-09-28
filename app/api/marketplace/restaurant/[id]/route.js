import {NextResponse} from 'next/server'
import {db,open} from '../../../../../lib/server/provider'

export const runtime='nodejs'

const norm=v=>String(v||'').trim().toLowerCase().replace(/\\s+/g,' ')
const first=(...xs)=>xs.find(v=>v!==null&&v!==undefined&&v!=='')

async function safeQuery(fn, fallback=null){
  try{
    const q=await fn();
    return q?.error ? {data:fallback,error:q.error} : {data:q?.data ?? fallback,error:null};
  }catch(error){ return {data:fallback,error}; }
}

async function loadLocal(s,id){
  // Public store identity must not depend on the tenant-private restaurants table.
  // Store membership is explicitly public-readable when enabled/published.
  const storeQ=await safeQuery(()=>s.from('anaira_platform_stores').select('id,enabled,published,store_name,slug').eq('store_type','restaurant').eq('enabled',true).eq('published',true).limit(10));
  const store=(storeQ.data||[])[0];
  if(!store?.enabled || !store?.published) return null;

  // The same restaurant may have both Hotel and Restaurant memberships.
  // Scope all public restaurant-store reads by the Restaurant platform store_id.
  const membershipQ=await safeQuery(()=>s.from('anaira_store_memberships').select('*').eq('restaurant_id',id).eq('store_id',store.id).eq('enabled',true).limit(10));
  if(membershipQ.error) return null;
  const membership=(membershipQ.data||[])[0];
  if(!membership) return null;

  const restaurantQ=await safeQuery(()=>s.from('restaurants').select('id,name,slug,status,logo,cover_image,cuisine,address,city,phone,website,delivery_enabled').eq('id',id).maybeSingle(),null);
  const [settingsQ,categoriesQ,menuQ,offersQ,featuredQ]=await Promise.all([
    safeQuery(()=>s.from('anaira_store_settings').select('*').eq('restaurant_id',id).eq('store_id',store.id).eq('store_type','restaurant').eq('enabled',true).eq('published',true).limit(10)),
    safeQuery(()=>s.from('anaira_store_categories').select('*').eq('restaurant_id',id).eq('active',true).order('display_order').order('name'),[]),
    safeQuery(()=>s.from('anaira_marketplace_menu_items').select('*').eq('restaurant_id',id).eq('active',true).order('display_order').order('item_name').limit(1000),[]),
    safeQuery(()=>s.from('anaira_store_offers').select('*').eq('restaurant_id',id).eq('active',true).order('created_at',{ascending:false}),[]),
    safeQuery(()=>s.from('anaira_marketplace_featured_items').select('*').eq('restaurant_id',id).eq('active',true).order('display_order'),[])
  ]);

  const settings=(settingsQ.data||[])[0]||null;
  const categories=categoriesQ.data||[];
  const menu=menuQ.data||[];
  const offers=offersQ.data||[];
  const featured=featuredQ.data||[];

  const itemIds=menu.map(x=>x.id);
  let variants=[],addons=[];
  if(itemIds.length){
    const [vr,ar]=await Promise.all([
      safeQuery(()=>s.from('anaira_store_item_variants').select('*').in('menu_item_id',itemIds).eq('active',true).order('display_order'),[]),
      safeQuery(()=>s.from('anaira_store_item_addons').select('*').in('menu_item_id',itemIds).eq('active',true).order('display_order'),[])
    ]);
    variants=vr.data||[]; addons=ar.data||[];
  }
  const byV=new Map(),byA=new Map();
  variants.forEach(v=>{const a=byV.get(v.menu_item_id)||[];a.push(v);byV.set(v.menu_item_id,a)});
  addons.forEach(a=>{const x=byA.get(a.menu_item_id)||[];x.push(a);byA.set(a.menu_item_id,x)});
  const localMenu=menu.map(i=>({...i,image:i.image_url||null,variants:byV.get(i.id)||[],addons:byA.get(i.id)||[]}));
  const listing=membership?.listing_override||{};
  const cfg=membership?.store_config||{};
  const baseRestaurant=restaurantQ.data || {id, name:listing.title||'Restaurant', slug:listing.slug||id, logo:listing.logo_url||'', cover_image:listing.cover_url||'', cuisine:listing.cuisine||'', address:listing.address||'', city:listing.city||'', phone:listing.phone||'', website:listing.website||'', delivery_enabled:true};
  return {restaurant:baseRestaurant,store,membership,settings,categories,menu:localMenu,offers,featured,listing_override:listing,store_config:cfg,
    errors:{membership:membershipQ.error?.message,settings:settingsQ.error?.message,categories:categoriesQ.error?.message,menu:menuQ.error?.message,offers:offersQ.error?.message,featured:featuredQ.error?.message}};
}
async function tryRemote(s,id,local){
  // Legacy connection table is optional. Some deployments use the v2 Integration Hub instead.
  try{
    const {data:conn,error}=await s.from('anaira_restaurant_connections').select('restaurant_id,restaurant_api_base_url,restaurant_api_key,status').eq('restaurant_id',id).eq('status','connected').maybeSingle()
    if(!error && conn){
      const key=open(conn.restaurant_api_key)
      const r=await fetch(`${String(conn.restaurant_api_base_url).replace(/\/$/,'')}/api/integrations/anaira-crm/bridge`,{headers:{'x-anaira-restaurant-key':key},cache:'no-store'})
      const j=await r.json().catch(()=>({}))
      if(r.ok&&j?.ok) return {snapshot:j.data||{},source:'restaurant_saas'}
    }
  }catch{}
  return {snapshot:null,source:local?.membership?.catalog_source==='restaurant_saas'?'restaurant_saas_unavailable':'local'}
}

function mergeSnapshot(local,remote){
  const remoteMenu=Array.isArray(remote?.menu)?remote.menu:[]
  const localMenu=Array.isArray(local?.menu)?local.menu:[]
  const byId=new Map(localMenu.map(i=>[String(i.id),i]))
  const byName=new Map(localMenu.map(i=>[norm(i.item_name||i.name),i]))
  const merged=[...localMenu]
  for(const ri of remoteMenu){
    const hit=byId.get(String(ri.id))||byName.get(norm(ri.name||ri.item_name))
    if(hit){
      Object.assign(hit,{description:first(hit.description,ri.description),price:first(hit.price,ri.price),image:first(hit.image_url,hit.image,ri.image),category_name:first(hit.category_name,ri.category,ri.category_name),discount_price:first(hit.discount_price,ri.discount_price),variants:hit.variants?.length?hit.variants:(ri.variants||[]),addons:hit.addons?.length?hit.addons:(ri.addons||[])})
    }else merged.push({...ri,id:ri.id,item_name:ri.name||ri.item_name,description:ri.description,price:ri.price||0,image_url:ri.image||ri.image_url||null,category_name:ri.category||ri.category_name||'Menu',variants:ri.variants||[],addons:ri.addons||[]})
  }
  return {
    ...remote,
    menu:merged,
    categories:(local.categories?.length?local.categories:(remote?.categories||[])),
    offers:(local.offers?.length?local.offers:(remote?.offers||[])),
    featured:local.featured||[],
  }
}

export async function GET(req,{params}){
  try{
    const id=(await params).id
    const s=db()
    const local=await loadLocal(s,id)
    if(!local) return NextResponse.json({ok:false,error:'Restaurant not found'},{status:404})
    if(local.store && (!local.store.enabled||!local.store.published)) return NextResponse.json({ok:false,error:'Restaurant marketplace is not currently published'},{status:404})

    const remote=await tryRemote(s,id,local)
    const merged=remote.snapshot?mergeSnapshot(local,remote.snapshot):{
      menu:local.menu,categories:local.categories,offers:local.offers,featured:local.featured
    }
    const listing=local.listing_override||{}
    const restaurant={...local.restaurant,
      name:first(listing.title,local.restaurant.name),
      logo:first(listing.logo_url,local.restaurant.logo),
      cover_image:first(listing.cover_url,local.restaurant.cover_image),
      city:first(listing.city,local.restaurant.city),
      address:first(listing.address,local.restaurant.address),
      phone:first(listing.phone,local.restaurant.phone),
      website:first(listing.website,local.restaurant.website)
    }
    return NextResponse.json({ok:true,source:remote.source,integrated:!!remote.snapshot,restaurant,membership:local.membership||{restaurant_id:id,enabled:true,catalog_source:remote.snapshot?'restaurant_saas':'local',listing_override:listing,store_config:local.store_config},store:local.store,settings:local.settings,listing_override:listing,store_config:local.store_config,data:merged},{headers:{'Cache-Control':'no-store'}})
  }catch(e){return NextResponse.json({ok:false,error:e.message},{status:400})}
}
