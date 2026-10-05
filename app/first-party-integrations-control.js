'use client';
import {useEffect,useMemo,useState} from 'react';
import Link from 'next/link';
import {supabase} from '../lib/supabase';

const PRODUCT_LINKS = [
 {key:'hotel-booking',name:'Anaira Booking Engine',category:'FIRST-PARTY · HOTEL',desc:'Direct booking, availability, rates, payments and confirmations. HMS/PMS remains the operational master.',route:'/booking-engine',plugin:'hotel-booking',pluginRoute:'/plugins/hotel-booking/settings'},
 {key:'hotel-marketplace',name:'Anaira Hotel Marketplace',category:'FIRST-PARTY · MARKETPLACE',desc:'Global hotel discovery and direct booking surface. It consumes the Booking Engine/HMS availability instead of creating a second room master.',route:'/super-admin/hotel-marketplace-settings',preview:'/anaira/hotels'},
 {key:'restaurant-marketplace',name:'Anaira Restaurant Marketplace',category:'FIRST-PARTY · FOOD',desc:'Customer marketplace for restaurants. Restaurant POS / Restaurant SaaS remains the canonical menu, pricing, availability and order source.',route:'/super-admin/marketplace-settings',preview:'/marketplace'},
 {key:'anaira-pos',name:'Anaira Restaurant POS',category:'FIRST-PARTY · OPERATIONS',desc:'Restaurant operational master for billing, KOT/KDS, menu, inventory and payments. CRM/Marketplace consume events; they do not replace POS.',route:'/plugins/anaira-pos/settings',plugin:'anaira-pos'},
 {key:'channel-manager',name:'Anaira Channel / OTA Manager',category:'FIRST-PARTY · DISTRIBUTION',desc:'External OTA/GDS distribution layer. Super Admin enables platforms, then property channels map rooms/rates and sync inventory/rates/reservations.',route:'/channel-manager',plugin:'channel-manager'},
 {key:'hotel-guest-crm',name:'Anaira CRM / Customer 360',category:'FIRST-PARTY · CRM',desc:'Customer relationship and intelligence layer. Booking, POS and marketplace activity can feed the customer timeline without becoming the operational master.',route:'/hotel-guest-crm',plugin:'hotel_guest_crm'},
];

const label=v=>String(v||'').replace(/[_-]+/g,' ').replace(/\b\w/g,m=>m.toUpperCase());

