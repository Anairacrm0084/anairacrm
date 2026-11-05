-- Anaira OTA distribution completion: normalized inbound reservations, audit, worker indexes.
-- Provider credentials and real provider certification remain per-property responsibilities.

alter table public.ota_sync_events add column if not exists direction text not null default 'outbound';
alter table public.ota_sync_events add column if not exists tenant_id uuid;
alter table public.ota_sync_events add column if not exists property_id uuid;
create index if not exists ota_sync_events_direction_worker_idx
  on public.ota_sync_events(direction,status,next_attempt_at,created_at);

alter table public.anaira_distribution_connections add column if not exists reservation_poll_path text;
alter table public.anaira_distribution_connections add column if not exists inventory_sync_window_days integer not null default 90;
alter table public.anaira_distribution_connections add column if not exists webhook_enabled boolean not null default false;

create table if not exists public.anaira_distribution_reservation_links (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  channel_id uuid not null references public.ota_channels(id) on delete cascade,
  provider_code text not null,
  external_reservation_id text not null,
  hms_reservation_id uuid not null references public.hms_reservations(id) on delete cascade,
  last_external_status text,
  last_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(channel_id,external_reservation_id),
  unique(hms_reservation_id)
);
create index if not exists ana_dist_res_links_tenant_idx
  on public.anaira_distribution_reservation_links(restaurant_id,provider_code,updated_at desc);
alter table public.anaira_distribution_reservation_links enable row level security;
drop policy if exists ana_dist_res_links_tenant_access on public.anaira_distribution_reservation_links;
create policy ana_dist_res_links_tenant_access on public.anaira_distribution_reservation_links
 for all to authenticated
 using (public.anaira_current_is_super_admin() or public.anaira_tenant_access(restaurant_id))
 with check (public.anaira_current_is_super_admin() or public.anaira_tenant_access(restaurant_id));

create or replace function public.anaira_distribution_import_reservation(
  p_restaurant_id uuid,
  p_channel_id uuid,
  p_provider_code text,
  p_action text,
  p_payload jsonb
) returns jsonb
language plpgsql security definer set search_path=public,pg_temp
as $$
declare
  ch public.ota_channels%rowtype;
  conn public.anaira_distribution_connections%rowtype;
  link_row public.anaira_distribution_reservation_links%rowtype;
  res public.hms_reservations%rowtype;
  guest public.hms_guests%rowtype;
  customer public.crm_customers%rowtype;
  v_external_id text;
  v_booking_ref text;
  v_name text;
  v_phone text;
  v_email text;
  v_checkin date;
  v_checkout date;
  v_adults integer;
  v_children integer;
  v_total numeric;
  v_room_code text;
  v_rate_code text;
  v_room_type_id uuid;
  v_rate_plan_id uuid;
  v_property_id uuid;
  v_status text;
  v_nights integer;
  v_event text;
  v_special jsonb;
  v_existing boolean := false;
  v_provider text := lower(coalesce(p_provider_code,''));
