'use client';
import {useEffect,useRef,useState} from 'react';
import {supabase} from '../../lib/supabase';
import {AppShell,Header,Section,Pill,Table} from '../components';

export const HOSPITALITY_META={
 hotel:{label:'Hotel',plural:'Hotels',unit:'Room',units:'Rooms',unitType:'Room Type',unitTypes:'Room Types',inventory:'Room Inventory',dashboard:'Hotel Dashboard',profile:'Hotel Profile',pms:'PMS / Front Desk',housekeeping:'Housekeeping',reservation:'Reservations',booking:'Hotel Booking Engine'},
 camp:{label:'Camping',plural:'Camps',unit:'Camp / Tent',units:'Camps / Tents',unitType:'Camp / Tent Type',unitTypes:'Camp / Tent Types',inventory:'Camp Inventory',dashboard:'Camping Dashboard',profile:'Camping Property',pms:'Camp Front Desk',housekeeping:'Camp Housekeeping',reservation:'Reservations',booking:'Camping Booking Engine'},
 homestay:{label:'Homestay',plural:'Homestays',unit:'Accommodation',units:'Accommodations',unitType:'Accommodation Type',unitTypes:'Accommodation Types',inventory:'Homestay Inventory',dashboard:'Homestay Dashboard',profile:'Homestay Property',pms:'Homestay Front Desk',housekeeping:'Homestay Housekeeping',reservation:'Reservations',booking:'Homestay Booking Engine'},
 guest_house:{label:'Guest House',plural:'Guest Houses',unit:'Accommodation',units:'Accommodations',unitType:'Accommodation Type',unitTypes:'Accommodation Types',inventory:'Guest House Inventory',dashboard:'Guest House Dashboard',profile:'Guest House Property',pms:'Guest House Front Desk',housekeeping:'Guest House Housekeeping',reservation:'Reservations',booking:'Guest House Booking Engine'},
 cottage:{label:'Cottage',plural:'Cottages',unit:'Cottage',units:'Cottages',unitType:'Cottage Type',unitTypes:'Cottage Types',inventory:'Cottage Inventory',dashboard:'Cottage Dashboard',profile:'Cottage Property',pms:'Cottage Front Desk',housekeeping:'Cottage Housekeeping',reservation:'Reservations',booking:'Cottage Booking Engine'}
};
export function hospitalityMeta(type){return HOSPITALITY_META[type]||HOSPITALITY_META.hotel}

