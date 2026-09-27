-- 048_unified_hospitality_marketplace_integrations.sql
-- ANAIRA UNIFIED LOCK:
-- ID-based customer marketplace. No public slug routing.
-- Canonical owners remain: CRM=customer intelligence, Booking=acquisition,
-- PMS=hotel operations, POS=restaurant operations, Delivery=fulfilment, OTA=distribution.

create table if not exists public.anaira_marketplace_listings (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  listing_type text not null default 'hotel_restaurant'
    check (listing_type in ('hotel','restaurant','hotel_restaurant')),
  marketplace_visible boolean not null default false,
  hotel_booking_enabled boolean not null default false,
  food_ordering_enabled boolean not null default false,
  restaurant_reservation_enabled boolean not null default false,
  approval_status text not null default 'pending'
    check (approval_status in ('pending','approved','rejected','suspended')),
  display_name text,
  short_description text,
  city text,
  cover_image text,
  commission_percent numeric(6,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(restaurant_id)
);

create table if not exists public.anaira_integration_links (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.restaurants(id) on delete cascade,
  source_system text not null,
  source_entity text not null,
  source_id uuid not null,
  target_system text not null,
  target_entity text not null,
  target_id uuid,
  status text not null default 'active',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(source_system,source_entity,source_id,target_system,target_entity)
);

create index if not exists anaira_marketplace_listings_public_idx
on public.anaira_marketplace_listings(marketplace_visible,approval_status,hotel_booking_enabled,food_ordering_enabled,city);

create index if not exists anaira_integration_links_lookup_idx
on public.anaira_integration_links(source_system,source_entity,source_id);

alter table public.anaira_marketplace_listings enable row level security;
alter table public.anaira_integration_links enable row level security;

drop policy if exists "marketplace listings public read" on public.anaira_marketplace_listings;
create policy "marketplace listings public read"
on public.anaira_marketplace_listings for select to anon,authenticated
using (marketplace_visible=true and approval_status='approved');

drop policy if exists "marketplace listings tenant manage" on public.anaira_marketplace_listings;
create policy "marketplace listings tenant manage"
on public.anaira_marketplace_listings for all to authenticated
using (
  restaurant_id in (
    select p.restaurant_id from public.profiles p where p.id=auth.uid()
  )
  or exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_super_admin=true)
)
with check (
  restaurant_id in (
    select p.restaurant_id from public.profiles p where p.id=auth.uid()
  )
  or exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_super_admin=true)
);

drop policy if exists "integration links tenant access" on public.anaira_integration_links;
create policy "integration links tenant access"
on public.anaira_integration_links for all to authenticated
using (
  tenant_id in (
    select p.restaurant_id from public.profiles p where p.id=auth.uid()
  )
  or exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_super_admin=true)
)
with check (
  tenant_id in (
    select p.restaurant_id from public.profiles p where p.id=auth.uid()
  )
  or exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_super_admin=true)
);

-- Public marketplace discovery. The ID is the canonical public reference.
create or replace function public.anaira_marketplace_businesses(
  p_city text default null,
  p_mode text default 'all'
) returns table(
  restaurant_id uuid, name text, city text, address text, logo text, cover_image text,
  cuisine text, listing_type text, hotel_booking_enabled boolean,
  food_ordering_enabled boolean, restaurant_reservation_enabled boolean
)
language sql stable security definer set search_path=public as $$
  select r.id,
         r.name,
         coalesce(nullif(l.city,''), nullif(r.address,'')) as city,
         r.address, r.logo, r.cover_image, r.cuisine,
         l.listing_type, l.hotel_booking_enabled, l.food_ordering_enabled,
         l.restaurant_reservation_enabled
  from public.restaurants r
  join public.anaira_marketplace_listings l on l.restaurant_id=r.id
  where r.status='active'
    and l.marketplace_visible=true
    and l.approval_status='approved'
    and (
      p_city is null or p_city='' or
      lower(coalesce(l.city,r.address,'')) like '%'||lower(p_city)||'%'
    )
    and (
      p_mode='all'
      or (p_mode='hotel' and l.hotel_booking_enabled=true)
      or (p_mode='food' and l.food_ordering_enabled=true)
    )
  order by r.name;
$$;

create or replace function public.anaira_marketplace_business(
  p_restaurant_id uuid
) returns table(
  restaurant_id uuid, name text, address text, logo text, cover_image text, cuisine text,
  listing_type text, hotel_booking_enabled boolean, food_ordering_enabled boolean,
  restaurant_reservation_enabled boolean
)
language sql stable security definer set search_path=public as $$
  select r.id,r.name,r.address,r.logo,r.cover_image,r.cuisine,l.listing_type,
         l.hotel_booking_enabled,l.food_ordering_enabled,l.restaurant_reservation_enabled
  from public.restaurants r
  join public.anaira_marketplace_listings l on l.restaurant_id=r.id
  where r.id=p_restaurant_id and r.status='active'
    and l.marketplace_visible=true and l.approval_status='approved';
