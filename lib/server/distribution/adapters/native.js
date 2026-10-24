import {requestWithConnection} from '../runtime-core.js';

// These providers do not share a universal REST API. This adapter is a configurable
// transport for an approved provider/channel-manager API, not a claim of native certification.
export const NATIVE_PROVIDER_CODES = new Set(['booking_com','expedia','agoda','makemytrip','goibibo','gds','google_hotel','trip_com','hostelworld','siteminder','staah','airbnb','google_hotel_ads']);

const EVENT_PATHS={inventory:'inventory_path',rates:'rate_path',reservation:'reservation_path',availability:'availability_path'};
function configFor(connection){return connection.config&&typeof connection.config==='object'?connection.config:{}}
function requiredPath(cfg,key,label){const path=String(cfg[key]||'').trim();if(!path)throw new Error(`Provider setup incomplete: configure the ${label} endpoint using the provider's approved API documentation.`);if(/^https?:\/\//i.test(path))throw new Error(`${label} endpoint must be a path relative to the configured Base URL.`);return path;}
export function nativeConfig(_platform,connection){return configFor(connection)}
export async function testNativeProvider(connection,platform,credentials){
 const cfg=nativeConfig(platform,connection);const started=Date.now();
 const testPath=requiredPath(cfg,'test_path','Test Connection');
 const method=String(cfg.test_method||'GET').toUpperCase();
 const r=await requestWithConnection(connection,credentials,{path:testPath,method,body:method==='GET'?undefined:(cfg.test_body||{}),timeoutMs:Number(cfg.timeout_ms)||20000});
 return {ok:true,status:'connected',adapter:`configured_rest_${platform.provider_code}`,provider_code:platform.provider_code,http_status:r.status,latency_ms:Date.now()-started,provider_response:r.data};
}
export async function executeNativeSync(connection,platform,credentials,event){
 const cfg=nativeConfig(platform,connection);const key=EVENT_PATHS[event.event_type];
 if(!key)throw new Error(`Unsupported distribution event type: ${event.event_type}`);
 const path=requiredPath(cfg,key,event.event_type);
 const method=String(cfg[`${event.event_type}_method`]||cfg.sync_method||'POST').toUpperCase();
 const r=await requestWithConnection(connection,credentials,{path,method,body:method==='GET'?undefined:(event.payload||{}),timeoutMs:Number(cfg.timeout_ms)||20000});
 return {ok:true,provider_status:'accepted',adapter:`configured_rest_${platform.provider_code}`,provider_code:platform.provider_code,http_status:r.status,response:r.data};
}
