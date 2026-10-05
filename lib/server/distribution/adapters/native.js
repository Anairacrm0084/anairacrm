import {requestWithConnection} from '../runtime-core.js';

export const NATIVE_PROVIDER_CODES = new Set(['booking_com','expedia','agoda','makemytrip','goibibo','gds','google_hotel']);

const DEFAULTS={
 booking_com:{test_path:'/health',inventory_path:'/inventory',rate_path:'/rates',reservation_path:'/reservations',availability_path:'/availability'},
 expedia:{test_path:'/health',inventory_path:'/inventory',rate_path:'/rates',reservation_path:'/reservations',availability_path:'/availability'},
 agoda:{test_path:'/health',inventory_path:'/inventory',rate_path:'/rates',reservation_path:'/reservations',availability_path:'/availability'},
 makemytrip:{test_path:'/health',inventory_path:'/inventory',rate_path:'/rates',reservation_path:'/reservations',availability_path:'/availability'},
 goibibo:{test_path:'/health',inventory_path:'/inventory',rate_path:'/rates',reservation_path:'/reservations',availability_path:'/availability'},
 gds:{test_path:'/health',inventory_path:'/inventory',rate_path:'/rates',reservation_path:'/reservations',availability_path:'/availability'},
 google_hotel:{test_path:'/health',inventory_path:'/inventory',rate_path:'/rates',reservation_path:'/reservations',availability_path:'/availability'}
};

export function nativeConfig(platform,connection){
 const code=platform.provider_code;
 return {...DEFAULTS[code],...(connection.config||{})};
}

export async function testNativeProvider(connection,platform,credentials){
 const cfg=nativeConfig(platform,connection);
 const started=Date.now();
 const r=await requestWithConnection(connection,credentials,{path:cfg.test_path||'/health',method:cfg.test_method||'GET',body:cfg.test_method&&cfg.test_method!=='GET'?cfg.test_body||{}:undefined});
 return {ok:true,status:'connected',adapter:`native_${platform.provider_code}`,provider_code:platform.provider_code,http_status:r.status,latency_ms:Date.now()-started};
}

export async function executeNativeSync(connection,platform,credentials,event){
 const cfg=nativeConfig(platform,connection);
 const path=event.event_type==='inventory'?(cfg.inventory_path||'/inventory'):
   event.event_type==='rates'?(cfg.rate_path||'/rates'):
   event.event_type==='reservation'?(cfg.reservation_path||'/reservations'):
   event.event_type==='availability'?(cfg.availability_path||'/availability'):
   (cfg.generic_path||'/sync');
 const method=event.event_type==='reservation'?(cfg.reservation_method||'POST'):(cfg.sync_method||'POST');
 const r=await requestWithConnection(connection,credentials,{path,method,body:event.payload||{}});
 return {ok:true,provider_status:'accepted',adapter:`native_${platform.provider_code}`,provider_code:platform.provider_code,http_status:r.status,response:r.data};
}
