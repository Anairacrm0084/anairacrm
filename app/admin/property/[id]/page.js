'use client';
import {useEffect,useState} from 'react';
import {useParams} from 'next/navigation';
import {AppShell,Header,Section,Table,Pill} from '../../../components';
import {supabase} from '../../../../lib/supabase';
const META={hotel:['Hotel','Hotel'],camp:['Camping','Camp / Tent'],homestay:['Homestay','Accommodation'],guest_house:['Guest House','Accommodation'],cottage:['Cottage','Cottage']};
export default function PropertyManage(){
 const {id}=useParams(); const [r,setR]=useState(null),[plugins,setPlugins]=useState([]),[error,setError]=useState('');
 useEffect(()=>{if(!id)return;(async()=>{const [a,b]=await Promise.all([supabase.from('restaurants').select('*').eq('id',id).maybeSingle(),supabase.from('restaurant_plugins').select('plugin_code,enabled,updated_at').eq('restaurant_id',id)]);if(a.error||b.error)setError(a.error?.message||b.error?.message);setR(a.data);setPlugins(b.data||[])})()},[id]);
 if(error)return <AppShell><div className="notice error">{error}</div></AppShell>; if(!r)return <AppShell><div className="notice">Loading property…</div></AppShell>;
 const [label,unit]=META[r.hospitality_type||'hotel']||META.hotel;
 const q=`?property=${id}`;
 return <AppShell active="/properties"><Header eyebrow="PROPERTY MANAGEMENT" title={r.name||label} subtitle={`Manage this ${label.toLowerCase()} property's master setup, store preview and activated plugins.`} actions={<a className="btn" href="/properties">Back to Properties</a>}/>
 <Section title="Property Master" meta={label}><div className="mini-grid">{[['Property Type',label],['Business Type',r.business_type],['Legal Name',r.legal_name],['Phone',r.phone],['Email',r.email],['Address',r.address],['Location',[r.city,r.state,r.postal_code].filter(Boolean).join(', ')],['Status',r.status]].map(([k,v])=><div className="mini" key={k}><span className="kpi-label">{k}</span><b>{v||'—'}</b></div>)}</div></Section>
 <Section title={`${label} Management Setup`} meta="Same canonical Hotel Management layout"><div className="module-grid">
 <a className="module-card" href={`/hotel-management/setup${q}`}><h3>{label} Profile</h3><p>Property identity, policies, tax, timings, media and marketplace settings.</p></a>
 <a className="module-card" href={`/hotel-management/room-types${q}`}><h3>{unit} Types</h3><p>Create every category with capacity, images, amenities and base data.</p></a>
 <a className="module-card" href={`/hotel-management/rooms${q}`}><h3>{unit}s</h3><p>Create physical sellable units exactly like Hotel Rooms.</p></a>
 <a className="module-card" href={`/hotel-management/rates${q}`}><h3>Rate Plans</h3><p>Per-unit or per-person pricing, weekend, seasonal and stay rules.</p></a>
 <a className="module-card" href={`/hotel-management/inventory${q}`}><h3>Auto Inventory</h3><p>Date-wise live inventory generated from physical units and reservations.</p></a>
 <a className="module-card" href={`/booking${q}`}><h3>Reservations</h3><p>Same reservation, payment, confirmation and operational lifecycle.</p></a>
 <a className="module-card" href={`/store-builder?kind=hotel`}><h3>My {label} Store Preview</h3><p>Same premium preview, branding, SEO, banners and publishing controls.</p></a>
 <a className="module-card" href="/plugins"><h3>Plugin Control Center</h3><p>Super Admin activation controls remain property-level.</p></a>
 </div></Section>
 <Section title="Activated Plugins" meta={`${plugins.filter(x=>x.enabled).length} active`}><Table columns={['Plugin','Status','Updated']} rows={plugins.map(x=>[x.plugin_code,<Pill tone={x.enabled?'success':'muted'}>{x.enabled?'Active':'Disabled'}</Pill>,x.updated_at||'—'])}/></Section>
 </AppShell>;
}
