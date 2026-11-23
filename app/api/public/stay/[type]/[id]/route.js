import {NextResponse} from 'next/server';
import {adminDb} from '../../../../../../lib/server/provider';

export const runtime='nodejs';
export const dynamic='force-dynamic';
const allowed=['homestay','guest_house','cottage'];

export async function GET(req,{params}){
  try{
    const {type,id}=await params;
    if(!allowed.includes(type)) return NextResponse.json({ok:false,error:'Unsupported stay type.'},{status:400});
    const db=adminDb();
    const {data:property,error:propertyError}=await db.from('anaira_stay_properties')
      .select('id,restaurant_id,stay_type,name,short_name,description,destination,address,city,state,country,logo_url,cover_image_url,gallery,check_in_time,check_out_time,cancellation_policy,child_policy,pet_policy,active,marketplace_visible')
      .eq('id',id).eq('stay_type',type).eq('active',true).eq('marketplace_visible',true).maybeSingle();
    if(propertyError) throw propertyError;
    if(!property) return NextResponse.json({ok:false,error:'Stay property not found.'},{status:404});
    const {data:restaurant,error:restaurantError}=await db.from('restaurants')
      .select('id,name,status,cover_image,logo,gallery,city,address,description')
      .eq('id',property.restaurant_id).eq('status','active').maybeSingle();
    if(restaurantError) throw restaurantError;
    if(!restaurant) return NextResponse.json({ok:false,error:'Published business is not active.'},{status:404});

    const bucket='anaira-media';
    const listImages=async(folder)=>{
      const {data,error}=await db.storage.from(bucket).list(`${property.restaurant_id}/hotel/${folder}`,{
        limit:100,sortBy:{column:'created_at',order:'desc'}
      });
      if(error) return [];
      return (data||[]).filter(f=>f?.name&&!f.name.endsWith('/')&&
        (!f.metadata?.mimetype||String(f.metadata.mimetype).startsWith('image/')))
        .map(f=>db.storage.from(bucket).getPublicUrl(`${property.restaurant_id}/hotel/${folder}/${f.name}`).data.publicUrl);
    };
    const [coverFiles,galleryFiles,roomFiles,detailFiles]=await Promise.all([
      listImages('cover'),listImages('gallery'),listImages('rooms'),listImages('homestay-details')
    ]);
    const dbGallery=Array.isArray(property.gallery)&&property.gallery.length?property.gallery:
      (Array.isArray(restaurant.gallery)?restaurant.gallery:[]);
    const gallery=dbGallery.length?dbGallery:galleryFiles;
    const coverCandidates=[...new Set([coverFiles[0],property.cover_image_url,restaurant.cover_image,...gallery,...galleryFiles,...detailFiles,...roomFiles].filter(x=>typeof x==='string'&&/^https?:\/\//i.test(x)))];
    const cover=coverCandidates[0]||'';

    const {data:units,error:unitsError}=await db.from('anaira_stay_unit_types')
      .select('id,restaurant_id,property_id,name,code,description,max_guests,max_adults,max_children,unit_count,base_rate,image_urls,amenities,active')
      .eq('restaurant_id',property.restaurant_id).eq('property_id',id).eq('active',true).order('name');
    if(unitsError) throw unitsError;
    const unitIds=(units||[]).map(u=>u.id);
    let rates=[];
    if(unitIds.length){
      const {data,error}=await db.from('anaira_stay_rate_plans')
        .select('id,restaurant_id,unit_type_id,name,code,pricing_mode,rate,weekend_rate,seasonal_multiplier,refundable,deposit_percent,cancellation_policy,min_stay,max_stay,active')
        .eq('restaurant_id',property.restaurant_id).in('unit_type_id',unitIds).eq('active',true).order('rate');
      if(error) throw error;
      rates=data||[];
    }
    const fallbackImages=roomFiles.length?roomFiles:detailFiles;
    const enrichedUnits=(units||[]).map((u,index)=>({
      ...u,
      image_urls:Array.isArray(u.image_urls)?u.image_urls:[],
      fallback_image_url:fallbackImages[index%Math.max(fallbackImages.length,1)]||gallery[index%Math.max(gallery.length,1)]||cover,
      rates:rates.filter(r=>r.unit_type_id===u.id)
    }));
    return NextResponse.json({ok:true,property:{...property,cover_image_url:cover,cover_image_candidates:coverCandidates,logo_url:property.logo_url||restaurant.logo||'',gallery,media_gallery:[...new Set([...gallery,...detailFiles])],restaurant_name:restaurant.name,city:property.city||restaurant.city,address:property.address||restaurant.address,description:property.description||restaurant.description||''},units:enrichedUnits},{
      headers:{'Cache-Control':'no-store, max-age=0'}
    });
  }catch(error){
    return NextResponse.json({ok:false,error:error?.message||'Stay property lookup failed.'},{status:500});
  }
}
