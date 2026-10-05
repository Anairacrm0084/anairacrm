'use client';
import {useEffect,useState} from 'react';
import {AppShell,Header,Section,Pill} from '../components';
import {supabase} from '../../lib/supabase';
import {pluginCatalog} from '../pluginCatalog';
import {pluginRegistry} from '../pluginRegistry';
const integrationLinks={
 'hotel-booking':'/super-admin/integrations?focus=hotel-booking',
 'channel-manager':'/super-admin/integrations?focus=channel-manager',
 'anaira-pos':'/super-admin/integrations?focus=anaira-pos',
 'restaurant-store':'/super-admin/integrations?focus=restaurant-marketplace',
 'food-delivery':'/super-admin/integrations?focus=restaurant-marketplace',
 'restaurant-reservation':'/super-admin/integrations?focus=restaurant-marketplace',
 'hotel_guest_crm':'/super-admin/integrations?focus=hotel-guest-crm',
 'crm':'/super-admin/integrations?focus=hotel-guest-crm',
};

export default function Plugins(){
 const [session,setSession]=useState(undefined),[profile,setProfile]=useState(null),[propertyId,setPropertyId]=useState(''),[properties,setProperties]=useState([]),[active,setActive]=useState({}),[err,setErr]=useState(''),[busy,setBusy]=useState('');
 const isSuperAdmin=profile?.is_super_admin===true||profile?.role==='super_admin'; const isAdmin=profile?.role==='admin';

 useEffect(()=>{if(!supabase){setSession(null);return} supabase.auth.getSession().then(({data})=>setSession(data.session));},[]);
 useEffect(()=>{if(!session||!supabase)return; (async()=>{
   const p=await supabase.from('anaira_my_profile').select('restaurant_id,is_super_admin,role').eq('id',session.user.id).maybeSingle();
   if(p.error){setErr(p.error.message);return}
   setProfile(p.data||null);
   if(p.data?.is_super_admin===true||p.data?.role==='super_admin'){
     const q=await supabase.from('restaurants').select('id,name,status').order('name');
     if(q.error)setErr(q.error.message); else setProperties(q.data||[]);
   } else setPropertyId(p.data?.restaurant_id||'');
 })().catch(e=>setErr(e.message));},[session]);

 useEffect(()=>{if(!supabase||!propertyId)return; (async()=>{
   const q=await supabase.from('restaurant_plugins').select('plugin_code,enabled').eq('restaurant_id',propertyId);
   if(q.error){setErr(q.error.message);return}
   setActive(Object.fromEntries((q.data||[]).map(x=>[x.plugin_code,x.enabled===true])));
 })()},[propertyId]);

 async function toggle(plugin){
   if(!propertyId){setErr('Select a property first.');return}
   setBusy(plugin.key);setErr('');
   const next=!active[plugin.key];
   const q=await supabase.from('restaurant_plugins').upsert({
     restaurant_id:propertyId,plugin_code:plugin.key,plugin_slug:plugin.key,
     display_name:plugin.name,category:plugin.category,description:plugin.description,
     feature_kind:'feature',enabled:next,activated_by:session.user.id,
     activated_at:next?new Date().toISOString():null,
     disabled_at:next?null:new Date().toISOString()
   },{onConflict:'restaurant_id,plugin_code'});
   if(q.error)setErr(q.error.message); else setActive(v=>({...v,[plugin.key]:next}));
   setBusy('');
 }

 if(!supabase)return <AppShell><div className="notice">Configure Supabase first.</div></AppShell>;
 if(session===undefined)return <AppShell><div className="notice">Connecting to Supabase Auth…</div></AppShell>;
 if(!session)return <AppShell><div className="auth-card"><h1>Sign in required</h1><a className="btn primary" href="/login">Login</a></div></AppShell>;
 const selected=properties.find(p=>p.id===propertyId);
 return <AppShell active="/plugins">
   <Header eyebrow="ANAIRA PLATFORM" title="Plugin Control Center" subtitle="Super Admin controls which plugins are activated for each property. Admin, Manager and Staff only receive functionality from plugins activated for their property." />
   <Section title="Property Activation" meta={isSuperAdmin?'Super Admin':'Business Admin'}>
     {isSuperAdmin ? <div style={{display:'flex',gap:12,alignItems:'center',flexWrap:'wrap'}}>
       <select value={propertyId} onChange={e=>setPropertyId(e.target.value)} style={{minWidth:320,padding:'12px 14px',borderRadius:10}}>
         <option value="">Select hotel / restaurant property</option>
         {properties.map(p=><option key={p.id} value={p.id}>{p.name}{p.status?` • ${p.status}`:''}</option>)}
       </select>
       {selected&&<span className="subtitle">Managing plugins for <b>{selected.name}</b></span>}
     </div> : <div className="notice">Current property: <b>{profile?.restaurant_id||'Not assigned'}</b></div>}
     {!propertyId&&isSuperAdmin&&<div className="notice" style={{marginTop:12}}>Select a property. Plugin activation is property-level, so activation here will immediately control what that property's Business Admin, Manager and Staff can access.</div>}
   </Section>
   {err&&<div className="notice error">{err}</div>}
   <div className="module-grid">
     {pluginCatalog.map(p=>{
       const enabled=active[p.key]===true;
       return <div className="module-card" key={p.key} style={{position:'relative'}}>
         <a href={p.route} style={{textDecoration:'none',color:'inherit'}}>
           <div className="module-icon">{p.core?'◆':'◇'}</div>
           <h3>{p.name}</h3><p>{p.description}</p>
           <Pill tone={enabled?'success':'muted'}>{enabled?'Activated':'Disabled'}</Pill>
           <div className="subtitle" style={{marginTop:8}}>{p.category} • {p.core?'Core':'Optional'} • {pluginRegistry.plugins[p.key]?.settingsSchema?.length||0} settings</div>
         </a>
         <div style={{display:'flex',gap:8,marginTop:14,flexWrap:'wrap'}}>
           <button className={'btn '+(enabled?'danger':'primary')} onClick={()=>toggle(p)} disabled={!propertyId||!!busy}>
             {busy===p.key?'Saving…':enabled?'Deactivate':'Activate'}
           </button>
           <a className="btn" href={`/plugins/${p.key}/settings`}>Open / Configure</a>{integrationLinks[p.key]&&<a className="btn" href={integrationLinks[p.key]}>Integration</a>}
         </div>
       </div>
     })}
   </div>
   <Section title="Product Integration Map" meta="First-party control plane"><div className="notice">Plugin activation controls whether the tenant can use a product. Product-to-product connections, marketplace publication, POS connections and external distribution belong to <a href="/super-admin/integrations"><b>Universal Integrations</b></a>. They are intentionally separate from plugin-local settings so a plugin can be enabled without silently creating a live external connection.</div></Section>
   <Section title="Activation Contract" meta="Tenant isolation">
     <div className="notice">A plugin becomes operational for a property only after Super Admin activates it here. Deactivation preserves existing records but removes the plugin from tenant operational access. Plugin permissions and RLS remain the backend enforcement layer.</div>
   </Section>
 </AppShell>
}
