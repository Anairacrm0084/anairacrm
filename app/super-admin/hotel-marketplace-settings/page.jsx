'use client';
import {useEffect,useState} from 'react';
import Link from 'next/link';
import {Hotel,Save,ExternalLink,Image as ImageIcon,MapPin,Plus,Trash2,Power,Pencil,X} from 'lucide-react';
import {AppShell,Header,Section} from '../../components';
import {supabase} from '../../../lib/supabase';
import MarketplaceImageUpload from '../MarketplaceImageUpload';
import HotelMediaUpload from '../../../components/anaira/HotelMediaUpload';

const defaults={
 hotel_marketplace_enabled:true,hotel_require_listing_approval:true,hotel_featured_enabled:true,hotel_marketplace_payment_mode:'platform',
 hotel_home_title:'Find a stay that feels like yours.',
 hotel_home_subtitle:'Thoughtfully selected hotels, homestays, cottages and camps. Discover beautiful places, compare live availability and book directly.',
 hotel_home_theme:'luxury',hotel_home_show_search:true,hotel_home_show_banners:true,hotel_home_show_destinations:true,hotel_home_show_trust:true,hotel_home_show_footer:true,hotel_home_enable_filters:true,hotel_home_enable_sort:true,hotel_home_enable_wishlist:true,
 hotel_home_hero_image:'',hotel_home_hero_mobile_image:'',hotel_home_hero_video:'',hotel_home_hero_mobile_video:'',hotel_home_hero_media_type:'image',hotel_home_hero_mobile_media_type:'image',hotel_home_hero_overlay:'0.48',hotel_home_background_media_type:'image',hotel_home_background_image:'',hotel_home_background_video:'',hotel_home_background_mobile_media_type:'image',hotel_home_background_mobile_image:'',hotel_home_background_mobile_video:'',hotel_home_background_overlay:'0.48',hotel_home_hero_cta:'Explore hotels',hotel_home_hero_cta_url:'#hotels',
 hotel_home_primary_color:'#17372b',hotel_home_accent_color:'#c7a15a',hotel_home_surface_color:'#ffffff',hotel_home_background_color:'#f6f3ed',hotel_home_text_color:'#20362d',
 hotel_home_container_width:1240,hotel_home_card_radius:22,hotel_home_hotel_columns:3,hotel_home_destination_columns:5,
 hotel_home_show_featured:true,hotel_home_show_why:false,hotel_home_show_about:false,hotel_home_show_stats:false,hotel_home_show_workflow:false,hotel_home_show_tech:false,
 hotel_home_featured_columns:3,hotel_home_featured_card_height:245,hotel_home_banner_height:350,hotel_home_hero_min_height:0,hotel_home_search_max_width:1240,hotel_home_section_spacing:38,
 hotel_home_why_title:'Thoughtfully chosen stays. Seamless booking.',hotel_home_why_subtitle:'More destinations, better stays, camps and a smoother booking experience for every traveler.',
 hotel_home_about_title:'A New Generation Hospitality Platform',hotel_home_about_subtitle:'Built for Hotels. Designed for Travelers.',
 hotel_home_workflow_title:'From Search to Stay / Camp — Simplified',hotel_home_workflow_subtitle:'A complete booking experience for hotels and camps, with real-time availability, flexible pricing and secure booking.',
 hotel_home_tech_title:'One connected hotel & camping ecosystem.',
 hotel_home_featured_title:'Featured properties',hotel_home_featured_subtitle:'Exceptional stays, handpicked by ANAIRA for your next getaway.',

 hotel_home_destination_title:'Top destinations',hotel_home_destination_subtitle:'Explore the places guests are discovering across ANAIRA.',
 hotel_home_footer_text:'ANAIRA Hotels — discover stays, compare live availability and book with confidence.',
 hotel_home_meta_title:'ANAIRA Hotels | Hotel Marketplace',hotel_home_meta_description:'Discover hotels, live room availability and direct booking experiences on ANAIRA.'
};
const blankBanner={title:'',subtitle:'',image_url:'',mobile_image_url:'',video_url:'',mobile_video_url:'',media_type:'image',mobile_media_type:'image',cta_label:'Explore hotels',cta_url:'#hotels',display_order:0,active:true};
const blankDestination={name:'',subtitle:'',image_url:'',mobile_image_url:'',cta_label:'Explore hotels',cta_url:'',display_order:0,active:true};