$$;

-- Hotel availability by business ID. This supersedes public slug routing.
create or replace function public.anaira_public_room_availability_by_id(
  p_restaurant_id uuid,p_check_in date,p_check_out date,
  p_adults integer default 2,p_children integer default 0
) returns table(
  room_type_id uuid,name text,code text,max_occupancy integer,base_rate numeric,available_rooms integer
)
language sql stable security definer set search_path=public as $$
  select rt.id,rt.name,rt.code,rt.max_occupancy,rt.base_rate,
    case
      when count(i.id)=0 then 0
      else greatest(0,min(i.total_rooms-i.booked_rooms-i.held_rooms))::integer
    end
  from public.booking_room_types rt
  join public.anaira_marketplace_listings l
    on l.restaurant_id=rt.restaurant_id
   and l.marketplace_visible=true and l.approval_status='approved'
   and l.hotel_booking_enabled=true
  left join public.booking_inventory i
    on i.room_type_id=rt.id
   and i.stay_date>=p_check_in and i.stay_date<p_check_out
   and i.closed=false
  where rt.restaurant_id=p_restaurant_id
    and rt.active=true
    and p_check_out>p_check_in
    and rt.max_occupancy >= greatest(1,p_adults+p_children)
  group by rt.id,rt.name,rt.code,rt.max_occupancy,rt.base_rate;
$$;

-- Customer identity helper: one CRM customer per business/phone when possible.
create or replace function public.anaira_resolve_crm_customer(
  p_restaurant_id uuid,p_name text,p_phone text,p_email text
) returns uuid
language plpgsql security definer set search_path=public as $$
declare cid uuid;
begin
  select id into cid from public.crm_customers
  where tenant_id=p_restaurant_id
    and (
      (nullif(trim(p_phone),'') is not null and phone=trim(p_phone))
      or (nullif(trim(p_email),'') is not null and lower(email)=lower(trim(p_email)))
    )
  order by created_at
  limit 1;

  if cid is null then
    insert into public.crm_customers(tenant_id,full_name,phone,email,customer_type)
    values(p_restaurant_id,coalesce(nullif(trim(p_name),''),'Guest'),nullif(trim(p_phone),''),nullif(trim(p_email),''),'guest')
    returning id into cid;
  else
    update public.crm_customers
    set full_name=coalesce(nullif(trim(p_name),''),full_name),
        email=coalesce(nullif(trim(p_email),''),email),
        phone=coalesce(nullif(trim(p_phone),''),phone),
        updated_at=now()
    where id=cid;
  end if;
  return cid;
end;
$$;

-- Unified booking creation: Booking Engine owns reservation, then emits contracts
-- for PMS + CRM + payment/reconciliation. It does not directly replace those systems.
create or replace function public.anaira_create_public_booking_by_id(
  p_restaurant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,
  p_check_in date,p_check_out date,p_room_type_id uuid,p_adults integer,
  p_children integer default 0,p_source text default 'anaira_marketplace'
) returns public.booking_reservations
language plpgsql security definer set search_path=public as $$
declare
  r public.restaurants;
  rt public.booking_room_types;
  rec public.booking_reservations;
  cid uuid;
  code text;
  nights integer;
  available integer;
