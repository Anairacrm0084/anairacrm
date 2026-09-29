import {supabase} from './supabase';

const normalize = (x) => ({
  id:x.restaurant_id || x.id,
  name:x.listing_override?.title || x.name || 'Property',
  slug:x.listing_override?.slug || x.id,
  logo:x.listing_override?.logo_url || x.logo || '',
  cover_image:x.listing_override?.cover_url || x.cover_image || '',
  cuisine:x.listing_override?.cuisine || x.cuisine || '',
  address:x.listing_override?.address || x.address || '',
  city:x.listing_override?.city || x.city || '',
  phone:x.listing_override?.phone || x.phone || '',
  website:x.listing_override?.website || x.website || '',
  delivery_enabled:x.delivery_enabled !== false,
  hospitality_types:Array.isArray(x.hospitality_types)&&x.hospitality_types.length ? x.hospitality_types : [x.hospitality_type || 'hotel'],
  hospitality_type:x.hospitality_type || (Array.isArray(x.hospitality_types)&&x.hospitality_types[0]) || 'hotel',
  store_id:x.store_id || null,
  listing_override:x.listing_override || {},
  store_config:x.store_config || {},
  catalog_source:x.catalog_source || 'local'
});

export async function resolveRestaurantId(key){
  if(!key) return null;
  const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(key);

  if(uuid){
    // The public /book/[id] URL is keyed by the canonical property ID.
    // Resolve the property first; do not require the property to be typed as "hotel".
    const {data:members,error:me}=await supabase
      .from('anaira_store_memberships')
      .select('restaurant_id,store_id,enabled,listing_override,store_config,catalog_source')
      .eq('restaurant_id',key)
      .eq('enabled',true)
      .limit(20);
    if(me) return null;

    const membership=(members||[])[0] || null;
    const {data:r,error:re}=await supabase
      .from('restaurants')
      .select('id,name,city,address,logo,cover_image,cuisine,phone,website,delivery_enabled,hospitality_type,hospitality_types')
      .eq('id',key)
      .maybeSingle();
    if(re || !r) return null;

    return normalize({...r,...(membership||{}),restaurant_id:r.id,hospitality_type:r.hospitality_type,hospitality_types:r.hospitality_types});
  }

  const {data:members,error}=await supabase
    .from('anaira_store_memberships')
    .select('restaurant_id,store_id,enabled,listing_override,store_config,catalog_source')
    .eq('enabled',true)
    .limit(500);
  if(error) throw error;

  const hit=(members||[]).find(x=>String(x.listing_override?.slug||'').toLowerCase()===String(key).toLowerCase());
  if(!hit) return null;

  const {data:r}=await supabase
    .from('restaurants')
    .select('id,name,city,address,logo,cover_image,cuisine,phone,website,delivery_enabled,hospitality_type,hospitality_types')
    .eq('id',hit.restaurant_id)
    .maybeSingle();

  return normalize({...r,...hit,restaurant_id:hit.restaurant_id});
}
