'use client';

import {useEffect,useMemo,useState} from 'react';
import {AppShell,Header,Section,Table,Pill,Kpi} from '../components';
import {supabase} from '../../lib/supabase';

const COUNT_SPECS=[
  ['CRM Customers','crm_customers','tenant_id'],
  ['CRM Leads','crm_leads','tenant_id'],
  ['CRM Campaigns','crm_campaigns','tenant_id'],
  ['CRM Complaints','crm_complaints','tenant_id'],
  ['CRM Timeline','crm_timeline_events','tenant_id'],
  ['CRM Booking Transactions','crm_booking_transactions','tenant_id'],
  ['CRM Loyalty Accounts','crm_loyalty_accounts','tenant_id'],
  ['HMS Rooms','hms_rooms','restaurant_id'],
  ['HMS Reservations','hms_reservations','restaurant_id'],
  ['HMS Inventory Rows','hms_inventory','restaurant_id'],
  ['HMS Guests','hms_guests','restaurant_id'],
  ['HMS Folios','hms_folios','restaurant_id'],
  ['Enabled Plugins','restaurant_plugins','restaurant_id'],
  ['Plugin Settings','plugin_settings','restaurant_id'],
];

const money=v=>`₹${Number(v||0).toLocaleString('en-IN',{maximumFractionDigits:2})}`;

const BUSINESS_TYPES=[
 ['hotel_resort','🏨 Hotel / Resort'],['restaurant_cafe','🍽️ Restaurant / Cafe'],['salon','💇 Salon'],['barber_shop','💈 Barber Shop'],['spa_wellness','💆 Spa'],['clinic_hospital','🏥 Clinic / Hospital'],['dentist_doctor','🦷 Dentist / Doctor'],['pharmacy','💊 Pharmacy'],['gym_yoga','🏋️ Gym / Yoga'],['retail_grocery','🛍️ Retail / Grocery'],['fashion','👗 Fashion'],['jewellery','💎 Jewellery'],['electronics_mobile','📱 Electronics / Mobile'],['automotive','🚗 Automotive'],['real_estate','🏠 Real Estate'],['travel','✈️ Travel'],['education_coaching','🎓 Education / Coaching'],['legal','⚖️ Legal'],['ca_accounting_tax','📊 CA / Accounting / Tax'],['it_agency','💻 IT / Agency'],['repair_maintenance','🔧 Repair / Maintenance'],['cleaning','🧹 Cleaning'],['veterinary','🐕 Veterinary'],['photography','📸 Photography'],['events','🎉 Events'],['coworking','🏢 Coworking'],['logistics','🚚 Logistics'],['construction_home_services','🏗️ Construction / Home Services'],['ecommerce','🛒 E-commerce'],['saas_subscription','☁️ SaaS / Subscription'],['creator_personal_brand','👤 Creator / Personal Brand'],['non_profit','🤝 Non-profit'],['other','• Other'],
];
const isHotelBusiness=t=>t==='hotel_resort'||t==='hotel_restaurant';


async function countFor(table,column,id,extra=''){
  let q=supabase.from(table).select('*',{count:'exact',head:true}).eq(column,id);
  if(extra) q=q.eq(extra.split('=')[0],extra.split('=').slice(1).join('='));
  const r=await q;
  return {count:r.count||0,error:r.error};
}

