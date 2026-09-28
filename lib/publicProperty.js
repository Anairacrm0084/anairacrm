import {supabase} from './supabase';

export async function resolveRestaurantId(key){
  if(!key) return null;
  const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(key);
  if(uuid){
    // Public store identity must not depend on the private restaurants table/RLS.
    // A restaurant can legitimately belong to both the Hotel and Restaurant stores.
    // Resolve the Restaurant platform store first, then use its store_id as the unique scope.
    const {data:stores,error:storeError}=await supabase.from('anaira_platform_stores').select('id,enabled,published').eq('store_type','restaurant').eq('enabled',true).eq('published',true).limit(10);
    if(storeError) return null;
    const platformStore=(stores||[])[0];
    if(!platformStore?.id) return null;
    const {data:members,error}=await supabase.from('anaira_store_memberships').select('restaurant_id,store_id,enabled,listing_override,store_config,catalog_source').eq('restaurant_id',key).eq('store_id',platformStore.id).eq('enabled',true).limit(10);
    if(error) return null;
    const data=(members||[])[0];
    if(!data) return null;
    const listing=data.listing_override||{};
    return {id:data.restaurant_id,name:listing.title||'Restaurant',slug:key,logo:listing.logo_url||'',cover_image:listing.cover_url||'',cuisine:listing.cuisine||'',address:listing.address||'',city:listing.city||'',phone:listing.phone||'',website:listing.website||'',delivery_enabled:true,store_id:data.store_id,listing_override:listing,store_config:data.store_config||{},catalog_source:data.catalog_source||'local'};
  }
  const {data,error}=await supabase.from('anaira_store_memberships').select('restaurant_id,store_id,enabled,listing_override,store_config,catalog_source').eq('enabled',true);
  if(error) throw error;
  const hit=(data||[]).find(x=>String(x.listing_override?.slug||'').toLowerCase()===String(key).toLowerCase());
  if(!hit) return null;
  const listing=hit.listing_override||{};
  return {id:hit.restaurant_id,name:listing.title||'Restaurant',slug:key,logo:listing.logo_url||'',cover_image:listing.cover_url||'',cuisine:listing.cuisine||'',address:listing.address||'',city:listing.city||'',phone:listing.phone||'',website:listing.website||'',delivery_enabled:true,store_id:hit.store_id,listing_override:listing,store_config:hit.store_config||{},catalog_source:hit.catalog_source||'local'};
}
