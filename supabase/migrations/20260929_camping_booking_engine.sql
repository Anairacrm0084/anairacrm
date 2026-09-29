-- Anaira Camping Booking Engine
-- Parallel to the Hotel Booking Engine; hotel tables and workflows remain untouched.

create table if not exists public.camp_properties (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null unique references public.restaurants(id) on delete cascade,
  name text not null,
  short_name text,
  description text,
  destination text,
  address text,
  city text,
  state text default 'Himachal Pradesh',
  country text default 'India',
  latitude numeric,
  longitude numeric,
  logo_url text,
  cover_image_url text,
  gallery jsonb not null default '[]'::jsonb,
  check_in_time text,
  check_out_time text,
  cancellation_policy text,
  child_policy text,
  pet_policy text,
  active boolean not null default true,
  marketplace_visible boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.camp_unit_types (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  name text not null,
  code text,
  description text,
  max_guests integer not null default 1 check (max_guests >= 1),
  max_adults integer not null default 1 check (max_adults >= 1),
  max_children integer not null default 0 check (max_children >= 0),
  unit_count integer not null default 1 check (unit_count >= 0),
  base_rate numeric(12,2) not null default 0 check (base_rate >= 0),
  image_urls jsonb not null default '[]'::jsonb,
  amenities jsonb not null default '[]'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.camp_rate_plans (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  unit_type_id uuid not null references public.camp_unit_types(id) on delete cascade,
  name text not null,
  code text,
  pricing_mode text not null default 'per_person' check (pricing_mode in ('per_person','per_unit')),
  rate numeric(12,2) not null default 0 check (rate >= 0),
  weekend_rate numeric(12,2),
  seasonal_multiplier numeric(8,4) not null default 1 check (seasonal_multiplier > 0),
  refundable boolean not null default true,
  deposit_percent numeric(6,2) not null default 0,
  cancellation_policy text,
  min_stay integer not null default 1 check (min_stay >= 1),
  max_stay integer,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.camp_inventory (
  id uuid primary key default gen_random_uuid(),
  unit_type_id uuid not null references public.camp_unit_types(id) on delete cascade,
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  stay_date date not null,
  total_units integer not null default 0 check (total_units >= 0),
  sold_units integer not null default 0 check (sold_units >= 0),
  held_units integer not null default 0 check (held_units >= 0),
  blocked_units integer not null default 0 check (blocked_units >= 0),
  closed boolean not null default false,
  unique(unit_type_id,stay_date)
);

create table if not exists public.camp_reservations (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  reservation_code text not null unique,
  guest_name text not null,
  guest_phone text not null,
  guest_email text,
  unit_type_id uuid not null references public.camp_unit_types(id),
  rate_plan_id uuid not null references public.camp_rate_plans(id),
  check_in date not null,
  check_out date not null,
  adults integer not null default 1 check (adults >= 1),
  children integer not null default 0 check (children >= 0),
  pricing_mode text not null default 'per_person',
  nightly_rate numeric(12,2) not null default 0,
  total_amount numeric(12,2) not null default 0,
  paid_amount numeric(12,2) not null default 0,
  balance_amount numeric(12,2) not null default 0,
  status text not null default 'payment_pending',
  payment_status text not null default 'pending',
  payment_method text,
  payment_reference text,
  payment_proof_url text,
  source text not null default 'anaira-camping-store',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check(check_out > check_in)
);

create table if not exists public.camp_inventory_holds (
  id uuid primary key default gen_random_uuid(),
  reservation_id uuid not null references public.camp_reservations(id) on delete cascade,
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  unit_type_id uuid not null references public.camp_unit_types(id) on delete cascade,
  check_in date not null,
  check_out date not null,
  units integer not null default 1 check (units > 0),
  status text not null default 'held',
  idempotency_key text not null unique,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table if not exists public.camp_booking_transactions (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  reservation_id uuid not null references public.camp_reservations(id) on delete cascade,
  inventory_hold_id uuid references public.camp_inventory_holds(id),
  state text not null default 'payment_pending',
  idempotency_key text not null unique,
  amount numeric(12,2) not null default 0,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_camp_unit_types_restaurant on public.camp_unit_types(restaurant_id,active);
create index if not exists idx_camp_rates_restaurant on public.camp_rate_plans(restaurant_id,active);
create index if not exists idx_camp_inventory_restaurant_date on public.camp_inventory(restaurant_id,stay_date);
create index if not exists idx_camp_reservations_restaurant on public.camp_reservations(restaurant_id,created_at desc);
create index if not exists idx_camp_holds_expiry on public.camp_inventory_holds(status,expires_at);

alter table public.camp_properties enable row level security;
alter table public.camp_unit_types enable row level security;
alter table public.camp_rate_plans enable row level security;
alter table public.camp_inventory enable row level security;
alter table public.camp_reservations enable row level security;
alter table public.camp_inventory_holds enable row level security;
alter table public.camp_booking_transactions enable row level security;

drop policy if exists camp_properties_public_select on public.camp_properties;
create policy camp_properties_public_select on public.camp_properties for select to anon,authenticated using (active and marketplace_visible);
drop policy if exists camp_properties_tenant_all on public.camp_properties;
create policy camp_properties_tenant_all on public.camp_properties for all to authenticated using (anaira_can_access_tenant(restaurant_id)) with check (anaira_can_access_tenant(restaurant_id));

drop policy if exists camp_unit_types_public_select on public.camp_unit_types;
create policy camp_unit_types_public_select on public.camp_unit_types for select to anon,authenticated using (active and exists(select 1 from public.camp_properties p where p.restaurant_id=camp_unit_types.restaurant_id and p.active and p.marketplace_visible));
drop policy if exists camp_unit_types_tenant_all on public.camp_unit_types;
create policy camp_unit_types_tenant_all on public.camp_unit_types for all to authenticated using (anaira_can_access_tenant(restaurant_id)) with check (anaira_can_access_tenant(restaurant_id));

drop policy if exists camp_rate_plans_public_select on public.camp_rate_plans;
create policy camp_rate_plans_public_select on public.camp_rate_plans for select to anon,authenticated using (active and exists(select 1 from public.camp_properties p where p.restaurant_id=camp_rate_plans.restaurant_id and p.active and p.marketplace_visible));
drop policy if exists camp_rate_plans_tenant_all on public.camp_rate_plans;
create policy camp_rate_plans_tenant_all on public.camp_rate_plans for all to authenticated using (anaira_can_access_tenant(restaurant_id)) with check (anaira_can_access_tenant(restaurant_id));

drop policy if exists camp_inventory_public_select on public.camp_inventory;
create policy camp_inventory_public_select on public.camp_inventory for select to anon,authenticated using (exists(select 1 from public.camp_properties p where p.restaurant_id=camp_inventory.restaurant_id and p.active and p.marketplace_visible));
drop policy if exists camp_inventory_tenant_all on public.camp_inventory;
create policy camp_inventory_tenant_all on public.camp_inventory for all to authenticated using (anaira_can_access_tenant(restaurant_id)) with check (anaira_can_access_tenant(restaurant_id));

drop policy if exists camp_reservations_tenant_select on public.camp_reservations;
create policy camp_reservations_tenant_select on public.camp_reservations for select to authenticated using (anaira_can_access_tenant(restaurant_id));
drop policy if exists camp_holds_tenant_select on public.camp_inventory_holds;
create policy camp_holds_tenant_select on public.camp_inventory_holds for select to authenticated using (anaira_can_access_tenant(restaurant_id));
drop policy if exists camp_tx_tenant_select on public.camp_booking_transactions;
create policy camp_tx_tenant_select on public.camp_booking_transactions for select to authenticated using (anaira_can_access_tenant(restaurant_id));

create or replace function public.anaira_marketplace_camp_search(
 p_check_in date,p_check_out date,p_adults integer default 1,p_children integer default 0,p_destination text default null
) returns setof jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare x record; available integer; guest_count integer; min_rate numeric;
begin
 if p_check_out<=p_check_in then raise exception 'Check-out must be after check-in'; end if;
 if p_adults<1 then raise exception 'At least 1 adult is required'; end if;
 guest_count:=p_adults+greatest(p_children,0);
 for x in
  select p.*,r.name as restaurant_name,
    coalesce((select min(case when rp.pricing_mode='per_person' then rp.rate else rp.rate end) from camp_rate_plans rp where rp.restaurant_id=p.restaurant_id and rp.active),0) as base_rate,
    (select count(*) from camp_unit_types ut where ut.restaurant_id=p.restaurant_id and ut.active and ut.max_guests>=guest_count and ut.max_adults>=p_adults and ut.max_children>=greatest(p_children,0)) as available_unit_types
  from camp_properties p join restaurants r on r.id=p.restaurant_id
  where p.active and p.marketplace_visible
    and (nullif(trim(p_destination),'') is null or lower(coalesce(p.destination,''))=lower(trim(p_destination)) or lower(coalesce(p.city,''))=lower(trim(p_destination)))
 loop
  select min(greatest(0,coalesce(i.total_units,0)-coalesce(i.sold_units,0)-coalesce(i.held_units,0)-coalesce(i.blocked_units,0))) into available
  from camp_inventory i join camp_unit_types ut on ut.id=i.unit_type_id
  where i.restaurant_id=x.restaurant_id and ut.active and ut.max_guests>=guest_count and ut.max_adults>=p_adults and ut.max_children>=greatest(p_children,0) and i.stay_date>=p_check_in and i.stay_date<p_check_out and not i.closed;
  if (select count(*) from camp_inventory i2 join camp_unit_types ut2 on ut2.id=i2.unit_type_id where i2.restaurant_id=x.restaurant_id and ut2.active and ut2.max_guests>=guest_count and ut2.max_adults>=p_adults and ut2.max_children>=greatest(p_children,0) and i2.stay_date>=p_check_in and i2.stay_date<p_check_out and not i2.closed)=p_check_out-p_check_in and available is not null and available>0 then
   select min(rp.rate) into min_rate from camp_rate_plans rp join camp_unit_types ut on ut.id=rp.unit_type_id where rp.restaurant_id=x.restaurant_id and rp.active and ut.active and ut.max_guests>=guest_count and ut.max_adults>=p_adults and ut.max_children>=greatest(p_children,0);
   return next jsonb_build_object('restaurant_id',x.restaurant_id,'camp_id',x.id,'camp_name',x.name,'name',x.name,'city',x.city,'state',x.state,'country',x.country,'destination',x.destination,'address',x.address,'description',coalesce(x.description,''),'cover_image',x.cover_image_url,'logo',x.logo_url,'available_unit_types',coalesce(x.available_unit_types,0),'min_rate',coalesce(min_rate,0),'pricing_note','Per-person camping rates available','check_in',p_check_in,'check_out',p_check_out,'adults',p_adults,'children',p_children);
  end if;
 end loop;
end $$;
revoke all on function public.anaira_marketplace_camp_search(date,date,integer,integer,text) from public;
grant execute on function public.anaira_marketplace_camp_search(date,date,integer,integer,text) to anon,authenticated;

create or replace function public.anaira_public_camp_availability(
 p_restaurant_id uuid,p_check_in date,p_check_out date,p_adults integer default 1,p_children integer default 0
) returns setof jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r record; available integer; guest_count integer; nights integer;
begin
 if p_check_out<=p_check_in then raise exception 'Check-out must be after check-in'; end if;
 if p_adults<1 then raise exception 'At least 1 adult is required'; end if;
 guest_count:=p_adults+greatest(p_children,0); nights:=p_check_out-p_check_in;
 for r in select * from camp_unit_types where restaurant_id=p_restaurant_id and active and max_guests>=guest_count order by name loop
  select min(greatest(0,i.total_units-i.sold_units-i.held_units-i.blocked_units)) into available
  from camp_inventory i where i.unit_type_id=r.id and i.stay_date>=p_check_in and i.stay_date<p_check_out and not i.closed;
  if (select count(*) from camp_inventory i2 where i2.unit_type_id=r.id and i2.stay_date>=p_check_in and i2.stay_date<p_check_out and not i2.closed) < nights then available:=0; end if;
  return next jsonb_build_object('unit_type_id',r.id,'available_units',coalesce(available,0),'nights',nights,'guests',guest_count,'max_guests',r.max_guests);
 end loop;
end $$;
revoke all on function public.anaira_public_camp_availability(uuid,date,date,integer,integer) from public;
grant execute on function public.anaira_public_camp_availability(uuid,date,date,integer,integer) to anon,authenticated;

create or replace function public.anaira_start_public_camp_booking(
 p_restaurant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,
 p_unit_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_idempotency_key text,p_source text default 'anaira-camping-store',p_verification_id uuid default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare ut camp_unit_types%rowtype; rp camp_rate_plans%rowtype; cp camp_properties%rowtype; r camp_reservations%rowtype; h camp_inventory_holds%rowtype; tx camp_booking_transactions%rowtype;
 d date; nights integer; guests integer; nightly numeric:=0; total numeric:=0; avail integer; code text; bid uuid; holdid uuid; i jsonb; verification uuid;
begin
 if p_check_out<=p_check_in then raise exception 'Check-out must be after check-in'; end if;
 if p_adults<1 then raise exception 'At least 1 adult is required'; end if;
 guests:=p_adults+greatest(p_children,0); nights:=p_check_out-p_check_in;
 if p_verification_id is null then raise exception 'Guest contact verification is required'; end if;
 select id into verification from anaira_guest_otp_challenges where id=p_verification_id and tenant_id=p_restaurant_id and verified_at is not null and verified_at>now()-interval '30 minutes';
 if verification is null then raise exception 'Guest contact verification has expired. Please verify again.'; end if;
 select * into cp from camp_properties where restaurant_id=p_restaurant_id and active and marketplace_visible limit 1;
 if not found then raise exception 'Camping property is not published'; end if;
 select * into ut from camp_unit_types where id=p_unit_type_id and restaurant_id=p_restaurant_id and active for update;
 if not found then raise exception 'Camp unit is not available'; end if;
 if guests>ut.max_guests or p_adults>ut.max_adults or p_children>ut.max_children then raise exception 'Selected camp cannot accommodate this guest count'; end if;
 select * into rp from camp_rate_plans where id=p_rate_plan_id and unit_type_id=ut.id and restaurant_id=p_restaurant_id and active for update;
 if not found then raise exception 'Active camp rate plan not found'; end if;
 if nights<rp.min_stay then raise exception 'Minimum stay for this rate plan is % night(s)',rp.min_stay; end if;
 if rp.max_stay is not null and nights>rp.max_stay then raise exception 'Maximum stay for this rate plan is % night(s)',rp.max_stay; end if;
 select * into tx from camp_booking_transactions where restaurant_id=p_restaurant_id and idempotency_key=p_idempotency_key for update;
 if found then return jsonb_build_object('ok',true,'idempotent',true,'transaction_id',tx.id,'reservation_id',tx.reservation_id,'booking_code',(tx.payload->>'booking_code'),'amount',tx.amount,'quote',tx.payload->'quote','state',tx.state); end if;
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
  select greatest(0,total_units-sold_units-held_units-blocked_units) into avail from camp_inventory where unit_type_id=ut.id and stay_date=d for update;
  if coalesce(avail,0)<1 then raise exception 'Camping unit is not available for all selected dates'; end if;
  nightly:=nightly + case when extract(isodow from d) in (6,7) and coalesce(rp.weekend_rate,0)>0 then rp.weekend_rate else rp.rate end * coalesce(rp.seasonal_multiplier,1);
 end loop;
 if rp.pricing_mode='per_person' then total:=nightly*guests; else total:=nightly; end if;
 total:=round(total,2);
 bid:=gen_random_uuid();code:='ANC-'||upper(substr(replace(bid::text,'-',''),1,10));
 insert into camp_reservations(id,restaurant_id,reservation_code,guest_name,guest_phone,guest_email,unit_type_id,rate_plan_id,check_in,check_out,adults,children,pricing_mode,nightly_rate,total_amount,balance_amount,status,payment_status,source,metadata)
 values(bid,p_restaurant_id,code,p_guest_name,p_guest_phone,p_guest_email,ut.id,rp.id,p_check_in,p_check_out,p_adults,p_children,rp.pricing_mode,round(nightly/nights,2),total,total,'payment_pending','pending',coalesce(p_source,'anaira-camping-store'),jsonb_build_object('guest_count',guests));
 holdid:=gen_random_uuid();
 insert into camp_inventory_holds(id,reservation_id,restaurant_id,unit_type_id,check_in,check_out,units,status,idempotency_key,expires_at) values(holdid,bid,p_restaurant_id,ut.id,p_check_in,p_check_out,1,'held',p_idempotency_key,now()+interval '15 minutes');
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
  update camp_inventory set held_units=held_units+1 where unit_type_id=ut.id and stay_date=d;
 end loop;
 insert into camp_booking_transactions(restaurant_id,reservation_id,inventory_hold_id,state,idempotency_key,amount,payload) values(p_restaurant_id,bid,holdid,'payment_pending',p_idempotency_key,total,jsonb_build_object('booking_code',code,'quote',jsonb_build_object('nights',nights,'guests',guests,'pricing_mode',rp.pricing_mode,'nightly_rate',round(nightly/nights,2),'total',total),'unit_type_id',ut.id,'rate_plan_id',rp.id)) returning * into tx;
 return jsonb_build_object('ok',true,'transaction_id',tx.id,'reservation_id',bid,'booking_code',code,'hold_id',holdid,'amount',total,'quote',tx.payload->'quote','state','payment_pending');
end $$;
revoke all on function public.anaira_start_public_camp_booking(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text,uuid) from public;
grant execute on function public.anaira_start_public_camp_booking(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text,uuid) to anon,authenticated;

create or replace function public.anaira_finalize_public_camp_booking(p_reservation_id uuid,p_payment_method text,p_reference text default null,p_proof_url text default null,p_notes text default null) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r camp_reservations%rowtype; h camp_inventory_holds%rowtype; tx camp_booking_transactions%rowtype; d date;
begin
 if p_payment_method not in ('pay_at_hotel','pay_at_camp','bank_transfer','qr_upi') then raise exception 'Invalid payment method'; end if;
 select * into r from camp_reservations where id=p_reservation_id for update;
 if not found then raise exception 'Camping reservation not found'; end if;
 if r.status='confirmed' then return jsonb_build_object('ok',true,'already_confirmed',true,'reservation_id',r.id,'booking_code',r.reservation_code,'status','confirmed','payment_status',r.payment_status); end if;
 select * into h from camp_inventory_holds where reservation_id=r.id and status='held' order by created_at desc limit 1 for update;
 if not found then raise exception 'Camping inventory hold not found'; end if;
 if h.expires_at<now() then raise exception 'Booking hold expired. Please check availability again.'; end if;
 select * into tx from camp_booking_transactions where reservation_id=r.id order by created_at desc limit 1 for update;
 for d in select generate_series(r.check_in,r.check_out-1,interval '1 day')::date loop
  update camp_inventory set held_units=greatest(0,held_units-1),sold_units=sold_units+1 where unit_type_id=r.unit_type_id and stay_date=d;
 end loop;
 update camp_inventory_holds set status='consumed' where id=h.id;
 update camp_reservations set status='confirmed',payment_status=case when p_payment_method in ('pay_at_hotel','pay_at_camp') then 'pending' else 'proof_submitted' end,payment_method=p_payment_method,payment_reference=p_reference,payment_proof_url=p_proof_url,paid_amount=case when p_payment_method in ('pay_at_hotel','pay_at_camp') then 0 else paid_amount end,balance_amount=total_amount,updated_at=now(),metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('payment_note',p_notes) where id=r.id;
 update camp_booking_transactions set state=case when p_payment_method in ('pay_at_hotel','pay_at_camp') then 'confirmed' else 'payment_proof_submitted' end,updated_at=now(),payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object('payment_method',p_payment_method,'payment_reference',p_reference,'payment_proof_url',p_proof_url) where id=tx.id;
 return jsonb_build_object('ok',true,'reservation_id',r.id,'booking_code',r.reservation_code,'status','confirmed','payment_status',case when p_payment_method in ('pay_at_hotel','pay_at_camp') then 'pending' else 'proof_submitted' end);
end $$;
revoke all on function public.anaira_finalize_public_camp_booking(uuid,text,text,text,text) from public;
grant execute on function public.anaira_finalize_public_camp_booking(uuid,text,text,text,text) to anon,authenticated;

comment on table public.camp_properties is 'Anaira Camping Marketplace property master; separate from hotel HMS inventory.';
comment on table public.camp_unit_types is 'Camping accommodation/tent types.';
comment on column public.camp_rate_plans.pricing_mode is 'per_person makes single-person and multi-person camping prices scale by guest count.';

create or replace function public.anaira_release_expired_camp_holds() returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare h record; d date; n integer:=0;
begin
 for h in select * from camp_inventory_holds where status='held' and expires_at<now() for update loop
  for d in select generate_series(h.check_in,h.check_out-1,interval '1 day')::date loop
   update camp_inventory set held_units=greatest(0,held_units-h.units) where unit_type_id=h.unit_type_id and stay_date=d;
  end loop;
  update camp_inventory_holds set status='expired' where id=h.id;
  update camp_reservations set status='expired',updated_at=now() where id=h.reservation_id and status='payment_pending';
  update camp_booking_transactions set state='expired',updated_at=now() where inventory_hold_id=h.id and state='payment_pending';
  n:=n+1;
 end loop;
 return n;
end $$;
revoke all on function public.anaira_release_expired_camp_holds() from public;
grant execute on function public.anaira_release_expired_camp_holds() to anon,authenticated;
