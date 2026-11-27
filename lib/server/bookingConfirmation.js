import {db} from './provider';
import {requireTenant} from './auth';

const first = value => Array.isArray(value) ? value[0] : value;

export async function loadBookingConfirmation(req, reservationId, restaurantId, source='hms') {
  if (!reservationId || !restaurantId) throw new Error('Reservation and property are required.');
  const {user} = await requireTenant(req, restaurantId);
  const auth = req.headers.get('authorization') || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7).trim() : null;
  const s = db(token);
  const [{data:property,error:propertyError}] = await Promise.all([
    s.from('restaurants').select('id,name,city,address,phone,logo,cover_image').eq('id',restaurantId).maybeSingle()
  ]);
  if (propertyError) throw propertyError;
  if (!property) throw new Error('Property not found for this booking.');

  let reservation=null, accommodation='', accommodationCode='', guestName='', guestPhone='', guestEmail='', stayType='hotel';
  let checkIn=null, checkOut=null, adults=0, children=0, total=0, paid=0, balance=0, paymentStatus='pending', status='pending', bookingCode='', createdAt=null;

  if (source === 'camp') {
    const {data,error}=await s.from('camp_reservations').select('*').eq('id',reservationId).eq('restaurant_id',restaurantId).maybeSingle();
    if(error) throw error;
    reservation=data;
    if(!reservation) throw new Error('Camping reservation not found.');
    const {data:unit,error:unitError}=reservation.unit_type_id
      ? await s.from('camp_unit_types').select('name,code').eq('id',reservation.unit_type_id).eq('restaurant_id',restaurantId).maybeSingle()
      : {data:null,error:null};
    if(unitError) throw unitError;
    accommodation=unit?.name||'Camping accommodation'; accommodationCode=unit?.code||'';
    stayType='camp';
    guestName=reservation.guest_name; guestPhone=reservation.guest_phone; guestEmail=reservation.guest_email;
    checkIn=reservation.check_in; checkOut=reservation.check_out; adults=reservation.adults||0; children=reservation.children||0;
    total=reservation.total_amount||0; paid=reservation.paid_amount||0; balance=reservation.balance_amount??Math.max(0,total-paid);
    paymentStatus=reservation.payment_status||'pending'; status=reservation.status||'pending';
    bookingCode=reservation.reservation_code; createdAt=reservation.created_at;
  } else if (source === 'stay') {
    const {data,error}=await s.from('anaira_stay_reservations').select('*').eq('id',reservationId).eq('restaurant_id',restaurantId).maybeSingle();
    if(error) throw error;
    reservation=data;
    if(!reservation) throw new Error('Stay reservation not found.');
    const [{data:unit,error:unitError},{data:stayProperty,error:stayPropertyError}]=await Promise.all([
      s.from('anaira_stay_unit_types').select('name,code').eq('id',reservation.unit_type_id).eq('restaurant_id',restaurantId).maybeSingle(),
      s.from('anaira_stay_properties').select('name').eq('id',reservation.property_id).eq('restaurant_id',restaurantId).maybeSingle()
    ]);
    if(unitError) throw unitError; if(stayPropertyError) throw stayPropertyError;
    accommodation=unit?.name||'Stay accommodation'; accommodationCode=unit?.code||'';
    stayType=reservation.stay_type||'stay';
    property.name=stayProperty?.name||property.name;
    guestName=reservation.guest_name; guestPhone=reservation.guest_phone; guestEmail=reservation.guest_email;
    checkIn=reservation.check_in; checkOut=reservation.check_out; adults=reservation.adults||0; children=reservation.children||0;
    total=reservation.total_amount||0; paid=reservation.paid_amount||0; balance=reservation.balance_amount??Math.max(0,total-paid);
    paymentStatus=reservation.payment_status||'pending'; status=reservation.status||'pending';
    bookingCode=reservation.reservation_code; createdAt=reservation.created_at;
  } else {
    const {data,error}=await s.from('hms_reservations').select('*').eq('id',reservationId).eq('restaurant_id',restaurantId).maybeSingle();
    if(error) throw error;
    reservation=data;
    if(!reservation) throw new Error('Hotel reservation not found.');
    stayType=reservation.hospitality_type||'hotel';
    let unit=null;
    // Room/unit IDs have appeared under different columns in older booking
    // flows. Resolve the canonical room first, then use the rate plan relation
    // and booking metadata as compatibility fallbacks.
    const specialRaw=first(reservation.special_requests);
    let special=specialRaw;
    if(typeof specialRaw==='string'){
      try{special=JSON.parse(specialRaw)}catch{special={}}
    }
    const roomTypeId=reservation.room_type_id
      ||reservation.unit_type_id
      ||special?.room_type_id
      ||special?.unit_type_id
      ||special?.camp_unit_type_id
      ||null;
    if(roomTypeId){
      const q=await s.from('hms_room_types').select('name,code').eq('id',roomTypeId).eq('restaurant_id',restaurantId).maybeSingle();
      if(q.error) throw q.error; unit=q.data;
    }
    // A few legacy camp reservations were mirrored into HMS without an HMS
    // room_type_id. Their original camp unit is retained in special_requests.
    const campUnitId=special?.camp_unit_type_id||null;
    if(!unit && campUnitId){
      const q=await s.from('camp_unit_types').select('name,code').eq('id',campUnitId).eq('restaurant_id',restaurantId).maybeSingle();
      if(q.error) throw q.error; unit=q.data;
    }
    // If the reservation only retained a rate-plan ID, recover its room type.
    if(!unit && reservation.rate_plan_id){
      const {data:plan,error:planError}=await s.from('hms_rate_plans').select('room_type_id').eq('id',reservation.rate_plan_id).eq('restaurant_id',restaurantId).maybeSingle();
      if(planError) throw planError;
      if(plan?.room_type_id){
        const q=await s.from('hms_room_types').select('name,code').eq('id',plan.room_type_id).eq('restaurant_id',restaurantId).maybeSingle();
        if(q.error) throw q.error; unit=q.data;
      }
    }
    // Last-resort display fallback from the tenant-scoped admin view.
    let adminRecord=null;
    if(!unit){
      const q=await s.from('anaira_hotel_booking_admin_records').select('room_type_name,rate_plan_name').eq('hms_reservation_id',reservationId).eq('tenant_id',restaurantId).maybeSingle();
      if(q.error && !/does not exist|schema cache/i.test(q.error.message||'')) throw q.error;
      adminRecord=q.data||null;
    }
    accommodation=unit?.name||adminRecord?.room_type_name
      ||(stayType==='camp'?'Camping accommodation':stayType==='hotel'?'Hotel accommodation':`${stayType.replaceAll('_',' ')} accommodation`);
    accommodationCode=unit?.code||'';
    const {data:guest,error:guestError}=reservation.guest_id
      ? await s.from('hms_guests').select('full_name,phone,email').eq('id',reservation.guest_id).eq('restaurant_id',restaurantId).maybeSingle()
      : {data:null,error:null};
    if(guestError) throw guestError;
    guestName=guest?.full_name||reservation.guest_name||''; guestPhone=guest?.phone||reservation.guest_phone||''; guestEmail=guest?.email||reservation.guest_email||'';
    checkIn=reservation.check_in; checkOut=reservation.check_out; adults=reservation.adults||0; children=reservation.children||0;
    total=reservation.total_amount||0; paid=reservation.paid_amount||0; balance=reservation.balance_amount??Math.max(0,total-paid);
    paymentStatus=reservation.payment_status||'pending'; status=reservation.status||'pending';
    bookingCode=reservation.booking_reference||reservation.reservation_code; createdAt=reservation.created_at;
  }

  return {
    reservation_id:reservation.id,
    booking_code:bookingCode||reservation.id,
    property_id:restaurantId,
    property_name:property.name,
    property_city:property.city,
    property_address:property.address,
    property_phone:property.phone,
    accommodation,
    accommodation_code:accommodationCode,
    stay_type:stayType,
    guest_name:guestName||'Guest',
    guest_phone:guestPhone||'',
    guest_email:guestEmail||'',
    check_in:checkIn,
    check_out:checkOut,
    adults:Number(adults||0),
    children:Number(children||0),
    total_amount:Number(total||0),
    paid_amount:Number(paid||0),
    balance_amount:Number(balance||0),
    payment_status:paymentStatus,
    status,
    created_at:createdAt,
    source,
    approved_by:user.id
  };
}