begin
  select * into r from public.restaurants where id=p_restaurant_id and status='active';
  if r.id is null then raise exception 'Property not found'; end if;
  if not exists(select 1 from public.anaira_marketplace_listings
                where restaurant_id=p_restaurant_id and marketplace_visible=true
                  and approval_status='approved' and hotel_booking_enabled=true)
    then raise exception 'Hotel booking is not enabled for this property'; end if;
  if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;

  select * into rt from public.booking_room_types
  where id=p_room_type_id and restaurant_id=p_restaurant_id and active=true;
  if rt.id is null then raise exception 'Room type not found'; end if;

  select coalesce(min(total_rooms-booked_rooms-held_rooms),0) into available
  from public.booking_inventory
  where room_type_id=rt.id and stay_date>=p_check_in and stay_date<p_check_out and closed=false;
  if available<=0 then raise exception 'No room inventory available for the selected dates'; end if;

  nights:=greatest(1,p_check_out-p_check_in);
  cid:=public.anaira_resolve_crm_customer(p_restaurant_id,p_guest_name,p_guest_phone,p_guest_email);
  code:='ANB-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));

  insert into public.booking_reservations(
    restaurant_id,booking_code,customer_id,room_type_id,check_in,check_out,adults,children,
    guest_name,guest_phone,guest_email,status,payment_status,total_amount,source
  ) values (
    p_restaurant_id,code,cid,rt.id,p_check_in,p_check_out,p_adults,p_children,
    p_guest_name,p_guest_phone,p_guest_email,'pending','unpaid',rt.base_rate*nights,p_source
  ) returning * into rec;

  insert into public.crm_interactions(customer_id,channel,interaction_type,subject,notes)
  values(cid,'booking_engine','hotel_booking','New hotel booking',
         jsonb_build_object('booking_id',rec.id,'booking_code',rec.booking_code,'restaurant_id',p_restaurant_id)::text);

  insert into public.anaira_platform_events(restaurant_id,event_name,source_plugin,aggregate_type,aggregate_id,payload)
  values
    (p_restaurant_id,'booking.created','hotel-booking','booking',rec.id,
      jsonb_build_object('booking_id',rec.id,'booking_code',rec.booking_code,'customer_id',cid,'room_type_id',rt.id,'check_in',p_check_in,'check_out',p_check_out)),
    (p_restaurant_id,'crm.customer.booking_created','hotel-booking','customer',cid,
      jsonb_build_object('booking_id',rec.id,'booking_code',rec.booking_code)),
    (p_restaurant_id,'payment.authorization_required','hotel-booking','booking',rec.id,
      jsonb_build_object('amount',rec.total_amount,'currency','INR'));

  return rec;
end;
$$;

-- Unified food order creation. Delivery owns fulfilment; POS consumes the event.
create or replace function public.anaira_create_public_delivery_order_by_id(
  p_restaurant_id uuid,p_customer_name text,p_customer_phone text,
  p_address jsonb,p_items jsonb,p_source text default 'anaira_marketplace'
) returns public.delivery_orders
language plpgsql security definer set search_path=public as $$
declare
  r public.restaurants;
  code text;
  total numeric:=0;
  item jsonb;
  rec public.delivery_orders;
  oid uuid;
  cid uuid;
begin
  select * into r from public.restaurants where id=p_restaurant_id and status='active'
    and delivery_enabled=true;
  if r.id is null then raise exception 'Restaurant not found or delivery disabled'; end if;
  if not exists(select 1 from public.anaira_marketplace_listings
                where restaurant_id=p_restaurant_id and marketplace_visible=true
                  and approval_status='approved' and food_ordering_enabled=true)
    then raise exception 'Food ordering is not enabled for this restaurant'; end if;

  cid:=public.anaira_resolve_crm_customer(p_restaurant_id,p_customer_name,p_customer_phone,null);

  for item in select * from jsonb_array_elements(coalesce(p_items,'[]'::jsonb)) loop
    total:=total+coalesce((item->>'unit_price')::numeric,0)*greatest(1,coalesce((item->>'quantity')::integer,1));
  end loop;
  if total<=0 then raise exception 'Cart is empty'; end if;

  code:='AND-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  insert into public.delivery_orders(
    restaurant_id,order_code,customer_id,customer_name,customer_phone,address,source,status,payment_status,
    subtotal,total_amount
  ) values (
    p_restaurant_id,code,cid,p_customer_name,p_customer_phone,coalesce(p_address,'{}'::jsonb),
    p_source,'placed','pending',total,total
  ) returning * into rec;
  oid:=rec.id;

  for item in select * from jsonb_array_elements(coalesce(p_items,'[]'::jsonb)) loop
    insert into public.delivery_order_items(delivery_order_id,menu_item_id,name,quantity,unit_price,modifiers)
    values(oid,null,item->>'name',greatest(1,coalesce((item->>'quantity')::integer,1)),
           coalesce((item->>'unit_price')::numeric,0),coalesce(item->'modifiers','{}'::jsonb));
  end loop;

  insert into public.crm_restaurant_visits(tenant_id,customer_id,outlet_id,guest_count,order_id,amount,payment_method)
  values(p_restaurant_id,cid,p_restaurant_id,1,oid,total,'pending');

  insert into public.crm_interactions(customer_id,channel,interaction_type,subject,notes)
  values(cid,'food_marketplace','food_order','New food order',
         jsonb_build_object('order_id',rec.id,'order_code',rec.order_code,'restaurant_id',p_restaurant_id)::text);

  insert into public.anaira_platform_events(restaurant_id,event_name,source_plugin,aggregate_type,aggregate_id,payload)
  values
    (p_restaurant_id,'delivery.order.created','food-delivery','delivery_order',rec.id,
      jsonb_build_object('order_id',rec.id,'order_code',rec.order_code,'customer_id',cid,'total',total)),
    (p_restaurant_id,'pos.order.import_requested','food-delivery','delivery_order',rec.id,
      jsonb_build_object('order_id',rec.id,'order_code',rec.order_code,'customer_id',cid,'items',p_items)),
    (p_restaurant_id,'payment.authorization_required','food-delivery','delivery_order',rec.id,
      jsonb_build_object('amount',total,'currency','INR'));

  return rec;
