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

const first = (...values) => values.find(v => v !== undefined && v !== null && String(v).trim() !== '');
const asDate = value => {
 if(!value) return null;
 const s=String(value);
 const m=s.match(/^(\d{4}-\d{2}-\d{2})/);
 if(m) return m[1];
 const d=new Date(s); return Number.isNaN(d.getTime())?null:d.toISOString().slice(0,10);
};

// Convert common webhook envelopes to Anaira's stable inbound contract.
// Each OTA may still require a provider-approved adapter/field mapping for its exact schema.
export function normalizeIncomingReservation(provider,body){
 const root=body?.data||body?.payload||body?.event?.data||body?.reservation||body?.booking||body||{};
 const guest=root.guest||root.customer||root.primary_guest||root.booker||{};
 const room=root.room||root.room_type||root.unit||root.accommodation||root.roomStay||{};
 const rate=root.rate_plan||root.ratePlan||root.rate||{};
 const externalId=first(root.external_reservation_id,root.reservation_id,root.booking_id,root.confirmation_number,root.reference,root.id,body?.event_id,body?.id);
 const checkIn=asDate(first(root.check_in,root.checkin,root.arrival,root.arrival_date,root.start_date,root.checkIn));
 const checkOut=asDate(first(root.check_out,root.checkout,root.departure,root.departure_date,root.end_date,root.checkOut));
 const eventType=String(first(body?.event_type,body?.type,root.event_type,root.status,'reservation')).toLowerCase();
 const statusRaw=String(first(root.status,root.reservation_status,root.booking_status,'confirmed')).toLowerCase();
 const action=/cancel|void/.test(eventType)||/cancel|void/.test(statusRaw)?'cancel':/modif|amend|change/.test(eventType)?'modify':'reservation';
 const normalized={
  external_reservation_id:String(externalId||''),
  guest_name:String(first(guest.full_name,guest.name,guest.first_name&&`${guest.first_name} ${guest.last_name||''}`.trim(),root.guest_name,root.customer_name,'OTA Guest')),
  guest_phone:first(guest.phone,guest.telephone,guest.mobile,root.guest_phone,root.phone)||null,
  guest_email:first(guest.email,root.guest_email,root.email)||null,
  check_in:checkIn,check_out:checkOut,
  adults:Number(first(root.adults,root.adult_count,root.number_of_adults,root.occupancy?.adults,1)),
  children:Number(first(root.children,root.child_count,root.number_of_children,root.occupancy?.children,0)),
  total_amount:Number(first(root.total_amount,root.total,root.amount,root.price?.total,root.pricing?.total,0)),
  external_room_code:first(room.external_code,room.room_type_code,room.code,room.id,root.external_room_code,root.room_code)||null,
  external_rate_code:first(rate.external_code,rate.code,rate.id,root.external_rate_code,root.rate_code)||null,
  status:/cancel|void/.test(statusRaw)?'cancelled':statusRaw,
  special_requests:root.special_requests||root.remarks||root.comments||{},
  hospitality_type:root.hospitality_type||'hotel',
  cancellation_reason:root.cancellation_reason||root.cancel_reason||null,
  event_type:eventType
 };
 if(!normalized.external_reservation_id) throw new Error('Provider webhook is missing a reservation identifier.');
 if(action!=='cancel'&&(!normalized.check_in||!normalized.check_out)) throw new Error('Provider webhook requires check-in and check-out dates; configure a provider-specific payload adapter if its schema differs.');
 return {action,payload:normalized};
}
