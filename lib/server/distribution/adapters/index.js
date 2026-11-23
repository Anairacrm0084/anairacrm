import crypto from 'node:crypto';
import {getDistributionProvider,DISTRIBUTION_PROVIDERS} from '../provider-catalog.js';

const PROVIDERS=Object.fromEntries(DISTRIBUTION_PROVIDERS.map(p=>[p.code,{name:p.name,category:p.category,capabilities:p.capabilities,mode:p.mode,approvalRequired:p.approvalRequired,signatureHeader:`x-${p.code.replace(/_/g,'-')}-signature`} ]));
export function getProviderAdapter(code){
 const key=String(code||'').toLowerCase();
 const provider=getDistributionProvider(key);
 return provider?PROVIDERS[key]:{name:key||'Custom',category:'connector',capabilities:[],mode:'customer_managed_rest',approvalRequired:true,signatureHeader:'x-provider-signature'};
}
const first=(...values)=>values.find(v=>v!==undefined&&v!==null&&String(v).trim()!=='');
export function normalizeReservation(provider,payload){
 const p=getProviderAdapter(provider),x=payload||{},guest=x.guest||x.primary_guest||x.customer||{};
 const rooms=x.rooms||x.roomStays||x.room_stays||x.room_types||[];
 return {provider,provider_name:p.name,external_reference:String(first(x.confirmationNumber,x.confirmation_number,x.confirmation_id,x.external_reservation_id,x.reservation_id,x.booking_id,x.id)||''),
  status:String(first(x.status,x.reservation_status,x.booking_status,'confirmed')).toLowerCase(),
  guest:{name:first(guest.name,guest.full_name,guest.first_name&&`${guest.first_name} ${guest.last_name||''}`.trim(),x.guest_name,x.primaryGuestName,''),email:first(guest.email,x.guest_email,x.email,''),phone:first(guest.phone,guest.mobile,x.guest_phone,x.phone,'')},
  stay:{check_in:first(x.check_in,x.checkIn,x.checkin,x.arrival,x.arrival_date,null),check_out:first(x.check_out,x.checkOut,x.checkout,x.departure,x.departure_date,null)},
  rooms,amount:Number(first(x.amount,x.total,x.total_amount,x.totalAmount,x.totalPrice,x.price?.total,0)),currency:String(first(x.currency,x.currencyCode,x.currency_code,'INR')).toUpperCase(),raw:x};
}
export function verifyProviderSignature(raw,signature,secret){
 if(!secret||!signature)return false;
 const expected=crypto.createHmac('sha256',secret).update(raw).digest('hex');
 return expected.length===String(signature).length&&crypto.timingSafeEqual(Buffer.from(expected),Buffer.from(String(signature)));
}
export {PROVIDERS};
