'use client';
import {useEffect,useMemo,useState} from 'react';
import {Section} from '../../components';
import {useTenantProperty,SetupHeader,SetupShell,Field,SelectField,SetupNav,ensureSelected,hospitalityMeta} from '../setup-components';
import {supabase} from '../../../lib/supabase';
import MediaPicker from '../../../components/anaira/MediaPicker';
import HotelMediaUpload from '../../../components/anaira/HotelMediaUpload';

const defaults={hotel_name:'',hospitality_type:'hotel',hospitality_types:['hotel'],short_name:'',legal_name:'',star_rating:'',phone:'',whatsapp:'',email:'',website:'',address:'',landmark:'',city:'',state:'',country:'India',postal_code:'',latitude:'',longitude:'',currency:'INR',timezone:'Asia/Kolkata',check_in_time:'12:00',check_out_time:'11:00',tax_percent:0,logo_url:'',cover_image_url:'',gallery:[],description:'',early_checkin_policy:'',late_checkout_policy:'',cancellation_policy:'',child_policy:'',pet_policy:'',smoking_policy:'',booking_engine_enabled:false,crm_integration_enabled:true,marketplace_background_media_type:'image',marketplace_background_image_url:'',marketplace_background_video_url:'',marketplace_background_mobile_media_type:'image',marketplace_background_mobile_image_url:'',marketplace_background_mobile_video_url:'',marketplace_background_overlay:0.48,marketplace_destination_id:'',global_marketplace_background_media_type:'image',global_marketplace_background_image_url:'',global_marketplace_background_video_url:'',global_marketplace_background_mobile_media_type:'image',global_marketplace_background_mobile_image_url:'',global_marketplace_background_mobile_video_url:'',global_marketplace_background_overlay:0.48,nearby_destinations:[],nearby_activities:[],hospitality_highlights:[]};
const required=['hotel_name','phone','email','address','city','state','country','postal_code','currency','timezone','check_in_time','check_out_time'];

const ICONS_FALLBACK={hotel:['🛏️','🍽️','🧖','🚗'],camp:['⛺','🔥','🥾','🌲'],homestay:['🏡','🍲','🧺','🧑‍🤝‍🧑'],guest_house:['🛏️','☕','🚗','📶'],cottage:['🛖','🔥','🌲','🌄']};
function ExperienceEditor({title,subtitle,items,onChange,restaurantId,folder,kind,icons,types}){
 const add=()=>onChange([...(items||[]),{name:'',description:'',distance:'',image:'',icon:icons?.[0]||'✦',hospitality_type:types?.[0]||''}]);
 const update=(i,k,v)=>onChange((items||[]).map((x,n)=>n===i?{...x,[k]:v}:x));
 const remove=(i)=>onChange((items||[]).filter((_,n)=>n!==i));
 return <Section title={title} meta={subtitle}>
   <div className="full" style={{display:'grid',gap:12}}>
    {(items||[]).map((x,i)=><div key={i} style={{display:'grid',gridTemplateColumns:'90px 150px 1fr 1fr 1fr auto',gap:10,alignItems:'start',padding:14,border:'1px solid #e5dccf',borderRadius:14,background:'#fffdf9'}}>
      <MediaPicker value={x.image||''} restaurantId={restaurantId} folder={folder} label="Photo" onChange={v=>update(i,'image',v)}/>
      <SelectField label="Hospitality Type" value={x.hospitality_type||types?.[0]||''} onChange={v=>update(i,'hospitality_type',v)} options={(types||[]).map(t=>[t,hospitalityMeta(t).label])}/><Field label="Name" value={x.name||''} onChange={v=>update(i,'name',v)}/>
      <Field label="Distance" value={x.distance||''} onChange={v=>update(i,'distance',v)}/>
      <Field label="Icon / Description" value={x.icon||''} onChange={v=>update(i,'icon',v)} hint={x.description||'Short description'}/>
      <button type="button" className="btn" onClick={()=>remove(i)}>Remove</button>
      <div style={{gridColumn:'2/-1'}}><Field label="Description" value={x.description||''} onChange={v=>update(i,'description',v)} full/></div>
    </div>)}
    <button type="button" className="btn primary" onClick={add}>+ Add {kind}</button>
   </div>
 </Section>
}

