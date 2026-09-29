-- Anaira Alternative Stay Booking Engine: Homestay / Guest House / Cottage
-- Same availability -> OTP -> hold -> payment -> confirmation contract as Camps, isolated from Hotel HMS.

create table if not exists public.anaira_stay_properties (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 stay_type text not null check(stay_type in ('homestay','guest_house','cottage')), name text not null, short_name text,
 description text, destination text, address text, city text, state text default 'Himachal Pradesh', country text default 'India',
 latitude numeric, longitude numeric, logo_url text, cover_image_url text, gallery jsonb not null default '[]'::jsonb,
 check_in_time text default '12:00', check_out_time text default '11:00', cancellation_policy text, child_policy text, pet_policy text,
 active boolean not null default true, marketplace_visible boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(restaurant_id,stay_type)
);
create table if not exists public.anaira_stay_unit_types (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 property_id uuid not null references public.anaira_stay_properties(id) on delete cascade, name text not null, code text, description text,
 max_guests integer not null default 1 check(max_guests>=1), max_adults integer not null default 1 check(max_adults>=1), max_children integer not null default 0 check(max_children>=0),
 unit_count integer not null default 1 check(unit_count>=0), base_rate numeric(12,2) not null default 0 check(base_rate>=0), image_urls jsonb not null default '[]'::jsonb, amenities jsonb not null default '[]'::jsonb,
 active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.anaira_stay_rate_plans (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade, unit_type_id uuid not null references public.anaira_stay_unit_types(id) on delete cascade,
 name text not null, code text, pricing_mode text not null default 'per_person' check(pricing_mode in ('per_person','per_unit')), rate numeric(12,2) not null default 0 check(rate>=0), weekend_rate numeric(12,2), seasonal_multiplier numeric(8,4) not null default 1 check(seasonal_multiplier>0),
 refundable boolean not null default true, deposit_percent numeric(6,2) not null default 0, cancellation_policy text, min_stay integer not null default 1 check(min_stay>=1), max_stay integer,
 active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.anaira_stay_inventory (
 id uuid primary key default gen_random_uuid(), unit_type_id uuid not null references public.anaira_stay_unit_types(id) on delete cascade, restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 stay_date date not null, total_units integer not null default 0 check(total_units>=0), sold_units integer not null default 0 check(sold_units>=0), held_units integer not null default 0 check(held_units>=0), blocked_units integer not null default 0 check(blocked_units>=0), closed boolean not null default false,
 unique(unit_type_id,stay_date)
);
create table if not exists public.anaira_stay_reservations (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade, property_id uuid not null references public.anaira_stay_properties(id) on delete restrict,
 stay_type text not null check(stay_type in ('homestay','guest_house','cottage')), reservation_code text not null unique, guest_name text not null, guest_phone text not null, guest_email text,
 unit_type_id uuid not null references public.anaira_stay_unit_types(id), rate_plan_id uuid not null references public.anaira_stay_rate_plans(id), check_in date not null, check_out date not null,
 adults integer not null default 1 check(adults>=1), children integer not null default 0 check(children>=0), pricing_mode text not null default 'per_person', nightly_rate numeric(12,2) not null default 0, total_amount numeric(12,2) not null default 0,
 paid_amount numeric(12,2) not null default 0, balance_amount numeric(12,2) not null default 0, status text not null default 'payment_pending', payment_status text not null default 'pending', payment_method text, payment_reference text, payment_proof_url text,
 source text not null default 'anaira-stay-marketplace', metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check(check_out>check_in)
);
create table if not exists public.anaira_stay_inventory_holds (
 id uuid primary key default gen_random_uuid(), reservation_id uuid not null references public.anaira_stay_reservations(id) on delete cascade, restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 unit_type_id uuid not null references public.anaira_stay_unit_types(id) on delete cascade, check_in date not null, check_out date not null, units integer not null default 1 check(units>0), status text not null default 'held', idempotency_key text not null unique, expires_at timestamptz not null, created_at timestamptz not null default now()
);
create table if not exists public.anaira_stay_booking_transactions (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade, reservation_id uuid not null references public.anaira_stay_reservations(id) on delete cascade, inventory_hold_id uuid references public.anaira_stay_inventory_holds(id), state text not null default 'payment_pending', idempotency_key text not null unique, amount numeric(12,2) not null default 0, payload jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists idx_anaira_stay_properties_type on public.anaira_stay_properties(stay_type,active,marketplace_visible);
create index if not exists idx_anaira_stay_units_property on public.anaira_stay_unit_types(property_id,active);
create index if not exists idx_anaira_stay_rates_unit on public.anaira_stay_rate_plans(unit_type_id,active);
create index if not exists idx_anaira_stay_inventory_date on public.anaira_stay_inventory(restaurant_id,stay_date);
create index if not exists idx_anaira_stay_reservations on public.anaira_stay_reservations(restaurant_id,stay_type,created_at desc);
create index if not exists idx_anaira_stay_holds_expiry on public.anaira_stay_inventory_holds(status,expires_at);

alter table public.anaira_stay_properties enable row level security; alter table public.anaira_stay_unit_types enable row level security; alter table public.anaira_stay_rate_plans enable row level security; alter table public.anaira_stay_inventory enable row level security; alter table public.anaira_stay_reservations enable row level security; alter table public.anaira_stay_inventory_holds enable row level security; alter table public.anaira_stay_booking_transactions enable row level security;

drop policy if exists anaira_stay_properties_public on public.anaira_stay_properties; create policy anaira_stay_properties_public on public.anaira_stay_properties for select to anon,authenticated using(active and marketplace_visible);
drop policy if exists anaira_stay_properties_tenant on public.anaira_stay_properties; create policy anaira_stay_properties_tenant on public.anaira_stay_properties for all to authenticated using(anaira_can_access_tenant(restaurant_id)) with check(anaira_can_access_tenant(restaurant_id));
drop policy if exists anaira_stay_units_public on public.anaira_stay_unit_types; create policy anaira_stay_units_public on public.anaira_stay_unit_types for select to anon,authenticated using(active and exists(select 1 from public.anaira_stay_properties p where p.id=property_id and p.active and p.marketplace_visible));
drop policy if exists anaira_stay_units_tenant on public.anaira_stay_unit_types; create policy anaira_stay_units_tenant on public.anaira_stay_unit_types for all to authenticated using(anaira_can_access_tenant(restaurant_id)) with check(anaira_can_access_tenant(restaurant_id));
drop policy if exists anaira_stay_rates_public on public.anaira_stay_rate_plans; create policy anaira_stay_rates_public on public.anaira_stay_rate_plans for select to anon,authenticated using(active and exists(select 1 from public.anaira_stay_unit_types u join public.anaira_stay_properties p on p.id=u.property_id where u.id=unit_type_id and p.active and p.marketplace_visible));
drop policy if exists anaira_stay_rates_tenant on public.anaira_stay_rate_plans; create policy anaira_stay_rates_tenant on public.anaira_stay_rate_plans for all to authenticated using(anaira_can_access_tenant(restaurant_id)) with check(anaira_can_access_tenant(restaurant_id));
drop policy if exists anaira_stay_inventory_public on public.anaira_stay_inventory; create policy anaira_stay_inventory_public on public.anaira_stay_inventory for select to anon,authenticated using(exists(select 1 from public.anaira_stay_properties p join public.anaira_stay_unit_types u on u.property_id=p.id where u.id=unit_type_id and p.active and p.marketplace_visible));
drop policy if exists anaira_stay_inventory_tenant on public.anaira_stay_inventory; create policy anaira_stay_inventory_tenant on public.anaira_stay_inventory for all to authenticated using(anaira_can_access_tenant(restaurant_id)) with check(anaira_can_access_tenant(restaurant_id));
drop policy if exists anaira_stay_reservations_tenant on public.anaira_stay_reservations; create policy anaira_stay_reservations_tenant on public.anaira_stay_reservations for select to authenticated using(anaira_can_access_tenant(restaurant_id));
drop policy if exists anaira_stay_holds_tenant on public.anaira_stay_inventory_holds; create policy anaira_stay_holds_tenant on public.anaira_stay_inventory_holds for select to authenticated using(anaira_can_access_tenant(restaurant_id));
drop policy if exists anaira_stay_tx_tenant on public.anaira_stay_booking_transactions; create policy anaira_stay_tx_tenant on public.anaira_stay_booking_transactions for select to authenticated using(anaira_can_access_tenant(restaurant_id));

create or replace function public.anaira_marketplace_stay_search(p_stay_type text,p_check_in date,p_check_out date,p_adults integer default 1,p_children integer default 0,p_destination text default null) returns table(restaurant_id uuid,property_id uuid,stay_type text,property_name text,destination text,city text,unit_type_id uuid,unit_name text,rate_plan_id uuid,rate_name text,pricing_mode text,rate numeric,available_units integer,max_guests integer,max_adults integer,max_children integer,cover_image_url text) language sql security definer set search_path=public,pg_temp as $$ select p.restaurant_id,p.id,p.stay_type,p.name,p.destination,p.city,u.id,u.name,r.id,r.name,r.pricing_mode,r.rate,greatest(0,least(u.unit_count,coalesce((select min(i.total_units-i.sold_units-i.held_units-i.blocked_units) from public.anaira_stay_inventory i where i.unit_type_id=u.id and i.stay_date>=p_check_in and i.stay_date<p_check_out and not i.closed),0)))::int,u.max_guests,u.max_adults,u.max_children,p.cover_image_url from public.anaira_stay_properties p join public.anaira_stay_unit_types u on u.property_id=p.id join lateral(select * from public.anaira_stay_rate_plans rr where rr.unit_type_id=u.id and rr.active order by rr.rate limit 1) r on true where p.active and p.marketplace_visible and u.active and p.stay_type=p_stay_type and (p_destination is null or p.destination ilike '%'||p_destination||'%' or p.city ilike '%'||p_destination||'%' or p.name ilike '%'||p_destination||'%') and p_adults>=1 and p_adults<=u.max_adults and p_children>=0 and p_children<=u.max_children and p_adults+p_children<=u.max_guests order by p.name,u.name $$;
revoke all on function public.anaira_marketplace_stay_search(text,date,date,integer,integer,text) from public; grant execute on function public.anaira_marketplace_stay_search(text,date,date,integer,integer,text) to anon,authenticated;

create or replace function public.anaira_public_stay_availability(p_restaurant_id uuid,p_property_id uuid,p_stay_type text,p_check_in date,p_check_out date,p_adults integer default 1,p_children integer default 0) returns table(unit_type_id uuid,available_units integer,max_guests integer,max_adults integer,max_children integer) language sql security definer set search_path=public,pg_temp as $$ select u.id,greatest(0,least(u.unit_count,coalesce((select min(i.total_units-i.sold_units-i.held_units-i.blocked_units) from public.anaira_stay_inventory i where i.unit_type_id=u.id and i.stay_date>=p_check_in and i.stay_date<p_check_out and not i.closed),0)))::int,u.max_guests,u.max_adults,u.max_children from public.anaira_stay_unit_types u join public.anaira_stay_properties p on p.id=u.property_id where u.restaurant_id=p_restaurant_id and p.id=p_property_id and p.stay_type=p_stay_type and p.active and p.marketplace_visible and u.active and p_adults>=1 and p_adults<=u.max_adults and p_children>=0 and p_children<=u.max_children and p_adults+p_children<=u.max_guests $$;
revoke all on function public.anaira_public_stay_availability(uuid,uuid,text,date,date,integer,integer) from public; grant execute on function public.anaira_public_stay_availability(uuid,uuid,text,date,date,integer,integer) to anon,authenticated;


create or replace function public.anaira_start_public_stay_booking(p_restaurant_id uuid,p_property_id uuid,p_stay_type text,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,p_unit_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_idempotency_key text,p_source text default 'anaira-stay-marketplace',p_verification_id uuid default null) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare u public.anaira_stay_unit_types%rowtype;r public.anaira_stay_rate_plans%rowtype;p public.anaira_stay_properties%rowtype;tx public.anaira_stay_booking_transactions%rowtype;d date;nights int;guests int;nightly numeric:=0;total numeric:=0;avail int;rid uuid;hid uuid;code text;v uuid;
begin
 if p_stay_type not in('homestay','guest_house','cottage') then raise exception 'Unsupported stay type'; end if;
 if p_check_out<=p_check_in then raise exception 'Check-out must be after check-in'; end if;
 if p_adults<1 then raise exception 'At least 1 adult is required'; end if;
 guests:=p_adults+greatest(p_children,0); nights:=p_check_out-p_check_in;
 if p_verification_id is null then raise exception 'Guest contact verification is required'; end if;
 select id into v from public.anaira_guest_otp_challenges where id=p_verification_id and tenant_id=p_restaurant_id and verified_at is not null and verified_at>now()-interval '30 minutes';
 if v is null then raise exception 'Guest contact verification has expired. Please verify again.'; end if;
 select * into p from public.anaira_stay_properties where id=p_property_id and restaurant_id=p_restaurant_id and stay_type=p_stay_type and active and marketplace_visible for update;
 if not found then raise exception 'Stay property is not published'; end if;
 select * into u from public.anaira_stay_unit_types where id=p_unit_type_id and property_id=p_property_id and restaurant_id=p_restaurant_id and active for update;
 if not found then raise exception 'Stay unit is not available'; end if;
 if guests>u.max_guests or p_adults>u.max_adults or p_children>u.max_children then raise exception 'Selected stay cannot accommodate this guest count'; end if;
 select * into r from public.anaira_stay_rate_plans where id=p_rate_plan_id and unit_type_id=u.id and restaurant_id=p_restaurant_id and active for update;
 if not found then raise exception 'Active rate plan not found'; end if;
 if nights<r.min_stay then raise exception 'Minimum stay for this rate plan is % night(s)',r.min_stay; end if;
 if r.max_stay is not null and nights>r.max_stay then raise exception 'Maximum stay for this rate plan is % night(s)',r.max_stay; end if;
 select * into tx from public.anaira_stay_booking_transactions where restaurant_id=p_restaurant_id and idempotency_key=p_idempotency_key for update;
 if found then return jsonb_build_object('ok',true,'idempotent',true,'transaction_id',tx.id,'reservation_id',tx.reservation_id,'booking_code',tx.payload->>'booking_code','amount',tx.amount,'quote',tx.payload->'quote','state',tx.state); end if;
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
   select greatest(0,total_units-sold_units-held_units-blocked_units) into avail from public.anaira_stay_inventory where unit_type_id=u.id and stay_date=d and not closed for update;
   if coalesce(avail,0)<1 then raise exception 'Stay unit is not available for all selected dates'; end if;
   nightly:=nightly+(case when extract(isodow from d) in(6,7) and coalesce(r.weekend_rate,0)>0 then r.weekend_rate else r.rate end)*coalesce(r.seasonal_multiplier,1);
 end loop;
 if r.pricing_mode='per_person' then total:=nightly*guests; else total:=nightly; end if; total:=round(total,2);
 rid:=gen_random_uuid(); code:='ANS-'||upper(substr(replace(rid::text,'-',''),1,10));
 insert into public.anaira_stay_reservations(id,restaurant_id,property_id,stay_type,reservation_code,guest_name,guest_phone,guest_email,unit_type_id,rate_plan_id,check_in,check_out,adults,children,pricing_mode,nightly_rate,total_amount,balance_amount,status,payment_status,source,metadata) values(rid,p_restaurant_id,p_property_id,p_stay_type,code,p_guest_name,p_guest_phone,p_guest_email,u.id,r.id,p_check_in,p_check_out,p_adults,p_children,r.pricing_mode,round(nightly/nights,2),total,total,'payment_pending','pending',coalesce(p_source,'anaira-stay-marketplace'),jsonb_build_object('guest_count',guests));
 hid:=gen_random_uuid(); insert into public.anaira_stay_inventory_holds(id,reservation_id,restaurant_id,unit_type_id,check_in,check_out,units,status,idempotency_key,expires_at) values(hid,rid,p_restaurant_id,u.id,p_check_in,p_check_out,1,'held',p_idempotency_key,now()+interval '15 minutes');
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop update public.anaira_stay_inventory set held_units=held_units+1 where unit_type_id=u.id and stay_date=d; end loop;
 insert into public.anaira_stay_booking_transactions(restaurant_id,reservation_id,inventory_hold_id,state,idempotency_key,amount,payload) values(p_restaurant_id,rid,hid,'payment_pending',p_idempotency_key,total,jsonb_build_object('booking_code',code,'quote',jsonb_build_object('nights',nights,'guests',guests,'pricing_mode',r.pricing_mode,'nightly_rate',round(nightly/nights,2),'total',total),'property_id',p_property_id,'stay_type',p_stay_type,'unit_type_id',u.id,'rate_plan_id',r.id)) returning * into tx;
 return jsonb_build_object('ok',true,'transaction_id',tx.id,'reservation_id',rid,'booking_code',code,'hold_id',hid,'amount',total,'quote',tx.payload->'quote','state','payment_pending');
end$$;
revoke all on function public.anaira_start_public_stay_booking(uuid,uuid,text,text,text,text,date,date,uuid,uuid,integer,integer,text,text,uuid) from public; grant execute on function public.anaira_start_public_stay_booking(uuid,uuid,text,text,text,text,date,date,uuid,uuid,integer,integer,text,text,uuid) to anon,authenticated;

create or replace function public.anaira_finalize_public_stay_booking(p_reservation_id uuid,p_payment_method text,p_reference text default null,p_proof_url text default null,p_notes text default null) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.anaira_stay_reservations%rowtype;h public.anaira_stay_inventory_holds%rowtype;tx public.anaira_stay_booking_transactions%rowtype;d date;
begin
 if p_payment_method not in('pay_at_hotel','pay_at_stay','bank_transfer','qr_upi') then raise exception 'Invalid payment method'; end if;
 select * into r from public.anaira_stay_reservations where id=p_reservation_id for update;if not found then raise exception 'Stay reservation not found';end if;
 if r.status='confirmed' then return jsonb_build_object('ok',true,'already_confirmed',true,'reservation_id',r.id,'booking_code',r.reservation_code,'status','confirmed','payment_status',r.payment_status);end if;
 select * into h from public.anaira_stay_inventory_holds where reservation_id=r.id and status='held' order by created_at desc limit 1 for update;if not found then raise exception 'Stay inventory hold not found';end if;
 if h.expires_at<now() then raise exception 'Booking hold expired. Please check availability again.';end if;
 select * into tx from public.anaira_stay_booking_transactions where reservation_id=r.id order by created_at desc limit 1 for update;
 for d in select generate_series(r.check_in,r.check_out-1,interval '1 day')::date loop update public.anaira_stay_inventory set held_units=greatest(0,held_units-1),sold_units=sold_units+1 where unit_type_id=r.unit_type_id and stay_date=d;end loop;
 update public.anaira_stay_inventory_holds set status='consumed' where id=h.id;
 update public.anaira_stay_reservations set status='confirmed',payment_status=case when p_payment_method in('pay_at_hotel','pay_at_stay') then 'pending' else 'proof_submitted' end,payment_method=p_payment_method,payment_reference=p_reference,payment_proof_url=p_proof_url,balance_amount=total_amount,updated_at=now(),metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('payment_note',p_notes) where id=r.id;
 update public.anaira_stay_booking_transactions set state=case when p_payment_method in('pay_at_hotel','pay_at_stay') then 'confirmed' else 'payment_proof_submitted' end,updated_at=now(),payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object('payment_method',p_payment_method,'payment_reference',p_reference,'payment_proof_url',p_proof_url) where id=tx.id;
 return jsonb_build_object('ok',true,'reservation_id',r.id,'booking_code',r.reservation_code,'status','confirmed','payment_status',case when p_payment_method in('pay_at_hotel','pay_at_stay') then 'pending' else 'proof_submitted' end);
end$$;
revoke all on function public.anaira_finalize_public_stay_booking(uuid,text,text,text,text) from public; grant execute on function public.anaira_finalize_public_stay_booking(uuid,text,text,text,text) to anon,authenticated;

create or replace function public.anaira_release_expired_stay_holds() returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare h record;d date;n int:=0;
begin
 for h in select * from public.anaira_stay_inventory_holds where status='held' and expires_at<now() for update loop
  for d in select generate_series(h.check_in,h.check_out-1,interval '1 day')::date loop update public.anaira_stay_inventory set held_units=greatest(0,held_units-h.units) where unit_type_id=h.unit_type_id and stay_date=d;end loop;
  update public.anaira_stay_inventory_holds set status='expired' where id=h.id; update public.anaira_stay_reservations set status='expired',updated_at=now() where id=h.reservation_id and status='payment_pending'; update public.anaira_stay_booking_transactions set state='expired',updated_at=now() where inventory_hold_id=h.id and state='payment_pending'; n:=n+1;
 end loop; return n;
end$$;
revoke all on function public.anaira_release_expired_stay_holds() from public; grant execute on function public.anaira_release_expired_stay_holds() to anon,authenticated;
