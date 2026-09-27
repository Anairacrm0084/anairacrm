-- Public Hotel Store -> ANAIRA HMS bridge.
-- Used when a hotel's Store Source is ANAIRA HMS / PMS.

create or replace function public.anaira_public_hms_room_availability(
  p_restaurant_id uuid,
  p_check_in date,
  p_check_out date,
  p_adults integer default 2,
  p_children integer default 0
)
returns table(room_type_id uuid,name text,description text,base_rate numeric,available_rooms integer,max_adults integer,max_children integer,image_urls jsonb,amenities jsonb)
language plpgsql security definer set search_path=public as $$
declare r record; days integer;
begin
  if p_check_out <= p_check_in then raise exception 'Invalid stay dates'; end if;
  if p_adults < 1 then raise exception 'At least one adult is required'; end if;
  select m.catalog_source,s.enabled,s.published into r
  from public.anaira_store_memberships m
  join public.anaira_platform_stores s on s.id=m.store_id
  where m.restaurant_id=p_restaurant_id and s.store_type='hotel' and m.enabled=true
  limit 1;
  if not found or not r.enabled or not r.published then raise exception 'Hotel store is not published'; end if;
  days:=p_check_out-p_check_in;
  return query
  select rt.id,rt.name,coalesce(rt.short_description,rt.description,''),rt.base_rate,
    greatest(0,least(coalesce(min(inv.total_rooms-inv.sold_rooms-inv.blocked_rooms),0),coalesce(min(inv.total_rooms-inv.sold_rooms-inv.blocked_rooms),0)))::integer,
    rt.max_adults,rt.max_children,rt.image_urls,rt.amenities
  from public.hms_room_types rt
  join public.hms_inventory inv on inv.room_type_id=rt.id and inv.restaurant_id=p_restaurant_id and inv.stay_date>=p_check_in and inv.stay_date<p_check_out and inv.closed=false
  where rt.restaurant_id=p_restaurant_id and rt.active=true and rt.max_adults>=p_adults and rt.max_children>=p_children
  group by rt.id,rt.name,rt.short_description,rt.description,rt.base_rate,rt.max_adults,rt.max_children,rt.image_urls,rt.amenities
  having count(*)=days and min(inv.total_rooms-inv.sold_rooms-inv.blocked_rooms)>0
  order by rt.base_rate;
end; $$;

grant execute on function public.anaira_public_hms_room_availability(uuid,date,date,integer,integer) to anon,authenticated;

create or replace function public.anaira_create_public_hms_booking(
  p_restaurant_id uuid,
  p_guest_name text,
  p_guest_phone text,
  p_guest_email text,
  p_check_in date,
  p_check_out date,
  p_room_type_id uuid,
  p_adults integer,
  p_children integer default 0,
  p_source text default 'anaira-hotel-store'
)
returns table(reservation_id uuid,reservation_code text,total_amount numeric,status text)
language plpgsql security definer set search_path=public as $$
declare
  rt public.hms_room_types;
  guest_id uuid;
  crm_id uuid;
  code text;
  nights integer;
  available integer;
  day date;
  amount numeric;
  tax numeric;
  total numeric;
  rid uuid;
begin
  if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
  nights:=p_check_out-p_check_in;
  select * into rt from public.hms_room_types where id=p_room_type_id and restaurant_id=p_restaurant_id and active=true;
  if rt.id is null then raise exception 'Room type not found'; end if;
  if rt.max_adults<p_adults or rt.max_children<p_children then raise exception 'Guest capacity exceeded'; end if;

  for day in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
    select total_rooms-sold_rooms-blocked_rooms into available from public.hms_inventory where restaurant_id=p_restaurant_id and room_type_id=p_room_type_id and stay_date=day and closed=false for update;
    if available is null or available<=0 then raise exception 'Room inventory unavailable for selected dates'; end if;
  end loop;

  crm_id:=public.anaira_resolve_crm_customer(p_restaurant_id,p_guest_name,p_guest_phone,p_guest_email);
  select id into guest_id from public.hms_guests where restaurant_id=p_restaurant_id and ((p_guest_phone is not null and phone=p_guest_phone) or (p_guest_email is not null and email=p_guest_email)) order by updated_at desc limit 1;
  if guest_id is null then
    insert into public.hms_guests(restaurant_id,crm_customer_id,full_name,phone,email) values(p_restaurant_id,crm_id,p_guest_name,p_guest_phone,p_guest_email) returning id into guest_id;
  else
    update public.hms_guests set crm_customer_id=coalesce(crm_id,crm_customer_id),full_name=p_guest_name,phone=p_guest_phone,email=p_guest_email,updated_at=now() where id=guest_id;
  end if;

  amount:=rt.base_rate*nights;
  tax:=amount*coalesce(rt.tax_percent,0)/100;
  total:=amount+tax;
  code:='ANH-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  insert into public.hms_reservations(restaurant_id,reservation_code,guest_id,room_type_id,source,status,check_in,check_out,adults,children,rate,total_amount,notes,crm_customer_id)
  values(p_restaurant_id,code,guest_id,rt.id,p_source,'pending',p_check_in,p_check_out,p_adults,p_children,rt.base_rate,total,'Payment pending from public hotel store',crm_id)
  returning id into rid;

  for day in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
    update public.hms_inventory set sold_rooms=sold_rooms+1,updated_at=now() where restaurant_id=p_restaurant_id and room_type_id=p_room_type_id and stay_date=day and closed=false;
  end loop;

  insert into public.hms_folios(restaurant_id,reservation_id,guest_id,status,subtotal,tax,total,balance)
  values(p_restaurant_id,rid,guest_id,'open',amount,tax,total,total);
  insert into public.crm_interactions(customer_id,channel,interaction_type,subject,notes)
  values(crm_id,'hotel_store','hotel_booking','New hotel store booking',jsonb_build_object('reservation_id',rid,'reservation_code',code,'hms_room_type_id',p_room_type_id)::text);
  return query select rid,code,total,'pending'::text;
end; $$;

grant execute on function public.anaira_create_public_hms_booking(uuid,text,text,text,date,date,uuid,integer,integer,text) to anon,authenticated;
