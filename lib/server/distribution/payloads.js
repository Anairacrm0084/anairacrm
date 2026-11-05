const dateOnly = (d) => d.toISOString().slice(0,10);
const plusDays = (d,n) => { const x=new Date(d); x.setUTCDate(x.getUTCDate()+n); return x; };

async function requireRows(query,label){ const {data,error}=await query; if(error) throw new Error(`${label}: ${error.message}`); return data||[]; }

export async function buildCanonicalOutboundPayload(s,connection,channel,event){
 const tenantId=connection.restaurant_id;
 const channelId=channel.id;
 const cfg=connection.config||{};
 const start=event.payload?.from||dateOnly(new Date());
 const window=Math.max(1,Math.min(365,Number(cfg.inventory_sync_window_days||connection.inventory_sync_window_days||90)));
 const end=event.payload?.to||dateOnly(plusDays(new Date(`${start}T00:00:00Z`),window));
 const [roomMappings,rateMappings]=await Promise.all([
  requireRows(s.from('ota_room_mappings').select('room_type_id,external_code,status').eq('channel_id',channelId).eq('status','mapped'),'Load verified room mappings'),
  requireRows(s.from('ota_rate_mappings').select('rate_plan_id,external_code,status').eq('channel_id',channelId).eq('status','mapped'),'Load verified rate mappings')
 ]);
 if(event.event_type==='inventory'){
  if(!roomMappings.length) throw new Error('No verified room/tent mappings. Map and mark partner room codes as mapped before inventory sync.');
  const ids=roomMappings.map(x=>x.room_type_id).filter(Boolean);
  const inventory=await requireRows(s.from('hms_inventory').select('room_type_id,stay_date,total_rooms,sold_rooms,blocked_rooms,closed,stop_sell,close_on_arrival,close_on_departure,cutoff_hours').eq('restaurant_id',tenantId).in('room_type_id',ids).gte('stay_date',start).lt('stay_date',end).order('stay_date'),'Load canonical PMS inventory');
  const rows=inventory.map(x=>{const map=roomMappings.find(m=>m.room_type_id===x.room_type_id);return {...x,external_room_code:map?.external_code,available_rooms:Math.max(0,Number(x.total_rooms||0)-Number(x.sold_rooms||0)-Number(x.blocked_rooms||0)),sellable:!x.closed&&!x.stop_sell};});
  return {schema:'anaira.ota.inventory.v1',tenant_id:tenantId,property_id:channel.property_id||null,channel_id:channelId,currency:cfg.currency||'INR',from:start,to:end,generated_at:new Date().toISOString(),inventory:rows};
 }
 if(event.event_type==='rates'){
  if(!rateMappings.length) throw new Error('No verified rate-plan mappings. Map and mark partner rate codes as mapped before rate sync.');
  const ids=rateMappings.map(x=>x.rate_plan_id).filter(Boolean);
  const plans=await requireRows(s.from('hms_rate_plans').select('id,room_type_id,name,code,rate,board_type,refundable,cancellation_policy,min_stay,max_stay,active_from,active_to').eq('restaurant_id',tenantId).in('id',ids).eq('active',true),'Load canonical PMS rate plans');
  const overrides=await requireRows(s.from('hms_rate_overrides').select('rate_plan_id,room_type_id,stay_date,rate,min_stay,closed').eq('restaurant_id',tenantId).in('rate_plan_id',ids).gte('stay_date',start).lt('stay_date',end).order('stay_date'),'Load PMS rate overrides');
  return {schema:'anaira.ota.rates.v1',tenant_id:tenantId,property_id:channel.property_id||null,channel_id:channelId,currency:cfg.currency||'INR',from:start,to:end,generated_at:new Date().toISOString(),rate_plans:plans.map(p=>({external_rate_code:rateMappings.find(m=>m.rate_plan_id===p.id)?.external_code,room_type_id:p.room_type_id,name:p.name,base_rate:Number(p.rate||0),board_type:p.board_type,refundable:p.refundable,cancellation_policy:p.cancellation_policy,min_stay:p.min_stay,max_stay:p.max_stay,active_from:p.active_from,active_to:p.active_to,dates:overrides.filter(o=>o.rate_plan_id===p.id).map(o=>({date:o.stay_date,rate:Number(o.rate||p.rate||0),min_stay:o.min_stay,closed:!!o.closed}))}))};
 }
 if(event.event_type==='reservation'){
  if(!roomMappings.length) throw new Error('No verified room mappings are configured for reservation export.');
  const reservations=await requireRows(s.from('hms_reservations').select('id,guest_id,reservation_code,booking_reference,source,status,check_in,check_out,adults,children,total_amount,paid_amount,balance_amount,payment_status,room_type_id,rate_plan_id,source_reference,modified_at,updated_at').eq('restaurant_id',tenantId).gte('check_in',start).lt('check_in',end).in('status',['confirmed','checked_in','cancelled','no_show']).order('updated_at',{ascending:false}).limit(500),'Load PMS reservations');
  const guestIds=[...new Set(reservations.map(x=>x.guest_id).filter(Boolean))];
  const ids=[...new Set(reservations.map(x=>x.id))];
  const withGuests=await Promise.all(reservations.map(async r=>{const [{data:g,error:ge},{data:rm,error:re},{data:rp,error:rpe}]=await Promise.all([
   r.guest_id?s.from('hms_guests').select('full_name,phone,email').eq('id',r.guest_id).maybeSingle():Promise.resolve({data:null,error:null}),
   Promise.resolve({data:roomMappings.find(m=>m.room_type_id===r.room_type_id)||null,error:null}),
   Promise.resolve({data:rateMappings.find(m=>m.rate_plan_id===r.rate_plan_id)||null,error:null})
  ]);if(ge||re||rpe)throw ge||re||rpe;return {external_reservation_id:r.booking_reference||r.reservation_code,reservation_code:r.reservation_code,status:r.status,guest:{name:g?.full_name||'',phone:g?.phone||'',email:g?.email||''},check_in:r.check_in,check_out:r.check_out,adults:r.adults,children:r.children,total_amount:Number(r.total_amount||0),paid_amount:Number(r.paid_amount||0),balance_amount:Number(r.balance_amount||0),payment_status:r.payment_status,external_room_code:rm?.external_code||null,external_rate_code:rp?.external_code||null,updated_at:r.updated_at};}));
  return {schema:'anaira.ota.reservations.v1',tenant_id:tenantId,property_id:channel.property_id||null,channel_id:channelId,generated_at:new Date().toISOString(),reservations:withGuests};
 }
 throw new Error(`Unsupported outbound event type: ${event.event_type}`);
}