export default function FirstPartyIntegrationControl(){
 const [rid,setRid]=useState(''),[properties,setProperties]=useState([]),[plugins,setPlugins]=useState({}),[settings,setSettings]=useState({}),[restaurantStore,setRestaurantStore]=useState(null),[pos,setPos]=useState(null),[busy,setBusy]=useState(false),[msg,setMsg]=useState(''),[posForm,setPosForm]=useState({base_url:'',credentials_ref:'',auth_type:'api_key',config:'{}',status:'disconnected'}),[posModal,setPosModal]=useState(false);

 const load=async(id=rid)=>{
  const [s,p,st,m]=await Promise.all([
   supabase.from('anaira_platform_settings').select('key,value').in('key',['global_booking_engine_enabled','hotel_marketplace_enabled']),
   id?supabase.from('restaurant_plugins').select('plugin_code,enabled').eq('restaurant_id',id):Promise.resolve({data:[]}),
   supabase.from('anaira_platform_stores').select('*').eq('store_type','restaurant').maybeSingle(),
   id?supabase.from('anaira_integration_connections_v2').select('*').eq('restaurant_id',id).eq('integration_type','pos').order('updated_at',{ascending:false}).limit(1):Promise.resolve({data:[]})
  ]);
  setSettings(Object.fromEntries((s.data||[]).map(x=>[x.key,x.value?.value??x.value])));
  setPlugins(Object.fromEntries((p.data||[]).map(x=>[x.plugin_code,x.enabled===true])));
  setRestaurantStore(st.data||null);
  const c=(m.data||[])[0]||null;setPos(c);
  if(c)setPosForm({base_url:c.base_url||'',credentials_ref:c.credentials_ref||'',auth_type:c.auth_type||'api_key',config:JSON.stringify(c.config||{},null,2),status:c.status||'disconnected'});
 };
 useEffect(()=>{(async()=>{const {data}=await supabase.from('restaurants').select('id,name,status').order('name');setProperties(data||[]);if(data?.[0]?.id)setRid(data[0].id)})()},[]);
 useEffect(()=>{load()},[rid]);

 const bookingEnabled=settings.global_booking_engine_enabled!==false && plugins['hotel-booking']!==false;
 const hotelMarketplaceEnabled=settings.hotel_marketplace_enabled===true;
 const restaurantMarketplaceEnabled=!!restaurantStore?.enabled && !!restaurantStore?.published;
 const posConnected=pos?.status==='connected';

 async function togglePlatformSetting(key,next){
  setBusy(true);setMsg('');
  const q=await supabase.from('anaira_platform_settings').upsert({key,value:{value:next},updated_at:new Date().toISOString()},{onConflict:'key'});
  if(q.error)setMsg(q.error.message);else{setMsg(`${label(key)} updated.`);await load()}setBusy(false);
 }
 async function toggleRestaurantStore(){
  if(!restaurantStore){setMsg('Restaurant marketplace store record is missing.');return}
  setBusy(true);const q=await supabase.from('anaira_platform_stores').update({enabled:!restaurantStore.enabled,published:!restaurantStore.published,updated_at:new Date().toISOString()}).eq('id',restaurantStore.id);
  if(q.error)setMsg(q.error.message);else{setMsg('Restaurant Marketplace publication updated.');await load()}setBusy(false);
 }
 function openPos(){setPosForm({base_url:pos?.base_url||'',credentials_ref:pos?.credentials_ref||'',auth_type:pos?.auth_type||'api_key',config:JSON.stringify(pos?.config||{},null,2),status:pos?.status||'disconnected'});setPosModal(true)}
 async function savePos(){
  if(!rid){setMsg('Select a property first.');return}
  let config={};try{config=JSON.parse(posForm.config||'{}')}catch{setMsg('POS config JSON is invalid.');return}
  setBusy(true);const payload={restaurant_id:rid,provider:'custom',integration_type:'pos',name:'Anaira POS',status:'configured',base_url:posForm.base_url.trim(),auth_type:posForm.auth_type,credentials_ref:posForm.credentials_ref.trim(),config,updated_at:new Date().toISOString()};
  const q=pos?.id?await supabase.from('anaira_integration_connections_v2').update(payload).eq('id',pos.id):await supabase.from('anaira_integration_connections_v2').insert(payload);
  if(q.error)setMsg(q.error.message);else{setMsg('Anaira POS integration settings saved. Run Test Connection to verify the live POS endpoint.');setPosModal(false);await load()}setBusy(false);
 }
 async function testPos(){
  if(!rid){setMsg('Select a property first.');return}
  setBusy(true);setMsg('Testing Anaira POS connection…');
  try{
   const session=(await supabase.auth.getSession()).data.session;
   const r=await fetch('/api/integrations/first-party/pos',{method:'POST',headers:{'content-type':'application/json',authorization:`Bearer ${session?.access_token||''}`},body:JSON.stringify({restaurant_id:rid})});
   const j=await r.json();if(!r.ok||!j.ok)throw new Error(j.error||'POS health check failed');
   setMsg(`Anaira POS connection verified · ${j.latency_ms} ms`);await load();
  }catch(e){setMsg(e.message)}finally{setBusy(false)}
 }

 return <section className="first-party-integrations">
  <div className="fpi-hero"><div><span>ANAIRA FIRST-PARTY INTEGRATION FABRIC</span><h2>Products, marketplaces & operational systems</h2><p>These are not fake OTA channels. They are Anaira's own product surfaces and canonical data boundaries. Configure what is enabled, where it gets its data, and which product owns the operational record.</p></div><div className="fpi-prop"><span>PROPERTY</span><select value={rid} onChange={e=>setRid(e.target.value)}><option value="">Select property</option>{properties.map(p=><option key={p.id} value={p.id}>{p.name}</option>)}</select></div></div>
  {msg&&<div className="notice">{msg}</div>}
  <div className="fpi-grid">
   <article className="fpi-card"><div className="fpi-top"><div><small>FIRST-PARTY · HOTEL</small><h3>Anaira Booking Engine</h3></div><b className={bookingEnabled?'fpi-on':'fpi-off'}>{bookingEnabled?'LIVE':'OFF'}</b></div><p>Global switch controls direct booking. Property room types, rooms, rates and inventory stay in HMS/PMS.</p><div className="fpi-links"><Link href="/super-admin/booking-engine">Global settings</Link><Link href="/booking-engine">Property engine</Link><Link href="/plugins/hotel-booking/settings">Plugin settings</Link></div><button className="btn primary" disabled={busy} onClick={()=>togglePlatformSetting('global_booking_engine_enabled',!bookingEnabled)}>{bookingEnabled?'Disable':'Enable'} Booking Engine</button></article>
   <article className="fpi-card"><div className="fpi-top"><div><small>FIRST-PARTY · HOTEL MARKETPLACE</small><h3>Anaira Hotel Marketplace</h3></div><b className={hotelMarketplaceEnabled?'fpi-on':'fpi-off'}>{hotelMarketplaceEnabled?'LIVE':'OFF'}</b></div><p>Public discovery surface for hotels. It consumes live booking/availability data and routes guests into the booking engine.</p><div className="fpi-links"><Link href="/super-admin/hotel-marketplace-settings">Marketplace settings</Link><Link href="/anaira/hotels" target="_blank">Open marketplace ↗</Link></div><button className="btn primary" disabled={busy} onClick={()=>togglePlatformSetting('hotel_marketplace_enabled',!hotelMarketplaceEnabled)}>{hotelMarketplaceEnabled?'Disable':'Enable'} Hotel Marketplace</button></article>
   <article className="fpi-card"><div className="fpi-top"><div><small>FIRST-PARTY · RESTAURANT MARKETPLACE</small><h3>Anaira Restaurant Marketplace</h3></div><b className={restaurantMarketplaceEnabled?'fpi-on':'fpi-off'}>{restaurantMarketplaceEnabled?'LIVE':'OFF'}</b></div><p>Restaurant marketplace is useful here because it is a first-party sales surface. POS/Restaurant SaaS remains the menu, pricing, stock and order master.</p><div className="fpi-links"><Link href="/super-admin/marketplace-settings">Marketplace settings</Link><Link href="/marketplace" target="_blank">Open marketplace ↗</Link><Link href="/super-admin/anaira-store">Store control</Link></div><button className="btn primary" disabled={busy||!restaurantStore} onClick={toggleRestaurantStore}>{restaurantMarketplaceEnabled?'Pause':'Publish'} Restaurant Marketplace</button></article>
   <article className="fpi-card"><div className="fpi-top"><div><small>FIRST-PARTY · RESTAURANT POS</small><h3>Anaira Restaurant POS</h3></div><b className={posConnected?'fpi-on':'fpi-off'}>{posConnected?'CONNECTED':'NOT CONNECTED'}</b></div><p>This is the setting you were looking for. It was present in the older integration model as a POS connection and is now surfaced here again.</p><div className="fpi-links"><Link href="/pos">Open POS</Link><Link href="/plugins/anaira-pos/settings">POS plugin settings</Link></div><button className="btn primary" onClick={openPos}>Configure POS Integration</button></article>
   <article className="fpi-card"><div className="fpi-top"><div><small>FIRST-PARTY · CRM</small><h3>Anaira CRM / Customer 360</h3></div><b className={plugins['crm']||plugins['hotel_guest_crm']?'fpi-on':'fpi-off'}>{plugins['crm']||plugins['hotel_guest_crm']?'AVAILABLE':'PLUGIN OFF'}</b></div><p>CRM receives booking/POS/marketplace customer activity and owns relationship intelligence, segmentation, loyalty and campaigns.</p><div className="fpi-links"><Link href="/plugins">Plugin Control Center</Link><Link href="/hotel-guest-crm">Customer 360</Link><Link href="/super-admin/integrations/restaurant">Restaurant SaaS bridge</Link></div></article>
   <article className="fpi-card"><div className="fpi-top"><div><small>FIRST-PARTY · DISTRIBUTION</small><h3>Anaira Channel / OTA Manager</h3></div><b className={plugins['channel-manager']?'fpi-on':'fpi-off'}>{plugins['channel-manager']?'PLUGIN ON':'PLUGIN OFF'}</b></div><p>External OTA/GDS connections are controlled separately. Global platform catalog → Channel / OTA Manager plugin → property connection → channel → room/rate mapping → ARI/reservation sync.</p><div className="fpi-links"><Link href="/channel-manager">Channel Manager</Link><Link href="/super-admin/integrations">Distribution control</Link><Link href="/hotel-management/room-rate-mapping">Room / Rate Mapping</Link></div></article>
  </div>
  <div className="fpi-flow"><b>MASTER DATA FLOW</b><div>HMS/PMS → Booking Engine → Hotel Marketplace</div><div>Restaurant POS → Restaurant Marketplace → Customer Order</div><div>Booking + POS + Marketplace Events → CRM / Customer 360</div><div>HMS/PMS → Channel Manager → OTA/GDS ↔ Reservations → PMS</div></div>
  {posModal&&<div className="overlay"><div className="modal fpi-modal"><div className="modal-head"><div><div className="eyebrow">ANAIRA POS INTEGRATION</div><h3>{properties.find(x=>x.id===rid)?.name||'Property'}</h3><p>Property-scoped POS connection. Keep machine secrets server-side.</p></div><button className="x" onClick={()=>setPosModal(false)}>×</button></div><div className="form-grid"><label><span>POS Base URL</span><input value={posForm.base_url} onChange={e=>setPosForm({...posForm,base_url:e.target.value})} placeholder="https://your-pos.example"/></label><label><span>Credentials Reference</span><input value={posForm.credentials_ref} onChange={e=>setPosForm({...posForm,credentials_ref:e.target.value})} placeholder="Server-side secret reference"/></label><label><span>Auth Type</span><select value={posForm.auth_type} onChange={e=>setPosForm({...posForm,auth_type:e.target.value})}><option value="api_key">API Key</option><option value="oauth2">OAuth 2.0</option><option value="basic">Basic Auth</option><option value="hmac">HMAC</option></select></label><label><span>Status</span><select value={posForm.status} onChange={e=>setPosForm({...posForm,status:e.target.value})}><option value="disconnected">Disconnected</option><option value="configured">Configured</option></select></label><label className="full"><span>Integration Config JSON</span><textarea rows="8" value={posForm.config} onChange={e=>setPosForm({...posForm,config:e.target.value})}/></label></div><div style={{display:'flex',gap:10,justifyContent:'flex-end'}}><button className="btn" onClick={()=>setPosModal(false)}>Cancel</button><button className="btn" disabled={busy||!pos?.id} onClick={testPos}>Test Connection</button><button className="btn primary" disabled={busy} onClick={savePos}>{busy?'Saving…':'Save POS Integration'}</button></div></div></div>}
 <style jsx global>{`.first-party-integrations{margin-bottom:22px}.fpi-hero{display:flex;justify-content:space-between;gap:18px;align-items:flex-start;padding:22px;border-radius:18px;background:linear-gradient(135deg,#10271f,#173d2f);color:#fff;margin-bottom:16px}.fpi-hero>div:first-child span{font-size:11px;font-weight:900;letter-spacing:1.8px;color:#d5ae4a}.fpi-hero h2{margin:7px 0;font-size:28px}.fpi-hero p{max-width:820px;color:#b9cbc1;line-height:1.6}.fpi-prop{min-width:240px;display:grid;gap:7px}.fpi-prop span{font-size:11px;font-weight:900;color:#d5ae4a}.fpi-prop select{padding:11px;border-radius:10px;border:1px solid #406a59;background:#091c15;color:#fff}.fpi-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:15px}.fpi-card{background:#fff;border:1px solid #e3dfd6;border-radius:18px;padding:19px;box-shadow:0 8px 25px rgba(20,35,28,.06)}.fpi-top{display:flex;justify-content:space-between;gap:10px}.fpi-top small{font-size:10px;font-weight:900;letter-spacing:1.2px;color:#8c6b20}.fpi-top h3{margin:6px 0;font-size:19px}.fpi-card p{color:#66716b;line-height:1.55;min-height:72px}.fpi-on,.fpi-off{font-size:10px;padding:6px 9px;border-radius:999px;height:max-content}.fpi-on{background:#d9f4e5;color:#17643b}.fpi-off{background:#eee;color:#666}.fpi-links{display:flex;gap:7px;flex-wrap:wrap;margin:10px 0 14px}.fpi-links a{font-size:12px;font-weight:800;text-decoration:none;color:#0a4a35}.fpi-flow{margin-top:16px;padding:17px;border-radius:16px;background:#f6f1e5;border:1px solid #e3d8bb;display:grid;gap:6px;color:#3b473f}.fpi-flow b{font-size:11px;letter-spacing:1.4px;color:#8c6b20}.fpi-modal{max-width:760px}@media(max-width:1050px){.fpi-grid{grid-template-columns:repeat(2,minmax(0,1fr))}.fpi-hero{flex-direction:column}.fpi-prop{width:100%}}@media(max-width:680px){.fpi-grid{grid-template-columns:1fr}.fpi-hero h2{font-size:23px}}`}</style>
 </section>;
}
