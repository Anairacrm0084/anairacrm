import { db } from './provider';

function normalizePhone(v){return String(v||'').replace(/\D/g,'');}
function normalizeEmail(v){return String(v||'').trim().toLowerCase();}
function normalizeName(v){return String(v||'').trim().replace(/\s+/g,' ').toLowerCase();}
function daysBetween(a,b){if(!a||!b)return 0;return Math.max(0,Math.round((new Date(b)-new Date(a))/86400000));}

async function resolveHospitalityProperty(s, tenantId, record){
  const candidate = record?.metadata?.property_id || record?.metadata?.hospitality_property_id || record?.property_id || null;
  if(candidate){
    const {data}=await s.from('anaira_hospitality_properties_master').select('id').eq('id',candidate).eq('tenant_id',tenantId).maybeSingle();
    if(data?.id)return data.id;
    const {data:source}=await s.from('anaira_hospitality_properties_master').select('id').eq('source_id',candidate).eq('tenant_id',tenantId).maybeSingle();
    if(source?.id)return source.id;
  }
  return null;
}

export async function syncHotelGuestTenant(tenantId){
  const s=db();
  const now=new Date().toISOString();
  const stats={customers_created:0,customers_linked:0,booking_links:0,stays_upserted:0,events_upserted:0,pms_applied:0,timeline_refreshed:0,events_processed:0};
  const {data:bookings,error:be}=await s.from('booking_reservations').select('*').eq('restaurant_id',tenantId).order('created_at',{ascending:false}).limit(5000);
  if(be)throw be;
  const {data:pms,error:pe}=await s.from('pms_reservations').select('*').eq('restaurant_id',tenantId).order('created_at',{ascending:false}).limit(5000);
  if(pe)throw pe;
  const {data:existing,error:ce}=await s.from('crm_customers').select('*').eq('tenant_id',tenantId).limit(10000);
  if(ce)throw ce;
  const customers=existing||[];
  const {data:properties}=await s.from('anaira_hospitality_properties_master').select('id,source_table,source_id,name,property_type').eq('tenant_id',tenantId).eq('active',true).order('created_at');
  const propertyBySource=new Map((properties||[]).map(p=>[String(p.source_id),p.id]));
  const defaultProperty=(properties||[])[0]?.id||null;
  const byEmail=new Map(),byPhone=new Map(),byName=new Map(),byBooking=new Map();
  for(const c of customers){
    const email=normalizeEmail(c.email), phone=normalizePhone(c.phone), name=normalizeName(c.full_name);
    if(email)byEmail.set(email,c); if(phone)byPhone.set(phone,c); if(name)byName.set(name,c);
  }
  for(const b of bookings||[]){
    if(b.booking_code && b.customer_id)byBooking.set(String(b.booking_code),b.customer_id);
  }

  const resolveCustomer=async(g)=>{
    const suppliedId=g.customer_id||null;
    const bookingCode=String(g.booking_code||'').trim();
    const email=normalizeEmail(g.guest_email||g.email);
    const phone=normalizePhone(g.guest_phone||g.phone);
    const name=String(g.guest_name||g.full_name||'').trim();
    let c=(suppliedId&&customers.find(x=>x.id===suppliedId))
      ||(bookingCode&&customers.find(x=>x.id===byBooking.get(bookingCode)))
      ||byEmail.get(email)||byPhone.get(phone)||byName.get(normalizeName(name));
    if(c){stats.customers_linked++;return c;}
    if(!name)return null;
    const ins=await s.from('crm_customers').insert({
      tenant_id:tenantId,full_name:name,phone:g.guest_phone||g.phone||null,
      email:g.guest_email||g.email||null,customer_type:'guest',country:'India',
      preferred_language:'en',created_at:now,updated_at:now
    }).select('*').single();
    if(ins.error)throw ins.error;
    c=ins.data;customers.push(c);
    if(email)byEmail.set(email,c);if(phone)byPhone.set(phone,c);byName.set(normalizeName(name),c);
    stats.customers_created++;return c;
  };

  for(const b of bookings||[]){
    const c=await resolveCustomer(b); if(!c)continue;
    const propertyId=await resolveHospitalityProperty(s,tenantId,b);
    if(b.customer_id!==c.id){
      const link=await s.from('booking_reservations').update({customer_id:c.id,updated_at:now}).eq('id',b.id).eq('restaurant_id',tenantId);
      if(link.error)throw link.error;
      stats.booking_links++;
    }
    if(b.booking_code)byBooking.set(String(b.booking_code),c.id);
    const payload={
      tenant_id:tenantId,customer_id:c.id,external_booking_id:b.booking_code||b.id,
      property_id:propertyId,room_type_id:b.room_type_id||null,room_number:b.room_number||null,
      check_in_date:b.check_in,check_out_date:b.check_out,
      nights:daysBetween(b.check_in,b.check_out),booking_source:b.source||'direct',
      booking_status:b.status||'pending',total_amount:Number(b.total_amount||0),
      special_requests:b.special_requests||b.metadata?.special_requests||null,updated_at:now
    };
    const u=await s.from('crm_guest_stays').upsert(payload,{onConflict:'tenant_id,external_booking_id'}).select('id').single();
    if(u.error)throw u.error; stats.stays_upserted++;
    const eventType=['confirmed','reserved'].includes(String(b.status||'').toLowerCase())?'booked':String(b.status||'').toLowerCase()==='cancelled'?'cancelled':'booked';
    const e=await s.from('crm_guest_stay_events').upsert({
      tenant_id:tenantId,customer_id:c.id,stay_id:u.data.id,event_type:eventType,
      payload:{booking_id:b.id,booking_code:b.booking_code,status:b.status,source:b.source},
      source:'booking_engine',event_key:`booking:${b.id}:${eventType}`
    },{onConflict:'tenant_id,event_key'});
    if(e.error)throw e.error; stats.events_upserted++;
  }

  for(const p of pms||[]){
    const bookingCode=String(p.booking_code||'').trim();
    let linkedCustomerId=bookingCode?byBooking.get(bookingCode):null;
    if(!linkedCustomerId && bookingCode){
      const {data:b}=await s.from('booking_reservations').select('customer_id').eq('restaurant_id',tenantId).eq('booking_code',bookingCode).maybeSingle();
      linkedCustomerId=b?.customer_id||null;
    }
    const c=await resolveCustomer({customer_id:linkedCustomerId,booking_code:bookingCode,guest_name:p.guest_name,guest_phone:p.guest_phone,guest_email:p.guest_email});
    if(!c)continue;
    const stayQuery=bookingCode
      ? s.from('crm_guest_stays').select('id').eq('tenant_id',tenantId).eq('external_booking_id',bookingCode).maybeSingle()
      : s.from('crm_guest_stays').select('id').eq('tenant_id',tenantId).eq('customer_id',c.id).eq('check_in_date',p.check_in).eq('check_out_date',p.check_out).maybeSingle();
    const {data:stay}=await stayQuery;
    const propertyId=await resolveHospitalityProperty(s,tenantId,p);
    const payload={
      tenant_id:tenantId,customer_id:c.id,external_booking_id:bookingCode||p.id,
      property_id:propertyId,room_number:p.room_number||null,check_in_date:p.check_in,
      check_out_date:p.check_out,nights:daysBetween(p.check_in,p.check_out),
      booking_source:p.source||'pms',booking_status:p.status||'reserved',
      total_amount:Number(p.total_amount||0),updated_at:now
    };
    let stayId=stay?.id||null;
    if(stay){const u=await s.from('crm_guest_stays').update(payload).eq('id',stay.id).eq('tenant_id',tenantId);if(u.error)throw u.error;}
    else {const u=await s.from('crm_guest_stays').upsert(payload,{onConflict:'tenant_id,external_booking_id'}).select('id').single();if(u.error)throw u.error;stayId=u.data.id;}
    stats.pms_applied++;
    const eventMap={reserved:'reserved',arrived:'arrived',checked_in:'checked_in','checked-in':'checked_in',checked_out:'checkout','checked-out':'checkout',cancelled:'cancelled',no_show:'no_show'};
    const et=eventMap[String(p.status||'').toLowerCase()]||'pms_sync';
    const e=await s.from('crm_guest_stay_events').upsert({
      tenant_id:tenantId,customer_id:c.id,stay_id:stayId,event_type:et,
      payload:{pms_reservation_id:p.id,status:p.status,room_id:p.room_id,booking_code:bookingCode},
      source:'pms',event_key:`pms:${p.id}:${et}`
    },{onConflict:'tenant_id,event_key'});
    if(e.error)throw e.error; stats.events_upserted++;
  }

  const {data:stays}=await s.from('crm_guest_stays').select('customer_id,total_amount').eq('tenant_id',tenantId).limit(20000);
  const totals=new Map();
  for(const x of stays||[]){if(!x.customer_id)continue;const v=totals.get(x.customer_id)||{count:0,revenue:0};v.count++;v.revenue+=Number(x.total_amount||0);totals.set(x.customer_id,v);}
  for(const [id,v] of totals){
    await s.from('crm_customers').update({total_stays:v.count,total_hotel_revenue:v.revenue,updated_at:now}).eq('id',id).eq('tenant_id',tenantId);
  }
  const {data:timelineResult,error:timelineError}=await s.rpc('anaira_rebuild_hotel_guest_timeline',{p_tenant_id:tenantId});
  if(!timelineError)stats.timeline_refreshed=Number(timelineResult||0);
  
  return {...stats,completed_at:now};
}
