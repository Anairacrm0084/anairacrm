import {supabase} from './supabase';

export async function resolveRestaurantId(key){
  if(!key) return null;
  const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(key);
  const q=supabase.from('restaurants').select('id,name,slug,status,logo,cover_image,cuisine,address,city,phone,website,delivery_enabled').eq(uuid?'id':'slug',key).maybeSingle();
  const {data,error}=await q;
  if(error) throw error;
  return data||null;
}