begin
  if p_restaurant_id is null or p_channel_id is null then raise exception 'Tenant and channel are required'; end if;
  select * into ch from public.ota_channels where id=p_channel_id and restaurant_id=p_restaurant_id for update;
  if ch.id is null then raise exception 'OTA channel does not belong to this property'; end if;
  select * into conn from public.anaira_distribution_connections
   where restaurant_id=p_restaurant_id and platform_id=ch.platform_id and status in ('configured','connected') limit 1;
  if conn.id is null then raise exception 'Verified distribution connection is missing'; end if;

  v_external_id:=nullif(trim(coalesce(p_payload->>'external_reservation_id',p_payload->>'reservation_id',p_payload->>'booking_id',p_payload->>'id','')),'');
  if v_external_id is null then raise exception 'Normalized OTA payload must include external_reservation_id'; end if;
  v_booking_ref:=upper(v_provider)||':'||v_external_id;
  perform pg_advisory_xact_lock(hashtext(p_channel_id::text||':'||v_external_id));

  select * into link_row from public.anaira_distribution_reservation_links
   where channel_id=p_channel_id and external_reservation_id=v_external_id for update;
  if link_row.id is not null then
    select * into res from public.hms_reservations where id=link_row.hms_reservation_id and restaurant_id=p_restaurant_id for update;
    v_existing:=true;
  else
    select * into res from public.hms_reservations
     where restaurant_id=p_restaurant_id and lower(coalesce(booking_reference,''))=lower(v_booking_ref) for update;
    v_existing:=res.id is not null;
  end if;

  v_event:=lower(coalesce(p_action,p_payload->>'event_type','reservation'));
  if v_event in ('cancel','cancelled','canceled','reservation_cancelled','booking_cancelled')
     or lower(coalesce(p_payload->>'status','')) in ('cancelled','canceled') then
    if res.id is null then
      return jsonb_build_object('ok',true,'ignored',true,'reason','cancel event received before reservation import','external_reservation_id',v_external_id);
    end if;
    update public.hms_reservations set status='cancelled',cancelled_at=now(),cancellation_reason=coalesce(p_payload->>'cancellation_reason','OTA cancellation'),modified_at=now(),updated_at=now()
     where id=res.id and restaurant_id=p_restaurant_id returning * into res;
    if res.room_type_id is not null then perform public.anaira_reconcile_hotel_inventory(p_restaurant_id,res.room_type_id,res.check_in,res.check_out); end if;
    update public.crm_guest_stays set booking_status='cancelled',cancellation_reason=coalesce(p_payload->>'cancellation_reason','OTA cancellation'),updated_at=now()
     where tenant_id=p_restaurant_id and external_booking_id=res.reservation_code;
    update public.anaira_distribution_reservation_links set last_external_status='cancelled',last_payload=p_payload,updated_at=now()
     where channel_id=p_channel_id and external_reservation_id=v_external_id;
    return jsonb_build_object('ok',true,'action','cancelled','hms_reservation_id',res.id,'reservation_code',res.reservation_code);
  end if;

  v_name:=nullif(trim(p_payload->>'guest_name'),'');
  v_phone:=nullif(trim(p_payload->>'guest_phone'),'');
  v_email:=nullif(lower(trim(p_payload->>'guest_email')),'');
  v_checkin:=nullif(p_payload->>'check_in','')::date;
  v_checkout:=nullif(p_payload->>'check_out','')::date;
  if v_name is null or v_checkin is null or v_checkout is null or v_checkout<=v_checkin then
    raise exception 'OTA reservation requires guest_name, check_in and check_out (checkout must be after checkin)';
  end if;
  v_adults:=greatest(1,coalesce(nullif(p_payload->>'adults','')::integer,1));
  v_children:=greatest(0,coalesce(nullif(p_payload->>'children','')::integer,0));
  v_total:=greatest(0,coalesce(nullif(p_payload->>'total_amount','')::numeric,0));
  v_room_code:=nullif(trim(p_payload->>'external_room_code'),'');
  v_rate_code:=nullif(trim(p_payload->>'external_rate_code'),'');
  v_special:=coalesce(p_payload->'special_requests','{}'::jsonb);

  if res.id is not null then
    v_room_type_id:=res.room_type_id; v_rate_plan_id:=res.rate_plan_id;
  end if;
  if v_room_code is not null then
    select m.room_type_id into v_room_type_id from public.ota_room_mappings m
     where m.channel_id=p_channel_id and m.external_code=v_room_code and m.status='mapped' limit 1;
    if v_room_type_id is null then raise exception 'OTA room code % is not mapped and verified in Anaira',v_room_code; end if;
  end if;
  if v_rate_code is not null then
    select m.rate_plan_id into v_rate_plan_id from public.ota_rate_mappings m
     where m.channel_id=p_channel_id and m.external_code=v_rate_code and m.status='mapped' limit 1;
    if v_rate_plan_id is null then raise exception 'OTA rate code % is not mapped and verified in Anaira',v_rate_code; end if;
  end if;
  if v_room_type_id is null then raise exception 'OTA reservation cannot be imported until its external room code is mapped'; end if;
  if not exists(select 1 from public.hms_room_types where id=v_room_type_id and restaurant_id=p_restaurant_id and active) then raise exception 'Mapped room type is inactive or belongs to another property'; end if;
  if v_rate_plan_id is not null and not exists(select 1 from public.hms_rate_plans where id=v_rate_plan_id and restaurant_id=p_restaurant_id and active) then raise exception 'Mapped rate plan is inactive or belongs to another property'; end if;

  select * into customer from public.crm_customers c where c.tenant_id=p_restaurant_id and
   ((v_phone is not null and regexp_replace(coalesce(c.phone,''),'[^0-9]','','g')=regexp_replace(v_phone,'[^0-9]','','g')) or
    (v_email is not null and lower(coalesce(c.email,''))=v_email)) order by c.updated_at desc limit 1 for update;
  v_property_id:=ch.property_id;
  if v_property_id is null then
    select id into v_property_id from (
      select id,count(*) over() as active_count
      from public.anaira_hospitality_properties_master where tenant_id=p_restaurant_id and active=true
    ) scoped_properties where active_count=1 limit 1;
  end if;
  if customer.id is null then
    insert into public.crm_customers(tenant_id,property_id,full_name,phone,email,customer_type,country,preferred_language,created_at,updated_at)
    values(p_restaurant_id,v_property_id,v_name,v_phone,v_email,'guest','India','en',now(),now()) returning * into customer;
  else
    update public.crm_customers set property_id=coalesce(v_property_id,property_id),full_name=v_name,phone=coalesce(v_phone,phone),email=coalesce(v_email,email),updated_at=now()
     where id=customer.id returning * into customer;
  end if;
  select * into guest from public.hms_guests where restaurant_id=p_restaurant_id and
   ((v_phone is not null and phone=v_phone) or (v_email is not null and lower(coalesce(email,''))=v_email)) order by updated_at desc limit 1 for update;
  if guest.id is null then
    insert into public.hms_guests(restaurant_id,crm_customer_id,full_name,phone,email)
    values(p_restaurant_id,customer.id,v_name,v_phone,v_email) returning * into guest;
  else
    update public.hms_guests set crm_customer_id=customer.id,full_name=v_name,phone=coalesce(v_phone,phone),email=coalesce(v_email,email),updated_at=now()
     where id=guest.id returning * into guest;
  end if;

  v_status:=case lower(coalesce(p_payload->>'status','confirmed'))
    when 'cancelled' then 'cancelled' when 'canceled' then 'cancelled'
    when 'pending' then 'inquiry' when 'requested' then 'inquiry' when 'inquiry' then 'inquiry'
    when 'checked_in' then 'checked_in' when 'checked_out' then 'checked_out'
    when 'no_show' then 'no_show' else 'confirmed' end;
  v_nights:=v_checkout-v_checkin;
  if res.id is null then
    insert into public.hms_reservations(
      restaurant_id,property_id,reservation_code,booking_reference,source,source_reference,status,
      guest_id,crm_customer_id,room_type_id,rate_plan_id,check_in,check_out,adults,children,guest_count,
      total_amount,rate,paid_amount,balance_amount,payment_status,payment_method,special_requests,hospitality_type,created_at,updated_at
    ) values (
      p_restaurant_id,v_property_id,'OTA-'||substr(md5(v_booking_ref),1,12),v_booking_ref,'ota:'||v_provider,v_external_id,v_status,
      guest.id,customer.id,v_room_type_id,v_rate_plan_id,v_checkin,v_checkout,v_adults,v_children,v_adults+v_children,
      v_total,case when v_nights>0 then v_total/v_nights else v_total end,0,v_total,'pending','ota',v_special,
      coalesce(nullif(p_payload->>'hospitality_type',''),(select hospitality_type from public.hms_room_types where id=v_room_type_id)),now(),now()
    ) returning * into res;
  else
    update public.hms_reservations set property_id=coalesce(v_property_id,property_id),guest_id=guest.id,crm_customer_id=customer.id,
      room_type_id=v_room_type_id,rate_plan_id=coalesce(v_rate_plan_id,rate_plan_id),check_in=v_checkin,check_out=v_checkout,
      adults=v_adults,children=v_children,guest_count=v_adults+v_children,total_amount=v_total,
      rate=case when v_nights>0 then v_total/v_nights else v_total end,status=v_status,special_requests=v_special,
      modified_at=now(),updated_at=now()
    where id=res.id and restaurant_id=p_restaurant_id returning * into res;
  end if;

  insert into public.anaira_distribution_reservation_links(restaurant_id,channel_id,provider_code,external_reservation_id,hms_reservation_id,last_external_status,last_payload,updated_at)
  values(p_restaurant_id,p_channel_id,v_provider,v_external_id,res.id,v_status,p_payload,now())
  on conflict(channel_id,external_reservation_id) do update set hms_reservation_id=excluded.hms_reservation_id,last_external_status=excluded.last_external_status,last_payload=excluded.last_payload,updated_at=now();

  v_property_id:=ch.property_id;
  if v_property_id is null then
    select id into v_property_id from (
      select id,count(*) over() as active_count
      from public.anaira_hospitality_properties_master where tenant_id=p_restaurant_id and active=true
    ) scoped_properties where active_count=1 limit 1;
  end if;
  if not exists(select 1 from public.crm_guest_stays where tenant_id=p_restaurant_id and external_booking_id=res.reservation_code) then
    insert into public.crm_guest_stays(tenant_id,customer_id,external_booking_id,property_id,check_in_date,check_out_date,nights,booking_source,booking_status,total_amount,special_requests)
    values(p_restaurant_id,customer.id,res.reservation_code,v_property_id,v_checkin,v_checkout,v_nights,'ota:'||v_provider,v_status,v_total,v_special::text);
  else
    update public.crm_guest_stays set customer_id=customer.id,property_id=coalesce(v_property_id,property_id),check_in_date=v_checkin,check_out_date=v_checkout,nights=v_nights,
      booking_source='ota:'||v_provider,booking_status=v_status,total_amount=v_total,special_requests=v_special::text,updated_at=now()
    where tenant_id=p_restaurant_id and external_booking_id=res.reservation_code;
  end if;
  if v_status in ('confirmed','checked_in') then
    perform public.anaira_reconcile_hotel_inventory(p_restaurant_id,v_room_type_id,v_checkin,v_checkout);
  elsif v_status in ('cancelled','no_show') then
    perform public.anaira_reconcile_hotel_inventory(p_restaurant_id,v_room_type_id,v_checkin,v_checkout);
  end if;
  return jsonb_build_object('ok',true,'action',case when v_existing then 'updated' else 'imported' end,
    'hms_reservation_id',res.id,'reservation_code',res.reservation_code,'crm_customer_id',customer.id,
    'room_type_id',v_room_type_id,'rate_plan_id',v_rate_plan_id,'status',v_status);
