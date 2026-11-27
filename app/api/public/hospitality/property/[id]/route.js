import {NextResponse} from 'next/server';
import {adminDb} from '../../../../../../lib/server/provider';

export const runtime='nodejs';
export const dynamic='force-dynamic';

const PUBLIC_RESTAURANT_FIELDS='id,name,status,city,address,logo,cover_image,cuisine,phone,website,delivery_enabled,description,gallery,hospitality_type,hospitality_types,nearby_destinations,nearby_activities,hospitality_highlights';

function publicStoreConfig(value={}){
  const c=value&&typeof value==='object'&&!Array.isArray(value)?value:{};
  const color=(v,fallback)=>typeof v==='string'&&/^#[0-9a-f]{6}$/i.test(v)?v:fallback;
  return {
    theme_mode:c.theme_mode==='dark'?'dark':'light',
    primary_color:color(c.primary_color,'#17372b'),
    accent_color:color(c.accent_color,'#c7a15a'),
    background_color:color(c.background_color||c.store_background,c.theme_mode==='dark'?'#15201a':'#f7f4ed'),
    surface_color:color(c.surface_color,c.theme_mode==='dark'?'#202d25':'#ffffff'),
    text_color:color(c.text_color,c.theme_mode==='dark'?'#f1f5f2':'#20362d'),
    announcement:typeof c.announcement==='string'?c.announcement.slice(0,240):'',
    show_gallery:c.show_gallery!==false,
    show_reviews:c.show_reviews===true,
    show_about:c.show_about!==false,
    show_units:c.show_units!==false,
    show_amenities:c.show_amenities!==false,
    show_location:c.show_location!==false,
    hero_cta_label:typeof c.hero_cta_label==='string'?c.hero_cta_label.slice(0,60):'Check availability',
    footer_text:typeof c.footer_text==='string'?c.footer_text.slice(0,300):'',
    google_maps_url:(()=>{try{const u=new URL(String(c.google_maps_url||''));const host=u.hostname.toLowerCase();return u.protocol==='https:'&&(['google.com','www.google.com','maps.google.com','maps.app.goo.gl','goo.gl'].includes(host)||host.endsWith('.google.com'))?u.toString().slice(0,2048):'';}catch{return '';}})()
  };
}

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
    const requestedTypeIsSupported=['camp','hotel','homestay','guest_house','cottage'].includes(requestedType);
    const preferredType=requestedTypeIsSupported && (types.includes(requestedType)||(requestedType==='camp'&&Boolean(camp))) ? requestedType : (types.find(t=>['camp','hotel','homestay','guest_house','cottage'].includes(t))||'hotel');
    let stayProperty=null;
    if(['homestay','guest_house','cottage','camp'].includes(preferredType)){
      const {data,error}=await db.from('anaira_stay_properties')
        .select('id,restaurant_id,stay_type,name,short_name,description,destination,address,city,state,country,logo_url,cover_image_url,gallery,check_in_time,check_out_time,cancellation_policy,child_policy,pet_policy,active,marketplace_visible')
        .eq('restaurant_id',id).eq('stay_type',preferredType).eq('active',true).eq('marketplace_visible',true).maybeSingle();
      if(error) throw error;
      stayProperty=data||null;
    }
    // Recover uploaded property media from the canonical storage folders when
    // older property records have empty cover/gallery columns. Storage listing
    // is server-side; only public URLs for this published property are returned.
    const mediaBucket='anaira-media';
    const listPropertyMedia=async(folder)=>{
      const {data,error}=await db.storage.from(mediaBucket).list(`${id}/hotel/${folder}`,{
        limit:100,sortBy:{column:'created_at',order:'desc'}
      });
      if(error) return [];
      return (data||[]).filter(file=>file?.name&&!file.name.endsWith('/')&&
        (!file.metadata?.mimetype||String(file.metadata.mimetype).startsWith('image/')))
        .map(file=>({
          name:file.name,
          url:db.storage.from(mediaBucket).getPublicUrl(`${id}/hotel/${folder}/${file.name}`).data.publicUrl
        }));
    };
    const [coverMedia,galleryMedia,roomMedia,detailMedia]=await Promise.all([
      listPropertyMedia('cover'),listPropertyMedia('gallery'),
      listPropertyMedia('rooms'),listPropertyMedia('homestay-details')
    ]);
    const storedCoverUrl=coverMedia[0]?.url||'';
    const storedGalleryUrls=galleryMedia.map(x=>x.url);
    const storedRoomUrls=roomMedia.map(x=>x.url);
    const storedDetailUrls=detailMedia.map(x=>x.url);
    const propertyGalleryFromDb=Array.isArray(stayProperty?.gallery)&&stayProperty.gallery.length
      ? stayProperty.gallery : (Array.isArray(camp?.gallery)&&camp.gallery.length
        ? camp.gallery : (Array.isArray(hms?.gallery)&&hms.gallery.length
          ? hms.gallery : (Array.isArray(restaurant.gallery)?restaurant.gallery:[])));
    const resolvedGallery=propertyGalleryFromDb.length?propertyGalleryFromDb:storedGalleryUrls;
    const roomFallbackImages=storedRoomUrls.length?storedRoomUrls:storedDetailUrls;

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
      const mappedUnits=(stayUnits||[]).map((u,index)=>({
        ...u,room_type_id:u.id,hospitality_type:preferredType,
        short_description:u.description||'',bed_type:null,number_of_beds:1,
        extra_adult_price:0,extra_child_price:0,pricing_mode:'per_unit',
        // Keep room-specific uploads first; otherwise use a real uploaded
        // property/room-detail photo as a visual fallback instead of a blank card.
        image_urls:Array.isArray(u.image_urls)&&u.image_urls.length?u.image_urls:[
          roomFallbackImages[index%Math.max(roomFallbackImages.length,1)]||
          resolvedGallery[index%Math.max(resolvedGallery.length,1)]||storedCoverUrl
        ].filter(Boolean),
        fallback_image_url:roomFallbackImages[index%Math.max(roomFallbackImages.length,1)]||
          resolvedGallery[index%Math.max(resolvedGallery.length,1)]||storedCoverUrl||''
      }));
      const mappedRates=stayRates.map(r=>({
        ...r,room_type_id:r.unit_type_id,hospitality_type:preferredType,
        board_type:r.code||'Standard',occupancy:null,extra_adult:0,extra_child:0
      }));
      catalogRooms=[...catalogRooms.filter(x=>x.hospitality_type!==preferredType),...mappedUnits];
      const stayRoomIds=new Set(mappedUnits.map(x=>x.id));
      catalogRates=[...catalogRates.filter(x=>x.hospitality_type!==preferredType),...mappedRates.filter(x=>stayRoomIds.has(x.room_type_id))];
    }
    // Legacy camping inventory is stored in camp_unit_types / camp_rate_plans.
    // Bridge only the public booking fields into the same property-store catalog
    // contract so Global Marketplace guests can book directly from /property.
    if(preferredType==='camp' && camp && !catalogRooms.some(x=>x.hospitality_type==='camp')){
      const [{data:campUnits,error:campUnitsError},{data:campRates,error:campRatesError}]=await Promise.all([
        db.from('camp_unit_types').select('*').eq('restaurant_id',id).eq('active',true).order('name'),
        db.from('camp_rate_plans').select('*').eq('restaurant_id',id).eq('active',true).order('rate')
      ]);
      if(campUnitsError) throw campUnitsError;
      if(campRatesError) throw campRatesError;
      const mappedCampUnits=(campUnits||[]).map((u,index)=>({
        id:u.id,room_type_id:u.id,restaurant_id:id,hospitality_type:'camp',
        name:u.name||u.title||`Camp accommodation ${index+1}`,code:u.code||'',
        description:u.description||u.short_description||'',short_description:u.short_description||u.description||'',
        max_adults:Number(u.max_adults??u.capacity??u.max_guests??2),
        max_children:Number(u.max_children??0),max_guests:Number(u.max_guests??u.capacity??u.max_adults??2),
        base_rate:Number(u.base_rate??u.rate??0),bed_type:u.bed_type||'Camping',
        number_of_beds:Number(u.number_of_beds??u.beds??1),
        image_urls:Array.isArray(u.image_urls)?u.image_urls:(Array.isArray(u.photos)?u.photos:[]),
        amenities:Array.isArray(u.amenities)?u.amenities:[],pricing_mode:u.pricing_mode||'per_person',active:true
      }));
      const campUnitIds=new Set(mappedCampUnits.map(x=>String(x.id)));
      const mappedCampRates=(campRates||[]).filter(r=>campUnitIds.has(String(r.unit_type_id))).map(r=>({
        id:r.id,restaurant_id:id,room_type_id:r.unit_type_id,hospitality_type:'camp',
        name:r.name||r.code||'Standard',code:r.code||'',rate:Number(r.rate??r.base_rate??0),
        pricing_mode:r.pricing_mode||'per_person',refundable:!!r.refundable,
        deposit_percent:Number(r.deposit_percent||0),cancellation_policy:r.cancellation_policy||null,
        min_stay:r.min_stay??null,max_stay:r.max_stay??null,weekend_rate:r.weekend_rate??null,
        seasonal_multiplier:r.seasonal_multiplier??null,active:true,source:'legacy_camp',legacy_unit_type_id:r.unit_type_id
      }));
      catalogRooms=[...catalogRooms,...mappedCampUnits];
      catalogRates=[...catalogRates,...mappedCampRates];
    }

    const publicCatalog={rooms:catalogRooms,rates:catalogRates};

    const publishedDirectStay=Boolean(stayProperty || (preferredType==='camp' && camp));

    const {data:members,error:membersError}=await db.from('anaira_store_memberships')
      .select('store_id,enabled,listing_override,catalog_source,store_config')
      .eq('restaurant_id',id).eq('enabled',true);
    if(membersError) throw membersError;
    const storeIds=[...new Set((members||[]).map(x=>x.store_id).filter(Boolean))];
    let stores=[];
    if(storeIds.length){
      const {data,error}=await db.from('anaira_platform_stores')
        .select('id,store_type,store_name,slug,enabled,published,is_platform_store,cover_url,logo_url,public_path,hospitality_type')
        .in('id',storeIds).eq('enabled',true).eq('is_platform_store',false);
      if(error) throw error;
      stores=data||[];
    }
    // For direct-stay properties, use the canonical published stay-property
    // record as the business identity; tenant membership is optional enrichment.
    const platformStore=stores.find(s=>s.hospitality_type===preferredType)
      || stores.find(s=>preferredType==='camp' && s.store_type==='hotel')
      || stores[0] || null;
    // A property direct store and a central marketplace listing have separate
    // publication controls. Store Builder publishes anaira_store_settings;
    // Super Admin publication controls anaira_platform_stores.published.
    const candidateMembership=platformStore
      ? (members||[]).find(m=>m.store_id===platformStore.id) || null
      : null;
    let storeSettings=null;
    if(platformStore){
      const {data,error}=await db.from('anaira_store_settings')
        .select('published,slug,seo_title,seo_description')
        .eq('store_id',platformStore.id).eq('restaurant_id',id).maybeSingle();
      if(error) throw error;
      storeSettings=data||null;
    }
    const publishedDirectStore=Boolean(platformStore?.enabled&&!platformStore?.is_platform_store&&candidateMembership?.enabled&&storeSettings?.published);
    const publishedMarketplaceStore=Boolean(platformStore?.enabled&&platformStore?.published&&!platformStore?.is_platform_store);
    if(!landing&&!publishedDirectStay&&!publishedDirectStore&&!publishedMarketplaceStore) return NextResponse.json({ok:false,error:'This property has not been published for public booking.'},{status:404});
    // Draft membership overrides/configuration are never returned to anonymous visitors.
    const membership=publishedDirectStore||publishedMarketplaceStore?candidateMembership:null;
    const safeStoreConfig=membership?publicStoreConfig(membership.store_config):publicStoreConfig({});

    const override=membership?.listing_override && typeof membership.listing_override==='object' ? membership.listing_override : {};
    // For property-owned stay pages, the canonical property's name must win
    // over the shared platform store or a stale membership title such as
    // "Anaira Hotels". Keep listing overrides for normal hotel pages.
    const propertyBrandedStay=['homestay','guest_house','cottage','camp'].includes(preferredType);
    const canonicalPropertyName=stayProperty?.name||camp?.name||hms?.hotel_name||restaurant.name;
    const resolvedPropertyTitle=propertyBrandedStay
      ? (canonicalPropertyName||override.title||platformStore?.store_name||'ANAIRA Stay')
      : (override.title||canonicalPropertyName||platformStore?.store_name||'ANAIRA Hotels');
    const coverCandidates=[...new Set([
      storedCoverUrl,
      stayProperty?.cover_image_url,camp?.cover_image_url,hms?.cover_image_url,
      restaurant.cover_image,platformStore?.cover_url,
      ...resolvedGallery,...storedGalleryUrls,...storedDetailUrls,...storedRoomUrls
    ].filter(x=>typeof x==='string'&&/^https?:\/\//i.test(x)))];
    const property={
      ...restaurant,
      cover_image_candidates:coverCandidates,
      title:resolvedPropertyTitle,
      hotel_name:canonicalPropertyName,
      tagline:override.tagline||'',
      description:override.description||stayProperty?.description||camp?.description||hms?.description||restaurant.description||'',
      logo_url:override.logo_url||stayProperty?.logo_url||platformStore?.logo_url||camp?.logo_url||hms?.logo_url||restaurant.logo||'',
      cover_url:override.cover_url||stayProperty?.cover_image_url||platformStore?.cover_url||camp?.cover_image_url||hms?.cover_image_url||restaurant.cover_image||storedCoverUrl||resolvedGallery[0]||'',
      cover_image_url:override.cover_url||stayProperty?.cover_image_url||platformStore?.cover_url||camp?.cover_image_url||hms?.cover_image_url||restaurant.cover_image||storedCoverUrl||resolvedGallery[0]||'',
      gallery:Array.isArray(override.gallery)&&override.gallery.length ? override.gallery : resolvedGallery,
      media_gallery:[...new Set([...resolvedGallery,...storedDetailUrls])],
      address:override.address||stayProperty?.address||camp?.address||hms?.address||restaurant.address,
      city:override.city||stayProperty?.city||camp?.city||hms?.city||restaurant.city,
      phone:override.phone||hms?.phone||restaurant.phone,
      email:override.email||hms?.email||'',
      website:override.website||hms?.website||restaurant.website,
      state:stayProperty?.state||camp?.state||hms?.state||'',
      hospitality_type:preferredType,
      stay_property_id:stayProperty?.id||null,
      hospitality_types:types.includes(preferredType)?types:[...types,preferredType],
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
    return NextResponse.json({ok:true,property,stayProperty,membership:membership?{store_id:membership.store_id,listing_override:override,catalog_source:membership.catalog_source}:null,public_store_config:safeStoreConfig,property_store_settings:publishedDirectStore||publishedMarketplaceStore?storeSettings:null,platformStore,hms:hms||{},camp:camp||null,landing:landing||null,catalog:publicCatalog},{headers:{'Cache-Control':'no-store, max-age=0'}});
  }catch(error){
    return NextResponse.json({ok:false,error:error?.message||'Unable to load public property.'},{status:500});
  }
}
