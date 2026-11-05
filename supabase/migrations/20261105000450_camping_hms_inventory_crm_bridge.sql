-- Bridge approved camping bookings into canonical HMS sellable inventory and CRM Customer 360.
-- The camp inventory ledger remains authoritative for camp-unit holds/sales; this bridge
-- also maps each approved camp booking to its matching HMS room type so the HMS daily
-- inventory calendar reports the sold unit and CRM receives the guest/stay relationship.

alter table public.hms_guests add column if not exists crm_customer_id uuid references public.crm_customers(id) on delete set null;
alter table public.hms_reservations add column if not exists crm_customer_id uuid references public.crm_customers(id) on delete set null;
alter table public.crm_guest_stay_events add column if not exists event_key text;
create unique index if not exists crm_guest_stay_events_event_key_uq
  on public.crm_guest_stay_events(tenant_id,event_key) where event_key is not null;

create or replace function public.anaira_sync_camp_reservation_inventory_crm(p_camp_reservation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  c public.camp_reservations%rowtype;
  u public.camp_unit_types%rowtype;
  hr public.hms_reservations%rowtype;
  hg public.hms_guests%rowtype;
  rt public.hms_room_types%rowtype;
  cust public.crm_customers%rowtype;
  stay_id uuid;
  v_property_id uuid;
  v_event_type text;
  v_nights integer;
begin
  select * into c from public.camp_reservations where id=p_camp_reservation_id;
  if not found or c.status<>'confirmed' or c.hms_reservation_id is null then
    return jsonb_build_object('ok',true,'skipped',true,'reason','camp booking is not approved or HMS-linked');
  end if;

  select * into u from public.camp_unit_types where id=c.unit_type_id and restaurant_id=c.restaurant_id;
  select * into hr from public.hms_reservations
    where id=c.hms_reservation_id and restaurant_id=c.restaurant_id for update;
  if not found then raise exception 'Linked HMS reservation is missing for camping booking %',c.reservation_code; end if;

  -- Match the legacy camp unit type to the canonical HMS room type by stable code first,
  -- then normalized name. This fills the missing room_type_id on the original camp mirror.
  select * into rt from public.hms_room_types
   where restaurant_id=c.restaurant_id and hospitality_type='camp'
     and ((nullif(u.code,'') is not null and code=u.code) or lower(trim(name))=lower(trim(u.name)))
   order by case when nullif(u.code,'') is not null and code=u.code then 0 else 1 end
   limit 1;

  if rt.id is null then
    raise exception 'No matching HMS Camp / Tent type exists for camp unit type %',u.name;
  end if;

  select * into hg from public.hms_guests
   where id=hr.guest_id and restaurant_id=c.restaurant_id for update;
  if hg.id is null then raise exception 'Linked HMS guest is missing'; end if;

  -- Reuse CRM identity by phone/email; create only when no matching tenant customer exists.
  select * into cust from public.crm_customers
   where tenant_id=c.restaurant_id
     and ((nullif(trim(c.guest_phone),'') is not null and regexp_replace(coalesce(phone,''),'[^0-9]','','g')=regexp_replace(c.guest_phone,'[^0-9]','','g'))
       or (nullif(trim(c.guest_email),'') is not null and lower(trim(coalesce(email,'')))=lower(trim(c.guest_email))))
   order by updated_at desc limit 1 for update;

  if cust.id is null then
    insert into public.crm_customers(tenant_id,full_name,phone,email,customer_type,country,preferred_language,created_at,updated_at)
    values(c.restaurant_id,c.guest_name,nullif(trim(c.guest_phone),''),nullif(trim(c.guest_email),''),'guest','India','en',now(),now())
    returning * into cust;
  else
    update public.crm_customers set
      full_name=coalesce(nullif(trim(c.guest_name),''),full_name),
      phone=coalesce(nullif(trim(c.guest_phone),''),phone),
      email=coalesce(nullif(trim(c.guest_email),''),email),
      updated_at=now()
    where id=cust.id returning * into cust;
  end if;

  update public.hms_guests set crm_customer_id=cust.id,updated_at=now()
   where id=hg.id and restaurant_id=c.restaurant_id;
  update public.hms_reservations set
    room_type_id=rt.id,
    crm_customer_id=cust.id,
    updated_at=now()
   where id=hr.id and restaurant_id=c.restaurant_id;

  select id into v_property_id from public.anaira_hospitality_properties_master
   where tenant_id=c.restaurant_id and source_table='restaurants'
     and source_id=c.restaurant_id and property_type='camp' and active
   order by created_at desc limit 1;

  select id into stay_id from public.crm_guest_stays
   where tenant_id=c.restaurant_id and external_booking_id=hr.reservation_code
   order by created_at desc limit 1 for update;

  v_nights:=greatest(0,c.check_out-c.check_in);
  if stay_id is null then
    insert into public.crm_guest_stays(
      tenant_id,customer_id,external_booking_id,property_id,room_number,
      check_in_date,check_out_date,nights,booking_source,booking_status,total_amount,special_requests
    ) values (
      c.restaurant_id,cust.id,hr.reservation_code,v_property_id,
      (select room_number from public.hms_rooms where id=hr.room_id and restaurant_id=c.restaurant_id),
      c.check_in,c.check_out,v_nights,'camping_booking_engine',hr.status,c.total_amount,hr.special_requests::text
    ) returning id into stay_id;
  else
    update public.crm_guest_stays set
      customer_id=cust.id,property_id=coalesce(v_property_id,property_id),
      room_number=coalesce((select room_number from public.hms_rooms where id=hr.room_id and restaurant_id=c.restaurant_id),room_number),
      check_in_date=c.check_in,check_out_date=c.check_out,nights=v_nights,
      booking_source='camping_booking_engine',booking_status=hr.status,
      total_amount=c.total_amount,special_requests=hr.special_requests::text,updated_at=now()
    where id=stay_id and tenant_id=c.restaurant_id;
  end if;

  v_event_type:=case lower(hr.status)
    when 'checked_in' then 'checked_in'
    when 'checked_out' then 'checkout'
    when 'cancelled' then 'cancelled'
    when 'no_show' then 'no_show'
    else 'booked' end;

  insert into public.crm_guest_stay_events(
    tenant_id,customer_id,stay_id,event_type,payload,source,event_key
  ) values (
    c.restaurant_id,cust.id,stay_id,v_event_type,
    jsonb_build_object('camp_reservation_id',c.id,'hms_reservation_id',hr.id,
      'reservation_code',c.reservation_code,'hms_reservation_code',hr.reservation_code,
      'unit_type_id',c.unit_type_id,'hms_room_type_id',rt.id,
      'check_in',c.check_in,'check_out',c.check_out,'status',hr.status),
    'camp_booking_engine','camp-booking:'||c.id::text||':'||v_event_type
  ) on conflict (tenant_id,event_key) where event_key is not null
    do update set customer_id=excluded.customer_id,stay_id=excluded.stay_id,
      payload=excluded.payload,created_at=now();

  -- Rebuild the HMS daily room-type totals so the inventory calendar shows approved bookings.
  perform public.anaira_sync_hotel_inventory_range(c.restaurant_id,c.check_in,c.check_out);

  update public.crm_customers cc set
    total_stays=(select count(*)::integer from public.crm_guest_stays gs where gs.tenant_id=c.restaurant_id and gs.customer_id=cc.id),
    total_hotel_revenue=(select coalesce(sum(gs.total_amount),0) from public.crm_guest_stays gs where gs.tenant_id=c.restaurant_id and gs.customer_id=cc.id),
    updated_at=now()
   where cc.id=cust.id and cc.tenant_id=c.restaurant_id;

  return jsonb_build_object('ok',true,'camp_reservation_id',c.id,'hms_reservation_id',hr.id,
    'hms_room_type_id',rt.id,'crm_customer_id',cust.id,'crm_guest_stay_id',stay_id,
    'inventory_synced',true);
end;
$$;

revoke all on function public.anaira_sync_camp_reservation_inventory_crm(uuid) from public,anon;
grant execute on function public.anaira_sync_camp_reservation_inventory_crm(uuid) to authenticated;

create or replace function public.anaira_camp_reservation_hms_crm_bridge_trigger()
returns trigger
language plpgsql
security definer
set search_path=public,pg_temp
as $$
begin
  if tg_op='INSERT' then
    if new.status='confirmed' and new.hms_reservation_id is not null then
      perform public.anaira_sync_camp_reservation_inventory_crm(new.id);
    end if;
  elsif new.status='confirmed' and new.hms_reservation_id is not null
     and (old.status is distinct from new.status
          or old.hms_reservation_id is distinct from new.hms_reservation_id) then
    perform public.anaira_sync_camp_reservation_inventory_crm(new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_camp_reservation_hms_crm_bridge on public.camp_reservations;
create trigger trg_camp_reservation_hms_crm_bridge
after insert or update of status,hms_reservation_id on public.camp_reservations
for each row execute function public.anaira_camp_reservation_hms_crm_bridge_trigger();

-- Backfill previously approved bookings so existing confirmed camping reservations also
-- appear in HMS daily inventory and CRM Customer 360.
do $$
declare x record;
begin
  for x in
    select id from public.camp_reservations
     where status='confirmed' and hms_reservation_id is not null
     order by approved_at nulls first,created_at
  loop
    perform public.anaira_sync_camp_reservation_inventory_crm(x.id);
  end loop;
end $$;


create or replace function public.anaira_hms_camp_crm_lifecycle_trigger()
returns trigger
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare camp_id uuid;
begin
  if new.source='camping_booking_engine'
     and (old.status is distinct from new.status or old.room_id is distinct from new.room_id) then
    select id into camp_id from public.camp_reservations
     where hms_reservation_id=new.id and restaurant_id=new.restaurant_id limit 1;
    if camp_id is not null then
      perform public.anaira_sync_camp_reservation_inventory_crm(camp_id);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_hms_camp_crm_lifecycle on public.hms_reservations;
create trigger trg_hms_camp_crm_lifecycle
after update of status,room_id on public.hms_reservations
for each row execute function public.anaira_hms_camp_crm_lifecycle_trigger();
