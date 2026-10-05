'use client';
import {useEffect,useMemo,useState} from 'react';
import {AppShell,Header,Section,Table,Pill,Kpi} from '../components';
import {supabase} from '../../lib/supabase';

const money=v=>`₹${Number(v||0).toLocaleString('en-IN',{maximumFractionDigits:2})}`;
const fmt=v=>v?new Date(v).toLocaleString('en-IN',{dateStyle:'medium',timeStyle:'short'}):'—';

const empty={prefs:[],tasks:[],complaints:[],timeline:[],loyalty:null,loyaltyTx:[],feedback:[],stays:[],visits:[],upsells:[],insights:[],channels:[],identity:[],assignments:[],requests:[],dataRequests:[],bookings:[],messages:[],campaigns:[],churn:null,vipProfile:null,consents:[],corporateContacts:[],partnerBookings:[],documents:[],reviews:[]};

export default function Customer360(){
 const [session,setSession]=useState(null),[properties,setProperties]=useState([]),[propertyId,setPropertyId]=useState(''),[tenant,setTenant]=useState(''),[customers,setCustomers]=useState([]),[c,setC]=useState(null),[related,setRelated]=useState(empty),[search,setSearch]=useState(''),[msg,setMsg]=useState(''),[error,setError]=useState(''),[busy,setBusy]=useState('');
 const property=useMemo(()=>properties.find(p=>p.id===propertyId)||null,[properties,propertyId]);

 const q=(table,select='*',filter={})=>{
   let x=supabase.from(table).select(select);
   for(const [k,v] of Object.entries(filter)) if(v!==undefined&&v!==null&&v!=='') x=x.eq(k,v);
   return x;
 };
 const scoped=async(table,select='*',extra={})=>{
   const base={tenant_id:tenant,...extra};
   let x=q(table,select,base);
   // Every operational CRM table in the completion migration carries property_id.
   if(propertyId) x=x.eq('property_id',propertyId);
   return x;
 };

 const loadCustomers=async()=>{
   if(!tenant||!propertyId)return;
   setError('');
   let x=supabase.from('crm_customers').select('*').eq('tenant_id',tenant).eq('property_id',propertyId).order('updated_at',{ascending:false}).limit(500);
   const r=await x;
   if(r.error)setError(r.error.message);else setCustomers(r.data||[]);
 };

 const loadProfile=async x=>{
   setC(x);setMsg('');setError('');
   const id=x.id;
   const qs=await Promise.all([
    scoped('crm_customer_preferences','*',{customer_id:id}),
    scoped('crm_tasks','*',{customer_id:id}),
    scoped('crm_complaints','*',{customer_id:id}),
    scoped('crm_timeline_events','*',{customer_id:id}),
    scoped('crm_loyalty_accounts','*',{customer_id:id}),
    scoped('crm_loyalty_transactions','*',{customer_id:id}),
    scoped('crm_feedback','*',{customer_id:id}),
    scoped('crm_guest_stays','*',{customer_id:id}),
    scoped('crm_restaurant_visits','*',{customer_id:id}),
    scoped('crm_upsell_events','*',{customer_id:id}),
    scoped('crm_ai_insights','*',{customer_id:id}),
    scoped('crm_customer_channels','*',{customer_id:id}),
    scoped('crm_customer_identity_links','*',{customer_id:id}),
    scoped('crm_relationship_assignments','*',{customer_id:id,active:true}),
    scoped('crm_guest_requests','*',{customer_id:id}),
    scoped('crm_data_requests','*',{customer_id:id}),
    scoped('crm_booking_transactions','*',{customer_id:id}),
    scoped('crm_message_log','*',{customer_id:id}),
    scoped('crm_campaign_recipients','*',{customer_id:id}),
    scoped('crm_churn_scores','*',{customer_id:id}),
    scoped('crm_vip_profiles','*',{customer_id:id}),
    scoped('crm_consents','*',{customer_id:id}),
    scoped('crm_corporate_contacts','*',{customer_id:id}),
    scoped('crm_partner_bookings','*',{customer_id:id}),
    scoped('crm_guest_documents','*',{customer_id:id}),
    scoped('crm_reviews','*',{customer_id:id})
   ]);
   const [prefs,tasks,complaints,timeline,loyalty,loyaltyTx,feedback,stays,visits,upsells,insights,channels,identity,assignments,requests,dataRequests,bookings,messages,campaigns,churn,vipProfile,consents,corporateContacts,partnerBookings,documents,reviews]=qs;
   const bad=qs.find(x=>x.error);
   if(bad)setError(bad.error.message);
   setRelated({
    prefs:prefs.data||[],tasks:tasks.data||[],complaints:complaints.data||[],timeline:(timeline.data||[]).sort((a,b)=>new Date(b.occurred_at||0)-new Date(a.occurred_at||0)),loyalty:loyalty.data?.[0]||null,loyaltyTx:loyaltyTx.data||[],feedback:feedback.data||[],stays:stays.data||[],visits:visits.data||[],upsells:upsells.data||[],insights:insights.data||[],channels:channels.data||[],identity:identity.data||[],assignments:assignments.data||[],requests:requests.data||[],dataRequests:dataRequests.data||[],bookings:bookings.data||[],messages:messages.data||[],campaigns:campaigns.data||[],churn:churn.data?.[0]||null,vipProfile:vipProfile.data?.[0]||null,consents:consents.data||[],corporateContacts:corporateContacts.data||[],partnerBookings:partnerBookings.data||[],documents:documents.data||[],reviews:reviews.data||[]
   });
 };

 useEffect(()=>{(async()=>{
   const {data:{session:s}}=await supabase.auth.getSession();setSession(s);if(!s)return;
   const {data:props,error}=await supabase.from('anaira_hospitality_properties_master').select('id,tenant_id,property_type,name,destination,city,state,country,active').eq('active',true).order('name');
   if(error){setError(error.message);return;}
   const list=props||[];setProperties(list);
   const requested=new URLSearchParams(window.location.search).get('property');
   const requestedCustomer=new URLSearchParams(window.location.search).get('customer');
   const profile=await supabase.from('anaira_my_profile').select('restaurant_id').eq('id',s.user.id).maybeSingle();
   const allowedTenant=profile.data?.restaurant_id||'';
   const chosen=list.find(p=>p.id===requested&&(!allowedTenant||p.tenant_id===allowedTenant))||list.find(p=>p.tenant_id===allowedTenant)||list[0];
   if(chosen){setPropertyId(chosen.id);setTenant(chosen.tenant_id||'');if(requestedCustomer)setTimeout(async()=>{const r=await supabase.from('crm_customers').select('*').eq('tenant_id',chosen.tenant_id).eq('property_id',chosen.id).eq('id',requestedCustomer).maybeSingle();if(r.data)loadProfile(r.data)},0);}
 })()},[]);
 useEffect(()=>{if(tenant&&propertyId)loadCustomers()},[tenant,propertyId]);

 const switchProperty=id=>{const p=properties.find(x=>x.id===id);if(!p)return;setPropertyId(id);setTenant(p.tenant_id);setC(null);setCustomers([]);setRelated(empty);const u=new URL(window.location.href);u.searchParams.set('property',id);u.searchParams.delete('customer');window.history.replaceState({},'',u);setMsg(`Property switched to ${p.name}.`);};
 const filtered=useMemo(()=>{const s=search.toLowerCase();return customers.filter(x=>`${x.full_name||''} ${x.phone||''} ${x.email||''}`.toLowerCase().includes(s))},[customers,search]);
 const runAction=async action=>{
   if(!c)return;setBusy(action);setError('');
   try{
    const token=(await supabase.auth.getSession()).data.session?.access_token||'';
    const r=await fetch('/api/plugins/customer_360/action',{method:'POST',headers:{'content-type':'application/json',authorization:`Bearer ${token}`},body:JSON.stringify({pluginKey:'customer_360',tenantId:tenant,actionId:action,recordKey:{id:c.id},payload:{propertyId}})});
    const j=await r.json();if(!r.ok||j.ok===false)throw new Error(j.error||'Action failed');
    setMsg(`${action.replaceAll('_',' ')} completed.`);await loadCustomers();const fresh=(await supabase.from('crm_customers').select('*').eq('tenant_id',tenant).eq('property_id',propertyId).eq('id',c.id).maybeSingle()).data;await loadProfile(fresh||c);
   }catch(e){setError(e.message||String(e))}finally{setBusy('')}
 };

 if(!session)return <AppShell><div className="auth-card"><h1>Sign in required</h1><a className="btn primary" href="/login">Open CRM Login</a></div></AppShell>;

 return <AppShell active="/customer-360">
  <Header eyebrow="CUSTOMER ENGINE" title="Customer 360" subtitle="Property-scoped unified customer profile across hotel, restaurant, service, loyalty, communications and intelligence." actions={<><select className="input" value={propertyId} onChange={e=>switchProperty(e.target.value)} disabled={!properties.length}>{properties.map(p=><option key={p.id} value={p.id}>{p.name} · {p.property_type}</option>)}</select><input placeholder="Search customer" value={search} onChange={e=>setSearch(e.target.value)}/><button className="btn" onClick={loadCustomers}>Refresh</button></>}/>
  {property&&<div className="notice"><b>{property.name}</b> · {property.property_type} · {property.city||property.destination||'—'} · <span>All Customer 360 reads/writes are scoped to this property.</span></div>}
  {error&&<div className="notice error">{error}</div>}{msg&&<div className="notice success">{msg}</div>}
  <div className="public-columns"><aside className="card"><h3>Customers</h3>{filtered.length===0?<div className="notice">No customers exist for this property.</div>:filtered.map(x=><button className="module-card" key={x.id} onClick={()=>loadProfile(x)}><b>{x.full_name}</b><p>{x.phone||x.email||'No contact'}</p><small>{x.customer_type||'guest'} · {x.vip?'VIP':'Standard'}</small></button>)}</aside>
  <main>{!c?<div className="notice">Select a customer. Data below will always belong to the selected property.</div>:<>
   <Section title={c.full_name} meta={`${property?.name||'Property'} · ${c.customer_type||'guest'} · ${c.phone||'—'} · ${c.email||'—'}`} actions={<><button className="btn" disabled={!!busy} onClick={()=>runAction('refresh_timeline')}>Refresh Timeline</button><button className="btn" disabled={!!busy} onClick={()=>runAction('refresh_value')}>Refresh Value</button></>}>
    <div className="grid kpis"><Kpi label="Hotel Revenue" value={money(c.total_hotel_revenue)}/><Kpi label="Restaurant Revenue" value={money(c.total_restaurant_revenue)}/><Kpi label="Stays" value={c.total_stays||0}/><Kpi label="Restaurant Visits" value={related.visits.length}/><Kpi label="Loyalty" value={related.loyalty?.points_balance||0}/><Kpi label="LTV" value={money(Number(c.total_hotel_revenue||0)+Number(c.total_restaurant_revenue||0))}/></div>
   </Section>
   <Section title="Hotel Bookings & Payments"><Table columns={['Reference','State','Amount','Payment','Created']} rows={related.bookings.map(x=>[x.booking_reference||x.reservation_code||x.id,<Pill>{x.state||x.status||'—'}</Pill>,money(x.amount||x.total_amount),x.payment_status||x.payment_method||'—',fmt(x.created_at)])}/></Section>
   <Section title="Hotel Stays"><Table columns={['Room','Check-in','Check-out','Source','Status','Value']} rows={related.stays.map(x=>[x.room_number||'—',x.check_in_date||'—',x.check_out_date||'—',x.booking_source||'—',<Pill>{x.booking_status||x.status||'—'}</Pill>,money(x.total_amount)])}/></Section>
   <Section title="Restaurant History"><Table columns={['Visit','Table','Guests','Order','Amount','Payment']} rows={related.visits.map(x=>[fmt(x.visit_at),x.table_number||'—',x.guest_count||0,String(x.order_id||'—').slice(0,10),money(x.amount),x.payment_method||'—'])}/></Section>
   <Section title="Service & Requests"><Table columns={['Type','Title','Status','Date']} rows={[...related.complaints.map(x=>({id:x.id,type:'Complaint',title:x.title,status:x.status,date:x.opened_at||x.created_at})),...related.requests.map(x=>({id:x.id,type:'Guest Request',title:x.description,status:x.status,date:x.created_at})),...related.tasks.map(x=>({id:x.id,type:'Task',title:x.title,status:x.status,date:x.due_at}))].map(x=><tr key={x.type+x.id}><td>{x.type}</td><td>{x.title}</td><td><Pill>{x.status}</Pill></td><td>{fmt(x.date)}</td></tr>)}/></Section>
   <Section title="Loyalty Ledger"><Table columns={['Type','Points','Reference','Date']} rows={related.loyaltyTx.map(x=>[x.transaction_type||x.type||'—',x.points||x.amount||0,x.reference_id||'—',fmt(x.created_at)])}/></Section>
   <Section title="Marketing & Communications"><Table columns={['Channel','Direction','Status','Date']} rows={[...related.messages.map(x=>({channel:x.channel,direction:x.direction,status:x.status,date:x.created_at})),...related.campaigns.map(x=>({channel:'Campaign',direction:x.campaign_id,status:x.status,date:x.sent_at||x.created_at}))].map(x=><tr key={`${x.channel}-${x.date}-${x.direction}`}><td>{x.channel}</td><td>{x.direction}</td><td><Pill>{x.status}</Pill></td><td>{fmt(x.date)}</td></tr>)}/></Section>
   <Section title="Risk, VIP, Reviews & Consent"><Table columns={['Area','Value','Details']} rows={[['Churn',related.churn?.risk_level||'—',related.churn?.factors?JSON.stringify(related.churn.factors):'—'],['VIP',related.vipProfile?.vip_level||(c.vip?'VIP':'Standard'),related.vipProfile?.welcome_amenities?JSON.stringify(related.vipProfile.welcome_amenities):'—'],['Reviews',related.reviews.length,related.reviews[0]?.rating||'—'],['Consent records',related.consents.length,related.consents.map(x=>`${x.channel}:${x.status}`).join(', ')||'—']]}/></Section>
   <Section title="Identity, Relationships & Privacy"><Table columns={['Area','Count','State']} rows={[['Identity links',related.identity.length,'Linked'],['Relationship managers',related.assignments.length,related.assignments.length?'Assigned':'Unassigned'],['Documents',related.documents.length,'Stored'],['Data requests',related.dataRequests.length,'Audited'],['Preferences',related.prefs.length,'Live']]}/></Section>
   <Section title="Upsell / AI"><Table columns={['Area','Count','Latest']} rows={[['Upsells',related.upsells.length,related.upsells[0]?.status||'—'],['AI insights',related.insights.length,related.insights[0]?.recommendation||'—']]}/></Section>
   <Section title="Omnichannel Timeline"><Table columns={['When','Event','Source','Value']} rows={related.timeline.map(x=>[fmt(x.occurred_at),x.title||x.event_type||'—',x.source_system||x.channel||'—',x.amount==null?'—':money(x.amount)])}/></Section>
  </>}</main></div>
 </AppShell>
}
