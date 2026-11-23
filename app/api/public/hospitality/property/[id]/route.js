import {NextResponse} from 'next/server';
import {adminDb} from '../../../../../../lib/server/provider';

export const runtime='nodejs';
export const dynamic='force-dynamic';

const PUBLIC_RESTAURANT_FIELDS='id,name,status,city,address,logo,cover_image,cuisine,phone,website,delivery_enabled,description,gallery,hospitality_type,hospitality_types,nearby_destinations,nearby_activities,hospitality_highlights';

export async function GET(req,{params}){
  try{
    const {id}=await params;
    const requestedType=new URL(req.url).searchParams.get('stay_type')||'';
    if(!id || !/^[0-9a-f-]{36}$/i.test(id)) return NextResponse.json({ok:false,error:'Invalid property id.'},{status:400});
    const db=adminDb();
    const [{data:restaurant,error:restaurantError},{data:landing,error:landingError},{data:camp,error:campError},{data:hms,error:hmsError}] = await Promise.all([
      db.from('restaurants').select(PUBLIC_RESTAURANT_FIELDS).eq('id',id).eq('status','active').maybeSingle(),
      db.from('anaira_business_landing_pages').select('business_id,slug,published,business_type').eq('business_id',id).eq('published',true).maybeSingle(),
      db.from('camp_properties').select('restaurant_id,name,short_name,description,destination,address,city,state,country,logo_url,cover_image_url,gallery,check_in_time,check_out_time,cancellation_policy,child_policy,pet_policy,active,marketplace_visible').eq('restaurant_id',id).eq('active',true).eq('marketplace_visible',true).maybeSingle(),
      db.from('hms_settings').select('hotel_name,short_name,description,phone,whatsapp,email,website,address,city,state,country,star_rating,logo_url,cover_image_url,gallery,check_in_time,check_out_time,cancellation_policy,child_policy,pet_policy,hospitality_type,hospitality_types,marketplace_background_image_url,marketplace_background_video_url,marketplace_background_media_type,marketplace_background_overlay').eq('restaurant_id',id).maybeSingle()
    ]);
    if(restaurantError) throw restaurantError;
    if(landingError) throw landingError;
    if(campError && campError.code!=='PGRST116') throw campError;
    if(hmsError && hmsError.code!=='PGRST116') throw hmsError;
    if(!restaurant) return NextResponse.json({ok:false,error:'Property not found.'},{status:404});

    const types=Array.isArray(restaurant.hospitality_types)&&restaurant.hospitality_types.length
      ? restaurant.hospitality_types : [restaurant.hospitality_type||'hotel'];
    const isDirectStay=types.some(t=>['camp','homestay','guest_house','cottage'].includes(t));
    const preferredType=types.includes(requestedType)?requestedType:(types.find(t=>['camp','hotel','homestay','guest_house','cottage'].includes(t))||'hotel');
    let stayProperty=null;
    if(['homestay','guest_house','cottage','camp'].includes(preferredType)){
      const {data,error}=await db.from('anaira_stay_properties')
        .select('id,restaurant_id,stay_type,name,short_name,description,destination,address,city,state,country,logo_url,cover_image_url,gallery,check_in_time,check_out_time,cancellation_policy,child_policy,pet_policy,active,marketplace_visible')
        .eq('restaurant_id',id).eq('stay_type',preferredType).eq('active',true).eq('marketplace_visible',true).maybeSingle();
      if(error) throw error;
      stayProperty=data||null;
    }
    // Public storefront catalog is served from this server route because the
    // underlying HMS catalog tables intentionally grant read access only to
    // authenticated tenant users. Never expose tenant-wide table reads to anon.
    const publicStayTypes=types.filter(t=>['hotel','homestay','guest_house','cottage','camp'].includes(t));
    const [{data:publicRooms,error:publicRoomsError},{data:publicRates,error:publicRatesError}] = await Promise.all([
      db.from('hms_room_types')
        .select('id,name,code,description,short_description,max_adults,max_children,max_guests,base_rate,bed_type,number_of_beds,extra_adult_price,extra_child_price,weekend_price,tax_percent,amenities,image_urls,pricing_mode,hospitality_type,active')
        .eq('restaurant_id',id).in('hospitality_type',publicStayTypes).eq('active',true)
        .order('hospitality_type').order('name'),
      db.from('hms_rate_plans')
        .select('id,name,code,board_type,description,room_type_id,rate,occupancy,extra_adult,extra_child,min_stay,max_stay,weekend_rate,seasonal_multiplier,refundable,deposit_percent,cancellation_policy,pricing_mode,hospitality_type,active')
        .eq('restaurant_id',id).in('hospitality_type',publicStayTypes).eq('active',true)
        .order('created_at')
    ]);
    if(publicRoomsError) throw publicRoomsError;
    if(publicRatesError) throw publicRatesError;
    const publicRoomIds=new Set((publicRooms||[]).map(x=>x.id));
    let catalogRooms=[...(publicRooms||[])];
    let catalogRates=(publicRates||[]).filter(x=>publicRoomIds.has(x.room_type_id));

    // Homestay / guest-house / cottage use the dedicated ANAIRA Stay catalogue.
    // Bridge it into the public storefront contract on the server; never expose
    // tenant-wide HMS tables to anonymous browser sessions.
    if(stayProperty && ['homestay','guest_house','cottage'].includes(preferredType)){
      const {data:stayUnits,error:stayUnitsError}=await db.from('anaira_stay_unit_types')
        .select('id,restaurant_id,property_id,name,code,description,max_guests,max_adults,max_children,unit_count,base_rate,image_urls,amenities,active')
        .eq('restaurant_id',id).eq('property_id',stayProperty.id).eq('active',true).order('name');
      if(stayUnitsError) throw stayUnitsError;
      const stayUnitIds=(stayUnits||[]).map(x=>x.id);
      let stayRates=[];
      if(stayUnitIds.length){
        const {data,error}=await db.from('anaira_stay_rate_plans')
          .select('id,restaurant_id,unit_type_id,name,code,pricing_mode,rate,weekend_rate,seasonal_multiplier,refundable,deposit_percent,cancellation_policy,min_stay,max_stay,active')
          .eq('restaurant_id',id).in('unit_type_id',stayUnitIds).eq('active',true).order('name');
        if(error) throw error;
        stayRates=data||[];
      }
      const mappedUnits=(stayUnits||[]).map(u=>({
        ...u,room_type_id:u.id,hospitality_type:preferredType,
        short_description:u.description||'',bed_type:null,number_of_beds:1,
        extra_adult_price:0,extra_child_price:0,pricing_mode:'per_unit'
      }));
      const mappedRates=stayRates.map(r=>({
        ...r,room_type_id:r.unit_type_id,hospitality_type:preferredType,
        board_type:r.code||'Standard',occupancy:null,extra_adult:0,extra_child:0
      }));
      catalogRooms=[...catalogRooms.filter(x=>x.hospitality_type!==preferredType),...mappedUnits];
      const stayRoomIds=new Set(mappedUnits.map(x=>x.id));
      catalogRates=[...catalogRates.filter(x=>x.hospitality_type!==preferredType),...mappedRates.filter(x=>stayRoomIds.has(x.room_type_id))];
    }
    const publicCatalog={rooms:catalogRooms,rates:catalogRates};

    const publishedDirectStay=Boolean(stayProperty || (preferredType==='camp' && camp));
    if(!landing && !publishedDirectStay) return NextResponse.json({ok:false,error:'This property has not been published for public booking.'},{status:404});

    const {data:members,error:membersError}=await db.from('anaira_store_memberships')
      .select('store_id,enabled,listing_override,catalog_source,store_config')
      .eq('restaurant_id',id).eq('enabled',true);
    if(membersError) throw membersError;
    const storeIds=[...new Set((members||[]).map(x=>x.store_id).filter(Boolean))];
    let stores=[];
    if(storeIds.length){
      const {data,error}=await db.from('anaira_platform_stores')
        .select('id,store_type,store_name,slug,enabled,published,cover_url,logo_url,public_path,hospitality_type')
        .in('id',storeIds).eq('enabled',true).eq('published',true);
      if(error) throw error;
      stores=data||[];
    }
    // For direct-stay properties, use the canonical published stay-property
    // record as the business identity; tenant membership is optional enrichment.
    const platformStore=stores.find(s=>s.hospitality_type===preferredType)
      || stores.find(s=>preferredType==='camp' && s.store_type==='hotel')
      || stores[0] || null;
    const membership=platformStore
      ? (members||[]).find(m=>m.store_id===platformStore.id) || null
      : (members||[])[0] || null;

    const override=membership?.listing_override && typeof membership.listing_override==='object' ? membership.listing_override : {};
    // For property-owned stay pages, the canonical property's name must win
    // over the shared platform store or a stale membership title such as
    // "Anaira Hotels". Keep listing overrides for normal hotel pages.
    const propertyBrandedStay=['homestay','guest_house','cottage','camp'].includes(preferredType);
    const canonicalPropertyName=stayProperty?.name||camp?.name||hms?.hotel_name||restaurant.name;
    const resolvedPropertyTitle=propertyBrandedStay
      ? (canonicalPropertyName||override.title||platformStore?.store_name||'ANAIRA Stay')
      : (override.title||canonicalPropertyName||platformStore?.store_name||'ANAIRA Hotels');
    const property={
      ...restaurant,
      title:resolvedPropertyTitle,
      hotel_name:canonicalPropertyName,
      tagline:override.tagline||'',
      description:override.description||stayProperty?.description||camp?.description||hms?.description||restaurant.description||'',
      logo_url:override.logo_url||stayProperty?.logo_url||platformStore?.logo_url||camp?.logo_url||hms?.logo_url||restaurant.logo||'',
      cover_url:override.cover_url||stayProperty?.cover_image_url||platformStore?.cover_url||camp?.cover_image_url||hms?.cover_image_url||restaurant.cover_image||'',
      cover_image_url:override.cover_url||stayProperty?.cover_image_url||platformStore?.cover_url||camp?.cover_image_url||hms?.cover_image_url||restaurant.cover_image||'',
      gallery:Array.isArray(override.gallery)&&override.gallery.length ? override.gallery
        : (Array.isArray(stayProperty?.gallery)&&stayProperty.gallery.length ? stayProperty.gallery
        : (Array.isArray(camp?.gallery)&&camp.gallery.length ? camp.gallery
        : (Array.isArray(hms?.gallery)&&hms.gallery.length ? hms.gallery
        : (Array.isArray(restaurant.gallery)?restaurant.gallery:[])))),
      address:override.address||stayProperty?.address||camp?.address||hms?.address||restaurant.address,
      city:override.city||stayProperty?.city||camp?.city||hms?.city||restaurant.city,
      phone:override.phone||hms?.phone||restaurant.phone,
      email:override.email||hms?.email||'',
      website:override.website||hms?.website||restaurant.website,
      state:stayProperty?.state||camp?.state||hms?.state||'',
      hospitality_type:restaurant.hospitality_type||preferredType,
      hospitality_types:types,
      check_in_time:stayProperty?.check_in_time||camp?.check_in_time||hms?.check_in_time||null,
      check_out_time:stayProperty?.check_out_time||camp?.check_out_time||hms?.check_out_time||null,
      cancellation_policy:stayProperty?.cancellation_policy||camp?.cancellation_policy||hms?.cancellation_policy||null,
      child_policy:stayProperty?.child_policy||camp?.child_policy||hms?.child_policy||null,
      pet_policy:stayProperty?.pet_policy||camp?.pet_policy||hms?.pet_policy||null,
      marketplace_background_image_url:hms?.marketplace_background_image_url||'',
      marketplace_background_video_url:hms?.marketplace_background_video_url||'',
      marketplace_background_media_type:hms?.marketplace_background_media_type||'image',
      marketplace_background_overlay:hms?.marketplace_background_overlay??0.45
    };
    return NextResponse.json({ok:true,property,stayProperty,membership:membership?{store_id:membership.store_id,listing_override:override,catalog_source:membership.catalog_source}:null,platformStore,hms:hms||{},camp:camp||null,landing:landing||null,catalog:publicCatalog},{headers:{'Cache-Control':'no-store, max-age=0'}});
  }catch(error){
    return NextResponse.json({ok:false,error:error?.message||'Unable to load public property.'},{status:500});
  }
}