export function useTenantProperty(){
 const readQuery=()=>{
  if(typeof window==='undefined') return {property:'',type:''};
  const q=new URLSearchParams(window.location.search);
  return {property:q.get('property')||'',type:q.get('type')||''};
 };
 const initial=readQuery();
 const [query,setQuery]=useState(initial);
 const [ctx,setCtx]=useState({loading:true,session:null,super:false,rid:null,properties:[],hospitalityType:'hotel',hospitalityTypes:['hotel'],error:'',selectProperty:null});
 const requestSeq=useRef(0);

 useEffect(()=>{
  let alive=true;
  const seq=++requestSeq.current;
  (async()=>{
   const {data:{session}}=await supabase.auth.getSession();
   if(!alive||seq!==requestSeq.current)return;
   if(!session){setCtx(x=>({...x,loading:false,session:null}));return;}
   const {data:p,error}=await supabase.from('anaira_my_profile').select('restaurant_id,is_super_admin,role').eq('id',session.user.id).maybeSingle();
   if(!alive||seq!==requestSeq.current)return;
   if(error){setCtx(x=>({...x,loading:false,session,error:error.message}));return;}
   const isSuper=p?.is_super_admin===true||p?.role==='super_admin';
   let properties=[];
   if(isSuper){
    const q=await supabase.from('restaurants').select('id,name,status,business_type,hospitality_type,hospitality_types').order('name');
    if(!alive||seq!==requestSeq.current)return;
    properties=q.data||[];
   }else if(p?.restaurant_id){
    const q=await supabase.from('restaurants').select('id,name,status,business_type,hospitality_type,hospitality_types').eq('id',p.restaurant_id).maybeSingle();
    if(!alive||seq!==requestSeq.current)return;
    if(q.data)properties=[q.data];
   }
   // Always read the latest URL after the async property query. This prevents
   // the initial request from overwriting a property the Super Admin selected
   // while the first context load was still in flight.
   const latest=readQuery();
   const selectedRid=isSuper?(latest.property||p?.restaurant_id||''):p?.restaurant_id||null;
   const selected=properties.find(x=>x.id===selectedRid);
   const selectedTypes=Array.isArray(selected?.hospitality_types)&&selected.hospitality_types.length
    ?selected.hospitality_types
    :[selected?.hospitality_type||'hotel'];
   const activeType=selectedTypes.includes(latest.type)?latest.type:selectedTypes[0];
   if(alive&&seq===requestSeq.current){
    setQuery(latest);
    setCtx({loading:false,session,super:isSuper,rid:selectedRid,properties,hospitalityType:activeType,hospitalityTypes:selectedTypes,error:'',selectProperty:null});
   }
  })();
  return()=>{alive=false};
 },[query.property,query.type]);

 const selectProperty=(value)=>{
  const nextId=value||null;
  const selected=ctx.properties.find(x=>x.id===nextId);
  const types=Array.isArray(selected?.hospitality_types)&&selected.hospitality_types.length
   ?selected.hospitality_types
   :[selected?.hospitality_type||'hotel'];
  const currentType=readQuery().type;
  const nextType=types.includes(currentType)?currentType:types[0];
  const nextQuery={property:nextId||'',type:nextType||''};

  // Update React state first. The setup page stays mounted and immediately
  // switches its data source to the selected property.
  setCtx(x=>({...x,rid:nextId,hospitalityTypes:types,hospitalityType:nextType,error:''}));
  setQuery(nextQuery);

  if(typeof window!=='undefined'){
   const u=new URL(window.location.href);
   if(nextId)u.searchParams.set('property',nextId);else u.searchParams.delete('property');
   if(nextType)u.searchParams.set('type',nextType);else u.searchParams.delete('type');
   // replaceState intentionally avoids adding a browser-history entry.
   window.history.replaceState(window.history.state,'',u.toString());
  }
 };
 return {...ctx,selectProperty};
}
export function SetupHeader({title,subtitle,ctx,rid,setRid,actions}){
 const selectProperty=(v)=>{
  const value=v||'';
  if(ctx?.selectProperty) ctx.selectProperty(value);
  if(setRid) setRid(value||null);
 };
 return <Header eyebrow="ANAIRA HOSPITALITY SETUP" title={title} subtitle={subtitle} actions={<div style={{display:'flex',gap:7,alignItems:'center',flexWrap:'wrap'}}>
  {ctx.super&&<select value={rid||''} onChange={e=>selectProperty(e.target.value)} style={{padding:'9px',border:'1px solid #d8d0bb',borderRadius:8,minWidth:220}}>
   <option value="">Select property</option>{ctx.properties.map(p=><option key={p.id} value={p.id}>{p.name}</option>)}
  </select>}
  {actions}
 </div>}/>
}
export function Field({label,value,onChange,type='text',children,full=false,min,max,step}){return <label className={full?'full':''} style={{display:'grid',gap:6,fontSize:11,fontWeight:700}}><span>{label}</span>{children||<input type={type} value={value??''} min={min} max={max} step={step} onChange={e=>onChange(e.target.value)} />}</label>}
export function SelectField({label,value,onChange,options,full=false}){return <label className={full?'full':''} style={{display:'grid',gap:6,fontSize:11,fontWeight:700}}><span>{label}</span><select value={value??''} onChange={e=>onChange(e.target.value)}>{options.map(([v,t])=><option key={v} value={v}>{t}</option>)}</select></label>}
export function SetupShell({children,active,title,subtitle,ctx}){if(ctx.loading)return <AppShell><div className="notice">Loading property context…</div></AppShell>; if(!ctx.session)return <AppShell><div className="auth-card"><h1>Sign in required</h1><a className="btn primary" href="/login">Open CRM Login</a></div></AppShell>; if(!ctx.super&&!ctx.rid)return <AppShell><div className="notice error">No property is assigned to this account.</div></AppShell>; return <AppShell active={active}>{children}</AppShell>}
export function SetupNav({hospitalityType='hotel'}){
 const m=hospitalityMeta(hospitalityType);
 const property=typeof window!=='undefined'?new URLSearchParams(window.location.search).get('property'):'';
 const q=`?${property?`property=${encodeURIComponent(property)}&`:''}type=${encodeURIComponent(hospitalityType)}`;
 return <Section title={`${m.label} Management Setup`} meta="Canonical HMS master data"><div className="module-grid">
  <a className="module-card" href={`/hotel-management${q}`}><h3>{m.dashboard}</h3><p>Operational dashboard using the same ANAIRA hospitality master data.</p></a>
  <a className="module-card" href={`/hotel-management/setup${q}`}><h3>{m.profile}</h3><p>Identity, address, policies, tax, media and operating timings.</p></a>
  <a className="module-card" href={`/hotel-management/room-types${q}`}><h3>{m.unitTypes}</h3><p>Create categories with capacity, pricing, amenities and photos.</p></a>
  <a className="module-card" href={`/hotel-management/rooms${q}`}><h3>{m.units}</h3><p>Create every physical sellable unit and its live status.</p></a>
  <a className="module-card" href={`/hotel-management/inventory${q}`}><h3>{m.inventory}</h3><p>Automatic date-wise inventory from physical units and bookings.</p></a>
  <a className="module-card" href={`/hotel-management/rates${q}`}><h3>Rate Plans</h3><p>Per-unit or per-person pricing, weekend, seasonal and stay rules.</p></a>
  <a className="module-card" href={`/booking?type=${encodeURIComponent(hospitalityType)}`}><h3>{m.reservation}</h3><p>Same booking control center, payment and confirmation lifecycle.</p></a>
  <a className="module-card" href={`/pms?type=${encodeURIComponent(hospitalityType)}`}><h3>{m.pms}</h3><p>Check-in, stay lifecycle, unit assignment and checkout.</p></a>
  <a className="module-card" href={`/housekeeping?type=${encodeURIComponent(hospitalityType)}`}><h3>{m.housekeeping}</h3><p>Cleaning, inspection, readiness and maintenance workflow.</p></a>
  <a className="module-card" href={`/store-builder?kind=${encodeURIComponent(hospitalityType)}`}><h3>My {m.label} Store</h3><p>Same premium preview, branding, banners, SEO and publishing controls.</p></a>
 </div></Section>
}
export function ensureSelected(ctx,rid){return rid||(!ctx.super?ctx.rid:null)}

export {Section,Pill,Table};