export default function HotelSetup(){
 const ctx=useTenantProperty(); const [rid,setRid]=useState(null); const [destinations,setDestinations]=useState([]);
const [form,setForm]=useState(defaults); const [msg,setMsg]=useState(''); const [error,setError]=useState(''); const [saving,setSaving]=useState(false); const id=ensureSelected(ctx,rid);
useEffect(()=>{if(!id||ctx.loading)return;setForm(x=>({...x,hospitality_types:Array.isArray(ctx.hospitalityTypes)&&ctx.hospitalityTypes.length?ctx.hospitalityTypes:[ctx.hospitalityType].filter(Boolean),hospitality_type:ctx.hospitalityType||''}));},[id,ctx.hospitalityType,JSON.stringify(ctx.hospitalityTypes)]); const selectedTypes=Array.isArray(form.hospitality_types)&&form.hospitality_types.length?form.hospitality_types:[form.hospitality_type||ctx.hospitalityType||'hotel']; const meta=hospitalityMeta(selectedTypes[0]);
 useEffect(()=>{if(!id)return;(async()=>{setMsg('');setError('');const {data,error}=await supabase.from('hms_settings').select('*').eq('restaurant_id',id).maybeSingle();if(error){setError(error.message);return}
const {data:restaurantType}=await supabase.from('restaurants').select('hospitality_type,business_type,nearby_destinations,nearby_activities,hospitality_highlights').eq('id',id).maybeSingle();
const {data:hotelStore}=await supabase.from('anaira_platform_stores').select('id').eq('store_type','hotel').eq('enabled',true).eq('published',true).maybeSingle();
const {data:destinationRows}=hotelStore?await supabase.from('anaira_hotel_store_destinations').select('id,name,subtitle').eq('store_id',hotelStore.id).eq('active',true).order('display_order'):{data:[]};
setDestinations(destinationRows||[]);
const {data:platformRows}=await supabase.from('anaira_platform_settings').select('key,value').in('key',['hotel_home_background_media_type','hotel_home_background_image','hotel_home_background_video','hotel_home_background_mobile_media_type','hotel_home_background_mobile_image','hotel_home_background_mobile_video','hotel_home_background_overlay']);
const pm={};(platformRows||[]).forEach(r=>pm[r.key]=r.value?.value??r.value);
setForm({...defaults,...(data||{}),hospitality_type:restaurantType?.hospitality_type||'',hospitality_types:Array.isArray(restaurantType?.hospitality_types)&&restaurantType.hospitality_types.length?restaurantType.hospitality_types:[restaurantType?.hospitality_type||'hotel'],
 global_marketplace_background_media_type:pm.hotel_home_background_media_type||'image',
 global_marketplace_background_image_url:pm.hotel_home_background_image||'',
 global_marketplace_background_video_url:pm.hotel_home_background_video||'',
 global_marketplace_background_mobile_media_type:pm.hotel_home_background_mobile_media_type||'image',
 global_marketplace_background_mobile_image_url:pm.hotel_home_background_mobile_image||'',
 global_marketplace_background_mobile_video_url:pm.hotel_home_background_mobile_video||'',
 global_marketplace_background_overlay:pm.hotel_home_background_overlay??0.48,
 star_rating:data?.star_rating??'',tax_percent:data?.tax_percent??0, gallery:Array.isArray(data?.gallery)?data.gallery:[],
 nearby_destinations:Array.isArray(restaurantType?.nearby_destinations)?restaurantType.nearby_destinations:[],
 nearby_activities:Array.isArray(restaurantType?.nearby_activities)?restaurantType.nearby_activities:[],
 hospitality_highlights:Array.isArray(restaurantType?.hospitality_highlights)?restaurantType.hospitality_highlights:[]});})()},[id]);
 const set=(k,v)=>setForm(x=>({...x,[k]:v}));
 const missing=useMemo(()=>required.filter(k=>!String(form[k]??'').trim()),[form]);
 const completeness=Math.round(((required.length-missing.length)/required.length)*100);
 async function save(e){e.preventDefault();setMsg('');setError('');if(!id){setError('Select a property first.');return}if(missing.length){setError(`Complete required property fields: ${missing.map(k=>k.replaceAll('_',' ')).join(', ')}.`);return}const lat=form.latitude===''?null:Number(form.latitude),lng=form.longitude===''?null:Number(form.longitude),tax=Number(form.tax_percent||0),stars=form.star_rating===''?null:Number(form.star_rating);if(Number.isNaN(lat)||Number.isNaN(lng)||Number.isNaN(tax)||Number.isNaN(stars)){setError('Latitude, longitude, star rating and tax must be valid numbers.');return}if(lat!==null&&(lat<-90||lat>90)||lng!==null&&(lng<-180||lng>180)){setError('Latitude must be -90 to 90 and longitude -180 to 180.');return}if(tax<0||tax>100||stars!==null&&(stars<0||stars>5)){setError('Tax must be 0–100% and star rating must be 0–5.');return}setSaving(true);const types=Array.isArray(form.hospitality_types)&&form.hospitality_types.length?form.hospitality_types:['hotel']; const experienceDestinations=Array.isArray(form.nearby_destinations)?form.nearby_destinations:[],experienceActivities=Array.isArray(form.nearby_activities)?form.nearby_activities:[],experienceHighlights=Array.isArray(form.hospitality_highlights)?form.hospitality_highlights:[];
const payload={
  marketplace_destination_id:form.marketplace_destination_id||null,...form,restaurant_id:id,hospitality_types:types,latitude:lat,longitude:lng,tax_percent:tax,star_rating:stars,marketplace_background_overlay:Number(form.marketplace_background_overlay||0),gallery:Array.isArray(form.gallery)?form.gallery:[]};
 delete payload.nearby_destinations;delete payload.nearby_activities;delete payload.hospitality_highlights;delete payload.id;delete payload.created_at;delete payload.updated_at;const {error:typeError}=await supabase.from('restaurants').update({hospitality_type:types[0],hospitality_types:types,nearby_destinations:experienceDestinations,nearby_activities:experienceActivities,hospitality_highlights:experienceHighlights}).eq('id',id);if(typeError){setSaving(false);setError(typeError.message);return}
// Super Admin is the authority for plugin activation. Keep plugin state in
// sync with the property's selected hospitality types so a saved profile and
// the Business Admin sidebar cannot drift apart.
if(ctx.super){
 const uid=(await supabase.auth.getUser()).data.user?.id;
 const pluginMeta={
  hotel:['hotel-management-suite','Anaira Hotel Management System','Hotel'],
  camp:['camping-management','Anaira Camping Management System','Camping'],
  homestay:['homestay-management','Anaira Homestay Management System','Homestay'],
  guest_house:['guest-house-management','Anaira Guest House Management System','Guest House'],
  cottage:['cottage-management','Anaira Cottage Management System','Cottage']
 };
 for(const type of Object.keys(pluginMeta)){
  const [plugin_code,display_name,category]=pluginMeta[type];
  const enabled=types.includes(type);
  const q=await supabase.from('restaurant_plugins').upsert({restaurant_id:id,plugin_code,plugin_slug:plugin_code,display_name,category,description:`Canonical ${category} master data and operations`,feature_kind:'feature',enabled,activated_by:enabled?uid:null,activated_at:enabled?new Date().toISOString():null,disabled_at:enabled?null:new Date().toISOString(),config:{schema_version:1,settings:{}}},{onConflict:'restaurant_id,plugin_code'});
  if(q.error){setSaving(false);setError(q.error.message);return}
 }
}
const {error:e2}=await supabase.from('hms_settings').upsert(payload,{onConflict:'restaurant_id'});
if(e2){setSaving(false);setError(e2.message);return}
if(ctx.super){
 const uid=(await supabase.auth.getUser()).data.user?.id;
 const globalMedia={
  hotel_home_background_media_type:form.global_marketplace_background_media_type||'image',
  hotel_home_background_image:form.global_marketplace_background_image_url||'',
  hotel_home_background_video:form.global_marketplace_background_video_url||'',
  hotel_home_background_mobile_media_type:form.global_marketplace_background_mobile_media_type||'image',
  hotel_home_background_mobile_image:form.global_marketplace_background_mobile_image_url||'',
  hotel_home_background_mobile_video:form.global_marketplace_background_mobile_video_url||'',
  hotel_home_background_overlay:Number(form.global_marketplace_background_overlay||0)
 };
 for(const [key,value] of Object.entries(globalMedia)){const q=await supabase.from('anaira_platform_settings').upsert({key,value:{value},updated_by:uid},{onConflict:'key'});if(q.error){setSaving(false);setError(q.error.message);return}}
}
setSaving(false);setMsg(`${meta.label} property profile saved successfully.`);}
 return <SetupShell active="/hotel-management" title={`${meta.label} Property`} subtitle={`Business Admin property master: identity, contact, location, policies, media and booking settings.`} ctx={ctx}>
  <SetupHeader title={`${meta.label} Property`} subtitle="Property master data" ctx={ctx} rid={rid} setRid={setRid} actions={<span className="pill">Profile {completeness}% complete</span>}/>
  {!id?<div className="notice">Select a property to configure the hotel.</div>:<>
   <Section title="Property Identity" meta="Business Admin master data"><form className="card admin-form" onSubmit={save}>
    <Field label={`${meta.label} Name *`} value={form.hotel_name} onChange={v=>set('hotel_name',v)}/><Field label="Short Name" value={form.short_name} onChange={v=>set('short_name',v)}/><Field label="Legal Name" value={form.legal_name} onChange={v=>set('legal_name',v)}/><div style={{gridColumn:"1/-1",display:"grid",gap:8}}><span style={{fontSize:11,fontWeight:700}}>Property / Hospitality Types *</span><div style={{display:"flex",gap:10,flexWrap:"wrap"}}>{[["hotel","Hotel"],["camp","Camping / Camp"],["homestay","Homestay"],["guest_house","Guest House"],["cottage","Cottage"]].map(([v,l])=><label key={v} style={{display:"flex",alignItems:"center",gap:7,padding:"10px 12px",border:"1px solid #d8d0bb",borderRadius:10,cursor:"pointer"}}><input type="checkbox" checked={(form.hospitality_types||[]).includes(v)} onChange={e=>{const next=e.target.checked?[...(form.hospitality_types||[]),v]:(form.hospitality_types||[]).filter(x=>x!==v); if(!next.length)return; setForm(x=>({...x,hospitality_types:next,hospitality_type:next[0]}))}}/><span>{l}</span></label>)}</div><small style={{opacity:.65}}>Select every business type this property offers. One Store ID will publish all selected types.</small></div><SelectField label="Star Rating" value={form.star_rating} onChange={v=>set('star_rating',v)} options={[["","Not specified"],["1","1 Star"],["2","2 Star"],["3","3 Star"],["4","4 Star"],["5","5 Star"]]}/>
    <SelectField label="Marketplace Destination" value={form.marketplace_destination_id||''} onChange={v=>set('marketplace_destination_id',v)} options={[[ '', 'No destination assigned'], ...destinations.map(d=>[d.id,d.name])]} />
    <Field label="Description" value={form.description} onChange={v=>set('description',v)} full/>
    <Section title="Contact & Location" meta="Used by booking, marketplace and guest communication"><Field label="Phone *" value={form.phone} onChange={v=>set('phone',v)}/><Field label="WhatsApp" value={form.whatsapp} onChange={v=>set('whatsapp',v)}/><Field label="Email *" value={form.email} onChange={v=>set('email',v)} type="email"/><Field label="Website" value={form.website} onChange={v=>set('website',v)}/><Field label="Address *" value={form.address} onChange={v=>set('address',v)} full/><Field label="Landmark" value={form.landmark} onChange={v=>set('landmark',v)}/><Field label="City *" value={form.city} onChange={v=>set('city',v)}/><Field label="State *" value={form.state} onChange={v=>set('state',v)}/><Field label="Country *" value={form.country} onChange={v=>set('country',v)}/><Field label="PIN / Postal Code *" value={form.postal_code} onChange={v=>set('postal_code',v)}/><Field label="Latitude" value={form.latitude} onChange={v=>set('latitude',v)} type="number"/><Field label="Longitude" value={form.longitude} onChange={v=>set('longitude',v)} type="number"/></Section>
    <Section title="Operations & Tax" meta="Core property defaults"><Field label="Currency *" value={form.currency} onChange={v=>set('currency',v)}/><Field label="Timezone *" value={form.timezone} onChange={v=>set('timezone',v)}/><Field label="Check-in *" value={form.check_in_time||'12:00'} onChange={v=>set('check_in_time',v)} type="time"/><Field label="Check-out *" value={form.check_out_time||'11:00'} onChange={v=>set('check_out_time',v)} type="time"/><Field label="GST / Tax %" value={form.tax_percent} onChange={v=>set('tax_percent',v)} type="number"/></Section>
    <Section title="Policies" meta="Shown during booking and used by operations"><Field label="Early Check-in Policy" value={form.early_checkin_policy} onChange={v=>set('early_checkin_policy',v)} full/><Field label="Late Checkout Policy" value={form.late_checkout_policy} onChange={v=>set('late_checkout_policy',v)} full/><Field label="Cancellation Policy" value={form.cancellation_policy} onChange={v=>set('cancellation_policy',v)} full/><Field label="Child Policy" value={form.child_policy} onChange={v=>set('child_policy',v)} full/><Field label="Pet Policy" value={form.pet_policy} onChange={v=>set('pet_policy',v)} full/><Field label="Smoking Policy" value={form.smoking_policy} onChange={v=>set('smoking_policy',v)} full/></Section>
    <Section title="Branding & Media" meta="Real Supabase media library"><MediaPicker value={form.logo_url} restaurantId={id} folder="hotel/logo" label="Hotel Logo" onChange={v=>set('logo_url',v)}/><MediaPicker value={form.cover_image_url} restaurantId={id} folder="hotel/cover" label="Hotel Cover" onChange={v=>set('cover_image_url',v)}/><div style={{gridColumn:'1/-1'}}><MediaPicker value={form.gallery} multiple restaurantId={id} folder="hotel/gallery" label="Hotel Gallery" onChange={v=>set('gallery',v)}/></div></Section>
    <ExperienceEditor title="Nearby Destinations" subtitle="Property-owned places guests can discover nearby. Add name, distance, description and image." items={form.nearby_destinations} onChange={v=>set('nearby_destinations',v)} restaurantId={id} folder={`hospitality/${selectedTypes[0]||''}/nearby-destinations`} kind="Destination" icons={['📍','🏔️','🌲','🏞️']} types={selectedTypes}/>
    <ExperienceEditor title="Nearby Activities & Experiences" subtitle="Property-owned activities with images and type-specific icons." items={form.nearby_activities} onChange={v=>set('nearby_activities',v)} restaurantId={id} folder={`hospitality/${selectedTypes[0]||''}/nearby-activities`} kind="Activity" icons={ICONS_FALLBACK[selectedTypes[0]||'']||['✦']} types={selectedTypes}/>
    <Section title={`${meta.label} Highlights`} meta="Short icon-led selling points shown above the public booking gallery.">
      <div className="full" style={{display:'grid',gap:10}}>{(form.hospitality_highlights||[]).map((x,i)=><div key={i} style={{display:'grid',gridTemplateColumns:'150px 90px 1fr 1fr auto',gap:10,alignItems:'end',padding:12,border:'1px solid #e5dccf',borderRadius:12}}><SelectField label="Hospitality Type" value={x.hospitality_type||selectedTypes[0]||''} onChange={v=>setForm(f=>({...f,hospitality_highlights:f.hospitality_highlights.map((a,n)=>n===i?{...a,hospitality_type:v}:a)}))} options={selectedTypes.map(t=>[t,hospitalityMeta(t).label])}/><Field label="Icon" value={x.icon||''} onChange={v=>setForm(f=>({...f,hospitality_highlights:f.hospitality_highlights.map((a,n)=>n===i?{...a,icon:v}:a)}))}/><Field label="Title" value={x.title||''} onChange={v=>setForm(f=>({...f,hospitality_highlights:f.hospitality_highlights.map((a,n)=>n===i?{...a,title:v}:a)}))}/><Field label="Text" value={x.text||''} onChange={v=>setForm(f=>({...f,hospitality_highlights:f.hospitality_highlights.map((a,n)=>n===i?{...a,text:v}:a)}))}/><button type="button" className="btn" onClick={()=>setForm(f=>({...f,hospitality_highlights:f.hospitality_highlights.filter((_,n)=>n!==i)}))}>Remove</button></div>)}<button type="button" className="btn primary" onClick={()=>setForm(f=>({...f,hospitality_highlights:[...(f.hospitality_highlights||[]),{icon:ICONS_FALLBACK[selectedTypes[0]||'']?.[0]||'✦',title:'',text:'',hospitality_type:selectedTypes[0]||''}]}))}>+ Add Highlight</button></div>
    </Section>
    <Section title="Hotel Marketplace Background Media" meta="Controls the full hero background layer used by the public ANAIRA Hotels experience. Existing property data and layout remain unchanged.">
      <div className="full"><HotelMediaUpload label="Desktop / PC marketplace background" imageValue={form.marketplace_background_image_url} videoValue={form.marketplace_background_video_url} mediaType={form.marketplace_background_media_type} restaurantId={id} folder="hotel/marketplace-background" onTypeChange={v=>set('marketplace_background_media_type',v)} onChange={v=>set(form.marketplace_background_media_type==='video'?'marketplace_background_video_url':'marketplace_background_image_url',v)}/></div>
      <div className="full"><HotelMediaUpload label="Mobile / Tablet marketplace background" imageValue={form.marketplace_background_mobile_image_url} videoValue={form.marketplace_background_mobile_video_url} mediaType={form.marketplace_background_mobile_media_type} restaurantId={id} folder="hotel/marketplace-background-mobile" onTypeChange={v=>set('marketplace_background_mobile_media_type',v)} onChange={v=>set(form.marketplace_background_mobile_media_type==='video'?'marketplace_background_mobile_video_url':'marketplace_background_mobile_image_url',v)}/></div>
      <Field label="Background overlay strength" value={form.marketplace_background_overlay} onChange={v=>set('marketplace_background_overlay',v)} type="number" min="0" max="0.9" step="0.01"/>
    </Section>
    <Section title="Global ANAIRA Hotels Background" meta="Super Admin only: controls the full green hero background on /anaira/hotels. Property data and existing page layout are not changed.">
      {!ctx.super&&<div className="notice">Global marketplace background is controlled by Super Admin. Your property media above remains property-owned.</div>}
      {ctx.super&&<>
        <div className="full"><HotelMediaUpload label="PC / Desktop green-background media" imageValue={form.global_marketplace_background_image_url} videoValue={form.global_marketplace_background_video_url} mediaType={form.global_marketplace_background_media_type} restaurantId={id} folder="hotel/global-marketplace-background" onTypeChange={v=>set('global_marketplace_background_media_type',v)} onChange={v=>set(form.global_marketplace_background_media_type==='video'?'global_marketplace_background_video_url':'global_marketplace_background_image_url',v)}/></div>
        <div className="full"><HotelMediaUpload label="Mobile / Tablet green-background media" imageValue={form.global_marketplace_background_mobile_image_url} videoValue={form.global_marketplace_background_mobile_video_url} mediaType={form.global_marketplace_background_mobile_media_type} restaurantId={id} folder="hotel/global-marketplace-background-mobile" onTypeChange={v=>set('global_marketplace_background_mobile_media_type',v)} onChange={v=>set(form.global_marketplace_background_mobile_media_type==='video'?'global_marketplace_background_mobile_video_url':'global_marketplace_background_mobile_image_url',v)}/></div>
        <Field label="Global background overlay strength" value={form.global_marketplace_background_overlay} onChange={v=>set('global_marketplace_background_overlay',v)} type="number" min="0" max="0.9" step="0.01"/>
      </>}
    </Section>
    <Section title="Booking & CRM" meta="Property-level feature switches"><div className="full" style={{display:'flex',gap:18,flexWrap:'wrap'}}><label><input type="checkbox" checked={!!form.booking_engine_enabled} onChange={e=>set('booking_engine_enabled',e.target.checked)}/> Direct Booking Engine</label><label><input type="checkbox" checked={!!form.crm_integration_enabled} onChange={e=>set('crm_integration_enabled',e.target.checked)}/> CRM Integration</label></div></Section>
    <div className="full"><button className="btn primary" disabled={saving}>{saving?'Saving…':'Save Property Profile'}</button>{msg&&<span style={{marginLeft:10,fontSize:11}}>{msg}</span>}{error&&<div className="notice error" style={{marginTop:10}}>{error}</div>}</div>
   </form></Section>
   <SetupNav hospitalityType={selectedTypes[0]||''}/>
  </>}
 </SetupShell>
}
