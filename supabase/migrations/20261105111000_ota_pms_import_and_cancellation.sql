-- Durable OTA-to-PMS import lifecycle. The function is service-role only;
-- application routes authenticate the user and enforce tenant access first.
create or replace function public.anaira_process_ota_reservation(
  p_inbox_id uuid,
  p_restaurant_id uuid,
  p_action text default 'import'
) returns jsonb
language plpgsql security definer set search_path=public,pg_temp
as $function$
declare
  v_inbox public.anaira_ota_reservation_inbox%rowtype;
  v_guest_id uuid; v_crm_customer_id uuid; v_reservation_id uuid;
  v_reservation_code text; v_property_id uuid; v_total numeric(12,2);
  v_nights integer; v_rate numeric(12,2); v_day date;
  v_inventory public.hms_inventory%rowtype; v_available integer;
  v_old_check_in date; v_old_check_out date; v_old_room_type uuid;
begin
  if p_action not in ('import','modify','cancel') then raise exception 'Unsupported OTA inbox action'; end if;
  select * into v_inbox from public.anaira_ota_reservation_inbox
    where id=p_inbox_id and restaurant_id=p_restaurant_id for update;
  if not found then raise exception 'OTA reservation not found for this property'; end if;

  if p_action='cancel' then
    if v_inbox.hms_reservation_id is not null then
      select check_in,check_out,room_type_id into v_old_check_in,v_old_check_out,v_old_room_type
        from public.hms_reservations where id=v_inbox.hms_reservation_id and restaurant_id=p_restaurant_id for update;
      update public.hms_reservations set status='cancelled',
        cancellation_reason=coalesce(cancellation_reason,'Cancelled by OTA: '||v_inbox.provider_code||' / '||v_inbox.external_reference),
        cancelled_at=coalesce(cancelled_at,now()),updated_at=now()
        where id=v_inbox.hms_reservation_id and restaurant_id=p_restaurant_id and status not in ('cancelled','checked_out');
      if v_old_room_type is not null then
        for v_day in select generate_series(v_old_check_in,v_old_check_out-1,interval '1 day')::date loop
          update public.hms_inventory i set sold_rooms=(select count(*)::integer from public.hms_reservations r
            where r.restaurant_id=p_restaurant_id and r.room_type_id=v_old_room_type
              and r.status in ('confirmed','checked_in') and r.check_in<=v_day and r.check_out>v_day),updated_at=now()
            where i.restaurant_id=p_restaurant_id and i.room_type_id=v_old_room_type and i.stay_date=v_day;
        end loop;
      end if;
    end if;
    update public.anaira_ota_reservation_inbox set import_status='cancelled',reservation_status='cancelled',updated_at=now(),last_error=null where id=v_inbox.id;
    return jsonb_build_object('ok',true,'action','cancel','hms_reservation_id',v_inbox.hms_reservation_id);
  end if;

  if v_inbox.reservation_status in ('cancelled','canceled') or v_inbox.import_status='cancelled' then
    raise exception 'Cancelled OTA reservations cannot be imported or modified';
  end if;
  if v_inbox.import_status='review' then raise exception 'This OTA reservation requires manual review before processing'; end if;
  if v_inbox.room_type_id is null then raise exception 'Map the external OTA room code to an Anaira room type first'; end if;
  if not exists(select 1 from public.hms_room_types where id=v_inbox.room_type_id and restaurant_id=p_restaurant_id and active=true) then
    raise exception 'Mapped room type is inactive or belongs to another property';
  end if;
  if v_inbox.rate_plan_id is not null and not exists(select 1 from public.hms_rate_plans
    where id=v_inbox.rate_plan_id and restaurant_id=p_restaurant_id and active=true
      and (room_type_id is null or room_type_id=v_inbox.room_type_id)) then
    raise exception 'Mapped rate plan is inactive, mismatched or belongs to another property';
  end if;
  v_nights:=v_inbox.check_out-v_inbox.check_in;
  if v_nights<1 then raise exception 'Invalid OTA stay dates'; end if;
  v_total:=case when v_inbox.amount>0 then v_inbox.amount else
    (select base_rate*v_nights from public.hms_room_types where id=v_inbox.room_type_id and restaurant_id=p_restaurant_id) end;
  if v_total is null or v_total<0 then raise exception 'OTA booking amount is invalid'; end if;
  v_rate:=round(v_total/v_nights,2);

  if p_action='modify' then
    if v_inbox.hms_reservation_id is null then raise exception 'This OTA reservation has not yet been imported; use Import to PMS first'; end if;
    select id,check_in,check_out,room_type_id into v_reservation_id,v_old_check_in,v_old_check_out,v_old_room_type
      from public.hms_reservations where id=v_inbox.hms_reservation_id and restaurant_id=p_restaurant_id
        and status in ('confirmed','payment_pending','inquiry') for update;
    if not found then raise exception 'Linked PMS reservation cannot be modified in its current state'; end if;
    for v_day in select generate_series(v_inbox.check_in,v_inbox.check_out-1,interval '1 day')::date loop
      insert into public.hms_inventory(restaurant_id,room_type_id,stay_date,total_rooms,sold_rooms,blocked_rooms,closed)
        select p_restaurant_id,v_inbox.room_type_id,v_day,count(*)::integer,0,0,false from public.hms_rooms
        where restaurant_id=p_restaurant_id and room_type_id=v_inbox.room_type_id and active=true
          and status not in ('maintenance','out_of_order','blocked')
        on conflict(restaurant_id,room_type_id,stay_date) do nothing;
      select * into v_inventory from public.hms_inventory where restaurant_id=p_restaurant_id
        and room_type_id=v_inbox.room_type_id and stay_date=v_day for update;
      if not found or v_inventory.closed or v_inventory.stop_sell then raise exception 'Inventory is closed or stop-sell is active for %',v_day; end if;
      select count(*)::integer into v_available from public.hms_reservations r
        where r.restaurant_id=p_restaurant_id and r.room_type_id=v_inbox.room_type_id and r.id<>v_reservation_id
          and r.status in ('confirmed','checked_in') and r.check_in<=v_day and r.check_out>v_day;
      if coalesce(v_inventory.total_rooms,0)-coalesce(v_inventory.blocked_rooms,0)-v_available<1 then
        raise exception 'No available room inventory for modified stay date %',v_day;
      end if;
    end loop;
    update public.hms_reservations set room_type_id=v_inbox.room_type_id,rate=v_rate,total_amount=v_total,
      rate_plan_id=v_inbox.rate_plan_id,check_in=v_inbox.check_in,check_out=v_inbox.check_out,
      adults=v_inbox.adults,children=v_inbox.children,booking_reference=v_inbox.external_reference,
      source_reference=v_inbox.provider_code||':'||v_inbox.external_reference,
      balance_amount=greatest(v_total-coalesce(paid_amount,0),0),
      payment_status=case when coalesce(paid_amount,0)>=v_total and v_total>0 then 'paid' when coalesce(paid_amount,0)>0 then 'partial' else 'pending' end,
      modified_at=now(),updated_at=now() where id=v_reservation_id and restaurant_id=p_restaurant_id;
    update public.hms_inventory i set sold_rooms=(select count(*)::integer from public.hms_reservations r
      where r.restaurant_id=p_restaurant_id and r.room_type_id=i.room_type_id and r.status in ('confirmed','checked_in')
        and r.check_in<=i.stay_date and r.check_out>i.stay_date),updated_at=now()
      where i.restaurant_id=p_restaurant_id
        and i.stay_date between least(v_old_check_in,v_inbox.check_in) and greatest(v_old_check_out,v_inbox.check_out)-1
        and i.room_type_id in (v_old_room_type,v_inbox.room_type_id);
    update public.hms_folios set subtotal=v_total,tax=0,total=v_total,
      balance=greatest(v_total-coalesce(paid_amount,0),0),updated_at=now()
      where reservation_id=v_reservation_id and restaurant_id=p_restaurant_id;
    update public.anaira_ota_reservation_inbox set import_status='imported',updated_at=now(),last_error=null where id=v_inbox.id;
    return jsonb_build_object('ok',true,'action','modify','hms_reservation_id',v_reservation_id,'total_amount',v_total);
  end if;

  v_crm_customer_id:=public.anaira_resolve_crm_customer(p_restaurant_id,v_inbox.guest_name,v_inbox.guest_phone,v_inbox.guest_email);
  select id into v_guest_id from public.hms_guests where restaurant_id=p_restaurant_id
    and ((v_inbox.guest_phone is not null and phone=v_inbox.guest_phone)
      or (v_inbox.guest_email is not null and lower(email)=lower(v_inbox.guest_email)))
    order by updated_at desc limit 1 for update;
  if v_guest_id is null then
    insert into public.hms_guests(restaurant_id,crm_customer_id,full_name,phone,email)
      values(p_restaurant_id,v_crm_customer_id,v_inbox.guest_name,v_inbox.guest_phone,v_inbox.guest_email) returning id into v_guest_id;
  else
    update public.hms_guests set crm_customer_id=coalesce(v_crm_customer_id,crm_customer_id),full_name=v_inbox.guest_name,
      phone=coalesce(v_inbox.guest_phone,phone),email=coalesce(v_inbox.guest_email,email),updated_at=now() where id=v_guest_id;
  end if;
  select id into v_property_id from public.anaira_hospitality_properties_master
    where tenant_id=p_restaurant_id and source_id=p_restaurant_id and active=true order by created_at desc limit 1;
  for v_day in select generate_series(v_inbox.check_in,v_inbox.check_out-1,interval '1 day')::date loop
    insert into public.hms_inventory(restaurant_id,room_type_id,stay_date,total_rooms,sold_rooms,blocked_rooms,closed)
      select p_restaurant_id,v_inbox.room_type_id,v_day,count(*)::integer,0,0,false from public.hms_rooms
      where restaurant_id=p_restaurant_id and room_type_id=v_inbox.room_type_id and active=true
        and status not in ('maintenance','out_of_order','blocked')
      on conflict(restaurant_id,room_type_id,stay_date) do nothing;
    select * into v_inventory from public.hms_inventory where restaurant_id=p_restaurant_id
      and room_type_id=v_inbox.room_type_id and stay_date=v_day for update;
    if not found or v_inventory.closed or v_inventory.stop_sell then raise exception 'Inventory is closed or stop-sell is active for %',v_day; end if;
    v_available:=coalesce(v_inventory.total_rooms,0)-coalesce(v_inventory.sold_rooms,0)-coalesce(v_inventory.blocked_rooms,0);
    if v_available<1 then raise exception 'No available room inventory for %',v_day; end if;
  end loop;
  v_reservation_code:='OTA-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  insert into public.hms_reservations(restaurant_id,reservation_code,guest_id,room_type_id,source,status,check_in,check_out,
    adults,children,rate,total_amount,notes,crm_customer_id,rate_plan_id,booking_reference,source_reference,
    payment_status,balance_amount,hospitality_type,pricing_mode,guest_count,property_id)
  values(p_restaurant_id,v_reservation_code,v_guest_id,v_inbox.room_type_id,
    'ota_'||regexp_replace(lower(v_inbox.provider_code),'[^a-z0-9_]+','_','g'),'confirmed',v_inbox.check_in,v_inbox.check_out,
    v_inbox.adults,v_inbox.children,v_rate,v_total,'Imported from OTA. External reference: '||v_inbox.external_reference,
    v_crm_customer_id,v_inbox.rate_plan_id,v_inbox.external_reference,v_inbox.provider_code||':'||v_inbox.external_reference,
    'pending',v_total,coalesce((select hospitality_type from public.hms_room_types where id=v_inbox.room_type_id),'hotel'),
    'per_unit',v_inbox.adults+v_inbox.children,v_property_id) returning id into v_reservation_id;
  for v_day in select generate_series(v_inbox.check_in,v_inbox.check_out-1,interval '1 day')::date loop
    update public.hms_inventory set sold_rooms=sold_rooms+1,updated_at=now()
      where restaurant_id=p_restaurant_id and room_type_id=v_inbox.room_type_id and stay_date=v_day;
  end loop;
  insert into public.hms_folios(restaurant_id,reservation_id,guest_id,status,subtotal,tax,total,balance,paid_amount,deposit_amount)
    values(p_restaurant_id,v_reservation_id,v_guest_id,'open',v_total,0,v_total,v_total,0,0);
  update public.anaira_ota_reservation_inbox set import_status='imported',hms_reservation_id=v_reservation_id,
    updated_at=now(),last_error=null where id=v_inbox.id;
  return jsonb_build_object('ok',true,'action','import','hms_reservation_id',v_reservation_id,
    'reservation_code',v_reservation_code,'external_reference',v_inbox.external_reference,'total_amount',v_total);
end
$function$;
revoke all on function public.anaira_process_ota_reservation(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.anaira_process_ota_reservation(uuid,uuid,text) to service_role;