export default function HotelMarketplaceSettings(){
 const [form,setForm]=useState(defaults),[store,setStore]=useState(null),[banners,setBanners]=useState([]),[destinations,setDestinations]=useState([]),
 [banner,setBanner]=useState(blankBanner),[destination,setDestination]=useState(blankDestination),[featuredProperties,setFeaturedProperties]=useState([]),[editingBannerId,setEditingBannerId]=useState(null),[editingDestinationId,setEditingDestinationId]=useState(null),[tab,setTab]=useState('design'),[msg,setMsg]=useState(''),[error,setError]=useState(''),[saving,setSaving]=useState(false);

 useEffect(()=>{(async()=>{const {data,error}=await supabase.from('anaira_platform_settings').select('key,value').in('key',Object.keys(defaults));if(error){setError(error.message);return}
  const x={...defaults};(data||[]).forEach(r=>x[r.key]=r.value?.value??r.value);setForm(x);
  const {data:s}=await supabase.from('anaira_platform_stores').select('id,store_name').eq('store_type','hotel').eq('is_platform_store',true).is('restaurant_id',null).maybeSingle();setStore(s||null);
  if(s){const [{data:b},{data:d}]=await Promise.all([
   supabase.from('anaira_hotel_store_banners').select('*').eq('store_id',s.id).order('display_order'),
   supabase.from('anaira_hotel_store_destinations').select('*').eq('store_id',s.id).order('display_order')
  ]);setBanners(b||[]);setDestinations(d||[]);
   const {data:members}=await supabase.from('anaira_store_memberships').select('id,restaurant_id,store_id,featured,sort_order,listing_override').eq('enabled',true);
   const memberRows=members||[],storeIds=[...new Set(memberRows.map(m=>m.store_id).filter(Boolean))],restaurantIds=[...new Set(memberRows.map(m=>m.restaurant_id).filter(Boolean))];
   const [{data:storeRows},{data:restaurantRows},{data:hmsRows},{data:campRows},{data:stayRows}]=await Promise.all([
    storeIds.length?supabase.from('anaira_platform_stores').select('id').in('id',storeIds).eq('store_type','hotel').eq('is_platform_store',false).eq('enabled',true).eq('published',true).eq('marketplace_approval_status','approved'):Promise.resolve({data:[]}),
    restaurantIds.length?supabase.from('restaurants').select('id,name,city,hospitality_type,cover_image').in('id',restaurantIds):Promise.resolve({data:[]}),
    restaurantIds.length?supabase.from('hms_settings').select('restaurant_id,hotel_name,city,cover_image_url').in('restaurant_id',restaurantIds):Promise.resolve({data:[]}),
    restaurantIds.length?supabase.from('camp_properties').select('restaurant_id,name,destination,city,cover_image_url').in('restaurant_id',restaurantIds):Promise.resolve({data:[]}),
    restaurantIds.length?supabase.from('anaira_stay_properties').select('restaurant_id,stay_type,name,destination,city,cover_image_url').in('restaurant_id',restaurantIds):Promise.resolve({data:[]})
   ]);
   const allowed=new Set((storeRows||[]).map(x=>x.id)),rMap=new Map((restaurantRows||[]).map(x=>[x.id,x])),hMap=new Map((hmsRows||[]).map(x=>[x.restaurant_id,x])),cMap=new Map((campRows||[]).map(x=>[x.restaurant_id,x])),aMap=new Map((stayRows||[]).map(x=>[x.restaurant_id+':'+x.stay_type,x]));
   setFeaturedProperties(memberRows.filter(m=>allowed.has(m.store_id)).map(m=>{const r=rMap.get(m.restaurant_id)||{},h=hMap.get(m.restaurant_id)||{},camp=cMap.get(m.restaurant_id)||{},item=aMap.get(m.restaurant_id+':'+(r.hospitality_type||''))||camp;return {...m,property_name:item?.name||h.hotel_name||r.name||'Hospitality Property',destination:item?.destination||item?.city||h.city||r.city||'',cover_image_url:item?.cover_image_url||h.cover_image_url||r.cover_image||'',stay_type:r.hospitality_type||'hotel'}}).sort((a,b)=>(a.sort_order||0)-(b.sort_order||0)));
  }
 })()},[]);

 const set=(k,v)=>setForm(x=>({...x,[k]:v}));
 async function save(){setSaving(true);setMsg('');setError('');const user=(await supabase.auth.getUser()).data.user?.id;
  for(const [key,value] of Object.entries(form)){const q=await supabase.from('anaira_platform_settings').upsert({key,value:{value},updated_by:user},{onConflict:'key'});if(q.error){setError(q.error.message);setSaving(false);return}}
  setMsg('Global Hotel Marketplace settings saved.');setSaving(false);
 }
 async function saveBanner(e){e.preventDefault();setError('');if(!store||!banner.title){setError('Banner title is required.');return}
  const payload={...banner,store_id:store.id,display_order:Number(banner.display_order)||0,updated_at:new Date().toISOString()};
  if(banner.media_type==='video'&&!banner.video_url){setError('Desktop banner video is required.');return}
  if(banner.media_type==='image'&&!banner.image_url){setError('Desktop banner image is required.');return}
  let q;
  if(editingBannerId) q=await supabase.from('anaira_hotel_store_banners').update(payload).eq('id',editingBannerId).select('*').single();
  else q=await supabase.from('anaira_hotel_store_banners').insert(payload).select('*').single();
  if(q.error){setError(q.error.message);return}
  setBanners(x=>(editingBannerId?x.map(i=>i.id===editingBannerId?q.data:i):[...x,q.data]).sort((a,b)=>(a.display_order||0)-(b.display_order||0)));
  setBanner(blankBanner);setEditingBannerId(null);setMsg(editingBannerId?'Promotional banner updated.':'Global hotel promotional banner added.');
 }
 function editBanner(b){setEditingBannerId(b.id);setBanner({...blankBanner,...b});setTab('hero');window.scrollTo({top:0,behavior:'smooth'});}
 function cancelBannerEdit(){setEditingBannerId(null);setBanner(blankBanner);}
 async function saveDestination(e){e.preventDefault();setError('');if(!store||!destination.name||!destination.image_url){setError('Destination name and image are required.');return}
  const payload={...destination,store_id:store.id,display_order:Number(destination.display_order)||0,cta_url:destination.cta_url||`/anaira/hotels?destination=${encodeURIComponent(destination.name)}`,updated_at:new Date().toISOString()};
  let q;
  if(editingDestinationId) q=await supabase.from('anaira_hotel_store_destinations').update(payload).eq('id',editingDestinationId).select('*').single();
  else q=await supabase.from('anaira_hotel_store_destinations').insert(payload).select('*').single();
  if(q.error){setError(q.error.message);return}
  setDestinations(x=>(editingDestinationId?x.map(i=>i.id===editingDestinationId?q.data:i):[...x,q.data]).sort((a,b)=>(a.display_order||0)-(b.display_order||0)));
  setDestination(blankDestination);setEditingDestinationId(null);setMsg(editingDestinationId?'Destination updated.':'Destination card added to the global hotel marketplace.');
 }
 function editDestination(d){setEditingDestinationId(d.id);setDestination({...blankDestination,...d});setTab('destinations');window.scrollTo({top:0,behavior:'smooth'});}
 function cancelDestinationEdit(){setEditingDestinationId(null);setDestination(blankDestination);}
 async function updateFeaturedProperty(item,patch){setError('');const {error}=await supabase.from('anaira_store_memberships').update({...patch,updated_at:new Date().toISOString()}).eq('id',item.id);if(error){setError(error.message);return}setFeaturedProperties(rows=>rows.map(x=>x.id===item.id?{...x,...patch}:x).sort((a,b)=>(Number(a.sort_order)||0)-(Number(b.sort_order)||0)));setMsg(patch.featured!==undefined?(patch.featured?'Property added to Featured Properties.':'Property removed from Featured Properties.'):'Featured property order updated.')}
 async function toggleBanner(b){const {error}=await supabase.from('anaira_hotel_store_banners').update({active:!b.active,updated_at:new Date().toISOString()}).eq('id',b.id);if(error){setError(error.message);return}setBanners(x=>x.map(i=>i.id===b.id?{...i,active:!b.active}:i))}
  async function delBanner(id){if(!window.confirm('Delete this global hotel banner? This cannot be undone.'))return;const {error}=await supabase.from('anaira_hotel_store_banners').delete().eq('id',id);if(error){setError(error.message);return}if(editingBannerId===id){setEditingBannerId(null);setBanner(blankBanner)}setBanners(x=>x.filter(i=>i.id!==id));setMsg('Global hotel banner deleted.')}
 async function toggleDestination(d){const {error}=await supabase.from('anaira_hotel_store_destinations').update({active:!d.active,updated_at:new Date().toISOString()}).eq('id',d.id);if(error){setError(error.message);return}setDestinations(x=>x.map(i=>i.id===d.id?{...i,active:!d.active}:i))}
  async function delDestination(id){if(!window.confirm('Delete this destination card? This cannot be undone.'))return;const {error}=await supabase.from('anaira_hotel_store_destinations').delete().eq('id',id);if(error){setError(error.message);return}if(editingDestinationId===id){setEditingDestinationId(null);setDestination(blankDestination)}setDestinations(x=>x.filter(i=>i.id!==id));setMsg('Destination deleted from the global hotel marketplace.')}

 const tabs=[['design','🎨 Brand & Design'],['hero','🖼 Hero & Promotions'],['destinations','📍 Top Destinations'],['layout','▦ Homepage Layout'],['content','✍ Sections & Content'],['rules','⚙ Marketplace Rules'],['seo','🔎 SEO & Footer']];
 return <AppShell active="/super-admin/hotel-marketplace-settings">
  <Header eyebrow="SUPER ADMIN • GLOBAL HOTEL STORE" title="ANAIRA Hotels — Marketplace Control Center" subtitle="Global hotel marketplace presentation, discovery, promotions and publishing are owned by Super Admin. Hotel PMS, rooms, rates, inventory and bookings remain operationally canonical in Hotel Management." actions={<div className="market-head-actions"><Link className="btn" href="/anaira/hotels" target="_blank"><ExternalLink size={15}/> Open Hotel Marketplace</Link><button className="btn primary" onClick={save} disabled={saving}><Save size={15}/>{saving?'Saving…':'Save All Changes'}</button></div>}/>
   <div className="hotel-marketplace-settings-page">
  <div className="market-control-hero"><div><div className="market-eyebrow"><Hotel size={15}/> GLOBAL HOTEL MARKETPLACE</div><h2>Ultra-premium hotel discovery for the entire ANAIRA network.</h2><p>Global branding, hero media, promotional campaigns and destination cards are platform-owned. Individual hotels keep control of their property master and operational inventory.</p></div><div className="market-hero-metrics"><span><b>GLOBAL</b><small>Store ownership</small></span><span><b>LIVE</b><small>HMS inventory</small></span><span><b>{destinations.length}</b><small>Destinations</small></span></div></div>
  <div className="store-control-tabs">{tabs.map(([id,label])=><button key={id} className={tab===id?'active':''} onClick={()=>setTab(id)}>{label}</button>)}</div>
  {msg&&<div className="notice success" style={{marginBottom:16}}>{msg}</div>}{error&&<div className="notice error" style={{marginBottom:16}}>{error}</div>}

  {tab==='design'&&<><Section title="Global Hotel Brand System" meta="Premium visual identity for /anaira/hotels. This does not duplicate hotel master data."><div className="card store-settings-grid">
   <label><span>Marketplace title</span><input value={form.hotel_home_title} onChange={e=>set('hotel_home_title',e.target.value)}/></label>
   <label><span>Marketplace subtitle</span><input value={form.hotel_home_subtitle} onChange={e=>set('hotel_home_subtitle',e.target.value)}/></label>
   <label><span>Theme preset</span><select value={form.hotel_home_theme} onChange={e=>set('hotel_home_theme',e.target.value)}><option value="luxury">Luxury Gold</option><option value="forest">Forest Luxury</option><option value="midnight">Midnight</option></select></label>
   <label><span>Primary color</span><input type="color" value={form.hotel_home_primary_color} onChange={e=>set('hotel_home_primary_color',e.target.value)}/></label><label><span>Accent / CTA color</span><input type="color" value={form.hotel_home_accent_color} onChange={e=>set('hotel_home_accent_color',e.target.value)}/></label>
   <label><span>Page background</span><input type="color" value={form.hotel_home_background_color} onChange={e=>set('hotel_home_background_color',e.target.value)}/></label><label><span>Surface color</span><input type="color" value={form.hotel_home_surface_color} onChange={e=>set('hotel_home_surface_color',e.target.value)}/></label><label><span>Text color</span><input type="color" value={form.hotel_home_text_color} onChange={e=>set('hotel_home_text_color',e.target.value)}/></label>
   <label><span>Content max width</span><input type="number" min="980" max="1600" value={form.hotel_home_container_width} onChange={e=>set('hotel_home_container_width',Number(e.target.value))}/></label>
   <label><span>Hotel cards per row</span><select value={form.hotel_home_hotel_columns} onChange={e=>set('hotel_home_hotel_columns',Number(e.target.value))}><option value="2">2</option><option value="3">3</option><option value="4">4</option></select></label>
   <label><span>Destination cards per row</span><select value={form.hotel_home_destination_columns} onChange={e=>set('hotel_home_destination_columns',Number(e.target.value))}><option value="4">4</option><option value="5">5</option><option value="6">6</option></select></label>
   <label><span>Card radius</span><input type="number" min="8" max="40" value={form.hotel_home_card_radius} onChange={e=>set('hotel_home_card_radius',Number(e.target.value))}/></label>
  </div></Section>
  <Section title="Homepage Modules" meta="Turn global marketplace modules on or off without affecting hotel operational systems."><div className="card store-toggle-grid">{[['hotel_marketplace_enabled','Hotel Marketplace enabled'],['hotel_home_show_search','Search & availability search'],['hotel_home_show_banners','Hero & promotions'],['hotel_home_show_destinations','Top destinations'],['hotel_home_show_trust','Trust / booking benefits'],['hotel_home_show_footer','Footer'],['hotel_home_enable_filters','Guest-side property & location filters'],['hotel_home_enable_sort','Sort by recommended / price / name'],['hotel_home_enable_wishlist','Guest wishlist / saved stays']].map(([k,l])=><label key={k} className="check-field"><input type="checkbox" checked={!!form[k]} onChange={e=>set(k,e.target.checked)}/><span>{l}</span></label>)}</div></Section></>}

  {tab==='hero'&&<><Section title="Ultra HD Hero & Background Media" meta="Desktop, tablet and mobile can use responsive image or video. The hero background is separate from the right-side media card so the existing layout stays intact."><div className="card store-settings-stack">
   <HotelMediaUpload label="Desktop hero media" imageValue={form.hotel_home_hero_image} videoValue={form.hotel_home_hero_video} mediaType={form.hotel_home_hero_media_type} restaurantId={store?.id} folder="marketplace/hotels/hero" onTypeChange={v=>set('hotel_home_hero_media_type',v)} onChange={v=>set(form.hotel_home_hero_media_type==='video'?'hotel_home_hero_video':'hotel_home_hero_image',v)}/>
   <HotelMediaUpload label="Mobile / tablet hero media" imageValue={form.hotel_home_hero_mobile_image} videoValue={form.hotel_home_hero_mobile_video} mediaType={form.hotel_home_hero_mobile_media_type} restaurantId={store?.id} folder="marketplace/hotels/hero-mobile" onTypeChange={v=>set('hotel_home_hero_mobile_media_type',v)} onChange={v=>set(form.hotel_home_hero_mobile_media_type==='video'?'hotel_home_hero_mobile_video':'hotel_home_hero_mobile_image',v)}/>
   <HotelMediaUpload label="Desktop full green-background media" imageValue={form.hotel_home_background_image} videoValue={form.hotel_home_background_video} mediaType={form.hotel_home_background_media_type} restaurantId={store?.id} folder="marketplace/hotels/background" onTypeChange={v=>set('hotel_home_background_media_type',v)} onChange={v=>set(form.hotel_home_background_media_type==='video'?'hotel_home_background_video':'hotel_home_background_image',v)}/>
   <HotelMediaUpload label="Mobile / tablet full green-background media" imageValue={form.hotel_home_background_mobile_image} videoValue={form.hotel_home_background_mobile_video} mediaType={form.hotel_home_background_mobile_media_type} restaurantId={store?.id} folder="marketplace/hotels/background-mobile" onTypeChange={v=>set('hotel_home_background_mobile_media_type',v)} onChange={v=>set(form.hotel_home_background_mobile_media_type==='video'?'hotel_home_background_mobile_video':'hotel_home_background_mobile_image',v)}/>
   <div className="hero-save-bar"><div><b>Save Hero & Background Media</b><small>Upload or replace media, then save it to the marketplace.</small></div><button className="btn primary" type="button" onClick={save} disabled={saving}><Save size={15}/>{saving?'Saving…':'Save Hero & Background Media'}</button></div>
   <div className="store-settings-grid"><label><span>Hero overlay strength</span><input type="number" min="0" max="0.9" step="0.05" value={form.hotel_home_hero_overlay} onChange={e=>set('hotel_home_hero_overlay',e.target.value)} step="0.01"/></label><label><span>Background overlay strength</span><input type="number" min="0" max="0.9" step="0.05" value={form.hotel_home_background_overlay} onChange={e=>set('hotel_home_background_overlay',e.target.value)} step="0.01"/></label><label><span>Hero CTA label</span><input value={form.hotel_home_hero_cta} onChange={e=>set('hotel_home_hero_cta',e.target.value)}/></label><label className="full"><span>Hero CTA URL</span><input value={form.hotel_home_hero_cta_url} onChange={e=>set('hotel_home_hero_cta_url',e.target.value)}/></label></div>
  </div></Section>
  <Section title="Global Hotel Promotional Banners" meta="Image/video campaigns with desktop/mobile media, edit, replace, enable/disable and delete."><div className="card"><form className="store-settings-stack" onSubmit={saveBanner}>
   <div className="store-settings-grid"><label><span>Banner title</span><input value={banner.title} onChange={e=>setBanner({...banner,title:e.target.value})} required/></label><label><span>Subtitle</span><input value={banner.subtitle} onChange={e=>setBanner({...banner,subtitle:e.target.value})}/></label></div>
   <HotelMediaUpload label="Desktop banner media" imageValue={banner.image_url} videoValue={banner.video_url} mediaType={banner.media_type} restaurantId={store?.id} folder="marketplace/hotels/banners" onTypeChange={v=>setBanner({...banner,media_type:v})} onChange={v=>setBanner({...banner,[banner.media_type==='video'?'video_url':'image_url']:v})}/>
   <HotelMediaUpload label="Mobile / tablet banner media" imageValue={banner.mobile_image_url} videoValue={banner.mobile_video_url} mediaType={banner.mobile_media_type||'image'} restaurantId={store?.id} folder="marketplace/hotels/banners-mobile" onTypeChange={v=>setBanner({...banner,mobile_media_type:v})} onChange={v=>setBanner({...banner,[banner.mobile_media_type==='video'?'mobile_video_url':'mobile_image_url']:v})}/>
   <div className="store-settings-grid"><label><span>CTA label</span><input value={banner.cta_label} onChange={e=>setBanner({...banner,cta_label:e.target.value})}/></label><label><span>CTA URL</span><input value={banner.cta_url} onChange={e=>setBanner({...banner,cta_url:e.target.value})}/></label><label><span>Display order</span><input type="number" value={banner.display_order} onChange={e=>setBanner({...banner,display_order:e.target.value})}/></label></div>
   <div className="edit-actions"><button className="btn primary" type="submit"><ImageIcon size={15}/>{editingBannerId?'Save Banner Changes':'Add Global Hotel Banner'}</button>{editingBannerId&&<button className="btn" type="button" onClick={cancelBannerEdit}><X size={14}/> Cancel edit</button>}</div>
   </form><div className="admin-list-heading"><div><b>Manage Existing Global Hotel Banners</b><small>Edit, replace media, enable/disable or delete banners already added.</small></div><span>{banners.length} total</span></div><div className="banner-admin-list">{banners.length?banners.map(b=><article key={b.id}><div className="banner-admin-thumb">{b.media_type==='video'?(<video src={b.video_url} muted autoPlay loop playsInline/>):(<img src={b.image_url} alt=""/>)}</div><div><b>{b.title}</b><p>{b.subtitle||'No subtitle'} · order {b.display_order}</p><small>{b.active?'LIVE':'DISABLED'} · {b.media_type==='video'?'VIDEO':'IMAGE'}</small></div><div className="admin-record-actions"><button type="button" className="btn" onClick={()=>editBanner(b)}><Pencil size={13}/> Edit / Replace</button><button type="button" className="btn" onClick={()=>toggleBanner(b)}>{b.active?'Disable':'Enable'}</button><button type="button" className="btn danger" onClick={()=>delBanner(b.id)}><Trash2 size={13}/> Delete</button></div></article>):<div className="admin-empty-state">No global hotel banners added yet. Use <b>Add Global Hotel Banner</b> above to create the first one.</div>}</div></div></Section></>}
  {tab==='destinations'&&<><Section title="Top Destinations — 5 Premium Cards" meta="Super Admin can add destination cards, upload their images, control order and link each card to hotel search. The public marketplace shows five cards in one row on desktop."><div className="card destination-form-card">
   <form className="store-settings-stack" onSubmit={saveDestination}>
    <div className="store-settings-grid"><label><span>Destination name</span><input value={destination.name} onChange={e=>setDestination({...destination,name:e.target.value})} placeholder="Manali" required/></label><label><span>Short subtitle</span><input value={destination.subtitle} onChange={e=>setDestination({...destination,subtitle:e.target.value})} placeholder="Mountain escapes"/></label></div>
    <MarketplaceImageUpload label="Destination image" value={destination.image_url} onChange={v=>setDestination({...destination,image_url:v})} folder="marketplace/hotels/destinations"/>
    <MarketplaceImageUpload label="Mobile destination image (optional)" value={destination.mobile_image_url} onChange={v=>setDestination({...destination,mobile_image_url:v})} folder="marketplace/hotels/destinations-mobile"/>
    <div className="store-settings-grid"><label><span>CTA label</span><input value={destination.cta_label} onChange={e=>setDestination({...destination,cta_label:e.target.value})}/></label><label><span>CTA URL (optional)</span><input value={destination.cta_url} onChange={e=>setDestination({...destination,cta_url:e.target.value})} placeholder="/anaira/hotels?destination=Manali"/></label><label><span>Display order</span><input type="number" min="0" value={destination.display_order} onChange={e=>setDestination({...destination,display_order:e.target.value})}/></label></div>
    <div className="edit-actions"><button className="btn primary" type="submit">{editingDestinationId?<><Save size={15}/> Save Destination Changes</>:<><Plus size={15}/> Add Destination Card</>}</button>{editingDestinationId&&<button className="btn" type="button" onClick={cancelDestinationEdit}><X size={14}/> Cancel edit</button>}</div>
   </form>
  </div></Section>
  
  <Section title="Manage Featured Properties" meta="Select approved hotel, camp, homestay, guest house and cottage listings for the luxury collection below Top Destinations. Changes publish immediately.">
   <div className="featured-admin-intro"><div><span className="featured-admin-kicker">✦ CURATED ANAIRA COLLECTION</span><h3>Choose the stays guests should discover first.</h3><p>Only published, approved property stores are available. Featured selection changes the homepage showcase only; it does not change booking availability or property approval.</p></div><strong>{featuredProperties.filter(x=>x.featured).length}<small>FEATURED</small></strong></div>
   <div className="featured-admin-list">{featuredProperties.length?featuredProperties.map(p=><article className={p.featured?'is-featured':''} key={p.id}>
    <div className="featured-admin-photo">{p.cover_image_url?<img src={p.cover_image_url} alt=""/>:<Hotel size={24}/>}<span>{String(p.stay_type||'hotel').replace('_',' ').toUpperCase()}</span></div>
    <div className="featured-admin-info"><b>{p.property_name}</b><small><MapPin size={12}/> {p.destination||'Destination not set'}</small><em>{p.featured?'✦ Featured on ANAIRA Hotels':'Available to feature'}</em></div>
    <label className="featured-admin-toggle"><input type="checkbox" checked={!!p.featured} onChange={e=>updateFeaturedProperty(p,{featured:e.target.checked})}/><span>{p.featured?'Featured':'Feature this stay'}</span></label>
    <label className="featured-admin-order"><small>ORDER</small><input aria-label={'Featured order for '+p.property_name} type="number" min="0" value={p.sort_order??0} onChange={e=>setFeaturedProperties(rows=>rows.map(x=>x.id===p.id?{...x,sort_order:e.target.value}:x))} onBlur={()=>updateFeaturedProperty(p,{sort_order:Number(p.sort_order)||0})}/></label>
   </article>):<div className="admin-empty-state">No approved, published hotel marketplace properties are available to feature yet.</div>}</div>
  </Section>
  <Section title="Manage Existing Top Destinations" meta={`${destinations.filter(d=>d.active).length} active · ${destinations.length} total`}><div className="admin-list-heading"><div><b>Destination Management</b><small>Every destination you add appears here with Edit / Replace, Enable / Disable and Delete controls.</small></div><span>{destinations.length} total</span></div><div className="destination-admin-grid">{destinations.length?destinations.map(d=><article className="destination-admin-card" key={d.id}><div className="destination-admin-image">{d.image_url?<img src={d.image_url} alt={d.name}/>:<MapPin size={28}/>}<span>#{Number(d.display_order)+1}</span><div className="destination-card-actions"><button type="button" onClick={()=>editDestination(d)} title="Edit this destination"><Pencil size={13}/> Edit</button><button type="button" onClick={()=>toggleDestination(d)} title={d.active?'Disable this destination':'Enable this destination'}><Power size={13}/> {d.active?'Disable':'Enable'}</button><button type="button" className="delete" onClick={()=>delDestination(d.id)} title="Delete this destination"><Trash2 size={13}/> Delete</button></div></div><div className="destination-admin-body"><b>{d.name}</b><p>{d.subtitle||'No subtitle'}</p><div className="admin-record-actions"><button type="button" className="btn" onClick={()=>editDestination(d)}><Pencil size={13}/> Edit / Replace</button><button type="button" className="btn" onClick={()=>toggleDestination(d)}><Power size={13}/>{d.active?'Disable':'Enable'}</button><button type="button" className="btn danger" onClick={()=>delDestination(d.id)}><Trash2 size={13}/> Delete</button></div></div></article>):<div className="admin-empty-state">No destinations added yet. Add your first destination above; after saving it will appear here for editing and deletion.</div>}</div></Section></>}

  {tab==='layout'&&<Section title="Hotel Discovery Layout" meta="Control the premium marketplace composition and search experience."><div className="card" style={{padding:16,marginBottom:14}}><b>Booking marketplace capabilities</b><p style={{fontSize:12,color:"#68766f",margin:"5px 0 12px"}}>Enable guest-facing discovery tools on ANAIRA Hotels. These controls do not change PMS rates or inventory.</p><div className="store-toggle-grid">{[["hotel_home_enable_filters","Search & property filters"],["hotel_home_enable_sort","Sorting controls"],["hotel_home_enable_wishlist","Wishlist / saved stays"]].map(([k,l])=><label key={k} className="check-field"><input type="checkbox" checked={form[k]!==false} onChange={e=>set(k,e.target.checked)}/><span>{l}</span></label>)}</div></div><div className="card store-section-layout"><div className="layout-preview"><div className="lp-hero">HERO / DESTINATION / DATES / SEARCH</div><div className="lp-row"><div>TOP DESTINATIONS × 5</div><div>TRUST SIGNALS</div></div><div>LIVE HOTEL DISCOVERY GRID</div><div>GLOBAL PROMOTIONS</div></div><div className="store-settings-grid"><label><span>Destination cards per row</span><select value={form.hotel_home_destination_columns} onChange={e=>set('hotel_home_destination_columns',Number(e.target.value))}><option value="4">4 columns</option><option value="5">5 columns</option><option value="6">6 columns</option></select></label><label><span>Destination section title</span><input value={form.hotel_home_destination_title} onChange={e=>set('hotel_home_destination_title',e.target.value)}/></label><label><span>Destination section subtitle</span><input value={form.hotel_home_destination_subtitle} onChange={e=>set('hotel_home_destination_subtitle',e.target.value)}/></label><label><span>Hotel cards per row</span><select value={form.hotel_home_hotel_columns} onChange={e=>set('hotel_home_hotel_columns',Number(e.target.value))}><option value="2">2 columns</option><option value="3">3 columns</option><option value="4">4 columns</option></select></label><label><span>Container width</span><input type="number" min="980" max="1600" value={form.hotel_home_container_width} onChange={e=>set('hotel_home_container_width',Number(e.target.value))}/></label><label><span>Card radius</span><input type="number" min="8" max="40" value={form.hotel_home_card_radius} onChange={e=>set('hotel_home_card_radius',Number(e.target.value))}/></label>
   <label><span>Hero minimum height (px)</span><input type="number" min="0" max="900" value={form.hotel_home_hero_min_height} onChange={e=>set('hotel_home_hero_min_height',Number(e.target.value))}/></label>
   <label><span>Search bar max width (px)</span><input type="number" min="700" max="1600" value={form.hotel_home_search_max_width} onChange={e=>set('hotel_home_search_max_width',Number(e.target.value))}/></label>
   <label><span>Vertical section spacing (px)</span><input type="number" min="12" max="100" value={form.hotel_home_section_spacing} onChange={e=>set('hotel_home_section_spacing',Number(e.target.value))}/></label>
   <label><span>Promotional banner height (px)</span><input type="number" min="180" max="600" value={form.hotel_home_banner_height} onChange={e=>set('hotel_home_banner_height',Number(e.target.value))}/></label>
  </div></div></Section>}

  {tab==='content'&&<Section title="Homepage Sections & Content" meta="Control section visibility, featured property layout and editorial copy."><div className="content-settings-stack">
   <div className="card store-toggle-grid">{[['hotel_home_show_featured','Featured properties section'],['hotel_home_show_why','Why book with ANAIRA'],['hotel_home_show_about','About ANAIRA'],['hotel_home_show_stats','Company & marketplace statistics'],['hotel_home_show_workflow','How booking works'],['hotel_home_show_tech','Hospitality technology section']].map(([k,l])=><label key={k} className="check-field"><input type="checkbox" checked={!!form[k]} onChange={e=>set(k,e.target.checked)}/><span>{l}</span></label>)}</div>
   <div className="card store-settings-grid">
    <label><span>Featured section title</span><input value={form.hotel_home_featured_title||''} onChange={e=>set('hotel_home_featured_title',e.target.value)}/></label>
    <label><span>Featured section subtitle</span><input value={form.hotel_home_featured_subtitle||''} onChange={e=>set('hotel_home_featured_subtitle',e.target.value)}/></label>
    <label><span>Featured cards per row</span><select value={form.hotel_home_featured_columns||3} onChange={e=>set('hotel_home_featured_columns',Number(e.target.value))}><option value="2">2 columns</option><option value="3">3 columns</option><option value="4">4 columns</option></select></label>
    <label><span>Featured image height (px)</span><input type="number" min="160" max="480" value={form.hotel_home_featured_card_height||245} onChange={e=>set('hotel_home_featured_card_height',Number(e.target.value))}/></label>
    <label><span>Why section heading</span><input value={form.hotel_home_why_title||''} onChange={e=>set('hotel_home_why_title',e.target.value)}/></label>
    <label><span>Why section subtitle</span><input value={form.hotel_home_why_subtitle||''} onChange={e=>set('hotel_home_why_subtitle',e.target.value)}/></label>
    <label><span>About section heading</span><input value={form.hotel_home_about_title||''} onChange={e=>set('hotel_home_about_title',e.target.value)}/></label>
    <label><span>About section subheading</span><input value={form.hotel_home_about_subtitle||''} onChange={e=>set('hotel_home_about_subtitle',e.target.value)}/></label>
    <label><span>Workflow section heading</span><input value={form.hotel_home_workflow_title||''} onChange={e=>set('hotel_home_workflow_title',e.target.value)}/></label>
    <label><span>Workflow section subtitle</span><input value={form.hotel_home_workflow_subtitle||''} onChange={e=>set('hotel_home_workflow_subtitle',e.target.value)}/></label>
    <label className="full"><span>Technology section heading</span><input value={form.hotel_home_tech_title||''} onChange={e=>set('hotel_home_tech_title',e.target.value)}/></label>
   </div>
  </div></Section>}
  {tab==='rules'&&<><Section title="Hotel Marketplace Governance" meta="Global marketplace policy. Individual hotel stores remain under their Business Admin scope."><div className="card store-settings-grid"><label className="check-field"><input type="checkbox" checked={!!form.hotel_marketplace_enabled} onChange={e=>set('hotel_marketplace_enabled',e.target.checked)}/><span>Hotel Marketplace enabled</span></label><label className="check-field"><input type="checkbox" checked={!!form.hotel_require_listing_approval} onChange={e=>set('hotel_require_listing_approval',e.target.checked)}/><span>Require hotel listing approval</span></label><label className="check-field"><input type="checkbox" checked={!!form.hotel_featured_enabled} onChange={e=>set('hotel_featured_enabled',e.target.checked)}/><span>Featured hotels enabled</span></label><label><span>Marketplace payment mode</span><select value={form.hotel_marketplace_payment_mode} onChange={e=>set('hotel_marketplace_payment_mode',e.target.value)}><option value="platform">Platform</option><option value="direct">Direct to hotel</option><option value="hybrid">Hybrid</option></select></label></div></Section><Section title="Global Marketplace Booking Journey" meta="The global marketplace opens the selected property's own storefront and continues checkout under that same property route."><div className="card" style={{padding:20,display:'grid',gap:10}}><div style={{display:'flex',gap:10,alignItems:'center',flexWrap:'wrap'}}><b>/anaira/hotels</b><span>→</span><b>/property/{'{id}'}</b><span>→</span><b>/property/{'{id}'}/checkout</b></div><p style={{margin:0,color:'#68766f',fontSize:12}}>Global Marketplace guests do not need the legacy /book/{'{id}'} storefront route. Property details, selected accommodation, dates, guest count and booking source stay connected through the property-owned checkout.</p><Link className="btn" href="/anaira/hotels" target="_blank">Preview Global Marketplace ↗</Link></div></Section></>}

  {tab==='seo'&&<Section title="Hotel Marketplace SEO & Footer" meta="Global metadata controlled by Super Admin."><div className="card store-settings-grid"><label><span>SEO title</span><input value={form.hotel_home_meta_title} onChange={e=>set('hotel_home_meta_title',e.target.value)}/></label><label><span>Footer text</span><input value={form.hotel_home_footer_text} onChange={e=>set('hotel_home_footer_text',e.target.value)}/></label><label className="full"><span>SEO description</span><textarea rows="4" value={form.hotel_home_meta_description} onChange={e=>set('hotel_home_meta_description',e.target.value)}/></label></div></Section>}

  <style jsx>{`
    .featured-admin-intro{display:flex;align-items:center;justify-content:space-between;gap:20px;padding:24px;border-radius:20px;background:radial-gradient(circle at 85% 15%,rgba(215,180,100,.24),transparent 35%),linear-gradient(125deg,#102f24,#1d4935 68%,#2a503c);color:#fff;margin-bottom:16px;box-shadow:0 18px 40px rgba(16,47,36,.15)}
    .featured-admin-kicker{font-size:9px;letter-spacing:.18em;font-weight:900;color:#e5c77e}.featured-admin-intro h3{font:700 25px/1.15 Georgia,serif;margin:8px 0;color:#fff}.featured-admin-intro p{max-width:680px;margin:0;color:rgba(255,255,255,.72);font-size:11px;line-height:1.6}.featured-admin-intro>strong{font:700 36px Georgia,serif;color:#e5c77e;text-align:center;min-width:90px}.featured-admin-intro>strong small{display:block;font:800 9px Arial,sans-serif;letter-spacing:.15em;color:#fff}
    .featured-admin-list{display:grid;gap:10px}.featured-admin-list article{display:grid;grid-template-columns:112px minmax(0,1fr) auto 82px;align-items:center;gap:15px;padding:11px;border:1px solid #e9e4d8;border-radius:15px;background:#fff;transition:.2s}.featured-admin-list article.is-featured{border-color:#c9a75f;background:linear-gradient(100deg,#fffdf7,#fff)}
    .featured-admin-photo{height:76px;border-radius:11px;overflow:hidden;position:relative;background:#edf1eb;display:grid;place-items:center;color:#b18b42}.featured-admin-photo img{width:100%;height:100%;object-fit:cover}.featured-admin-photo span{position:absolute;left:6px;bottom:6px;border-radius:99px;padding:4px 7px;background:#15372a;color:#f4e3b6;font-size:8px;font-weight:900}
    .featured-admin-info b{display:block;color:#18392b;font-size:13px}.featured-admin-info small{display:flex;align-items:center;gap:4px;color:#78847c;font-size:10px;margin-top:5px}.featured-admin-info em{display:block;color:#a17b32;font-size:9px;font-style:normal;font-weight:800;margin-top:6px}
    .featured-admin-toggle{display:flex;align-items:center;gap:7px;color:#244a37;font-size:10px;font-weight:800;white-space:nowrap}.featured-admin-toggle input{accent-color:#b18b42;width:17px;height:17px}.featured-admin-order{display:grid;gap:4px;color:#8b8d82;font-size:8px;font-weight:900;letter-spacing:.12em}.featured-admin-order input{width:70px;padding:8px;border:1px solid #e5dfd1;border-radius:8px;color:#17372b;font-size:12px}
    @media(max-width:700px){.featured-admin-list article{grid-template-columns:76px 1fr;gap:10px}.featured-admin-photo{height:70px}.featured-admin-toggle{grid-column:2;grid-row:2}.featured-admin-order{grid-column:1;grid-row:2}.featured-admin-intro{align-items:flex-start;padding:18px}.featured-admin-intro h3{font-size:20px}.featured-admin-intro>strong{font-size:28px;min-width:60px}}
    .destination-admin-image{position:relative;overflow:hidden}
    .destination-card-actions{position:absolute;left:10px;right:10px;bottom:10px;display:flex;gap:6px;z-index:5}
    .destination-card-actions button{appearance:none;border:1px solid rgba(255,255,255,.72);background:rgba(12,37,28,.92);color:#fff;border-radius:9px;padding:8px 10px;display:inline-flex;align-items:center;justify-content:center;gap:5px;font-size:11px;font-weight:800;cursor:pointer;box-shadow:0 6px 18px rgba(0,0,0,.22);backdrop-filter:blur(8px)}
    .destination-card-actions button:hover{background:#c7a15a;color:#132f24}
    .destination-card-actions button.delete{background:#8f332d}
    .destination-card-actions button.delete:hover{background:#b9473d;color:#fff}
    .destination-admin-body{display:block!important;visibility:visible!important;opacity:1!important;padding:12px}
    .destination-admin-body>b,.destination-admin-body p{display:block!important;visibility:visible!important}
    @media(max-width:700px){.destination-card-actions{left:8px;right:8px;bottom:8px;display:grid;grid-template-columns:repeat(3,1fr)}.destination-card-actions button{padding:8px 5px;font-size:10px}.destination-admin-body .admin-record-actions{display:grid;grid-template-columns:1fr}.destination-admin-body .admin-record-actions .btn{width:100%}}
  `}</style>
  <div className="marketplace-final-save"><div><b>Final Marketplace Settings Save</b><small>Save Hero, Background, Design, Layout, Rules and SEO changes made on this page.</small></div><button className="btn primary" type="button" onClick={save} disabled={saving}><Save size={15}/>{saving?'Saving…':'Save All Marketplace Settings'}</button></div>
  <style jsx>{`
    .hero-save-bar,.marketplace-final-save,.admin-list-heading{display:flex;align-items:center;justify-content:space-between;gap:16px;border:1px solid rgba(23,55,43,.12);background:linear-gradient(135deg,#fff,#f7f3e9);border-radius:16px;padding:16px 18px;margin-top:16px;box-shadow:0 10px 28px rgba(20,40,30,.06)}
    .hero-save-bar b,.marketplace-final-save b,.admin-list-heading b{display:block;color:#17372b;font-size:14px}
    .hero-save-bar small,.marketplace-final-save small,.admin-list-heading small{display:block;color:#6b756f;font-size:11px;margin-top:4px}
    .admin-list-heading{margin:18px 0 12px}
    .admin-list-heading>span{font-size:11px;font-weight:800;color:#a17b32;background:#f4ead2;border-radius:999px;padding:6px 10px;white-space:nowrap}
    .admin-record-actions{display:flex;flex-wrap:wrap;gap:8px;align-items:center}
    .admin-record-actions .danger{border-color:rgba(170,55,45,.25);color:#a13d35}
    .admin-empty-state{grid-column:1/-1;padding:28px;text-align:center;border:1px dashed rgba(23,55,43,.18);border-radius:16px;background:#fbfaf7;color:#66716b;font-size:13px}
    @media(max-width:900px){.hero-save-bar,.marketplace-final-save,.admin-list-heading{align-items:flex-start;flex-direction:column}.hero-save-bar .btn,.marketplace-final-save .btn{width:100%}.admin-record-actions{width:100%}.admin-record-actions .btn{flex:1;min-width:110px}}
    @media(max-width:560px){.admin-record-actions{display:grid;grid-template-columns:1fr}.admin-record-actions .btn{width:100%}.hero-save-bar,.marketplace-final-save{padding:14px}}
  `}</style>
  <div className="store-control-footer"><b>Ownership boundary:</b> Super Admin controls the global hotel marketplace. Business Admin controls only the individual hotel's customer-facing store. PMS owns rooms, rates, inventory, availability and bookings. <Link href="/anaira/hotels" target="_blank">Preview global hotel store ↗</Link></div>

   <style jsx global>{`
    .hotel-marketplace-settings-page{width:100%;max-width:100%;min-width:0;box-sizing:border-box}
    .hotel-marketplace-settings-page *{box-sizing:border-box}
    .hotel-marketplace-settings-page .store-control-tabs{max-width:100%;overflow-x:auto;overscroll-behavior-x:contain;scrollbar-width:thin;scroll-snap-type:x proximity}
    .hotel-marketplace-settings-page .store-control-tabs button{flex:0 0 auto;min-height:44px;scroll-snap-align:start}
    .hotel-marketplace-settings-page .market-control-hero{min-width:0}
    .hotel-marketplace-settings-page .market-head-actions{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
    .hotel-marketplace-settings-page .store-settings-grid,.hotel-marketplace-settings-page .store-toggle-grid,.hotel-marketplace-settings-page .store-section-layout,.hotel-marketplace-settings-page .banner-admin-list,.hotel-marketplace-settings-page .destination-admin-grid,.hotel-marketplace-settings-page .featured-admin-list{min-width:0}
    .hotel-marketplace-settings-page input,.hotel-marketplace-settings-page select,.hotel-marketplace-settings-page textarea{max-width:100%;min-width:0}
    .hotel-marketplace-settings-page .banner-admin-list article,.hotel-marketplace-settings-page .banner-admin-list article>div{min-width:0}
    .hotel-marketplace-settings-page .banner-admin-list article>div:nth-child(2){overflow-wrap:anywhere}
    .hotel-marketplace-settings-page .store-control-footer{overflow-wrap:anywhere;line-height:1.65}
    .hotel-marketplace-settings-page .store-control-footer a{display:inline-block}
    @media(max-width:900px){
      .hotel-marketplace-settings-page .market-control-hero{display:grid;grid-template-columns:minmax(0,1fr);gap:16px;padding:22px}
      .hotel-marketplace-settings-page .market-hero-metrics{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px}
      .hotel-marketplace-settings-page .market-hero-metrics span{min-width:0;text-align:center;padding:10px 6px;border-right:1px solid rgba(255,255,255,.16)}
      .hotel-marketplace-settings-page .store-settings-grid{grid-template-columns:minmax(0,1fr)}
      .hotel-marketplace-settings-page .store-toggle-grid{grid-template-columns:repeat(2,minmax(0,1fr))}
      .hotel-marketplace-settings-page .store-section-layout{grid-template-columns:minmax(0,1fr)}
      .hotel-marketplace-settings-page .banner-admin-list article{grid-template-columns:112px minmax(0,1fr);gap:12px}
      .hotel-marketplace-settings-page .banner-admin-list article .admin-record-actions{grid-column:1/-1;display:flex;flex-wrap:wrap}
      .hotel-marketplace-settings-page .banner-admin-list article .admin-record-actions .btn{flex:1 1 130px;min-height:42px;justify-content:center}
      .hotel-marketplace-settings-page .hotel-media-body,.hotel-marketplace-settings-page .market-image-row{grid-template-columns:minmax(0,1fr)}
      .hotel-marketplace-settings-page .hotel-media-preview{height:190px;max-width:100%}
      .hotel-marketplace-settings-page .market-image-preview{height:170px;min-height:170px}
      .hotel-marketplace-settings-page .market-image-preview img{height:100%;min-height:170px}
      .hotel-marketplace-settings-page .market-image-actions{grid-template-columns:repeat(2,minmax(0,1fr))}
      .hotel-marketplace-settings-page .market-image-actions input{grid-column:1/-1;width:100%}
    }
    @media(max-width:600px){
      .hotel-marketplace-settings-page .market-control-hero{padding:18px 15px;border-radius:16px}
      .hotel-marketplace-settings-page .market-control-hero h2{font-size:25px;line-height:1.15}
      .hotel-marketplace-settings-page .market-control-hero p{font-size:12px;line-height:1.6}
      .hotel-marketplace-settings-page .market-hero-metrics{grid-template-columns:repeat(3,minmax(0,1fr));gap:5px}
      .hotel-marketplace-settings-page .market-hero-metrics b{font-size:10px}
      .hotel-marketplace-settings-page .market-hero-metrics small{font-size:9px;overflow-wrap:anywhere}
      .hotel-marketplace-settings-page .store-control-tabs{position:relative;top:auto;display:flex;gap:6px;padding:6px;margin-bottom:14px;border-radius:12px}
      .hotel-marketplace-settings-page .store-control-tabs button{font-size:11px;padding:10px 12px;min-height:44px}
      .hotel-marketplace-settings-page .store-settings-grid{gap:12px}
      .hotel-marketplace-settings-page .store-toggle-grid{grid-template-columns:minmax(0,1fr);gap:8px}
      .hotel-marketplace-settings-page .store-settings-grid label{font-size:12px;min-width:0}
      .hotel-marketplace-settings-page .store-settings-grid input,.hotel-marketplace-settings-page .store-settings-grid select,.hotel-marketplace-settings-page .store-settings-grid textarea{font-size:16px;min-height:44px;padding:11px 12px}
      .hotel-marketplace-settings-page .store-settings-grid input[type=color]{min-height:48px}
      .hotel-marketplace-settings-page .store-settings-stack{gap:13px}
      .hotel-marketplace-settings-page .hotel-media-upload{padding:12px;border-radius:13px;min-width:0}
      .hotel-marketplace-settings-page .hotel-media-head{display:grid;grid-template-columns:minmax(0,1fr);gap:10px}
      .hotel-marketplace-settings-page .hotel-media-switch{display:grid;grid-template-columns:1fr 1fr;width:100%}
      .hotel-marketplace-settings-page .hotel-media-switch button{justify-content:center;min-height:42px}
      .hotel-marketplace-settings-page .hotel-media-body{grid-template-columns:minmax(0,1fr);gap:10px}
      .hotel-marketplace-settings-page .hotel-media-preview{height:165px;width:100%}
      .hotel-marketplace-settings-page .hotel-media-actions{display:grid;grid-template-columns:minmax(0,1fr);width:100%}
      .hotel-marketplace-settings-page .hotel-media-actions .btn,.hotel-marketplace-settings-page .hotel-media-actions input{width:100%;min-width:0;min-height:44px;font-size:13px}
      .hotel-marketplace-settings-page .hero-save-bar,.hotel-marketplace-settings-page .marketplace-final-save,.hotel-marketplace-settings-page .admin-list-heading{padding:13px;border-radius:13px;gap:10px}
      .hotel-marketplace-settings-page .hero-save-bar .btn,.hotel-marketplace-settings-page .marketplace-final-save .btn{width:100%;min-height:46px;justify-content:center}
      .hotel-marketplace-settings-page .market-image-field{min-width:0}
      .hotel-marketplace-settings-page .market-image-label{display:grid;gap:4px;align-items:start}
      .hotel-marketplace-settings-page .market-image-label small{overflow-wrap:anywhere}
      .hotel-marketplace-settings-page .market-image-row{grid-template-columns:minmax(0,1fr);gap:10px}
      .hotel-marketplace-settings-page .market-image-preview{height:155px;min-height:155px}
      .hotel-marketplace-settings-page .market-image-preview img{height:100%;min-height:155px}
      .hotel-marketplace-settings-page .market-image-actions{display:grid;grid-template-columns:minmax(0,1fr);gap:8px}
      .hotel-marketplace-settings-page .market-image-actions .btn,.hotel-marketplace-settings-page .market-image-actions input{width:100%;min-width:0;min-height:44px;font-size:13px}
      .hotel-marketplace-settings-page .banner-admin-list article{grid-template-columns:minmax(0,1fr);padding:10px}
      .hotel-marketplace-settings-page .banner-admin-thumb{width:100%;height:155px}
      .hotel-marketplace-settings-page .banner-admin-thumb img,.hotel-marketplace-settings-page .banner-admin-thumb video{width:100%;height:100%;object-fit:cover}
      .hotel-marketplace-settings-page .banner-admin-list article .admin-record-actions{display:grid;grid-template-columns:minmax(0,1fr);width:100%}
      .hotel-marketplace-settings-page .banner-admin-list article .admin-record-actions .btn{width:100%;min-height:44px}
      .hotel-marketplace-settings-page .featured-admin-intro{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:12px;padding:16px}
      .hotel-marketplace-settings-page .featured-admin-intro h3{font-size:19px}
      .hotel-marketplace-settings-page .featured-admin-intro p{font-size:11px}
      .hotel-marketplace-settings-page .featured-admin-intro>strong{font-size:25px;min-width:52px}
      .hotel-marketplace-settings-page .featured-admin-list article{grid-template-columns:76px minmax(0,1fr);gap:9px;padding:9px}
      .hotel-marketplace-settings-page .featured-admin-info{min-width:0;overflow-wrap:anywhere}
      .hotel-marketplace-settings-page .featured-admin-toggle{grid-column:1/-1;grid-row:auto;min-height:42px}
      .hotel-marketplace-settings-page .featured-admin-order{grid-column:1/-1;grid-row:auto;display:flex;align-items:center;gap:10px}
      .hotel-marketplace-settings-page .featured-admin-order input{width:100%;max-width:120px;min-height:42px}
      .hotel-marketplace-settings-page .destination-admin-grid{grid-template-columns:minmax(0,1fr)}
      .hotel-marketplace-settings-page .destination-card-actions{grid-template-columns:repeat(3,minmax(0,1fr));gap:5px}
      .hotel-marketplace-settings-page .destination-card-actions button{min-width:0;min-height:40px;font-size:9px}
      .hotel-marketplace-settings-page .edit-actions,.hotel-marketplace-settings-page .admin-record-actions{display:grid;grid-template-columns:minmax(0,1fr)}
      .hotel-marketplace-settings-page .edit-actions .btn,.hotel-marketplace-settings-page .admin-record-actions .btn{width:100%;min-height:44px;justify-content:center}
      .hotel-marketplace-settings-page .layout-preview{padding:10px}
      .hotel-marketplace-settings-page .layout-preview>div{padding:14px 8px;font-size:10px}
      .hotel-marketplace-settings-page .layout-preview .lp-hero{padding:22px 8px}
      .hotel-marketplace-settings-page .layout-preview .lp-row{grid-template-columns:minmax(0,1fr)}
      .hotel-marketplace-settings-page .store-control-footer{padding:13px;font-size:11px}
      .hotel-marketplace-settings-page .store-control-footer a{margin-left:0;margin-top:6px}
    }
    @media(max-width:360px){
      .hotel-marketplace-settings-page .market-hero-metrics{grid-template-columns:1fr}
      .hotel-marketplace-settings-page .featured-admin-intro{grid-template-columns:minmax(0,1fr)}
      .hotel-marketplace-settings-page .featured-admin-intro>strong{text-align:left}
      .hotel-marketplace-settings-page .destination-card-actions button{font-size:8px;padding:7px 3px}
    }
   `}</style>
    </div>
  </AppShell>
}
