'use client';
import {Suspense,useEffect,useState} from 'react';
import {useParams,useRouter,useSearchParams} from 'next/navigation';
import {resolveRestaurantId} from '../../lib/publicProperty';
import {supabase} from '../../lib/supabase';

function HotelBookingCheckout({ routeBase = '/property' }){
 const params=useParams(),router=useRouter(),search=useSearchParams();
 const requestedStayType=search.get('stay_type')||'hotel';
 const bookingSource=search.get('booking_source')==='anaira-global-marketplace'?'anaira-global-marketplace':`anaira-${requestedStayType}-store`;
 const [stayType,setStayType]=useState(requestedStayType);
 const key=params?.id||'';
 const [hotel,setHotel]=useState(null),[room,setRoom]=useState(null),[rates,setRates]=useState([]),[rate,setRate]=useState(null),[available,setAvailable]=useState(null),[pay,setPay]=useState(null),[bookingMode,setBookingMode]=useState('hms');
 const [form,setForm]=useState({checkIn:search.get('check_in')||'',checkOut:search.get('check_out')||'',adults:Number(search.get('adults')||2),children:Number(search.get('children')||0),name:'',phone:'',email:'',customerId:search.get('customer_id')||'',corporateCode:search.get('corporate')||'',negotiatedCode:search.get('negotiated')||''});
 const [payment,setPayment]=useState({method:'pay_at_hotel',reference:'',proof:null,proofUrl:'',notes:''});
 const [preferences,setPreferences]=useState({bed_preference:'',arrival_time:'',dietary_preference:'',accessibility:'',airport_transfer:'',nationality:'',billing_company:'',billing_gstin:'',special_requests:''});
 const [loading,setLoading]=useState(true),[busy,setBusy]=useState(false),[quote,setQuote]=useState(null),[quoteError,setQuoteError]=useState(''),[uploading,setUploading]=useState(false),[msg,setMsg]=useState(''),[booking,setBooking]=useState(null);
 const [couponCode,setCouponCode]=useState(search.get('coupon')||'');
 const [couponApplied,setCouponApplied]=useState(search.get('coupon')||'');
 const [addons,setAddons]=useState([]),[selectedAddons,setSelectedAddons]=useState([]),[addonsLoading,setAddonsLoading]=useState(false),[compareQuotes,setCompareQuotes]=useState([]),[compareBusy,setCompareBusy]=useState(false);
  const [showCompareModal,setShowCompareModal]=useState(false),[compareError,setCompareError]=useState('');
 const [sessionId]=useState(()=>{try{return crypto.randomUUID()}catch{return `${Date.now()}-${Math.random().toString(36).slice(2)}`}});
 const [verificationId,setVerificationId]=useState(''),[verifyDestination,setVerifyDestination]=useState(''),[verifyMode,setVerifyMode]=useState('phone'),[verifySent,setVerifySent]=useState(false),[verifyToken,setVerifyToken]=useState(''),[verifyBusy,setVerifyBusy]=useState(false),[verified,setVerified]=useState(false);
 useEffect(()=>{(async()=>{try{const r=await resolveRestaurantId(key);if(!r)throw new Error('Property not found.');
  // Homestay / guest-house / cottage use the canonical Stay catalogue,
  // but retain the established premium 3-step booking experience below.
  if(['homestay','guest_house','cottage'].includes(requestedStayType)){
    const response=await fetch(`/api/public/hospitality/property/${encodeURIComponent(r.id)}?stay_type=${encodeURIComponent(requestedStayType)}`,{cache:'no-store'});
    const payload=await response.json().catch(()=>({}));
    if(!response.ok||!payload?.ok) throw new Error(payload?.error||'Published stay property could not be loaded.');
    const stayProperty=payload.stayProperty;
    if(!stayProperty?.id) throw new Error('Published accommodation property was not found.');
    const catalog=payload.catalog||{};
    const rooms=Array.isArray(catalog.rooms)?catalog.rooms:[];
    const rateRows=Array.isArray(catalog.rates)?catalog.rates:[];
    const requestedRoom=search.get('room_type');
    const requestedRate=search.get('rate_plan');
    const selectedRate=rateRows.find(x=>String(x.id)===String(requestedRate));
    const selectedRoom=rooms.find(x=>String(x.id)===String(requestedRoom)||String(x.room_type_id)===String(requestedRoom))
      ||(selectedRate?rooms.find(x=>String(x.id)===String(selectedRate.room_type_id)||String(x.room_type_id)===String(selectedRate.room_type_id)):null);
    if(!selectedRoom) throw new Error('Selected accommodation is not active on this property. Please return to the room list and select again.');
    const finalRate=selectedRate&&String(selectedRate.room_type_id)===String(selectedRoom.id)
      ? selectedRate : rateRows.find(x=>String(x.room_type_id)===String(selectedRoom.id));
    if(!finalRate) throw new Error('No active rate plan is configured for this accommodation.');
    const normalizedRoom={...selectedRoom,id:selectedRoom.id,room_type_id:selectedRoom.id,
      short_description:selectedRoom.short_description||selectedRoom.description||'',
      description:selectedRoom.description||selectedRoom.short_description||'',
      max_adults:selectedRoom.max_adults??selectedRoom.max_guests??2,
      max_children:selectedRoom.max_children??0,max_guests:selectedRoom.max_guests??selectedRoom.max_adults??2,
      base_rate:selectedRoom.base_rate??finalRate.rate??0,pricing_mode:finalRate.pricing_mode||'per_unit',
      hospitality_type:requestedStayType,image_urls:selectedRoom.image_urls||[],amenities:selectedRoom.amenities||[]};
    const normalizedRates=rateRows.filter(x=>String(x.room_type_id)===String(selectedRoom.id)).map(x=>({
      ...x,room_type_id:selectedRoom.id,hospitality_type:requestedStayType,
      board_type:x.code||x.name||'Standard',rate:Number(x.rate||0),pricing_mode:x.pricing_mode||'per_unit',
      extra_adult:Number(x.extra_adult||0),extra_child:Number(x.extra_child||0)
    }));
    setStayType(requestedStayType);
    setBookingMode('canonical_stay');
    setHotel({id:r.id,stay_property_id:stayProperty.id,...payload.property,
      hotel_name:stayProperty.name||payload.property?.hotel_name||r.name,
      hospitality_type:requestedStayType,hospitality_types:[requestedStayType],
      engine:{},currency:'INR'});
    setRoom(normalizedRoom);setRates(normalizedRates);setRate(normalizedRates.find(x=>String(x.id)===String(finalRate.id))||normalizedRates[0]);
    setLoading(false);
    const {data:ax}=await supabase.from('booking_addons').select('id,name,description,price,addon_type,active').eq('restaurant_id',r.id).eq('active',true).order('name');
    setAddons(ax||[]);
    return;
  }
  const [{data:h},{data:rt},{data:rps},{data:eng},{data:biz}]=await Promise.all([
  supabase.from('hms_settings').select('hotel_name,short_name,logo_url,cover_image_url,address,city,state,country,phone,whatsapp,currency').eq('restaurant_id',r.id).maybeSingle(),
  supabase.from('hms_room_types').select('*').eq('id',search.get('room_type')).eq('restaurant_id',r.id).eq('active',true).maybeSingle(),
  supabase.from('hms_rate_plans').select('*').eq('room_type_id',search.get('room_type')).eq('restaurant_id',r.id).eq('active',true).order('rate'),
  supabase.from('booking_engine_settings').select('*').eq('restaurant_id',r.id).maybeSingle(),
  supabase.from('restaurants').select('hospitality_type,hospitality_types').eq('id',r.id).maybeSingle()
 ]);
 let resolvedRoom=rt;
 let resolvedRates=rps||[];
 let resolvedBookingMode='hms';

 if(requestedStayType==='camp'){
   const {data:legacyUnits}=await supabase.from('camp_unit_types').select('*').eq('restaurant_id',r.id).eq('active',true);
   const legacyById=(legacyUnits||[]).find(x=>String(x.id)===String(search.get('room_type')));
   const legacy=legacyById||(legacyUnits||[]).find(x=>{
     if(!resolvedRoom) return false;
     const sameCode=resolvedRoom.code&&x.code&&String(resolvedRoom.code).trim().toLowerCase()===String(x.code).trim().toLowerCase();
     const sameName=resolvedRoom.name&&x.name&&String(resolvedRoom.name).trim().toLowerCase()===String(x.name).trim().toLowerCase();
     return sameCode||sameName;
   });
   if(!resolvedRates.length&&legacy){
     const {data:legacyRates}=await supabase.from('camp_rate_plans').select('*').eq('restaurant_id',r.id).eq('unit_type_id',legacy.id).eq('active',true).order('rate');
     if(legacyRates?.length){
       resolvedRoom={...legacy,id:legacy.id,room_type_id:legacy.id,hospitality_type:'camp',
         short_description:legacy.short_description||legacy.description||'',
         description:legacy.description||legacy.short_description||'',
         base_rate:legacy.base_rate??legacy.rate??0,
         extra_adult_price:legacy.extra_adult_price??legacy.extra_adult??0,
         extra_child_price:legacy.extra_child_price??legacy.extra_child??0,
         image_urls:Array.isArray(legacy.image_urls)?legacy.image_urls:(Array.isArray(legacy.photos)?legacy.photos:[]),
         amenities:Array.isArray(legacy.amenities)?legacy.amenities:[],
         number_of_beds:legacy.number_of_beds??legacy.beds??1,
         max_adults:legacy.max_adults??legacy.capacity??2,
         max_children:legacy.max_children??0,
         max_guests:legacy.max_guests??legacy.capacity??2,
         bed_type:legacy.bed_type||'Camping',
         pricing_mode:legacy.pricing_mode||'per_person'};
       resolvedRates=legacyRates.map(x=>({...x,room_type_id:legacy.id,hospitality_type:'camp',
         pricing_mode:x.pricing_mode||'per_person',source:'legacy_camp',legacy_unit_type_id:x.unit_type_id}));
       resolvedBookingMode='legacy_camp';
     }
   }
 }
 if(!resolvedRoom)throw new Error('Accommodation type is no longer available.');
 const effectiveStayType=resolvedRoom.hospitality_type||requestedStayType||'hotel';if(Array.isArray(biz?.hospitality_types)&&biz.hospitality_types.length&&!biz.hospitality_types.includes(effectiveStayType))throw new Error('This accommodation type is not enabled for this property.');setStayType(effectiveStayType);setBookingMode(resolvedBookingMode);const list=(resolvedRates||[]).filter(x=>(x.hospitality_type||effectiveStayType)===effectiveStayType);if(!list.length)throw new Error(`No active ${effectiveStayType} rate plan is configured for this accommodation.`);const selected=list.find(x=>x.id===search.get('rate_plan'))||list[0];setHotel({id:r.id,...h,engine:eng||{},hospitality_type:effectiveStayType,hospitality_types:Array.isArray(biz?.hospitality_types)&&biz.hospitality_types.length?biz.hospitality_types:[biz?.hospitality_type||effectiveStayType]});setRoom(resolvedRoom);setRates(list);setRate(selected);setLoading(false);
 const {data:ax}=await supabase.from('booking_addons').select('id,name,description,price,addon_type,active').eq('restaurant_id',r.id).eq('active',true).order('name');setAddons(ax||[]);}catch(e){setMsg(e.message);setLoading(false)}})()},[key,search]);
  useEffect(()=>{if(!showCompareModal)return;const previousOverflow=document.body.style.overflow;const onKeyDown=e=>{if(e.key==='Escape')setShowCompareModal(false)};document.body.style.overflow='hidden';document.addEventListener('keydown',onKeyDown);return()=>{document.body.style.overflow=previousOverflow;document.removeEventListener('keydown',onKeyDown)}},[showCompareModal]);
 useEffect(()=>{setVerified(false);},[]);
 function updateGuestContact(field,value){
  setForm(v=>({...v,[field]:value}));
  setVerified(false);setVerifySent(false);setVerifyToken('');setMsg('');
 }
 async function sendVerification(){
  const email=form.email.trim(), phone=form.phone.trim();
  if(verifyMode==='email'&&!email){setMsg('Enter your email address first.');return}
  if(verifyMode==='phone'&&!phone){setMsg('Enter your mobile number first.');return}
  setVerifyBusy(true);setMsg('');
  try{const res=await fetch('/api/hotel/guest-otp',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({tenant_id:hotel.id,property_type:bookingMode==='canonical_stay'?stayType:(stayType==='camp'?'camp':'hotel'),channel:verifyMode,email,phone})});const data=await res.json();if(!res.ok||!data.ok)throw new Error(data.error||'Unable to send OTP.');setVerificationId(data.verification_id);setVerifyDestination(data.destination_masked||'');setVerifySent(true);setVerifyToken('');setVerified(false);setMsg(`OTP sent to ${data.destination_masked||'your contact'}. It expires in 10 minutes.`)}catch(e){setMsg(e.message)}finally{setVerifyBusy(false)}
 }
 async function verifyContact(){
  if(!verificationId){setMsg('Request a new OTP first.');return}
  if(!/^[0-9]{6}$/.test(verifyToken.trim())){setMsg('Enter the 6-digit verification code.');return}
  setVerifyBusy(true);setMsg('');
  try{const res=await fetch('/api/hotel/guest-otp',{method:'PUT',headers:{'content-type':'application/json'},body:JSON.stringify({verification_id:verificationId,channel:verifyMode,email:form.email.trim(),phone:form.phone.trim(),otp:verifyToken.trim()})});const data=await res.json();if(!res.ok||!data.ok)throw new Error(data.error||'Unable to verify OTP.');setVerified(true);setVerifySent(false);setVerifyToken('');setVerifyDestination(data.destination_masked||verifyDestination);setMsg('Guest contact verified. You can now continue with the booking.')}catch(e){setVerified(false);setMsg(e.message)}finally{setVerifyBusy(false)}
 }
 useEffect(()=>{if(!hotel?.id)return;fetch('/api/public/booking/ab',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({hotel_id:hotel.id,experiment_key:'checkout_premium_v1',session_id:sessionId})}).catch(()=>{});},[hotel?.id,sessionId]);
 useEffect(()=>{let alive=true;setQuote(null);setQuoteError('');(async()=>{if(!hotel||!room||!rate||!form.checkIn||!form.checkOut)return;
  if(bookingMode==='canonical_stay'){
    const nights=Math.max(0,Math.ceil((new Date(form.checkOut+'T00:00:00')-new Date(form.checkIn+'T00:00:00'))/86400000));
    const guests=Math.max(1,Number(form.adults)||1)+Math.max(0,Number(form.children)||0);
    const nightly=Number(rate.rate||0)*(rate.pricing_mode==='per_person'?guests:1);
    const subtotal=Math.round(nightly*nights*Number(rate.seasonal_multiplier||1));
    if(alive)setQuote({ok:true,total:subtotal,subtotal,room_total:subtotal,nights,nightly_rate:nightly,currency:'INR',tax_total:0,addons_total:0,discount_total:0});
    return;
  }
  try{const isCamp=stayType==='camp'&&bookingMode==='legacy_camp';const endpoint=isCamp?'/api/public/booking/camp/quote':'/api/public/booking/premium/quote';const res=await fetch(endpoint,{method:'POST',headers:{'content-type':'application/json'},cache:'no-store',body:JSON.stringify({hotel_id:hotel.id,room_type_id:room.id,rate_plan_id:rate.id,check_in:form.checkIn,check_out:form.checkOut,adults:Number(form.adults)||1,children:Number(form.children)||0,coupon_code:couponApplied||null,addons:selectedAddons,customer_id:form.customerId||null,corporate_code:form.corporateCode||null,negotiated_code:form.negotiatedCode||null})});const data=await res.json();if(!res.ok||!data?.ok)throw new Error(data?.error||'Unable to calculate booking quote.');if(alive)setQuote(data)}catch(e){if(alive)setQuoteError(e.message)}})();return()=>{alive=false}},[hotel?.id,room?.id,rate?.id,form.checkIn,form.checkOut,form.adults,form.children,couponApplied,JSON.stringify(selectedAddons)]);
 useEffect(()=>{setAvailable(null)},[form.checkIn,form.checkOut,form.adults,form.children,room?.id]);
 async function check(){
  if(!hotel||!form.checkIn||!form.checkOut){setMsg('Select check-in and check-out dates.');return false}
  if(capacityExceeded){setAvailable(null);setMsg('Guest occupancy exceeds accommodation capacity. Please reduce the guest count.');return false}
  setMsg('');
  if(stayType==='camp'&&bookingMode==='legacy_camp'){
    const {data,error}=await supabase.rpc('anaira_public_camp_availability',{p_restaurant_id:hotel.id,p_check_in:form.checkIn,p_check_out:form.checkOut,p_adults:Number(form.adults),p_children:Number(form.children)});
    if(error){setAvailable(null);setMsg(error.message);return false}
    const row=(data||[]).find(x=>String(x.unit_type_id||x.room_type_id)===String(room.id));
    const count=Number(row?.available_units??0);setAvailable(count);
    if(!row||count<=0){setMsg('This camping unit is not available for the selected dates.');return false}
    return true;
  }
  if(bookingMode==='canonical_stay'){
    const params=new URLSearchParams({restaurant_id:hotel.id,property_id:hotel.stay_property_id,stay_type:stayType,check_in:form.checkIn,check_out:form.checkOut,adults:String(Number(form.adults)||1),children:String(Number(form.children)||0)});
    const response=await fetch(`/api/public/stay/availability?${params.toString()}`,{cache:'no-store'});
    const payload=await response.json().catch(()=>({}));
    if(!response.ok||!payload?.ok){setAvailable(null);setMsg(payload?.error||'Unable to check stay availability.');return false;}
    const rows=Array.isArray(payload.units)?payload.units:(Array.isArray(payload.data)?payload.data:(Array.isArray(payload.availability)?payload.availability:[]));
    const row=rows.find(x=>String(x.unit_type_id||x.room_type_id)===String(room.id));
    const count=Number(row?.available_units??row?.available_rooms??row?.available_count??0);
    setAvailable(count);
    if(!row||count<=0){setMsg('This accommodation is not available for the selected dates.');return false;}
    return true;
  }
  const {data,error}=await supabase.rpc('anaira_public_hospitality_room_availability_by_id',{p_restaurant_id:hotel.id,p_check_in:form.checkIn,p_check_out:form.checkOut,p_adults:Number(form.adults),p_children:Number(form.children),p_hospitality_type:stayType});
  if(error){setMsg(error.message);setAvailable(null);return false}
  const row=(data||[]).find(x=>String(x.room_type_id)===String(room.id));
  const count=Number(row?.available_rooms??0);setAvailable(count);
  if(!row||count<=0){setMsg(`This ${stayType==='camp'?'camp':'accommodation'} is not available for the selected dates.`);return false}
  return true;
 }
 async function uploadProof(file){if(!file)return;setUploading(true);setMsg('');try{const fd=new FormData();fd.append('file',file);fd.append('restaurant_id',hotel.id);const res=await fetch('/api/hotel/payment-proof',{method:'POST',body:fd});const data=await res.json();if(!res.ok||!data.ok)throw new Error(data.error||'Upload failed');setPayment(p=>({...p,proof:file,proofUrl:data.url}));}catch(e){setMsg(`Receipt upload failed: ${e.message}`)}finally{setUploading(false)}}
 async function applyCoupon(){setCouponApplied(couponCode.trim());}
 async function compareRates(){
  if(!hotel?.id||!room?.id){setMsg('Accommodation details are still loading. Please try again.');return;}
  setShowCompareModal(true);setCompareError('');setCompareQuotes([]);setMsg('');
  // Dates are optional for viewing configured plans. Without dates, show each
  // active plan and its configured nightly rate; do not invent a stay total.
  if(!form.checkIn||!form.checkOut){
   setCompareQuotes((rates||[]).map(plan=>({rate_plan:plan,rate_plan_id:plan.id,nightly_rate:Number(plan.rate||0),_local_plan:true})));
   return;
  }
  if(form.checkOut<=form.checkIn){setCompareError('Check-out must be after check-in.');return;}
  setCompareBusy(true);
  try{
   const r=await fetch('/api/public/booking/rates/compare',{method:'POST',headers:{'content-type':'application/json'},cache:'no-store',body:JSON.stringify({hotel_id:hotel.id,room_type_id:room.id,check_in:form.checkIn,check_out:form.checkOut,adults:Number(form.adults)||1,children:Number(form.children)||0,hospitality_type:stayType,booking_mode:bookingMode,coupon_code:couponApplied||null,addons:selectedAddons,customer_id:form.customerId||null,corporate_code:form.corporateCode||null,negotiated_code:form.negotiatedCode||null})});
   const x=await r.json().catch(()=>({}));
   if(!r.ok||!x.ok)throw new Error(x.error||`Rate comparison failed (HTTP ${r.status}).`);
   setCompareQuotes(Array.isArray(x.quotes)?x.quotes:[]);
   track('rate_compare_opened',{count:(x.quotes||[]).length});
  }catch(e){setCompareError(e.message||'Unable to compare stay plans.');}
  finally{setCompareBusy(false);}
 }
 async function track(event_name,extra={}){try{await fetch('/api/public/booking/events',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({restaurant_id:hotel?.id,session_id:sessionId,event_name,property_id:hotel?.id,room_type_id:room?.id,rate_plan_id:rate?.id,value:quote?.total||null,metadata:extra})})}catch{}}