end;
$$;

-- Reservation integration: reservation engine emits CRM/POS events.
create or replace function public.anaira_create_public_restaurant_reservation_by_id(
  p_restaurant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,
  p_date date,p_time time,p_party_size integer,p_source text default 'anaira_marketplace'
) returns public.restaurant_reservations
language plpgsql security definer set search_path=public as $$
declare r public.restaurants; rec public.restaurant_reservations; cid uuid; code text;
begin
  select * into r from public.restaurants where id=p_restaurant_id and status='active';
  if r.id is null then raise exception 'Restaurant not found'; end if;
  if not exists(select 1 from public.anaira_marketplace_listings
                where restaurant_id=p_restaurant_id and marketplace_visible=true
                  and approval_status='approved' and restaurant_reservation_enabled=true)
    then raise exception 'Restaurant reservation is not enabled'; end if;
  cid:=public.anaira_resolve_crm_customer(p_restaurant_id,p_guest_name,p_guest_phone,p_guest_email);
  code:='ANR-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  insert into public.restaurant_reservations(
    restaurant_id,reservation_code,guest_name,guest_phone,guest_email,
    reservation_date,reservation_time,party_size,status,source
  ) values(p_restaurant_id,code,p_guest_name,p_guest_phone,p_guest_email,p_date,p_time,p_party_size,'confirmed',p_source)
  returning * into rec;

  insert into public.crm_interactions(customer_id,channel,interaction_type,subject,notes)
  values(cid,'restaurant_reservation','restaurant_reservation','New restaurant reservation',
         jsonb_build_object('reservation_id',rec.id,'reservation_code',rec.reservation_code)::text);

  insert into public.anaira_platform_events(restaurant_id,event_name,source_plugin,aggregate_type,aggregate_id,payload)
  values
    (p_restaurant_id,'restaurant.reservation.created','restaurant-reservation','reservation',rec.id,
      jsonb_build_object('reservation_id',rec.id,'reservation_code',rec.reservation_code,'customer_id',cid,'party_size',p_party_size)),
    (p_restaurant_id,'pos.table_reservation_requested','restaurant-reservation','reservation',rec.id,
      jsonb_build_object('reservation_id',rec.id,'reservation_code',rec.reservation_code,'party_size',p_party_size));

  return rec;
end;
$$;

grant execute on function public.anaira_marketplace_businesses(text,text) to anon,authenticated;
grant execute on function public.anaira_marketplace_business(uuid) to anon,authenticated;
grant execute on function public.anaira_public_room_availability_by_id(uuid,date,date,integer,integer) to anon,authenticated;
grant execute on function public.anaira_create_public_booking_by_id(uuid,text,text,text,date,date,uuid,integer,integer,text) to anon,authenticated;
grant execute on function public.anaira_create_public_delivery_order_by_id(uuid,text,text,jsonb,jsonb,text) to anon,authenticated;
grant execute on function public.anaira_create_public_restaurant_reservation_by_id(uuid,text,text,text,date,time,integer,text) to anon,authenticated;

comment on table public.anaira_marketplace_listings is
'Unified Anaira customer marketplace listing. restaurant_id is the canonical business reference; public URLs must use IDs, not slugs.';

comment on table public.anaira_integration_links is
'Cross-plugin identity map. Business operations stay owned by their canonical plugin; links are integration metadata only.';

insert into public.anaira_plugin_catalog(plugin_key,display_name,category,description,route,core)
values ('marketplace','Anaira Customer Marketplace','Commerce','Unified customer-facing hotel booking and restaurant food marketplace.','/marketplace',false)
on conflict (plugin_key) do update set display_name=excluded.display_name,category=excluded.category,description=excluded.description,route=excluded.route,core=excluded.core;
insert into public.anaira_plugin_dependencies(plugin_key,dependency_key,dependency_type)
values ('marketplace','crm','optional'),('marketplace','hotel-booking','optional'),('marketplace','hotel-pms','optional'),('marketplace','food-delivery','optional'),('marketplace','restaurant-reservation','optional'),('marketplace','anaira-pos','optional')
on conflict do nothing;
