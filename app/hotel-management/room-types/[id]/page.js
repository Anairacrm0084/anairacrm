'use client';
import {useEffect,useState} from 'react';
import {useParams,useRouter} from 'next/navigation';
import {supabase} from '../../../../lib/supabase';
import MediaPicker from '../../../../components/anaira/MediaPicker';
import {SetupShell,SetupHeader,Field,SelectField,useTenantProperty,hospitalityMeta} from '../../setup-components';

export default function AccommodationDetailEditor(){
 const ctx=useTenantProperty(),params=useParams(),router=useRouter();
 const id=params?.id||'';
 const [rid,setRid]=useState(null),[requestedType,setRequestedType]=useState('hotel'),[form,setForm]=useState(null),[source,setSource]=useState('hms'),[msg,setMsg]=useState(''),[loading,setLoading]=useState(true);
 const propertyId=rid||ctx.rid; const m=hospitalityMeta(requestedType);
 const set=(k,v)=>setForm(x=>({...x,[k]:v}));
 useEffect(()=>{if(typeof window==='undefined')return;const q=new URLSearchParams(window.location.search);setRid(q.get('property')||ctx.rid||null);setRequestedType(q.get('type')||ctx.hospitalityType||'hotel')},[ctx.rid,ctx.hospitalityType]);
 useEffect(()=>{if(!propertyId||!id)return; (async()=>{setLoading(true);let {data,error}=await supabase.from('hms_room_types').select('*').eq('id',id).eq('restaurant_id',propertyId).maybeSingle();
   if(!data && requestedType==='camp') { const q=await supabase.from('camp_unit_types').select('*').eq('id',id).eq('restaurant_id',propertyId).maybeSingle(); data=q.data;error=q.error;if(data)setSource('legacy'); }
   if(error){setMsg(error.message)}
   else if(data){setForm({...data,amenities:Array.isArray(data.amenities)?data.amenities.join(', '):data.amenities||'',image_urls:Array.isArray(data.image_urls)?data.image_urls:data.photos||[]})}
   else setMsg(`${m.unitType} not found.`); setLoading(false); })()},[propertyId,id,requestedType]);
 async function save(e){e.preventDefault();if(!form||!propertyId)return;setMsg('Saving…');
   const payload={name:form.name,code:form.code,description:form.description,short_description:form.short_description,max_adults:Number(form.max_adults||1),max_children:Number(form.max_children||0),number_of_beds:Number(form.number_of_beds||1),bed_type:form.bed_type,base_rate:Number(form.base_rate||0),weekend_price:Number(form.weekend_price||0),extra_adult_price:Number(form.extra_adult_price??form.extra_adult??0),extra_child_price:Number(form.extra_child_price??form.extra_child??0),tax_percent:Number(form.tax_percent||0),amenities:(Array.isArray(form.amenities)?form.amenities:String(form.amenities||'').split(',')).map(x=>String(x).trim()).filter(Boolean),image_urls:Array.isArray(form.image_urls)?form.image_urls:[],active:form.active!==false};
   let q;
   if(source==='legacy' && requestedType==='camp'){
     q=await supabase.from('camp_unit_types').update({name:payload.name,code:payload.code,description:payload.description,short_description:payload.short_description,max_adults:payload.max_adults,max_children:payload.max_children,max_guests:payload.max_adults+payload.max_children,number_of_beds:payload.number_of_beds,bed_type:payload.bed_type,base_rate:payload.base_rate,extra_adult_price:payload.extra_adult_price,extra_child_price:payload.extra_child_price,amenities:payload.amenities,image_urls:payload.image_urls,active:payload.active}).eq('id',id).eq('restaurant_id',propertyId);
   }else{
     q=await supabase.from('hms_room_types').update({...payload,hospitality_type:requestedType}).eq('id',id).eq('restaurant_id',propertyId);
   }
   if(q.error){setMsg(q.error.message);return} setMsg(`${m.unitType} details saved.`);
 }
 if(ctx.loading||loading)return <SetupShell active="/hotel-management" title={`${m.unitType} Details`} subtitle="Edit complete customer-facing accommodation details." ctx={ctx}><div className="notice">Loading details…</div></SetupShell>;
 if(!form)return <SetupShell active="/hotel-management" title={`${m.unitType} Details`} subtitle="Edit complete customer-facing accommodation details." ctx={ctx}><div className="notice error">{msg||'Details not found.'}</div></SetupShell>;
 return <SetupShell active="/hotel-management" title={`${m.unitType} Details`} subtitle={`Manage the full public detail page for this ${m.unit.toLowerCase()}.`} ctx={ctx}>
  <SetupHeader title={`${form.name||m.unitType} — Details`} subtitle="Photos, description, capacity, amenities and pricing" ctx={ctx} rid={propertyId} setRid={setRid} actions={<button className="btn" onClick={()=>router.push(`/book/${propertyId}?stay_type=${requestedType}`)}>View Public Page</button>}/>
  <form className="card admin-form" onSubmit={save}>
   <SelectField label="Hospitality Type" value={requestedType} onChange={()=>{}} options={[[requestedType,m.label]]}/>
   <Field label={`${m.unitType} Name`} value={form.name} onChange={v=>set('name',v)}/><Field label="Code" value={form.code} onChange={v=>set('code',v)}/>
   <Field label="Base Price" value={form.base_rate} onChange={v=>set('base_rate',v)} type="number" min="0"/><Field label="Weekend Price" value={form.weekend_price} onChange={v=>set('weekend_price',v)} type="number" min="0"/>
   <Field label="Maximum Adults" value={form.max_adults} onChange={v=>set('max_adults',v)} type="number" min="1"/><Field label="Maximum Children" value={form.max_children} onChange={v=>set('max_children',v)} type="number" min="0"/>
   <Field label="Bed Type" value={form.bed_type} onChange={v=>set('bed_type',v)}/><Field label="Number of Beds" value={form.number_of_beds} onChange={v=>set('number_of_beds',v)} type="number" min="1"/>
   <Field label="Extra Adult Price" value={form.extra_adult_price??form.extra_adult??0} onChange={v=>set('extra_adult_price',v)} type="number" min="0"/><Field label="Extra Child Price" value={form.extra_child_price??form.extra_child??0} onChange={v=>set('extra_child_price',v)} type="number" min="0"/>
   <Field label="Tax %" value={form.tax_percent||0} onChange={v=>set('tax_percent',v)} type="number" min="0" max="100"/>
   <Field label="Short Description" value={form.short_description} onChange={v=>set('short_description',v)} full/>
   <Field label="Amenities (comma separated)" value={Array.isArray(form.amenities)?form.amenities.join(', '):form.amenities} onChange={v=>set('amenities',v)} full/>
   <div className="full"><MediaPicker value={Array.isArray(form.image_urls)?form.image_urls:[]} multiple restaurantId={propertyId} folder={`hotel/${requestedType}-details`} label={`${m.unitType} Images`} onChange={v=>set('image_urls',v)}/></div>
   <Field label="Full Description" value={form.description} onChange={v=>set('description',v)} full/>
   <div className="full"><button className="btn primary">Save Details</button>{msg&&<span style={{marginLeft:10,fontSize:11}}>{msg}</span>}</div>
  </form>
 </SetupShell>
}