useEffect(()=>{if(!hotel?.id)return;const save=()=>{if(booking)return;const payload={restaurant_id:hotel.id,session_id:sessionId,guest_name:form.name||null,guest_email:form.email||null,guest_phone:form.phone||null,check_in:form.checkIn||null,check_out:form.checkOut||null,adults:Number(form.adults)||1,children:Number(form.children)||0,room_type_id:room?.id||null,rate_plan_id:rate?.id||null,quote:quote||{},last_step:'checkout',recovered:false,metadata:{hospitality_type:hotel.hospitality_type||'hotel'}};try{fetch('/api/public/booking/abandoned',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(payload),keepalive:true}).catch(()=>{})}catch{}};window.addEventListener('pagehide',save);return()=>window.removeEventListener('pagehide',save)},[hotel?.id,booking,form.name,form.email,form.phone,form.checkIn,form.checkOut,form.adults,form.children,room?.id,rate?.id,quote,sessionId]);
 async function confirmBooking(){
  track('checkout_confirm_started');
  if(!form.name||!form.phone||!form.checkIn||!form.checkOut||!rate){setMsg('Guest name, mobile, dates and rate plan are required.');return}
  if(capacityExceeded){setMsg('Guest occupancy exceeds accommodation capacity. Please reduce the guest count.');return}
  if(quoteError){setMsg(quoteError);return}
  if(!quote){setMsg('Please wait for the selected rate plan price to calculate.');return}
  if(!verified){setMsg('Please verify your phone number or email before booking.');return}
  setBusy(true);setMsg('');
  const idempotency=`${hotel.hospitality_type||'hotel'}:${hotel.id}:${form.checkIn}:${form.checkOut}:${room.id}:${rate.id}:${form.phone.trim().toLowerCase()}`;
  const hotelBookingRpc='anaira_start_verified_hotel_booking_transaction_v3';
  const bookingRuntimeContext={p_customer_id:form.customerId||null,p_corporate_code:form.corporateCode||null,p_negotiated_code:form.negotiatedCode||null};
  try{
   const availabilityOk=available===null?await check():Number(available)>0;
   if(!availabilityOk){setMsg(`This ${label.toLowerCase()} is not available for the selected dates.`);setBusy(false);return}
   const payload={hospitality_type:hotel.hospitality_type,property_id:bookingMode==='canonical_stay'?hotel.stay_property_id:hotel.id,restaurant_id:hotel.id,stay_property_id:hotel.stay_property_id||null,guest_name:form.name,guest_phone:form.phone,guest_email:form.email||null,check_in:form.checkIn,check_out:form.checkOut,unit_type_id:room.id,rate_plan_id:rate.id,adults:Number(form.adults),children:Number(form.children),coupon_code:couponApplied||null,addons:selectedAddons,idempotency_key:idempotency,source:bookingSource,verification_id:verificationId,customer_id:form.customerId||null,corporate_code:form.corporateCode||null,negotiated_code:form.negotiatedCode||null};
   const start=async()=>{const response=await fetch('/api/public/booking/start',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(payload)});const result=await response.json().catch(()=>null);if(!response.ok||!result) {const error=new Error(result?.error||`Booking service returned HTTP ${response.status||'network error'}.`);error.retryable=!response.status||response.status>=500;throw error;}return Array.isArray(result)?result[0]:result;};
   let rec;
   try{rec=await start()}catch(first){if(!first.retryable)throw first;rec=await start()}
   if(!rec?.reservation_id&&!rec?.hms_reservation_id)throw new Error('Reservation was not returned by the booking service. Please check your booking list before retrying.');
   if(rec?.idempotent){
    setBooking(rec);
    if(rec.payment_status==='paid'||rec.reservation_status==='confirmed'||rec.status==='confirmed'){
     setPay({state:'confirmed',payment_status:'paid',booking_code:rec.booking_code});
     setMsg('This booking was already confirmed and paid. Showing the existing reservation; no duplicate booking or payment was created.');
    }else{
     setMsg('An existing reservation was found for these details. Continuing with its saved booking amount.');
    }
    return;
   }
   if(Number.isFinite(Number(rec.amount))&&Number(rec.amount)>0&&Math.abs(Number(rec.amount)-Number(quote.total))>0.01){throw new Error('Rate changed during booking. Please refresh and verify the latest calendar price before proceeding. No payment was submitted. Check the booking list before retrying.');}
   setBooking(rec);
   // Booking created: show payment selection. Do not auto-submit pay-at-property.
   // Camping stays pending property-admin approval until the admin approves.
   setMsg('');
   try{await fetch('/api/public/booking/preferences',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({booking_code:rec.booking_code,phone:form.phone,preferences})})}catch{}
  }catch(error){setMsg(error?.message||'Booking could not be completed. Please retry.');}
  finally{setBusy(false)}
 }
 async function submitPayment(){
  track('payment_started');
  if(!booking?.reservation_id&&!booking?.hms_reservation_id){setMsg('Booking reference is missing.');return}
  if(payment.method!=='pay_at_hotel'&&!payment.proofUrl){setMsg('Please upload the payment receipt/screenshot.');return}
  setBusy(true);setMsg('');
  try{
   const payload={booking_code:booking.booking_code,phone:form.phone,email:form.email,restaurant_id:hotel.id,hospitality_type:hotel.hospitality_type,verification_id:verificationId,verification_channel:verifyMode,payment_method:payment.method,reference:payment.reference||null,proof_url:payment.proofUrl||null,notes:payment.notes||preferences.special_requests||null};
   const res=await fetch('/api/public/booking/payment',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(payload)});
   const data=await res.json().catch(()=>null);
   if(!res.ok||!data?.ok)throw new Error(data?.error||`Payment submission failed (HTTP ${res.status}).`);
   setPay(data);track('payment_submitted',{payment_method:payment.method});
  }catch(error){setMsg(error?.message||'Payment submission failed. Please retry.');}
  finally{setBusy(false)}
 }
 async function downloadGuestConfirmation(){
  if(hotel?.hospitality_type!=='camp'||!booking?.booking_code){setMsg('Guest PDF is available after a camping reservation is confirmed.');return}
  setBusy(true);setMsg('');
  try{
   const response=await fetch('/api/public/booking/confirmation/pdf',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({restaurant_id:hotel.id,booking_code:booking.booking_code,phone:form.phone,email:form.email,verification_id:verificationId,verification_channel:verifyMode})});
   if(!response.ok){const body=await response.json().catch(()=>({}));throw new Error(body?.error||'Confirmation PDF could not be downloaded.');}
   const blob=await response.blob();const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download=`ANAIRA-Booking-${booking.booking_code}.pdf`;document.body.appendChild(a);a.click();a.remove();URL.revokeObjectURL(url);
  }catch(error){setMsg(error?.message||'Confirmation PDF download failed.');}
  finally{setBusy(false)}
 }
 if(loading)return <main className="checkout"><div className="box">Loading booking page…</div></main>;
 if(!room)return <main className="checkout"><div className="box">{msg||'Room not found.'}</div></main>;
 const nights=form.checkIn&&form.checkOut?Math.max(1,Math.round((new Date(form.checkOut)-new Date(form.checkIn))/86400000)):1;
 const nightly=Number(rate?.rate||room.base_rate||0); const pricingMode=rate?.pricing_mode||room.pricing_mode||'per_unit'; const adults=Math.max(1,Number(form.adults)||1); const children=Math.max(0,Number(form.children)||0); const total=Number(quote?.total ?? 0); const quoteSubtotal=Number(quote?.subtotal ?? 0); const label=hotel?.hospitality_type==='camp'?'Camping':hotel?.hospitality_type==='homestay'?'Homestay':hotel?.hospitality_type==='guest_house'?'Guest House':hotel?.hospitality_type==='cottage'?'Cottage':'Hotel'; const eng=hotel?.engine||{}; const bank=eng; const whatsapp=hotel?.whatsapp||hotel?.phone||eng?.whatsapp||eng?.phone||'';
 const maxAdults=Number(room.max_adults??999), maxChildren=Number(room.max_children??999), maxGuests=Number(room.max_guests??(maxAdults+maxChildren)); const capacityExceeded=adults>maxAdults||children>maxChildren||adults+children>maxGuests; const calendarOccupancyQuote=quote?.rate_basis==='daily calendar occupancy rate'||Number(quote?.calendar_nights||0)>0; const quotedNightlyTotal=Number(quote?.nightly_rate??(quote?.nights?Number(quote.subtotal||0)/Number(quote.nights):0)); const calendarPerPerson=calendarOccupancyQuote&&quote?.rate_basis==='per person'; const selectedPlanRate=Number(quote?.nights?(calendarPerPerson?quotedNightlyTotal/Math.max(1,adults+children):calendarOccupancyQuote?quotedNightlyTotal:rate?.pricing_mode==='per_person'?quotedNightlyTotal/Math.max(1,bookingMode==='legacy_camp'?adults+children:adults):quotedNightlyTotal):(rate?.rate||room.base_rate||0)); const extraAdultRate=Number(rate?.extra_adult||rate?.extra_adult_price||room.extra_adult_price||0); const extraChildRate=Number(rate?.extra_child||rate?.extra_child_price||room.extra_child_price||0); const boardType=rate?.board_type||'room_only'; const planPricingMode=rate?.pricing_mode||pricingMode; const planUnit=calendarPerPerson?'person':calendarOccupancyQuote?'unit':planPricingMode==='per_person'?'person':'unit';
 const waText=encodeURIComponent(`${label} booking enquiry\nBooking: ${booking?.booking_code||''}\nGuest: ${form.name}\nRoom: ${room.name}\nRate Plan: ${rate?.name||''}\nCheck-in: ${form.checkIn}\nCheck-out: ${form.checkOut}\nAmount: ₹${total.toLocaleString('en-IN')}`);
 const approvalPending=pay?.state==='pending_approval'||pay?.status==='payment_pending';
 if(pay)return <main className="checkout"><section className="luxury-confirmation"><div className="luxury-gold-rule"/><div className="luxury-mark">✦</div><div className="luxury-kicker">ANAIRA · DIRECT STAYS</div><h1>{approvalPending?'Your stay request is received':pay.state==='confirmed'?'Your stay is confirmed':'Your payment details are received'}</h1><p className="luxury-subtitle">{approvalPending?'The property team will review and approve your reservation. Your stay is not confirmed yet.':pay.payment_status==='pending'?'Your reservation is confirmed. Payment is due at the property.':pay.payment_status==='proof_submitted'?'Your payment proof is awaiting verification.':'Thank you for choosing us. Your booking details are below.'}</p><div className="luxury-divider">✦ &nbsp; RESERVATION DETAILS &nbsp; ✦</div><div className="luxury-ref"><small>YOUR BOOKING REFERENCE</small><strong>{booking?.booking_code||pay.booking_code||'—'}</strong></div><div className="luxury-details"><div><small>GUEST</small><b>{form.name||'—'}</b></div><div><small>ACCOMMODATION</small><b>{room?.name||'—'}</b></div><div><small>CHECK-IN</small><b>{form.checkIn}</b></div><div><small>CHECK-OUT</small><b>{form.checkOut}</b></div><div><small>GUESTS</small><b>{adults} adults · {children} children</b></div><div><small>PAYMENT METHOD</small><b>{payment.method==='pay_at_hotel'?'Pay at property':payment.method.replaceAll('_',' ')}</b></div></div><div className="luxury-total"><span>BOOKING AMOUNT</span><strong>₹{Number(booking?.amount??total).toLocaleString('en-IN')}</strong><small>{approvalPending?'Awaiting property approval':String(pay.payment_status||'pending').replaceAll('_',' ')}</small></div><div className="luxury-actions">{hotel?.hospitality_type==='camp'&&pay.state==='confirmed'&&<button className="confirm" disabled={busy} onClick={downloadGuestConfirmation}>{busy?'Preparing PDF…':'Download Confirmation PDF'}</button>}{whatsapp&&<a className="luxury-contact" href={`https://wa.me/${String(whatsapp).replace(/\D/g,'')}?text=${waText}`} target="_blank" rel="noreferrer">Contact Property on WhatsApp</a>}<button className="luxury-return" onClick={()=>router.push(`${routeBase}/${key}?stay_type=${encodeURIComponent(stayType)}&booking_source=${encodeURIComponent(bookingSource)}#accommodations`)}>Return to Property</button></div><p className="luxury-footer">{approvalPending?'Please keep your reference number. Approval is issued by the property team.':'We look forward to welcoming you.'}</p>{msg&&<div className="error">{msg}</div>}</section><style jsx>{` .luxury-confirmation{max-width:760px;margin:42px auto;padding:50px 54px;background:linear-gradient(160deg,#fffefb,#faf6ee);border:1px solid #e5d9c5;border-radius:24px;text-align:center;box-shadow:0 24px 70px rgba(38,35,23,.09);color:#20372d}.luxury-gold-rule{height:4px;width:140px;margin:-50px auto 32px;background:#c6a66a}.luxury-mark{font-size:32px;color:#bd9556}.luxury-kicker{font-size:10px;letter-spacing:3px;color:#a47e43;font-weight:800;margin:12px}.luxury-confirmation h1{font:400 43px/1.15 Georgia,serif;margin:16px 0}.luxury-subtitle{max-width:550px;margin:0 auto 24px;font-size:14px;line-height:1.7;color:#6e716a}.luxury-divider{color:#b18b4d;font-size:10px;letter-spacing:2px;margin:30px 0}.luxury-ref{padding:24px;background:#f2ece0;border-radius:15px;display:grid;gap:9px}.luxury-ref small,.luxury-details small{font-size:9px;letter-spacing:1.5px;color:#9b8059}.luxury-ref strong{font:500 29px Georgia,serif;letter-spacing:1px}.luxury-details{display:grid;grid-template-columns:1fr 1fr;text-align:left;gap:22px;padding:30px 8px;border-bottom:1px solid #e8decc}.luxury-details>div{display:grid;gap:6px}.luxury-details b{font-size:13px}.luxury-total{display:grid;gap:8px;margin:26px auto}.luxury-total span{font-size:10px;letter-spacing:2px}.luxury-total strong{font:500 37px Georgia,serif}.luxury-total small{color:#7d7b6b}.luxury-actions{display:grid;gap:12px;max-width:400px;margin:auto}.luxury-actions a,.luxury-actions button{padding:14px;border-radius:10px;font-weight:700;text-decoration:none;cursor:pointer}.luxury-contact{border:1px solid #244a3a;color:#244a3a}.luxury-return{background:transparent;border:0;color:#766c60}.luxury-footer{margin-top:28px;color:#8e8679;font-size:11px}@media(max-width:600px){.luxury-confirmation{padding:35px 20px;margin:15px auto}.luxury-confirmation h1{font-size:32px}.luxury-details{grid-template-columns:1fr 1fr;gap:16px}.luxury-ref strong{font-size:22px}} `}</style></main>;
 return <><main className="checkout"><div className="checkout-shell">{!booking&&<><div className="checkout-head"><button className="back" onClick={()=>router.push(`${routeBase}/${key}?stay_type=${encodeURIComponent(stayType)}&booking_source=${encodeURIComponent(bookingSource)}#accommodations`)}>← Back to stays</button><div className="head-copy"><small>DIRECT {label.toUpperCase()} BOOKING</small><h1>Complete Your Stay</h1><p>Choose your dates, guests and rate plan. The final price updates instantly.</p></div><div className="head-badge"><span>STEP 1 OF 2</span><b>Stay details</b></div></div><div className="progress-bar"><div className="progress-step active"><span>01</span><div><b>Stay & guest</b><small>Details and verification</small></div></div><i></i><div className="progress-step"><span>02</span><div><b>Confirm</b><small>Payment & reservation</small></div></div></div><div className="checkout-grid"><section className="box summary"><div className="photo">{room.image_urls?.[0]?<img src={room.image_urls[0]} alt={room.name}/>:<span>{label.toUpperCase()}</span>}<div className="photo-badge">{label}</div></div><div className="summary-top"><div><small>SELECTED {label.toUpperCase()}</small><h2>{room.name}</h2><p>{room.description||room.short_description||'A comfortable stay prepared for a relaxed experience.'}</p></div><div className="capacity-card"><b>{maxGuests}</b><span>max guests</span></div></div><div className="chips"><span>👤 {maxAdults} Adults max</span>{maxChildren>0&&<span>🧒 {maxChildren} Children max</span>}{room.bed_type&&<span>🛏 {room.bed_type}</span>}</div><div className="selected-rate-card"><div><small>SELECTED RATE PLAN</small><strong>{rate?.name||'Select a rate plan'}</strong><span>{boardType.replaceAll('_',' ')} · {rate?.refundable?'Refundable':'Non-refundable'} · {calendarOccupancyQuote?'Calendar occupancy rate':planPricingMode==='per_person'?'Per person':'Per accommodation'}</span></div><div className="rate-price"><b>₹{selectedPlanRate.toLocaleString('en-IN')}</b><span>/{planUnit}/night</span></div></div><div className="rate-applied-note"><span>✓</span><div><b>Rate plan applied</b><small>{quote?.calendar_nights>0?`Calendar pricing applied to ${quote.calendar_nights} of ${quote.nights} nights; other dates use the active rate plan.`:'Changing the plan or stay dates recalculates the active rate automatically.'}</small></div></div><div className="stay-summary"><div><span>Stay</span><b>{nights} night{nights===1?'':'s'}</b></div><div><span>Guests</span><b>{adults} adult{adults===1?'':'s'} · {children} child{children===1?'':'ren'}</b></div><div className="stay-total"><span>Total</span><b>₹{total.toLocaleString('en-IN')}</b></div></div>{quote&&<div className="quote-breakdown"><div><span>Rate plan</span><b>{quote.rate_plan_name||rate?.name}</b></div><div><span>Base / occupancy</span><b>₹{quoteSubtotal.toLocaleString('en-IN')}</b></div>{Number(quote.addons||0)>0&&<div><span>Stay add-ons</span><b>₹{Number(quote.addons).toLocaleString('en-IN')}</b></div>}{Number(quote.discount||0)>0&&<div><span>Discount</span><b>−₹{Number(quote.discount).toLocaleString('en-IN')}</b></div>}{Number(quote.extra_adults||0)>0&&<div><span>Extra adults</span><b>{quote.extra_adults} × ₹{extraAdultRate.toLocaleString('en-IN')}</b></div>}{children>0&&<div><span>Children</span><b>{children} × ₹{extraChildRate.toLocaleString('en-IN')}</b></div>}{Number(quote.tax||0)>0&&<div><span>Taxes</span><b>₹{Number(quote.tax).toLocaleString('en-IN')}</b></div>}</div>}{quoteError&&<div className="quote-error">{quoteError}</div>}<button type="button" onClick={compareRates} disabled={compareBusy} style={{width:'100%',marginTop:10,padding:11,border:'1px solid #d8c8b6',borderRadius:10,background:'#fffaf4',color:'#7d4e28',fontWeight:900,cursor:'pointer'}}>{compareBusy?'Comparing rates…':'Compare Stay Plans'}</button></section><section className="box form booking-panel"><div className="section-heading"><div><small>GUEST & STAY</small><h2>Guest & Stay Details</h2></div><span className="live-pill">● Live pricing</span></div><div className="booking-details-grid"><div className="booking-fields-panel"><div className="dates"><label><span className="field-label">Check-in</span><input type="date" value={form.checkIn} onChange={e=>{setForm({...form,checkIn:e.target.value});setAvailable(null)}}/></label><label><span className="field-label">Check-out</span><input type="date" value={form.checkOut} onChange={e=>{setForm({...form,checkOut:e.target.value});setAvailable(null)}}/></label></div><div className="date-hint">Select your stay dates to calculate the exact nightly rate, guest supplements and total.</div><div className="guests"><label><span className="field-label">Adults</span><input type="number" min="1" max={maxAdults} value={form.adults} onChange={e=>{setForm({...form,adults:Math.max(1,Number(e.target.value)||1)});setAvailable(null)}}/><span>Up to {maxAdults}</span></label><label><span className="field-label">Children</span><input type="number" min="0" max={maxChildren} value={form.children} onChange={e=>{setForm({...form,children:Math.max(0,Number(e.target.value)||0)});setAvailable(null)}}/><span>Up to {maxChildren}</span></label></div>{capacityExceeded&&<div className="capacity-warning"><b>Guest capacity exceeded</b><span>This accommodation allows {maxGuests} guest{maxGuests===1?'':'s'} total.</span></div>}</div><div className="rate-section"><div className="rate-section-head"><div><small>RATE PLAN</small><b>Select your stay plan</b></div><span>{rates.length} plan{rates.length===1?'':'s'}</span></div><select value={rate?.id||''} onChange={e=>{const next=rates.find(x=>x.id===e.target.value)||rate;setRate(next);setAvailable(null);setMsg('')}}>{rates.map(x=><option key={x.id} value={x.id}>{x.name} — ₹{Number(x.id===rate?.id&&quote?.nights?selectedPlanRate:x.rate||0).toLocaleString('en-IN')} {calendarOccupancyQuote&&x.id===rate?.id?'/ unit':x.pricing_mode==='per_person'?'/ person':'/ unit'} / night{x.refundable?' · Refundable':' · Non-refundable'}</option>)}</select></div><div className="premium-extras addons-panel"><div className="section-heading"><div><small>ENHANCE YOUR STAY</small><h2>Add-ons & offers</h2></div><span className="live-pill">Premium booking</span></div><div className="coupon-row"><input value={couponCode} onChange={e=>setCouponCode(e.target.value.toUpperCase())} placeholder="Promo / coupon code"/><button type="button" onClick={applyCoupon} disabled={!couponCode.trim()}>Apply</button></div>{couponApplied&&<div className="coupon-applied">✓ {couponApplied} applied</div>}{addons.length>0&&<div className="addon-grid">{addons.map(a=>{const sel=selectedAddons.find(x=>x.id===a.id);return <button type="button" key={a.id} className={'addon-option '+(sel?'active':'')} onClick={()=>setSelectedAddons(cur=>sel?cur.filter(x=>x.id!==a.id):[...cur,{id:a.id,quantity:1}])}><span><b>{a.name}</b><small>{a.description||a.addon_type}</small></span><strong>+₹{Number(a.price||0).toLocaleString('en-IN')}</strong></button>})}</div>}</div><button className="availability" onClick={check} disabled={capacityExceeded}>{capacityExceeded?'Fix guest count first':'Check Live Availability'}</button>{available!==null&&<div className={`available ${available<=0?'unavailable':''}`}><span>{available>0?'✓':'!'}</span><b>{available}</b> {label.toLowerCase()}{available===1?'':'s'} available for these dates.</div>} </div></section><section className="box form guest-details-panel"><div className="guest-panel-heading"><small>YOUR DETAILS</small><h2>Guest Information</h2><p>Contact, preferences and verification</p></div><div className="guest-details-grid"><div className="guest-divider"><span>Guest information</span></div><label>Guest full name<input value={form.name} onChange={e=>setForm({...form,name:e.target.value})} placeholder="Full name"/></label><div className="contact-grid"><label>Mobile number<input value={form.phone} onChange={e=>updateGuestContact('phone',e.target.value)} placeholder="Guest mobile number" autoComplete="tel"/></label><label>Email address<input value={form.email} onChange={e=>updateGuestContact('email',e.target.value)} placeholder="Guest email address" autoComplete="email"/></label></div><div className="premium-extras guest-preferences"><div className="section-heading"><div><small>GUEST PREFERENCES</small><h2>Personalize your stay</h2></div><span className="live-pill">Optional</span></div><div className="contact-grid"><label>Bed preference<input value={preferences.bed_preference} onChange={e=>setPreferences({...preferences,bed_preference:e.target.value})} placeholder="King / Twin"/></label><label>Arrival time<input type="time" value={preferences.arrival_time} onChange={e=>setPreferences({...preferences,arrival_time:e.target.value})}/></label><label>Dietary preference<input value={preferences.dietary_preference} onChange={e=>setPreferences({...preferences,dietary_preference:e.target.value})} placeholder="Veg / Jain / Other"/></label><label>Accessibility<input value={preferences.accessibility} onChange={e=>setPreferences({...preferences,accessibility:e.target.value})} placeholder="Any requirement"/></label></div><label>Special requests<textarea value={preferences.special_requests} onChange={e=>setPreferences({...preferences,special_requests:e.target.value})} placeholder="Anything the property should know" style={{minHeight:70,padding:13,border:'1px solid #dfd3c5',borderRadius:11}}/></label></div><div className="verify-box"><div className="verify-title"><span>Guest verification</span><small>Required before booking</small></div>{verified?<div className="verified">✓ Verified {verifyMode==='phone'?'mobile number':'email address'}{verifyDestination?` · ${verifyDestination}`:''}</div>:<><div className="verify-methods"><label><input type="radio" checked={verifyMode==='phone'} onChange={()=>{setVerifyMode('phone');setVerifySent(false)}}/> Phone OTP</label><label><input type="radio" checked={verifyMode==='email'} onChange={()=>{setVerifyMode('email');setVerifySent(false)}}/> Email OTP</label></div>{verifySent&&<label>Verification code<input value={verifyToken} onChange={e=>setVerifyToken(e.target.value)} placeholder="Enter 6-digit OTP" inputMode="numeric"/></label>}<div className="verify-actions"><button type="button" className="verify-btn" disabled={verifyBusy} onClick={verifySent?verifyContact:sendVerification}>{verifyBusy?'Please wait…':verifySent?'Verify OTP':`Send ${verifyMode==='phone'?'Phone':'Email'} OTP`}</button>{verifySent&&<button type="button" className="resend" onClick={sendVerification}>Resend</button>}</div></>}</div></div>{msg&&<div className="error">{msg}</div>}<button className="confirm" disabled={busy||!verified||capacityExceeded||!!quoteError||!quote||available===0} onClick={confirmBooking}>{busy?'Creating Reservation…':verified?'Confirm Booking →':'Verify contact to continue'}</button><div className="secure-note">Secure booking · Live availability · Rate plan pricing applied to your reservation</div></section></div></>}{booking&&<section className="payment-box box"><div className="section-heading"><div><small>PAYMENT & CONFIRMATION</small><h2>Complete Payment</h2></div><span className="live-pill">{rate?.name}</span></div><div className="payment-total"><span>Booking {booking.booking_code}</span><b>₹{total.toLocaleString('en-IN')}</b></div><div className="methods"><label><input type="radio" checked={payment.method==='pay_at_hotel'} onChange={()=>setPayment({...payment,method:'pay_at_hotel'})}/> Pay at Property</label><label><input type="radio" checked={payment.method==='bank_transfer'} onChange={()=>setPayment({...payment,method:'bank_transfer'})}/> Bank Transfer</label><label><input type="radio" checked={payment.method==='qr_upi'} onChange={()=>setPayment({...payment,method:'qr_upi'})}/> Pay by QR / UPI</label></div>{payment.method==='bank_transfer'&&<div className="bank"><h3>Bank Account Details</h3><p><b>{bank.bank_name||'Bank details not configured'}</b></p><p>Account Name: {bank.bank_account_name||'—'}</p><p>Account Number: {bank.bank_account_number||'—'}</p><p>IFSC: {bank.bank_ifsc||'—'}</p><p>Branch: {bank.bank_branch||'—'}</p><p>UPI ID: {bank.bank_upi_id||'—'}</p></div>}{payment.method==='qr_upi'&&<div className="bank"><h3>Scan & Pay</h3>{bank.payment_qr_url?<img className="qr" src={bank.payment_qr_url} alt="Property payment QR"/>:<p>QR image is not configured in Booking Engine Control.</p>}{bank.bank_upi_id&&<p>UPI ID: {bank.bank_upi_id}</p>}</div>}{payment.method!=='pay_at_hotel'&&<><label>Payment Reference<input value={payment.reference} onChange={e=>setPayment({...payment,reference:e.target.value})} placeholder="UTR / transaction reference"/></label><label>Upload Payment Screenshot / Receipt<input type="file" accept="image/*,.pdf" onChange={e=>uploadProof(e.target.files?.[0])}/></label>{uploading&&<p>Uploading receipt…</p>}{payment.proofUrl&&<div className="proof-ok">✓ Receipt uploaded</div>}</>}<button className="confirm" disabled={busy||uploading} onClick={submitPayment}>{busy?'Processing…':payment.method==='pay_at_hotel'?'Confirm Stay · Pay at Property':'Submit Payment & Booking'}</button>{whatsapp&&<a className="wa" href={`https://wa.me/${String(whatsapp).replace(/\\D/g,'')}?text=${waText}`} target="_blank" rel="noreferrer">Send Booking on WhatsApp</a>}</section>}</div>{showCompareModal&&<div className="rate-compare-overlay" role="presentation" onMouseDown={e=>{if(e.target===e.currentTarget)setShowCompareModal(false)}}><section className="rate-compare-modal" role="dialog" aria-modal="true" aria-labelledby="rate-compare-title"><div className="rate-compare-header"><div><small>ANAIRA · RATE COMPARISON</small><h2 id="rate-compare-title">Compare available rates</h2><p>{room.name} · {form.checkIn&&form.checkOut?`${form.checkIn} to ${form.checkOut} · ${nights} night${nights===1?'':'s'}`:'Select dates to calculate your stay total'} · {adults} adults, {children} children</p></div><button type="button" className="rate-compare-close" aria-label="Close rate comparison" onClick={()=>setShowCompareModal(false)}>×</button></div>{compareBusy?<div className="rate-compare-empty"><b>Comparing stay plans…</b><span>Checking available prices for your selected dates and guests.</span></div>:compareError?<div className="rate-compare-empty rate-compare-error"><b>Could not compare stay plans</b><span>{compareError}</span><button type="button" onClick={compareRates}>Try again</button></div>:compareQuotes.length===0?<div className="rate-compare-empty"><b>No comparable stay plans found</b><span>No active rate plans are configured for this accommodation.</span></div>:<div className="rate-compare-list">{compareQuotes.map((x,i)=>{const p=x.rate_plan||x.plan||{};const planId=p.id||x.rate_plan_id||x.id;const matchingPlan=rates.find(v=>String(v.id)===String(planId));const planName=p.name||x.rate_plan_name||matchingPlan?.name||'Stay plan';const pricing=p.pricing_mode||matchingPlan?.pricing_mode||'per_unit';const refundable=p.refundable??matchingPlan?.refundable??false;const totalPrice=Number(x.total??x.quote?.total??x.grand_total??0);const localPlan=Boolean(x._local_plan);const nightsCount=Number(x.nights||nights||1);const selected=String(rate?.id)===String(planId);const board=p.board_type||matchingPlan?.board_type||p.meal_plan||'Standard';const cancellation=p.cancellation_policy||matchingPlan?.cancellation_policy||'';const deposit=p.deposit_percent??matchingPlan?.deposit_percent;const minStay=p.min_stay??matchingPlan?.min_stay;const maxStay=p.max_stay??matchingPlan?.max_stay;const nightlyPrice=Number(x.nightly_rate??(nightsCount?totalPrice/nightsCount:totalPrice));return <article className={'rate-compare-item '+(selected?'selected':'')} key={planId||i}><div className="rate-compare-main"><div className="rate-compare-name"><b>{planName}</b>{selected&&<span className="rate-compare-current">CURRENTLY SELECTED</span>}</div><small>{String(board).replaceAll('_',' ')} · {refundable?'Refundable':'Non-refundable'} · {pricing==='per_person'?'Per person':'Per accommodation'}</small><div className="rate-compare-details"><span>Nightly: ₹{nightlyPrice.toLocaleString('en-IN')}</span><span>Base rate: ₹{Number(p.rate??matchingPlan?.rate??0).toLocaleString('en-IN')}</span>{deposit!==undefined&&deposit!==null&&<span>Advance: {deposit}%</span>}{minStay!=null&&<span>Minimum stay: {minStay} nights</span>}{maxStay!=null&&<span>Maximum stay: {maxStay} nights</span>}{cancellation&&<span className="rate-compare-policy">Cancellation: {cancellation}</span>}</div></div><div className="rate-compare-price"><strong>₹{localPlan?Number(p.rate??matchingPlan?.rate??nightlyPrice).toLocaleString('en-IN'):totalPrice.toLocaleString('en-IN')}</strong><small>{localPlan?'per night · select dates for total':`total · ${nightsCount} night${nightsCount===1?'':'s'}`}</small>{Number(x.tax_total||x.tax||0)>0&&<small>Tax ₹{Number(x.tax_total||x.tax).toLocaleString('en-IN')}</small>}{Number(x.discount_total||x.discount||0)>0&&<small>Discount −₹{Number(x.discount_total||x.discount).toLocaleString('en-IN')}</small>}</div><button type="button" className="rate-compare-select" disabled={!matchingPlan||selected} onClick={()=>{setRate(matchingPlan);setAvailable(null);setMsg('');setShowCompareModal(false)}}>{selected?'Selected':matchingPlan?'Select this plan':'Unavailable'}</button></article>})}</div>}<div className="rate-compare-footer"><span>Final price is recalculated when you select a plan.</span><button type="button" onClick={()=>setShowCompareModal(false)}>Close</button></div></section></div>}</main><style>{`
.rate-compare-overlay{position:fixed;inset:0;z-index:10000;display:grid;place-items:center;padding:22px;background:rgba(28,22,17,.58);backdrop-filter:blur(5px)}
.rate-compare-modal{width:min(760px,100%);max-height:min(82vh,760px);overflow:auto;background:#fffdf9;border:1px solid #e5d6c4;border-radius:20px;padding:24px;box-shadow:0 28px 90px rgba(0,0,0,.28);color:#332316}
.rate-compare-header{display:flex;justify-content:space-between;align-items:flex-start;gap:18px;padding-bottom:17px;border-bottom:1px solid #eadfd2}
.rate-compare-header small{font-size:9px;letter-spacing:2px;font-weight:900;color:#b0783c}
.rate-compare-header h2{font:500 29px/1.15 Georgia,serif;margin:6px 0;color:#342316}
.rate-compare-header p{font-size:11px;line-height:1.5;color:#83766a;margin:0}
.rate-compare-close{flex:0 0 36px;width:36px;height:36px;border:1px solid #e4d7c8;border-radius:50%;background:#fff;color:#62452d;font-size:25px;line-height:1;cursor:pointer}
.rate-compare-list{display:grid;gap:10px;padding:18px 0}

.rate-compare-details{display:flex;flex-wrap:wrap;gap:6px;margin-top:3px}
.rate-compare-details span{font-size:8px;line-height:1.45;padding:4px 7px;border-radius:6px;background:#f7f1e9;color:#77685a}
.rate-compare-details .rate-compare-policy{flex-basis:100%;background:#f1f5ed;color:#566b48}
.rate-compare-error span{color:#a33d32}
.rate-compare-error button{justify-self:center;margin-top:8px;border:0;border-radius:8px;padding:10px 16px;background:#8b5c32;color:white;font-weight:800;cursor:pointer}

.rate-compare-item{display:grid;grid-template-columns:minmax(0,1fr) auto auto;align-items:center;gap:16px;padding:15px;border:1px solid #e8ddd1;border-radius:13px;background:#fff}
.rate-compare-item.selected{border-color:#b68a58;background:#fcf6ed;box-shadow:inset 3px 0 #a36a32}
.rate-compare-main{min-width:0;display:grid;gap:7px}
.rate-compare-name{display:flex;align-items:center;flex-wrap:wrap;gap:8px}
.rate-compare-name>b{font-size:13px;color:#382719}
.rate-compare-main>small{font-size:9px;line-height:1.5;color:#82766b;text-transform:capitalize}
.rate-compare-current{font-size:7px;font-weight:900;letter-spacing:.7px;padding:4px 6px;border-radius:99px;background:#e9f1e3;color:#557246}
.rate-compare-price{text-align:right;display:grid;gap:3px;white-space:nowrap}
.rate-compare-price strong{font:600 20px Georgia,serif;color:#925d2f}
.rate-compare-price small{font-size:8px;color:#8b8075}
.rate-compare-select,.rate-compare-footer>button{border:0;border-radius:9px;padding:10px 13px;background:#8b5c32;color:white;font-size:9px;font-weight:900;white-space:nowrap;cursor:pointer}
.rate-compare-select:disabled{background:#e9e1d7;color:#75695d;cursor:default}
.rate-compare-empty{display:grid;gap:7px;padding:30px 12px;text-align:center;color:#493626}
.rate-compare-empty span{font-size:11px;color:#82766b}
.rate-compare-footer{display:flex;justify-content:space-between;align-items:center;gap:12px;padding-top:15px;border-top:1px solid #eadfd2}
.rate-compare-footer>span{font-size:9px;color:#8a7e72;line-height:1.5}
.rate-compare-footer>button{background:#f1e9df;color:#624a34}
@media(max-width:600px){.rate-compare-overlay{padding:10px;align-items:end}.rate-compare-modal{max-height:88vh;padding:17px;border-radius:18px 18px 12px 12px}.rate-compare-header h2{font-size:24px}.rate-compare-item{grid-template-columns:minmax(0,1fr) auto;gap:10px;padding:12px}.rate-compare-select{grid-column:1/-1;width:100%}.rate-compare-price strong{font-size:17px}.rate-compare-footer{align-items:flex-start}.rate-compare-footer>span{max-width:70%}}
:root{--ink:#2f2016;--muted:#776b61;--gold:#a36a32;--gold2:#7f4e25;--line:#e8ddd0;--soft:#faf6ef;--cream:#f6f1e8}
*{box-sizing:border-box}.checkout{min-height:100vh;background:radial-gradient(circle at 15% 0%,#fffdf9 0,#f7f1e8 42%,#f2ece2 100%);padding:34px 24px 80px;color:var(--ink)}.checkout-shell{max-width:1220px;margin:0 auto}.checkout-head{display:grid;grid-template-columns:auto 1fr auto;align-items:center;gap:24px;margin-bottom:16px}.back{border:1px solid #dfd1c0;background:#fffaf4;color:#71451f;border-radius:999px;padding:10px 15px;font-size:11px;font-weight:800;cursor:pointer;white-space:nowrap;box-shadow:0 5px 16px rgba(58,35,18,.05)}.head-copy small,.summary>small,.payment-box>small,.section-heading small,.rate-section-head small{letter-spacing:2.2px;font-size:9px;font-weight:900;color:#b0783c}.checkout-head h1{font:500 44px/1.05 Georgia,serif;margin:6px 0 6px;color:#322015;letter-spacing:-.6px}.head-copy p{margin:0;color:#82766b;font-size:12px;line-height:1.5}.head-badge{padding:12px 16px;border:1px solid #e3d6c7;border-radius:14px;background:rgba(255,255,255,.88);display:grid;gap:4px;min-width:122px;box-shadow:0 10px 25px rgba(62,39,21,.05)}.head-badge span{font-size:8px;letter-spacing:1.6px;color:#b47d3d;font-weight:900}.head-badge b{font-size:11px}.progress-bar{display:grid;grid-template-columns:minmax(0,1fr) 70px minmax(0,1fr);align-items:center;margin:0 0 22px;padding:12px 16px;border:1px solid #e8dccf;background:rgba(255,255,255,.68);border-radius:16px}.progress-bar>i{height:1px;background:#d9c9b8}.progress-step{display:flex;align-items:center;gap:10px;justify-content:center}.progress-step>span{width:29px;height:29px;border-radius:50%;display:grid;place-items:center;border:1px solid #d8c8b6;background:#fff;color:#8b6a4a;font-size:8px;font-weight:900}.progress-step.active>span{background:linear-gradient(135deg,#a8733d,#7d4d27);border-color:#8b5c32;color:#fff}.progress-step b{display:block;font-size:10px}.progress-step small{display:block;color:#92867b;font-size:8px;margin-top:2px}.checkout-grid{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,.98fr);gap:22px;align-items:start}.box{background:rgba(255,255,255,.96);border:1px solid #e5d9cb;border-radius:22px;padding:24px;box-shadow:0 20px 55px rgba(62,39,21,.09);backdrop-filter:blur(6px)}.summary{overflow:hidden}.booking-panel{position:sticky;top:20px}.photo{height:320px;border-radius:17px;overflow:hidden;background:#eee6d9;position:relative;margin-bottom:21px;box-shadow:0 12px 30px rgba(46,30,18,.10)}.photo:after{content:"";position:absolute;inset:auto 0 0;height:38%;background:linear-gradient(transparent,rgba(24,16,10,.32));pointer-events:none}.photo img{width:100%;height:100%;object-fit:cover}.photo span{height:100%;display:grid;place-items:center;color:#8b5c32;font:600 24px Georgia,serif}.photo-badge{position:absolute;z-index:1;left:15px;bottom:14px;padding:8px 11px;border-radius:999px;background:rgba(36,25,17,.82);color:#fff;font-size:8px;font-weight:900;letter-spacing:1.2px;text-transform:uppercase}.summary-top{display:flex;justify-content:space-between;gap:18px;align-items:flex-start}.summary h2,.form h2,.payment-box h2{font:500 30px/1.1 Georgia,serif;margin:5px 0 7px;color:#3b2416}.summary p{color:#7b7066;font-size:12px;line-height:1.7;margin:0;max-width:620px}.capacity-card{min-width:82px;border:1px solid #eadfd2;border-radius:14px;padding:11px;text-align:center;background:#fbf8f3}.capacity-card b{display:block;font:600 22px Georgia,serif;color:#8b5c32}.capacity-card span{font-size:8px;color:#8b8177}.chips{display:flex;flex-wrap:wrap;gap:7px;margin:16px 0}.chips span{background:#f6f0e7;border:1px solid #ebe0d3;padding:7px 10px;border-radius:999px;font-size:9px;color:#66584c}.selected-rate-card{display:flex;justify-content:space-between;gap:15px;align-items:center;border:1px solid #e5d5c3;background:linear-gradient(135deg,#fffaf3,#f7eee2);border-radius:15px;padding:16px;margin-top:16px}.selected-rate-card>div:first-child{display:grid;gap:4px}.selected-rate-card small{font-size:8px;letter-spacing:1.6px;color:#b47d3d;font-weight:900}.selected-rate-card strong{font-size:14px;color:#3b2416}.selected-rate-card span{font-size:9px;color:#7c7167;text-transform:capitalize}.rate-price{text-align:right;white-space:nowrap}.rate-price b{display:block;font:600 23px Georgia,serif;color:#8b5c32}.rate-price span{font-size:8px;color:#8a8076}.rate-applied-note{display:flex;align-items:center;gap:9px;margin-top:10px;padding:10px 12px;border:1px solid #e6dfd5;border-radius:11px;background:#fcfaf7}.rate-applied-note>span{width:20px;height:20px;border-radius:50%;display:grid;place-items:center;background:#edf5e9;color:#4f7540;font-size:10px;font-weight:900}.rate-applied-note b{display:block;font-size:9px}.rate-applied-note small{display:block;color:#8c8177;font-size:8px;margin-top:2px}.stay-summary{display:grid;grid-template-columns:1fr 1fr 1.15fr;gap:1px;background:#e9dfd3;border:1px solid #e9dfd3;border-radius:14px;overflow:hidden;margin-top:15px}.stay-summary>div{background:#fff;padding:13px}.stay-summary span{display:block;color:#8a7f74;font-size:8px;text-transform:uppercase;letter-spacing:1px;margin-bottom:5px}.stay-summary b{font-size:11px}.stay-summary .stay-total{text-align:right;background:#fbf7f1}.stay-summary .stay-total b{font:600 19px Georgia,serif;color:#8b5c32}.quote-breakdown{margin-top:12px;padding:14px;border-radius:13px;background:#faf7f2;border:1px dashed #dccab6;display:grid;gap:8px}.quote-breakdown>div{display:flex;justify-content:space-between;gap:12px;font-size:10px}.quote-breakdown span{color:#81766b}.quote-breakdown b{color:#4b3424;text-align:right}.quote-error,.capacity-warning{margin-top:12px;padding:11px 13px;border-radius:10px;background:#fff0ed;color:#a24738;font-size:10px;border:1px solid #f0d0c9}.capacity-warning{display:grid;gap:3px;margin-bottom:12px}.capacity-warning b{font-size:10px}.capacity-warning span{font-size:9px}.section-heading{display:flex;justify-content:space-between;gap:12px;align-items:flex-start;margin-bottom:18px}.section-heading>div{display:grid;gap:2px}.section-heading h2{margin:3px 0 0}.live-pill{background:#f2f7ee;color:#547045;border:1px solid #d9e6d0;border-radius:999px;padding:7px 10px;font-size:8px;font-weight:900;white-space:nowrap}.dates,.guests{display:grid;grid-template-columns:1fr 1fr;gap:12px}.form label,.payment-box label{display:grid;gap:7px;font-size:9px;font-weight:900;color:#6f6358;margin-bottom:13px}.field-label{font-size:9px;font-weight:900;color:#6f6358}.form input,.form select,.payment-box input{width:100%;box-sizing:border-box;padding:13px 14px;border:1px solid #dfd3c5;background:#fff;border-radius:11px;font:600 11px Montserrat,Arial,sans-serif;color:#3e2b1e;outline:none;transition:.18s}.form input:hover,.form select:hover{border-color:#cbb59e}.form input:focus,.form select:focus,.payment-box input:focus{border-color:#a97845;box-shadow:0 0 0 3px rgba(169,120,69,.10)}.date-hint{font-size:8px;color:#95897e;margin:-4px 0 13px;line-height:1.5}.guests label{position:relative}.guests label>span:not(.field-label){font-size:8px;color:#978b80;font-weight:600;margin-top:-2px}.rate-section{margin-top:4px;padding:15px;border:1px solid #e8ddd1;border-radius:15px;background:#fcfaf7}.rate-section-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:11px}.rate-section-head>div{display:grid;gap:3px}.rate-section-head b{font-size:11px}.rate-section-head>span{font-size:8px;color:#8d8176;background:#f1e9df;padding:5px 8px;border-radius:999px}.rate-section select{margin-bottom:8px}.rate-option:hover{border-color:#c49a6d;transform:translateY(-1px);box-shadow:0 5px 15px rgba(62,39,21,.05)}.rate-option strong{font-size:10px}.rate-option span{font-size:8px;color:#81766d;text-transform:capitalize}.rate-option b small{display:block;font:500 7px Montserrat,Arial,sans-serif;color:#8a7f75;margin-top:2px}.availability,.confirm{width:100%;padding:14px;border:0;border-radius:11px;background:linear-gradient(135deg,#a36b37,#7d4e28);color:#fff;font-weight:900;cursor:pointer;box-shadow:0 9px 22px rgba(127,82,44,.19);margin-top:14px;transition:.18s}.availability:hover:not(:disabled),.confirm:hover:not(:disabled){transform:translateY(-1px);box-shadow:0 12px 26px rgba(127,82,44,.24)}.availability:disabled,.confirm:disabled{opacity:.5;cursor:not-allowed;box-shadow:none}.available{margin:10px 0;padding:10px 12px;border-radius:9px;background:#edf6e9;color:#4c6e40;font-size:10px;font-weight:700;border:1px solid #d9e9d1;display:flex;align-items:center;gap:6px}.available.unavailable{background:#fff0ed;color:#9d4638;border-color:#f0d0c9}.available span{font-weight:900}.guest-divider{border-top:1px solid #e7ddd1;margin:21px 0 16px;position:relative}.guest-divider span{position:relative;top:-9px;background:#fff;padding-right:9px;font-size:8px;text-transform:uppercase;letter-spacing:1.5px;color:#b47d3d;font-weight:900}.contact-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}.verify-box{margin:6px 0 14px;padding:15px;border:1px solid #e6dbcf;border-radius:14px;background:#fbf8f3}.verify-title{display:flex;justify-content:space-between;align-items:center;gap:10px}.verify-title span{font-size:10px;font-weight:900}.verify-title small{font-size:8px;color:#968a80}.verify-methods{display:flex;gap:16px;flex-wrap:wrap;margin:11px 0}.verify-methods label{display:flex;align-items:center;gap:6px;margin:0;font-size:9px}.verify-methods input{width:auto;padding:0}.verify-actions{display:flex;gap:8px;flex-wrap:wrap}.verify-btn,.resend{border:0;border-radius:9px;padding:10px 13px;background:#8b5c32;color:#fff;font-weight:900;cursor:pointer;font-size:9px}.resend{background:#eee6dc;color:#5d4b3c}.verified{margin-top:8px;padding:10px;border-radius:9px;background:#edf7ef;color:#28734b;font-size:9px;font-weight:900}.error{margin:11px 0;padding:11px;border-radius:9px;background:#fff0ed;color:#9b3d2f;font-size:9px;border:1px solid #f0d0c9}.secure-note{text-align:center;color:#9a8e83;font-size:8px;margin-top:10px}.payment-box{max-width:1220px;margin:22px auto}.payment-total{display:flex;justify-content:space-between;align-items:center;padding:14px 16px;background:#faf6f0;border:1px solid #e8ddd1;border-radius:12px;margin-bottom:12px}.payment-total span{font-size:9px;color:#7b7066}.payment-total b{font:600 22px Georgia,serif;color:#8b5c32}.methods{display:grid;grid-template-columns:repeat(3,1fr);gap:9px}.methods label{display:flex;align-items:center;gap:8px;background:#f8f3ec;border:1px solid #e8ddd1;padding:12px;border-radius:10px;margin:0;font-size:9px}.bank{margin:14px 0;padding:16px;background:#f8f3ec;border:1px solid #e7dbce;border-radius:12px}.bank p{margin:7px 0;font-size:10px}.qr{width:190px;height:190px;object-fit:contain;background:#fff;border-radius:10px}.proof-ok{margin:8px 0;padding:9px;background:#eef5eb;color:#49633e;border-radius:8px;font-size:9px}.wa{display:block;text-align:center;margin-top:9px;padding:11px;border-radius:9px;background:#2e7d32;color:#fff;text-decoration:none;font-weight:800;font-size:10px}.success{max-width:680px;margin:10vh auto;text-align:center}.success h1{font:500 44px Georgia,serif}.reference{margin:25px 0;padding:18px;background:#f5f0e7;border-radius:12px;display:grid;gap:5px}.reference span{font-size:10px;color:#756b62}.reference strong{font:600 25px Georgia,serif;color:#8b5c32}.success button{border:0;border-radius:9px;background:#8b5c32;color:#fff;padding:13px 22px;font-weight:700}@media(max-width:980px){.checkout-head{grid-template-columns:1fr}.head-badge{display:none}.progress-bar{grid-template-columns:1fr 30px 1fr 30px 1fr}.checkout-grid{grid-template-columns:1fr}.booking-panel{position:relative;top:auto}.photo{height:300px}}@media(max-width:600px){.checkout{padding:18px 12px 55px}.box{padding:17px;border-radius:16px}.checkout-head h1{font-size:34px}.progress-bar{grid-template-columns:minmax(0,1fr) 30px minmax(0,1fr);padding:10px 8px}.progress-step div{display:none}.progress-step>span{width:28px;height:28px}.dates,.guests,.contact-grid,.methods{grid-template-columns:1fr}.photo{height:220px}.summary h2,.form h2,.payment-box h2{font-size:26px}.stay-summary{grid-template-columns:1fr 1fr}.stay-summary .stay-total{grid-column:1/-1;text-align:left}.selected-rate-card{align-items:flex-start}.rate-price b{font-size:18px}}
}.premium-extras{margin:18px 0;padding:16px;border:1px solid #e8ddd1;border-radius:15px;background:#fcfaf7}.coupon-row{display:grid;grid-template-columns:1fr auto;gap:8px}.coupon-row input{padding:12px;border:1px solid #dfd3c5;border-radius:10px}.coupon-row button{border:0;border-radius:10px;padding:0 18px;background:#8b5c32;color:#fff;font-weight:900}.coupon-row button:disabled{opacity:.45}.coupon-applied{margin-top:8px;padding:8px 10px;border-radius:8px;background:#edf7ef;color:#28734b;font-size:9px;font-weight:800}.addon-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:12px}.addon-option{display:flex;justify-content:space-between;gap:10px;text-align:left;border:1px solid #e5d9cb;background:#fff;border-radius:11px;padding:11px;cursor:pointer}.addon-option.active{border-color:#8b5c32;background:#fff8ee}.addon-option span{display:grid;gap:3px}.addon-option small{font-size:8px;color:#8a8077}.addon-option strong{font:600 12px Georgia,serif;color:#8b5c32;white-space:nowrap}@media(max-width:600px){.addon-grid{grid-template-columns:1fr}.coupon-row{grid-template-columns:1fr}.coupon-row button{padding:12px}}
/* Desktop-first compact checkout: preserve all fields and handlers while using the full viewport. */
/* ANAIRA premium checkout v2: explicit section grids prevent guest fields from auto-flowing into empty columns. */
@media(min-width:1100px){
 .checkout{padding:22px clamp(24px,3vw,58px) 48px;min-height:100dvh}
 .checkout-shell{width:100%;max-width:1560px;margin:0 auto}
 .checkout-head{gap:24px;margin-bottom:18px}
 .checkout-head h1{font-size:clamp(38px,3vw,50px);margin:4px 0 7px;letter-spacing:-1.1px}
 .head-copy p{font-size:12px}
 .back{padding:11px 16px}
 .head-badge{padding:13px 17px}
 .progress-bar{grid-template-columns:minmax(0,1fr) 100px minmax(0,1fr);margin-bottom:20px;padding:12px 22px}
 .progress-step{justify-content:flex-start;gap:12px}
 .progress-step:last-child{justify-content:flex-end}
 .progress-step>span{width:34px;height:34px;font-size:9px}
 .progress-step b{font-size:11px}
 .progress-step small{font-size:9px}
 .checkout-grid{grid-template-columns:minmax(360px,.72fr) minmax(0,1.28fr);gap:22px;align-items:start}
 .box{padding:24px;border-radius:22px}
 .summary{position:sticky;top:22px}
 .photo{height:clamp(210px,25vh,310px);margin-bottom:20px}
 .summary h2{font-size:30px}
 .summary p{font-size:12px;line-height:1.65}
 .chips{margin:16px 0;gap:7px}
 .chips span{padding:7px 10px;font-size:9px}
 .selected-rate-card{padding:16px;margin-top:16px}
 .selected-rate-card strong{font-size:14px}
 .rate-price b{font-size:23px}
 .rate-applied-note{padding:10px 12px;margin-top:10px}
 .stay-summary{margin-top:15px}
 .stay-summary>div{padding:13px}
 .quote-breakdown{padding:14px;margin-top:12px;gap:8px}
 .quote-breakdown>div{font-size:10px}
 .booking-panel{position:relative;top:auto;display:block;min-width:0}
 .booking-panel>.section-heading{margin-bottom:22px;align-items:center}
 .booking-panel>.section-heading h2{font-size:29px}
 .booking-details-grid{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:14px 18px;align-items:start}
 .booking-details-grid>.dates{grid-column:1;gap:10px}
 .booking-details-grid>.date-hint{grid-column:1;margin:-7px 0 0;font-size:9px}
 .booking-details-grid>.guests{grid-column:2;grid-row:1;gap:10px}
 .booking-details-grid>.capacity-warning{grid-column:2;grid-row:2;margin-top:-3px}
 .booking-details-grid>.rate-section,.booking-details-grid>.addons-panel,.booking-details-grid>.availability,.booking-details-grid>.available{grid-column:1/-1}
 .booking-details-grid>.rate-section{margin-top:4px;padding:17px}
 
 .booking-details-grid>.addons-panel{margin:0;padding:17px}
 .booking-details-grid .section-heading h2{font-size:24px}
 .booking-details-grid .availability{margin-top:0;padding:15px;font-size:11px}
 .booking-details-grid .available{margin:0;padding:12px 14px;font-size:10px}
 .guest-details-grid{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:14px 18px;margin-top:22px;padding:22px;border:1px solid #e9dfd3;border-radius:17px;background:linear-gradient(145deg,#fdfbf8,#faf6f0)}
 .guest-details-grid>.guest-divider,.guest-details-grid>label,.guest-details-grid>.contact-grid,.guest-details-grid>.guest-preferences,.guest-details-grid>.verify-box{grid-column:1/-1}
 .guest-details-grid>.guest-divider{margin:2px 0 4px}
 .guest-details-grid>.guest-divider span{background:#fcfaf6}
 .guest-details-grid>label{margin:0}
 .guest-details-grid>.contact-grid{gap:14px}
 .booking-panel label{margin-bottom:0;gap:7px;font-size:10px}
 .booking-panel input,.booking-panel select{padding:12px 13px;font-size:11px;border-radius:10px}
 .booking-panel .date-hint{line-height:1.6}
 .booking-panel .rate-section-head{margin-bottom:12px}
 
 
 
 
 .booking-panel .premium-extras .section-heading{margin-bottom:12px}
 .booking-panel .coupon-row{gap:10px}
 .booking-panel .coupon-row input{padding:12px}
 .booking-panel .coupon-row button{font-size:10px;padding:0 18px}
 .booking-panel .addon-grid{max-height:none;overflow:visible;gap:9px}
 .booking-panel .addon-option{padding:12px}
 .booking-panel .addon-option b{font-size:10px}
 .booking-panel .addon-option small{font-size:9px}
 .booking-panel .addon-option strong{font-size:12px}
 .booking-panel .verify-box{margin:0;padding:16px}
 .booking-panel .verify-methods{margin:12px 0}
 .booking-panel .verify-actions{gap:8px}
 .booking-panel .verify-btn,.booking-panel .resend{padding:11px 15px;font-size:10px}
 .booking-panel .verified{padding:11px;margin-top:8px;font-size:10px}
 .booking-panel>.error,.booking-panel>.confirm,.booking-panel>.secure-note{margin-top:14px}
 .booking-panel>.confirm{padding:16px;font-size:12px}
 .booking-panel .secure-note{font-size:9px}
 .payment-box{max-width:1560px;margin:22px auto}
}
@media(min-width:1100px) and (max-width:1350px){
 .checkout-grid{grid-template-columns:minmax(320px,.82fr) minmax(0,1.18fr);gap:16px}
 .box{padding:18px}
 .guest-details-grid{padding:16px;gap:12px}
 .booking-details-grid{gap:12px}
}
@media(max-width:1099px){
 .checkout-shell{width:100%}
 .checkout-grid{grid-template-columns:minmax(0,1fr)}
 .booking-panel{position:relative;top:auto}
 .booking-details-grid,.guest-details-grid{display:grid;grid-template-columns:minmax(0,1fr);gap:14px}.booking-fields-panel{grid-template-columns:minmax(0,1fr);gap:10px}.booking-fields-panel>.dates,.booking-fields-panel>.date-hint,.booking-fields-panel>.guests,.booking-fields-panel>.capacity-warning{grid-column:1;grid-row:auto}
 .booking-details-grid>* ,.guest-details-grid>*{grid-column:1!important;grid-row:auto!important}
 .guest-details-grid{margin-top:16px;padding:16px;border:1px solid #e9dfd3;border-radius:15px;background:#fcfaf7}
 .booking-panel>.section-heading{margin-bottom:16px}
}
@media(max-width:600px){
 .booking-details-grid>.dates,.booking-details-grid>.guests,.guest-details-grid>.contact-grid{grid-template-columns:1fr 1fr;gap:8px}
 .booking-details-grid .rate-section,.booking-details-grid .addons-panel{padding:13px}
 .guest-details-grid{padding:13px;gap:12px}
}
/* Desktop 3-column, one-screen homestay checkout */
@media(min-width:1200px){
 .checkout{padding:12px 26px 14px;min-height:100dvh}.checkout-shell{max-width:1840px;width:100%}
 .checkout-head{gap:18px;margin-bottom:10px}.checkout-head h1{font-size:clamp(30px,2.2vw,40px);margin:2px 0 4px}.head-copy p{font-size:10px}.back{padding:9px 13px;font-size:10px}.head-badge{padding:9px 13px}
 .progress-bar{margin-bottom:12px;padding:8px 16px;grid-template-columns:1fr 64px 1fr}.progress-step>span{width:27px;height:27px}.progress-step b{font-size:9px}.progress-step small{font-size:7px}
 .checkout-grid{grid-template-columns:minmax(0,1fr) minmax(0,1fr) minmax(0,1fr);gap:14px;align-items:stretch}.checkout-grid>.box{min-width:0;min-height:0;padding:15px;border-radius:17px}
 .summary{position:relative;top:auto}.photo{height:clamp(130px,17vh,175px);margin-bottom:11px;border-radius:12px}.summary-top{gap:8px}.summary h2{font-size:21px;margin:3px 0 4px}.summary p{font-size:9px;line-height:1.4;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
 .capacity-card{min-width:58px;padding:7px}.capacity-card b{font-size:18px}.chips{gap:5px;margin:9px 0}.chips span{font-size:8px;padding:5px 7px}
 .selected-rate-card{padding:10px;margin-top:8px;gap:7px}.selected-rate-card strong{font-size:11px}.selected-rate-card span{font-size:7px;line-height:1.3}.selected-rate-card small{font-size:7px}.rate-price b{font-size:18px}
 .rate-applied-note{padding:7px 9px;margin-top:7px;gap:7px}.rate-applied-note small{font-size:7px}.stay-summary{margin-top:9px}.stay-summary>div{padding:8px 7px}.stay-summary span{font-size:7px;margin-bottom:3px}.stay-summary b{font-size:8px}.stay-summary .stay-total b{font-size:15px}
 .summary .quote-breakdown{padding:9px;margin-top:8px;gap:5px}.summary .quote-breakdown>div{font-size:8px}.summary>button{padding:8px!important;font-size:9px}.summary>.quote-error{font-size:8px}
 .booking-panel{position:relative;top:auto;display:flex;flex-direction:column;gap:9px}.booking-panel>.section-heading{margin:0;align-items:center}.booking-panel>.section-heading h2{font-size:20px}.booking-panel .section-heading small,.guest-panel-heading small{font-size:7px;letter-spacing:1.5px}.booking-panel .live-pill{font-size:7px;padding:5px 7px}
 .booking-details-grid{display:flex;flex-direction:column;align-items:stretch;gap:8px;min-width:0;width:100%}.booking-details-grid>*{width:100%;min-width:0;align-self:stretch;box-sizing:border-box}.booking-fields-panel{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:8px 12px;padding:10px;border:1px solid #e8ddd1;border-radius:11px;background:linear-gradient(145deg,#fdfbf8,#faf6f0);width:100%;min-width:0;box-sizing:border-box}.booking-fields-panel>.dates{grid-column:1;grid-row:1;display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:8px}.booking-fields-panel>.date-hint{grid-column:1;grid-row:2;margin:-4px 0 0;font-size:7px;line-height:1.35}.booking-fields-panel>.guests{grid-column:2;grid-row:1;display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:8px}.booking-fields-panel>.capacity-warning{grid-column:2;grid-row:2;margin:0}.booking-details-grid>.rate-section,.booking-details-grid>.addons-panel{width:100%;min-width:0;align-self:stretch;box-sizing:border-box}.booking-details-grid>.date-hint{margin:-4px 0 0;font-size:7px;line-height:1.35}
 .booking-panel label{margin:0;gap:4px;font-size:8px}.booking-panel input,.booking-panel select{padding:8px 9px;font-size:9px;border-radius:8px}.booking-panel .field-label{font-size:8px}.booking-panel .guests label>span:not(.field-label){font-size:7px}
 .booking-details-grid>.rate-section{margin:0;padding:10px;border-radius:11px;width:100%;min-width:0;align-self:stretch}.booking-panel .rate-section-head{margin-bottom:7px}.booking-panel .rate-section-head b{font-size:9px}.booking-panel .rate-section select{margin:0;padding:8px;font-size:8px}
 .booking-panel .rate-option b small{font-size:6px}
 .booking-panel .premium-extras{margin:0;padding:10px;border-radius:11px}.booking-panel .premium-extras .section-heading{margin-bottom:7px}.booking-panel .section-heading h2{font-size:17px}.booking-panel .coupon-row{gap:6px}.booking-panel .coupon-row input{padding:8px;font-size:8px}.booking-panel .coupon-row button{font-size:8px;padding:0 10px}
 .booking-panel .addon-grid{max-height:72px;overflow:auto;grid-template-columns:1fr;gap:5px;margin-top:6px}.booking-panel .addon-option{padding:7px 8px;border-radius:8px}.booking-panel .addon-option b{font-size:8px}.booking-panel .addon-option small{font-size:7px}.booking-panel .addon-option strong{font-size:9px}
 .booking-panel .availability{margin:0;padding:10px;font-size:9px;border-radius:8px}.booking-panel .available{margin:0;padding:8px;font-size:8px}
 .guest-details-panel{display:flex;flex-direction:column;gap:8px}.guest-details-panel label{margin:0}.guest-panel-heading{padding-bottom:8px;border-bottom:1px solid #eee4d8}.guest-panel-heading h2{font:500 21px/1.1 Georgia,serif;margin:3px 0;color:#3b2416}.guest-panel-heading p{font-size:8px;color:#897d72;margin:0}
 .guest-details-grid{display:flex;flex-direction:column;gap:8px;margin:0;padding:0;border:0;background:transparent;min-width:0}.guest-details-grid>.guest-divider{margin:0;border:0}.guest-details-grid>.guest-divider span{top:0;padding:0;background:transparent;font-size:7px}
 .guest-details-grid>label,.guest-details-grid>.contact-grid,.guest-details-grid>.guest-preferences,.guest-details-grid>.verify-box{width:100%}.guest-details-grid>label{margin:0;font-size:8px}.guest-details-grid>.contact-grid{gap:8px}.guest-details-grid .contact-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}
 .guest-details-grid .premium-extras{margin:0;padding:9px;border-radius:10px}.guest-details-grid .section-heading{margin-bottom:6px}.guest-details-grid .section-heading h2{font-size:14px}.guest-details-grid .guest-preferences .contact-grid{gap:6px}.guest-details-grid .guest-preferences label{font-size:7px;gap:3px}.guest-details-grid .guest-preferences input{padding:7px;font-size:8px}.guest-details-grid .guest-preferences textarea{min-height:38px!important;height:38px;padding:7px!important;font-size:8px}
 .guest-details-grid .verify-box{margin:0;padding:9px;border-radius:10px}.guest-details-grid .verify-title span{font-size:8px}.guest-details-grid .verify-title small,.guest-details-grid .verify-methods label{font-size:7px}.guest-details-grid .verify-methods{margin:6px 0}.guest-details-grid .verify-btn,.guest-details-grid .resend{padding:7px 9px;font-size:8px}.guest-details-grid .verified{padding:7px;font-size:8px}
 .guest-details-panel>.error{margin:0;padding:7px;font-size:8px}.guest-details-panel>.confirm{margin:0;padding:11px;font-size:9px}.guest-details-panel>.secure-note{margin:0;font-size:7px}
}
@media(min-width:1200px) and (max-height:850px){.checkout{padding-top:8px;padding-bottom:8px}.checkout-head{margin-bottom:7px}.checkout-head h1{font-size:30px}.progress-bar{margin-bottom:8px;padding:6px 14px}.checkout-grid>.box{padding:12px}.photo{height:125px}.guest-details-grid .guest-preferences textarea{height:30px;min-height:30px!important}}

/* Readability pass: taller desktop panels, clearer typography and aligned middle column */
@media(min-width:1200px){
 .checkout{padding:16px 30px 20px}.checkout-head{margin-bottom:13px}
 .checkout-head h1{font-size:clamp(34px,2.45vw,44px);margin:3px 0 5px}.head-copy p{font-size:12px}
 .back{font-size:11px;padding:10px 15px}.head-badge{padding:11px 15px}
 .progress-bar{margin-bottom:15px;padding:10px 18px}.progress-step>span{width:30px;height:30px}
 .progress-step b{font-size:10px}.progress-step small{font-size:8px}
 .checkout-grid{gap:16px;align-items:stretch}.checkout-grid>.box{padding:18px;min-height:620px}
 .photo{height:clamp(150px,18vh,190px);margin-bottom:13px}
 .summary h2{font-size:23px}.summary p{font-size:10px;line-height:1.5}
 .chips{gap:6px;margin:11px 0}.chips span{font-size:9px;padding:6px 8px}
 .selected-rate-card{padding:12px;margin-top:10px}.selected-rate-card strong{font-size:12px}
 .selected-rate-card span,.selected-rate-card small{font-size:8px}.rate-price b{font-size:20px}
 .rate-applied-note{padding:9px 11px;margin-top:9px}.rate-applied-note small{font-size:8px}
 .stay-summary{margin-top:11px}.stay-summary>div{padding:10px 9px}.stay-summary span{font-size:8px}
 .stay-summary b{font-size:9px}.stay-summary .stay-total b{font-size:17px}
 .summary>button{padding:10px!important;font-size:10px}
 .booking-panel{gap:12px}.booking-panel>.section-heading h2{font-size:22px}
 .booking-panel .section-heading small,.guest-panel-heading small{font-size:8px}.booking-panel .live-pill{font-size:8px;padding:6px 9px}
 .booking-details-grid{gap:10px}.booking-details-grid>.dates,.booking-details-grid>.guests{gap:10px}
 .booking-details-grid>.date-hint{font-size:8px;line-height:1.45}.booking-panel label{gap:5px;font-size:9px}
 .booking-panel input,.booking-panel select{padding:10px 11px;font-size:11px;border-radius:9px}
 .booking-panel .field-label{font-size:9px}.booking-panel .guests label>span:not(.field-label){font-size:8px}
 .booking-details-grid>.rate-section{padding:12px;border-radius:12px}.booking-panel .rate-section-head{margin-bottom:9px}
 .booking-panel .rate-section-head b{font-size:10px}.booking-panel .rate-section select{padding:10px;font-size:10px}
 
 
 .booking-panel .rate-option b small{font-size:7px}
 .booking-panel .premium-extras{padding:12px;border-radius:12px}.booking-panel .premium-extras .section-heading{margin-bottom:9px}
 .booking-panel .section-heading h2{font-size:19px}.booking-panel .coupon-row{gap:8px}
 .booking-panel .coupon-row input{padding:10px;font-size:10px}.booking-panel .coupon-row button{font-size:9px;padding:0 12px}
 .booking-panel .addon-grid{max-height:96px;gap:7px;margin-top:8px}.booking-panel .addon-option{padding:9px 10px}
 .booking-panel .addon-option b{font-size:9px}.booking-panel .addon-option small{font-size:8px}.booking-panel .addon-option strong{font-size:10px}
 .booking-panel .availability{padding:12px;font-size:10px}.booking-panel .available{padding:10px;font-size:9px}
 .guest-details-panel{gap:10px}.guest-panel-heading{padding-bottom:10px}
 .guest-panel-heading h2{font-size:23px}.guest-panel-heading p{font-size:9px}.guest-details-grid{gap:10px}
 .guest-details-grid>.guest-divider span{font-size:8px}.guest-details-grid>label{font-size:9px}
 .guest-details-grid>.contact-grid,.guest-details-grid .contact-grid{gap:10px}.guest-details-grid .premium-extras{padding:11px}
 .guest-details-grid .section-heading h2{font-size:16px}.guest-details-grid .guest-preferences label{font-size:8px;gap:4px}
 .guest-details-grid .guest-preferences input{padding:9px;font-size:9px}
 .guest-details-grid .guest-preferences textarea{min-height:48px!important;height:48px;padding:9px!important;font-size:9px}
 .guest-details-grid .verify-box{padding:11px}.guest-details-grid .verify-title span{font-size:9px}
 .guest-details-grid .verify-title small,.guest-details-grid .verify-methods label{font-size:8px}
 .guest-details-grid .verify-methods{margin:8px 0}.guest-details-grid .verify-btn,.guest-details-grid .resend{padding:9px 11px;font-size:9px}
 .guest-details-grid .verified{padding:9px;font-size:9px}.guest-details-panel>.error{padding:9px;font-size:9px}
 .guest-details-panel>.confirm{padding:13px;font-size:10px}.guest-details-panel>.secure-note{font-size:8px}
  /* Full-width centre card layout: use the entire middle panel for date and guest fields. */
  .booking-panel,.booking-panel>.section-heading,.booking-panel>.booking-details-grid{width:100%;min-width:0}
  .booking-panel .booking-details-grid{
    display:grid;
    grid-template-columns:minmax(0,1fr);
    align-items:start;
    gap:10px;
    width:100%;
  }
  .booking-panel .booking-details-grid>*{min-width:0;width:100%;max-width:100%;box-sizing:border-box}
  .booking-panel .booking-fields-panel{
    display:grid;
    grid-template-columns:minmax(0,1fr) minmax(0,1fr);
    gap:10px 12px;
    width:100%;
    min-width:0;
    padding:12px;
    box-sizing:border-box;
  }
  .booking-panel .booking-fields-panel>.dates,
  .booking-panel .booking-fields-panel>.guests{
    grid-column:1/-1;
    display:grid;
    grid-template-columns:repeat(2,minmax(0,1fr));
    gap:10px;
    width:100%;
    min-width:0;
  }
  .booking-panel .booking-fields-panel>.date-hint{grid-column:1/-1;margin:-4px 0 0;line-height:1.45}
  .booking-panel .booking-fields-panel>.capacity-warning{grid-column:1/-1;margin:0}
  .booking-panel .booking-details-grid>.rate-section,
  .booking-panel .booking-details-grid>.addons-panel{grid-column:1;width:100%;min-width:0}
  .booking-panel .rate-section select{width:100%;max-width:100%;box-sizing:border-box}
  
  
  .booking-panel .coupon-row{display:grid;grid-template-columns:minmax(0,1fr) auto;width:100%}
  .booking-panel .addon-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));width:100%;max-height:140px;overflow:auto}
  .booking-panel .availability,.booking-panel .available{width:100%;box-sizing:border-box}

}
@media(min-width:1200px) and (max-height:850px){
 .checkout{padding-top:10px;padding-bottom:12px}.checkout-head{margin-bottom:9px}.progress-bar{margin-bottom:10px}
 .checkout-grid>.box{min-height:590px;padding:15px}.photo{height:145px}
}

  /* FINAL DESKTOP FIELD LAYOUT FIX
     Keep dates and guest counts on separate rows. The previous two-column
     parent grid placed the nested .dates and .guests grids side-by-side,
     causing their labels to collide at common desktop widths. */
  @media(min-width:1200px){
    .checkout-grid{
      grid-template-columns:minmax(0,1.02fr) minmax(0,1fr) minmax(0,1fr);
      align-items:start;
    }
    .checkout-grid>.box{
      min-width:0;
      min-height:0;
      height:auto;
    }
    .booking-panel{
      min-width:0;
      overflow:visible;
    }
    .booking-panel .booking-details-grid{
      display:flex;
      flex-direction:column;
      align-items:stretch;
      gap:12px;
      width:100%;
      min-width:0;
    }
    .booking-panel .booking-fields-panel{
      display:flex;
      flex-direction:column;
      align-items:stretch;
      gap:12px;
      width:100%;
      min-width:0;
      padding:14px;
      box-sizing:border-box;
    }
    .booking-panel .booking-fields-panel>.dates,
    .booking-panel .booking-fields-panel>.guests{
      display:grid;
      grid-template-columns:repeat(2,minmax(0,1fr));
      grid-auto-flow:row;
      align-items:start;
      gap:12px;
      width:100%;
      min-width:0;
      margin:0;
    }
    .booking-panel .booking-fields-panel>.date-hint,
    .booking-panel .booking-fields-panel>.capacity-warning{
      width:100%;
      margin:0;
    }
    .booking-panel .booking-fields-panel label{
      display:grid;
      grid-template-columns:minmax(0,1fr);
      align-content:start;
      align-items:start;
      gap:6px;
      min-width:0;
      width:100%;
      margin:0;
      position:static;
    }
    .booking-panel .booking-fields-panel .field-label{
      display:block;
      position:static;
      float:none;
      line-height:1.35;
      white-space:normal;
      min-height:12px;
    }
    .booking-panel .booking-fields-panel input{
      display:block;
      width:100%;
      min-width:0;
      height:42px;
      margin:0;
      position:static;
      line-height:1.2;
    }
    .booking-panel .booking-fields-panel label>span:not(.field-label){
      display:block;
      position:static;
      line-height:1.3;
      margin:0;
    }
    .booking-panel .booking-details-grid>.rate-section,
    .booking-panel .booking-details-grid>.addons-panel,
    .booking-panel .booking-details-grid>.availability,
    .booking-panel .booking-details-grid>.available{
      width:100%;
      min-width:0;
      grid-column:auto;
      margin-left:0;
      margin-right:0;
    }
    
    .booking-panel .addon-grid{
      grid-template-columns:repeat(2,minmax(0,1fr));
    }
  }
  @media(min-width:701px) and (max-width:1199px){
    .checkout-grid{grid-template-columns:minmax(0,1fr) minmax(0,1fr)}
    .checkout-grid>.guest-details-panel{grid-column:1/-1}
    .guest-details-grid{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr)}
    .guest-details-grid>.guest-divider,
    .guest-details-grid>label,
    .guest-details-grid>.contact-grid,
    .guest-details-grid>.guest-preferences,
    .guest-details-grid>.verify-box{grid-column:1/-1}
  }
  @media(max-width:700px){
    .booking-panel .booking-fields-panel{display:flex;flex-direction:column;gap:12px}
    .booking-panel .booking-fields-panel>.dates,
    .booking-panel .booking-fields-panel>.guests{
      display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:9px;width:100%;
    }
    .booking-panel .booking-fields-panel label{display:grid;gap:6px;min-width:0}
    .booking-panel .booking-fields-panel input{width:100%;min-width:0;height:44px}
  }


`}
</style></>;
}


export default function HotelBookingCheckoutPage({ routeBase = '/property' }) {
 return <Suspense fallback={<div style={{padding:'24px',fontFamily:'system-ui'}}>Loading…</div>}>
  <HotelBookingCheckout routeBase={routeBase} />
 </Suspense>;
}
