import crypto from 'node:crypto';

const PROVIDERS={
 booking_com:{name:'Booking.com',paths:{inventory:'/inventory',rates:'/rates',reservations:'/reservations'},signatureHeader:'x-booking-signature'},
 expedia:{name:'Expedia',paths:{inventory:'/inventory',rates:'/rates',reservations:'/reservations'},signatureHeader:'x-expedia-signature'},
 agoda:{name:'Agoda',paths:{inventory:'/inventory',rates:'/rates',reservations:'/reservations'},signatureHeader:'x-agoda-signature'},
 makemytrip:{name:'MakeMyTrip',paths:{inventory:'/inventory',rates:'/rates',reservations:'/reservations'},signatureHeader:'x-mmt-signature'},
 goibibo:{name:'Goibibo',paths:{inventory:'/inventory',rates:'/rates',reservations:'/reservations'},signatureHeader:'x-goibibo-signature'},
 google_hotel:{name:'Google Hotel',paths:{inventory:'/inventory',rates:'/rates',reservations:'/reservations'},signatureHeader:'x-google-signature'},
 gds:{name:'GDS',paths:{inventory:'/inventory',rates:'/rates',reservations:'/reservations'},signatureHeader:'x-gds-signature'}
};
export function getProviderAdapter(code){
 const key=String(code||'').toLowerCase();
 return PROVIDERS[key]||{name:key||'Custom',paths:{inventory:'/inventory',rates:'/rates',reservations:'/reservations'},signatureHeader:'x-provider-signature'};
}
export function normalizeReservation(provider,payload){
 const p=getProviderAdapter(provider),x=payload||{};
 return {provider,provider_name:p.name,external_reference:String(x.confirmationNumber||x.confirmation_number||x.reservation_id||x.id||''),
   status:String(x.status||'confirmed').toLowerCase(),guest:{name:x.guest?.name||x.guest_name||x.primaryGuestName||'',email:x.guest?.email||x.email||'',phone:x.guest?.phone||x.phone||''},
   stay:{check_in:x.check_in||x.checkIn||x.arrival||null,check_out:x.check_out||x.checkOut||x.departure||null},
   rooms:x.rooms||x.roomStays||[],amount:Number(x.amount||x.total||x.total_amount||0),currency:x.currency||'INR',raw:x};
}
export function verifyProviderSignature(raw,signature,secret){
 if(!secret||!signature)return false;
 const expected=crypto.createHmac('sha256',secret).update(raw).digest('hex');
 return expected.length===signature.length&&crypto.timingSafeEqual(Buffer.from(expected),Buffer.from(signature));
}
export {PROVIDERS};
