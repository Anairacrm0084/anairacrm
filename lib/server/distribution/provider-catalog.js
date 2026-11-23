/**
 * Anaira distribution connector catalogue.
 * `configurable_rest` means a provider-approved API/channel-manager endpoint must be
 * supplied. It is NOT a claim that Anaira has been certified by that provider.
 */
export const DISTRIBUTION_PROVIDERS = Object.freeze([
 {code:'booking_com',name:'Booking.com',category:'ota',mode:'direct_or_channel_manager',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:true},
 {code:'airbnb',name:'Airbnb',category:'ota',mode:'approved_connectivity_partner',capabilities:['availability','reservations','modifications','cancellations'],approvalRequired:true},
 {code:'agoda',name:'Agoda',category:'ota',mode:'direct_or_channel_manager',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:true},
 {code:'expedia',name:'Expedia Group',category:'ota',mode:'direct_or_channel_manager',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:true},
 {code:'makemytrip',name:'MakeMyTrip',category:'ota',mode:'partner_api_or_channel_manager',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:true},
 {code:'goibibo',name:'Goibibo',category:'ota',mode:'partner_api_or_channel_manager',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:true},
 {code:'trip_com',name:'Trip.com',category:'ota',mode:'direct_or_channel_manager',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:true},
 {code:'hostelworld',name:'Hostelworld',category:'ota',mode:'partner_api_or_channel_manager',capabilities:['availability','reservations','modifications','cancellations'],approvalRequired:true},
 {code:'google_hotel_ads',name:'Google Hotel Ads',category:'metasearch',mode:'hotel_center_connectivity',capabilities:['rates','booking_links'],approvalRequired:true},
 {code:'google_hotel',name:'Google Hotel',category:'metasearch',mode:'hotel_center_connectivity',capabilities:['rates','booking_links'],approvalRequired:true},
 {code:'siteminder',name:'SiteMinder',category:'channel_manager',mode:'channel_manager_api',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:true},
 {code:'staah',name:'STAAH',category:'channel_manager',mode:'channel_manager_api',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:true},
 {code:'gds',name:'GDS',category:'channel_manager',mode:'contracted_gds_bridge',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:true},
 {code:'custom_api',name:'Custom API Connector',category:'connector',mode:'customer_managed_rest',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:false},
 {code:'anaira_booking_engine',name:'Anaira Booking Engine',category:'anaira',mode:'native_internal',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:false},
 {code:'anaira_marketplace',name:'Anaira Marketplace',category:'anaira',mode:'native_internal',capabilities:['rates','availability','reservations','modifications','cancellations'],approvalRequired:false},
]);
export const PROVIDER_BY_CODE = Object.freeze(Object.fromEntries(DISTRIBUTION_PROVIDERS.map(p=>[p.code,p])));
export function getDistributionProvider(code){return PROVIDER_BY_CODE[String(code||'').trim().toLowerCase()]||null;}
export function validateProviderSetup(providerCode,connection={}){
 const provider=getDistributionProvider(providerCode); if(!provider) return {ok:false,stage:'provider',errors:['Unsupported distribution provider.']};
 const errors=[]; const warnings=[]; const cfg=connection.config&&typeof connection.config==='object'?connection.config:{};
 if(provider.mode!=='native_internal'){
  let u;try{u=new URL(String(connection.base_url||''));}catch{}
  if(!u||u.protocol!=='https:'||u.username||u.password) errors.push('A public provider-approved HTTPS Base URL is required.');
  if(!connection.auth_type) errors.push('Authentication type is required.');
  for(const [key,label] of [['test_path','test connection'],['inventory_path','inventory'],['rate_path','rates'],['reservation_path','reservations']]){
   if(provider.category==='metasearch'&&key==='reservation_path') continue;
   if(!String(cfg[key]||'').trim()) errors.push(`Configure the approved ${label} endpoint path.`);
   else if(/^https?:\/\//i.test(String(cfg[key]))) errors.push(`${label} endpoint must be a relative path, not a full URL.`);
  }
  if(provider.approvalRequired) warnings.push('Provider approval, contract and production credentials must be confirmed outside Anaira before activation.');
 }
 if(provider.category==='metasearch') warnings.push('Metasearch booking-link integration is not a general OTA reservation inbox.');
 return {ok:errors.length===0,stage:errors.length?'configuration':'ready_for_live_test',provider,errors,warnings};
}