export default function Properties(){
  const [rows,setRows]=useState([]),[selected,setSelected]=useState(''),[detail,setDetail]=useState(null),[counts,setCounts]=useState({}),[form,setForm]=useState({}),[editing,setEditing]=useState(false),[error,setError]=useState(''),[msg,setMsg]=useState(''),[loading,setLoading]=useState(true),[loadingDetail,setLoadingDetail]=useState(false);

  const load=async()=>{
    setLoading(true);setError('');
    const r=await supabase.from('restaurants').select('id,name,slug,status,email,phone,city,state,country,address,business_type,hospitality_type,hospitality_types,marketplace_visible,created_at,updated_at').order('created_at',{ascending:false});
    if(r.error)setError(r.error.message); else {setRows(r.data||[]);if(!selected&&r.data?.[0]?.id)setSelected(r.data[0].id)}
    setLoading(false);
  };

  useEffect(()=>{load()},[]);
  useEffect(()=>{const editId=new URLSearchParams(window.location.search).get('edit');if(editId&&rows.length){const r=rows.find(x=>x.id===editId);if(r)startEdit(r)}},[rows.length]);

  const startEdit=(r)=>{setSelected(r.id);setEditing(true);setForm({...r});setMsg('');setError('');};
  const cancelEdit=()=>{setEditing(false);setForm({});setError('');setMsg('');};

  const property=useMemo(()=>rows.find(x=>x.id===selected)||null,[rows,selected]);

  const loadDetail=async(id)=>{
    if(!id)return;
    setLoadingDetail(true);setError('');
    const r=rows.find(x=>x.id===id);
    const [master, plugins] = await Promise.all([
      supabase.from('anaira_hospitality_properties_master').select('*').eq('tenant_id',id).order('updated_at',{ascending:false}).limit(20),
      supabase.from('restaurant_plugins').select('plugin_code,enabled').eq('restaurant_id',id).order('plugin_code')
    ]);
    const nextCounts={};
    const results=await Promise.all(COUNT_SPECS.map(async ([label,table,column])=>[label,await countFor(table,column,id)]));
    for(const [label,v] of results) nextCounts[label]=v.count;
    const enabled=(plugins.data||[]).filter(x=>x.enabled).length;
    nextCounts['Enabled Plugins']=enabled;
    setCounts(nextCounts);

    let source=null;
    const m=(master.data||[])[0]||null;
    if(m?.source_table&&m?.source_id){
      const allowed=['anaira_hotel_properties','camp_properties','anaira_stay_properties'];
      if(allowed.includes(m.source_table)){
        const sr=await supabase.from(m.source_table).select('*').eq('id',m.source_id).maybeSingle();
        source=sr.data||null;
      }
    }
    setDetail({master:m,masters:master.data||[],source,plugins:plugins.data||[],restaurant:r});
    setLoadingDetail(false);
  };

  useEffect(()=>{if(selected&&rows.length)loadDetail(selected)},[selected,rows.length]);

  const set=(k,v)=>setForm(x=>({...x,[k]:v}));

  async function create(e){
    e.preventDefault();setError('');setMsg('');
    const businessType=form.business_type||null;
    if(!businessType){setError('Select a Business Type before creating the business.');return;}
    const hospitalityType=isHotelBusiness(businessType)?(form.hospitality_type||'hotel'):null;
    const slug=(form.slug||form.name||'').toLowerCase().trim().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'');
    const q=await supabase.rpc('anaira_create_property',{p_name:form.name,p_slug:slug,p_email:form.email||null,p_phone:form.phone||null,p_address:form.address||null});
    if(q.error){setError(q.error.message);return}
    const u=await supabase.from('restaurants').update({business_type:businessType,legal_name:form.legal_name||null,owner_name:form.owner_name||null,whatsapp:form.whatsapp||null,website:form.website||null,city:form.city||null,state:form.state||null,country:form.country||'India',postal_code:form.postal_code||null,landmark:form.landmark||null,cuisine:form.cuisine||null,description:form.description||null,hospitality_type:hospitalityType,hospitality_types:isHotelBusiness(businessType)?[hospitalityType]:[]}).eq('id',q.data);
    if(u.error)setError(u.error.message);else{const w=await supabase.from('anaira_business_workspaces').upsert({business_id:q.data,business_type:businessType,setup_status:'configured',settings:{...form,business_type:businessType,hospitality_type:hospitalityType,hospitality_types:isHotelBusiness(businessType)?[hospitalityType]:[]}}, {onConflict:'business_id'});if(w.error){setError(w.error.message);return;}setMsg('Property created.');setForm({});await load();setSelected(q.data)}
  }

  async function updateProperty(e){
    e.preventDefault();setError('');setMsg('');
    if(!selected){setError('Select a property to edit.');return;}
    const businessType=form.business_type||null;
    if(!businessType){setError('Select a Business Type.');return;}
    const hospitalityType=isHotelBusiness(businessType)?(form.hospitality_type||'hotel'):null;
    const u=await supabase.from('restaurants').update({name:form.name,slug:form.slug||null,email:form.email||null,phone:form.phone||null,address:form.address||null,legal_name:form.legal_name||null,owner_name:form.owner_name||null,whatsapp:form.whatsapp||null,website:form.website||null,city:form.city||null,state:form.state||null,country:form.country||'India',postal_code:form.postal_code||null,landmark:form.landmark||null,cuisine:form.cuisine||null,description:form.description||null,business_type:businessType,hospitality_type:hospitalityType,hospitality_types:isHotelBusiness(businessType)?[hospitalityType]:[]}).eq('id',selected);
    if(u.error)setError(u.error.message);else{const w=await supabase.from('anaira_business_workspaces').upsert({business_id:selected,business_type:businessType,setup_status:'configured',settings:{...form,business_type:businessType,hospitality_type:hospitalityType,hospitality_types:isHotelBusiness(businessType)?[hospitalityType]:[]}}, {onConflict:'business_id'});if(w.error){setError(w.error.message);return;}setMsg('Property updated successfully.');setEditing(false);await load();}
  }

  if(loading)return <AppShell active="/properties"><Header eyebrow="SUPER ADMIN • PROPERTIES" title="Properties / Tenants" subtitle="Loading live property data…"/><div className="notice">Loading live properties from Supabase…</div></AppShell>;

  return <AppShell active="/properties">
    <Header eyebrow="SUPER ADMIN • PROPERTY CONTROL" title="Properties / Tenants" subtitle="Property-wise control center. Select one property and inspect its CRM, HMS, booking, inventory, plugins and marketplace data separately." actions={<button className="btn" onClick={load}>Refresh</button>}/>

    {error&&<div className="notice error">{error}</div>}{msg&&<div className="notice success">{msg}</div>}

    <Section title="Property Selector" meta={`${rows.length} live businesses`}>
      <div className="card" style={{display:'grid',gridTemplateColumns:'minmax(280px,1fr) auto',gap:12,alignItems:'end'}}>
        <label><span>Select Property</span><select value={selected} onChange={e=>setSelected(e.target.value)}><option value="">Select property</option>{rows.map(r=><option key={r.id} value={r.id}>{r.name} · {r.hospitality_type||r.business_type||'business'} · {r.status||'—'}</option>)}</select></label>
        {property&&<a className="btn primary" href={'/admin/property/'+property.id}>Open Property Workspace →</a>}
      </div>
    </Section>

    {property&&<>
      <Section title={property.name} meta={`${property.hospitality_type||property.business_type||'property'} · ${property.city||'—'}, ${property.state||'—'}`}>
        <div className="grid kpis">
          <Kpi label="CRM Customers" value={counts['CRM Customers']||0}/><Kpi label="Bookings" value={counts['CRM Booking Transactions']||0}/><Kpi label="HMS Reservations" value={counts['HMS Reservations']||0}/><Kpi label="Rooms" value={counts['HMS Rooms']||0}/><Kpi label="Inventory Rows" value={counts['HMS Inventory Rows']||0}/><Kpi label="Enabled Plugins" value={counts['Enabled Plugins']||0}/>
        </div>
      </Section>

      <Section title="Property Master" meta="Canonical hospitality property layer">
        <Table columns={['Field','Value']} rows={[
          ['Property ID',property.id],['Hospitality Type',property.hospitality_type||property.business_type||'—'],['Hospitality Types',(property.hospitality_types||[]).join(', ')||'—'],['Status',<Pill tone={property.status==='active'?'success':'muted'}>{property.status||'—'}</Pill>],['Destination',detail?.master?.destination||detail?.source?.destination||'—'],['Address',[property.address,property.city,property.state,property.country].filter(Boolean).join(', ')||'—'],['Marketplace',property.marketplace_visible?'Visible':'Hidden']
        ]}/>
      </Section>

      <Section title="Property-wise Data" meta="Live records scoped to the selected property/tenant">
        <Table columns={['Module','Records']} rows={Object.entries(counts).map(([k,v])=>[k,v])}/>
      </Section>

      <Section title="Property Plugins" meta={`${detail?.plugins?.length||0} plugin assignments`}>
        <Table columns={['Plugin','State']} rows={(detail?.plugins||[]).map(x=>[x.plugin_code,<Pill tone={x.enabled?'success':'muted'}>{x.enabled?'Enabled':'Disabled'}</Pill>])}/>
      </Section>

      <Section title="Business Management & Settings" meta="Controls are selected from the current Business Type and enabled plugins">
        <div className="mini-grid">
          <div className="mini"><b>{property.business_type==='hotel_resort'||property.business_type==='hotel_restaurant'?'Hotel / Hospitality Setup':(property.business_type||'Business')+' Setup'}</b><span>Identity, settings, business-specific catalog, offers and landing page.</span><a className="btn primary" href={(property.business_type&&property.business_type!=='hotel_resort'&&property.business_type!=='hotel_restaurant')?`/business/${property.business_type}/setup?business=${property.id}`:'/admin/property/'+property.id}>Open Setup</a></div>
          {(property.business_type==='hotel_resort'||property.business_type==='hotel_restaurant')&&<div className="mini"><b>Hotel / Booking Engine</b><span>Rooms, rates, inventory and reservations.</span><a className="btn" href={'/hotel-management?property='+property.id}>Open HMS</a></div>}
          {(detail?.plugins||[]).some(x=>x.enabled&&['restaurant-management','restaurant-core','restaurant-store'].includes(x.plugin_code))&&<div className="mini"><b>Restaurant Management</b><span>Restaurant setup, menu, POS, store and reservations.</span><a className="btn" href={'/restaurant-setup?property='+property.id}>Open Restaurant</a></div>}
          <div className="mini"><b>Front Landing Page</b><span>Customer-facing page using this business's live catalog and offers.</span><a className="btn" href={`/business/${property.business_type||'other'}?business=${property.id}`} target="_blank" rel="noreferrer">Open Landing ↗</a></div>
          <div className="mini"><b>CRM / Customer 360</b><span>CRM records remain tenant/business scoped.</span><a className="btn" href={'/customer-360'}>Open CRM</a></div>
        </div>
      </Section>
    </>}

    <Section title={editing?`Edit Property / Business — ${form.name||""}`:"Add Property / Business"} meta="Super Admin">
      <form className="admin-form" onSubmit={editing?updateProperty:create}>
        <label><span>Business Name</span><input required value={form.name||''} onChange={e=>set('name',e.target.value)}/></label><label><span>Slug</span><input value={form.slug||''} onChange={e=>set('slug',e.target.value)}/></label>
        <label><span>Business Type</span><select required value={form.business_type||''} onChange={e=>{const v=e.target.value;setForm(x=>({...x,business_type:v,hospitality_type:isHotelBusiness(v)?(x.hospitality_type||'hotel'):''}))}}><option value="">Select Business Type</option><option value="hotel_restaurant">🏨🍽️ Hotel + Restaurant</option>{BUSINESS_TYPES.map(([v,l])=><option key={v} value={v}>{l}</option>)}</select></label>
        {isHotelBusiness(form.business_type)&&<label><span>Hospitality Type</span><select value={form.hospitality_type||'hotel'} onChange={e=>set('hospitality_type',e.target.value)}><option value="hotel">Hotel</option><option value="camp">Camp / Camping</option><option value="homestay">Homestay</option><option value="guest_house">Guest House</option><option value="cottage">Cottage</option></select></label>}
        <label><span>Legal Name</span><input value={form.legal_name||''} onChange={e=>set('legal_name',e.target.value)}/></label><label><span>Owner</span><input value={form.owner_name||''} onChange={e=>set('owner_name',e.target.value)}/></label><label><span>Phone</span><input value={form.phone||''} onChange={e=>set('phone',e.target.value)}/></label><label><span>WhatsApp</span><input value={form.whatsapp||''} onChange={e=>set('whatsapp',e.target.value)}/></label><label><span>Email</span><input type="email" value={form.email||''} onChange={e=>set('email',e.target.value)}/></label><label><span>Website</span><input value={form.website||''} onChange={e=>set('website',e.target.value)}/></label><label className="full"><span>Address</span><input value={form.address||''} onChange={e=>set('address',e.target.value)}/></label><label><span>City</span><input value={form.city||''} onChange={e=>set('city',e.target.value)}/></label><label><span>State</span><input value={form.state||''} onChange={e=>set('state',e.target.value)}/></label><label><span>Country</span><input value={form.country||'India'} onChange={e=>set('country',e.target.value)}/></label><label><span>PIN</span><input value={form.postal_code||''} onChange={e=>set('postal_code',e.target.value)}/></label><label><span>Landmark</span><input value={form.landmark||''} onChange={e=>set('landmark',e.target.value)}/></label><label><span>Cuisine</span><input value={form.cuisine||''} onChange={e=>set('cuisine',e.target.value)}/></label><label className="full"><span>Description</span><input value={form.description||''} onChange={e=>set('description',e.target.value)}/></label><div className="full" style={{display:"flex",gap:8}}><button className="btn primary">{editing?"Save Changes":"Create Property"}</button>{editing&&<button type="button" className="btn" onClick={cancelEdit}>Cancel</button>}</div>
      </form>
    </Section>

    <Section title="All Properties" meta={`${rows.length} tenants`}>
      <Table columns={['Property','Business Type','Hospitality','Location','Status','Contact','Actions']} rows={rows.map(r=>[r.name||'—',r.business_type||'Not selected',r.hospitality_type||'—',[r.city,r.state].filter(Boolean).join(', ')||r.address||'—',<Pill key={r.id} tone={r.status==='active'?'success':'muted'}>{r.status||'—'}</Pill>,r.phone||r.email||'—',<div style={{display:'flex',gap:6,flexWrap:'wrap'}}><button className="btn" onClick={()=>setSelected(r.id)}>View</button><button className="btn primary" onClick={()=>startEdit(r)}>Edit</button></div>])}/>
    </Section>
  </AppShell>;
}