end;
$$;
revoke all on function public.anaira_distribution_import_reservation(uuid,uuid,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.anaira_distribution_import_reservation(uuid,uuid,text,text,jsonb) to service_role;

comment on function public.anaira_distribution_import_reservation(uuid,uuid,text,text,jsonb) is
'Internal normalized OTA webhook/polling ingestion. Requires verified room mapping; idempotently creates/updates HMS reservation and CRM customer/stay, and reconciles inventory.';

-- Queue all enabled channel syncs on a deterministic 15-minute bucket. Vercel Cron (or
-- another scheduler) invokes the protected worker; duplicate cron calls remain idempotent.
create or replace function public.anaira_distribution_enqueue_due_auto_sync()
returns integer
language plpgsql security definer set search_path=public,pg_temp
as $$
declare c record; ch record; kind text; queued integer:=0; bucket text;
begin
 bucket:=floor(extract(epoch from now())/900)::bigint::text;
 for c in select * from public.anaira_distribution_connections
   where auto_sync=true and status='connected'
 loop
  for ch in select * from public.ota_channels where restaurant_id=c.restaurant_id and platform_id=c.platform_id
  loop
   foreach kind in array array[
    case when coalesce(c.inventory_sync,true) then 'inventory' else null end,
    case when coalesce(c.rate_sync,true) then 'rates' else null end,
    case when coalesce(c.reservation_sync,true) then 'reservation' else null end
   ] loop
    if kind is null then continue; end if;
    insert into public.ota_sync_events(
      restaurant_id,tenant_id,property_id,connection_id,channel_id,event_type,direction,status,payload,
      idempotency_key,max_attempts,next_attempt_at
    ) values(
      c.restaurant_id,c.restaurant_id,ch.property_id,c.id,ch.id,kind,'outbound','queued',
      jsonb_build_object('requested_from','auto_sync_scheduler','from',(now() at time zone 'Asia/Kolkata')::date::text),
      md5('auto|'||c.id::text||'|'||kind||'|'||bucket),8,now()
    ) on conflict (idempotency_key) where idempotency_key is not null do nothing;
    if found then queued:=queued+1; end if;
   end loop;
  end loop;
 end loop;
 return queued;
end;
$$;
revoke all on function public.anaira_distribution_enqueue_due_auto_sync() from public,anon,authenticated;
grant execute on function public.anaira_distribution_enqueue_due_auto_sync() to service_role;
