-- Anaira Booking Engine Premium Closure
-- Credentials/providers are intentionally not embedded here.
-- Adds conversion, multi-room, premium quote, guest self-service, parity and group-booking foundations.

alter table public.booking_reservations
  add column if not exists booking_group_id uuid,
  add column if not exists cancellation_policy_snapshot text,
  add column if not exists rate_snapshot jsonb not null default '{}'::jsonb,
  add column if not exists tax_breakdown jsonb not null default '{}'::jsonb,
  add column if not exists fee_breakdown jsonb not null default '{}'::jsonb,
  add column if not exists guest_preferences jsonb not null default '{}'::jsonb,
  add column if not exists modified_at timestamptz,
  add column if not exists cancelled_at timestamptz;

create table if not exists public.booking_master_orders (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 booking_code text not null,
 guest_name text not null,
 guest_email text,
 guest_phone text,
 check_in date not null,
 check_out date not null,
 adults integer not null default 1,
 children integer not null default 0,
 room_count integer not null default 1,
 status text not null default 'payment_pending',
 payment_status text not null default 'unpaid',
 subtotal numeric(14,2) not null default 0,
 discount_amount numeric(14,2) not null default 0,
 addons_amount numeric(14,2) not null default 0,
 tax_amount numeric(14,2) not null default 0,
 fee_amount numeric(14,2) not null default 0,
 total_amount numeric(14,2) not null default 0,
 source text not null default 'direct',
 promo_code text,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(restaurant_id,booking_code)
);

alter table public.booking_reservations
  drop constraint if exists booking_reservations_booking_group_id_fkey;
alter table public.booking_reservations
  add constraint booking_reservations_booking_group_id_fkey
  foreign key (booking_group_id) references public.booking_master_orders(id) on delete set null;

create table if not exists public.booking_conversion_events (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 session_id text not null,
 event_name text not null,
 booking_id uuid,
 property_id uuid,
 room_type_id uuid,
 rate_plan_id uuid,
 value numeric(14,2),
 currency text default 'INR',
 metadata jsonb not null default '{}'::jsonb,
 occurred_at timestamptz not null default now()
);
create index if not exists booking_conversion_events_idx on public.booking_conversion_events(restaurant_id,session_id,occurred_at desc);

create table if not exists public.booking_abandoned_sessions (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 session_id text not null,
 guest_name text,
 guest_email text,
 guest_phone text,
 check_in date,
 check_out date,
 adults integer not null default 1,
 children integer not null default 0,
 room_type_id uuid,
 rate_plan_id uuid,
 quote jsonb not null default '{}'::jsonb,
 last_step text,
 recovered boolean not null default false,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(restaurant_id,session_id)
);

create table if not exists public.booking_rate_parity_snapshots (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 room_type_id uuid,
 rate_plan_id uuid,
 stay_date date not null,
 channel_code text not null,
 currency text not null default 'INR',
 public_rate numeric(14,2),
 channel_rate numeric(14,2),
 availability integer,
 parity_status text not null default 'unknown',
 source text,
 raw jsonb not null default '{}'::jsonb,
 observed_at timestamptz not null default now()
);
create index if not exists booking_rate_parity_idx on public.booking_rate_parity_snapshots(restaurant_id,stay_date,channel_code,observed_at desc);

create table if not exists public.booking_group_requests (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 group_name text not null,
 contact_name text not null,
 email text,
 phone text,
 check_in date not null,
 check_out date not null,
 rooms_requested integer not null default 1,
 guests integer not null default 1,
 budget numeric(14,2),
 status text not null default 'new',
 notes text,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

create table if not exists public.booking_member_rates (
 id uuid primary key default gen_random_uuid(),
 restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 rate_plan_id uuid not null,
 tier_code text not null,
 adjustment_type text not null default 'percent',
 adjustment_value numeric(12,2) not null default 0,
 active boolean not null default true,
 created_at timestamptz not null default now(),
 unique(restaurant_id,rate_plan_id,tier_code)
);

create index if not exists booking_master_orders_lookup on public.booking_master_orders(restaurant_id,booking_code,status);
create index if not exists booking_reservations_group_idx on public.booking_reservations(booking_group_id);

-- Premium quote: canonical guest-facing quote with add-ons + coupon/promotion + tax.
create or replace function public.anaira_calculate_hotel_premium_quote(
 p_tenant_id uuid,p_room_type_id uuid,p_rate_plan_id uuid,p_check_in date,p_check_out date,
 p_adults integer default 2,p_children integer default 0,p_coupon_code text default null,p_addons jsonb default '[]'::jsonb
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare q jsonb; addon jsonb; addon_id uuid; qty integer; unit numeric; addons_total numeric:=0;
 base_subtotal numeric:=0; discount numeric:=0; tax numeric:=0; fee numeric:=0; taxable numeric:=0; total numeric:=0;
 coupon record; promo record; nights integer; tax_pct numeric:=0; s public.hms_settings%rowtype;
begin
 q:=public.anaira_calculate_hms_daily_booking_quote(p_tenant_id,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children);
 nights:=coalesce((q->>'nights')::integer,0); base_subtotal:=coalesce((q->>'subtotal')::numeric,0);
 for addon in select * from jsonb_array_elements(coalesce(p_addons,'[]'::jsonb)) loop
   addon_id:=nullif(addon->>'id','')::uuid; qty:=greatest(1,coalesce((addon->>'quantity')::integer,1));
   select price into unit from public.booking_addons where id=addon_id and restaurant_id=p_tenant_id and active=true;
   if unit is null then raise exception 'Selected add-on is unavailable'; end if;
   addons_total:=addons_total+(unit*qty);
 end loop;
 select * into s from public.hms_settings where restaurant_id=p_tenant_id limit 1;
 tax_pct:=coalesce((q->>'tax_percent')::numeric,s.default_tax_percent,s.tax_percent,0);
 taxable:=base_subtotal+addons_total;
 if nullif(trim(p_coupon_code),'') is not null then
   select * into coupon from public.crm_coupon_definitions c where c.tenant_id=p_tenant_id and upper(c.code)=upper(trim(p_coupon_code)) and c.active=true and (c.starts_at is null or now()>=c.starts_at) and (c.ends_at is null or now()<=c.ends_at) limit 1;
   if coupon.id is not null then
     if coupon.discount_type='percent' then discount:=round(taxable*coupon.discount_value/100,2); else discount:=least(taxable,coupon.discount_value); end if;
   else
     select * into promo from public.booking_promotions p where p.restaurant_id=p_tenant_id and upper(p.code)=upper(trim(p_coupon_code)) and p.active=true and (p.start_date is null or p_check_in>=p.start_date) and (p.end_date is null or p_check_out<=p.end_date) and coalesce(p.min_nights,1)<=nights limit 1;
     if promo.id is not null then
       if promo.discount_type='percent' then discount:=round(taxable*promo.discount_value/100,2); else discount:=least(taxable,promo.discount_value); end if;
     else raise exception 'Coupon or promotion code is invalid or expired'; end if;
   end if;
 end if;
 taxable:=greatest(0,taxable-discount); tax:=round(taxable*tax_pct/100,2); total:=round(taxable+tax+fee,2);
 return jsonb_build_object('ok',true,'nights',nights,'subtotal',round(base_subtotal,2),'addons',round(addons_total,2),'discount',round(discount,2),'tax',tax,'tax_percent',tax_pct,'fees',fee,'total',total,'coupon_code',nullif(trim(p_coupon_code),''),'rate_plan_id',p_rate_plan_id,'room_type_id',p_room_type_id,'line_items',jsonb_build_array(jsonb_build_object('type','room','amount',round(base_subtotal,2)),jsonb_build_object('type','addons','amount',round(addons_total,2)),jsonb_build_object('type','discount','amount',round(-discount,2)),jsonb_build_object('type','tax','amount',tax)));
end $$;
grant execute on function public.anaira_calculate_hotel_premium_quote(uuid,uuid,uuid,date,date,integer,integer,text,jsonb) to anon,authenticated;

-- Canonical verified hotel booking wrapper now persists the exact premium quote.
create or replace function public.anaira_start_verified_hotel_booking_transaction_v2(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,p_room_type_id uuid,p_rate_plan_id uuid,
 p_adults integer,p_children integer,p_coupon_code text,p_addons jsonb,p_idempotency_key text,p_source text default 'anaira-hotel-store',p_verification_id uuid default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v_ok boolean:=false; v_channel text; v_hash text; r jsonb; q jsonb; tx public.crm_booking_transactions%rowtype; a jsonb; aid uuid; aq integer; unit numeric;
begin
 if p_verification_id is null then raise exception 'Customer verification is required before booking'; end if;
 if nullif(trim(coalesce(p_guest_email,'')),'') is not null then v_channel:='email'; v_hash:=encode(digest(lower(trim(p_guest_email)),'sha256'),'hex'); v_ok:=public.anaira_verify_guest_otp_challenge(p_verification_id,p_tenant_id,v_channel,v_hash); end if;
 if not v_ok and nullif(trim(coalesce(p_guest_phone,'')),'') is not null then v_channel:='phone'; v_hash:=encode(digest(regexp_replace(p_guest_phone,'\D','','g'),'sha256'),'hex'); v_ok:=public.anaira_verify_guest_otp_challenge(p_verification_id,p_tenant_id,v_channel,v_hash); end if;
 if not v_ok then raise exception 'The guest contact could not be verified for this booking'; end if;
 q:=public.anaira_calculate_hotel_premium_quote(p_tenant_id,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children,p_coupon_code,p_addons);
 r:=public.anaira_start_hotel_booking_transaction(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email,p_check_in,p_check_out,p_room_type_id,p_rate_plan_id,p_adults,p_children,p_coupon_code,p_addons,p_idempotency_key,p_source);
 if coalesce((r->>'ok')::boolean,false) then
   if r->>'booking_id' is not null then
     update public.booking_reservations set subtotal=(q->>'subtotal')::numeric,tax_amount=(q->>'tax')::numeric,total_amount=(q->>'total')::numeric,rate_snapshot=q,tax_breakdown=jsonb_build_object('tax',(q->>'tax')::numeric,'tax_percent',(q->>'tax_percent')::numeric),metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('premium_quote',q) where id=(r->>'booking_id')::uuid and restaurant_id=p_tenant_id;
     for a in select * from jsonb_array_elements(coalesce(p_addons,'[]'::jsonb)) loop
       aid:=nullif(a->>'id','')::uuid; aq:=greatest(1,coalesce((a->>'quantity')::integer,1)); select price into unit from public.booking_addons where id=aid and restaurant_id=p_tenant_id and active=true;
       if unit is not null then insert into public.booking_reservation_addons(reservation_id,addon_id,quantity,unit_price) values((r->>'booking_id')::uuid,aid,aq,unit) on conflict do nothing; end if;
     end loop;
     if nullif(trim(coalesce(p_coupon_code,'')),'') is not null then
       insert into public.crm_coupon_redemptions(tenant_id,coupon_id,reference_type,reference_id,discount_amount,customer_id)
       select p_tenant_id,c.id,'hotel_booking',(r->>'booking_id'),coalesce((q->>'discount')::numeric,0),null from public.crm_coupon_definitions c where c.tenant_id=p_tenant_id and upper(c.code)=upper(trim(p_coupon_code)) and c.active=true limit 1;
     end if;
   end if;
   select * into tx from public.crm_booking_transactions where id=(r->>'transaction_id')::uuid and tenant_id=p_tenant_id for update;
   if found then update public.crm_booking_transactions set amount=(q->>'total')::numeric,payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object('quote',q,'premium_quote',true) where id=tx.id; if tx.payment_intent_id is not null then update public.anaira_payment_intents set amount=(q->>'total')::numeric,metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('premium_quote',true) where id=tx.payment_intent_id; end if; end if;
 end if;
 return coalesce(r,'{}'::jsonb)||jsonb_build_object('quote',q,'amount',(q->>'total')::numeric);
end $$;
grant execute on function public.anaira_start_verified_hotel_booking_transaction_v2(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) to anon,authenticated;

-- Multi-room atomic order: all holds/reservations are created in one transaction.
create or replace function public.anaira_create_multi_room_booking_transaction(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,p_rooms jsonb,
 p_coupon_code text default null,p_idempotency_key text default null,p_source text default 'anaira-direct',p_verification_id uuid default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare master_id uuid; master_code text; customer uuid; item jsonb; room_id uuid; rate_id uuid; adults integer; children integer; qty integer; i integer; q jsonb; r jsonb;
v_subtotal numeric:=0; v_addons numeric:=0; v_discount numeric:=0; v_tax numeric:=0; v_fee numeric:=0; v_total numeric:=0;
booking_id uuid; arr jsonb:='[]'::jsonb; v_ok boolean:=false; v_channel text; v_hash text;
begin
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
 if jsonb_typeof(p_rooms)<>'array' or jsonb_array_length(p_rooms)=0 then raise exception 'At least one room is required'; end if;
 if jsonb_array_length(p_rooms)>10 then raise exception 'Maximum 10 rooms per booking'; end if;
 if p_verification_id is null then raise exception 'Customer verification is required before booking'; end if;
 if nullif(trim(coalesce(p_guest_email,'')),'') is not null then
  v_channel:='email'; v_hash:=encode(digest(lower(trim(p_guest_email)),'sha256'),'hex'); v_ok:=public.anaira_verify_guest_otp_challenge(p_verification_id,p_tenant_id,v_channel,v_hash);
 end if;
 if not v_ok and nullif(trim(coalesce(p_guest_phone,'')),'') is not null then
  v_channel:='phone'; v_hash:=encode(digest(regexp_replace(p_guest_phone,'\D','','g'),'sha256'),'hex'); v_ok:=public.anaira_verify_guest_otp_challenge(p_verification_id,p_tenant_id,v_channel,v_hash);
 end if;
 if not v_ok then raise exception 'The guest contact could not be verified for this booking'; end if;
 if p_idempotency_key is not null then
  select id,booking_code into master_id,master_code from public.booking_master_orders where restaurant_id=p_tenant_id and metadata->>'idempotency_key'=p_idempotency_key limit 1;
  if master_id is not null then return jsonb_build_object('ok',true,'idempotent',true,'master_order_id',master_id,'booking_code',master_code); end if;
 end if;
 customer:=public.anaira_resolve_crm_customer(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email);
 master_id:=gen_random_uuid(); master_code:='ANM-'||upper(substr(replace(master_id::text,'-',''),1,10));
 insert into public.booking_master_orders(id,restaurant_id,booking_code,guest_name,guest_email,guest_phone,check_in,check_out,room_count,source,promo_code,metadata)
 values(master_id,p_tenant_id,master_code,p_guest_name,p_guest_email,p_guest_phone,p_check_in,p_check_out,jsonb_array_length(p_rooms),p_source,p_coupon_code,jsonb_build_object('idempotency_key',p_idempotency_key));
 for item in select * from jsonb_array_elements(p_rooms) loop
  room_id:=nullif(item->>'room_type_id','')::uuid; rate_id:=nullif(item->>'rate_plan_id','')::uuid; adults:=greatest(1,coalesce((item->>'adults')::integer,1)); children:=greatest(0,coalesce((item->>'children')::integer,0)); qty:=greatest(1,least(10,coalesce((item->>'quantity')::integer,1)));
  for i in 1..qty loop
   q:=public.anaira_calculate_hotel_premium_quote(p_tenant_id,room_id,rate_id,p_check_in,p_check_out,adults,children,p_coupon_code,coalesce(item->'addons','[]'::jsonb));
   v_subtotal:=v_subtotal+coalesce((q->>'subtotal')::numeric,0); v_addons:=v_addons+coalesce((q->>'addons')::numeric,0); v_discount:=v_discount+coalesce((q->>'coupon')::numeric,0); v_tax:=v_tax+coalesce((q->>'tax')::numeric,0); v_fee:=v_fee+coalesce((q->>'service_charge')::numeric,0); v_total:=v_total+coalesce((q->>'total')::numeric,0);
   r:=public.anaira_start_hotel_booking_transaction(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email,p_check_in,p_check_out,room_id,rate_id,adults,children,p_coupon_code,coalesce(item->'addons','[]'::jsonb),coalesce(p_idempotency_key,master_id::text)||':'||i,p_source);
   if coalesce((r->>'ok')::boolean,false)=false then raise exception 'Room booking transaction failed'; end if;
   booking_id:=nullif(r->>'booking_id','')::uuid;
   update public.booking_reservations set booking_group_id=master_id,rate_snapshot=q,tax_breakdown=jsonb_build_object('tax',(q->>'tax')::numeric),fee_breakdown=jsonb_build_object('service_charge',(q->>'service_charge')::numeric),subtotal=(q->>'subtotal')::numeric,tax_amount=(q->>'tax')::numeric,total_amount=(q->>'total')::numeric,promo_code=p_coupon_code where id=booking_id and restaurant_id=p_tenant_id;
   arr:=arr||jsonb_build_array(jsonb_build_object('booking_id',booking_id,'booking_code',r->>'booking_code','amount',(q->>'total')::numeric,'room_type_id',room_id,'rate_plan_id',rate_id));
  end loop;
 end loop;
 update public.booking_master_orders set subtotal=v_subtotal,discount_amount=v_discount,addons_amount=v_addons,tax_amount=v_tax,fee_amount=v_fee,total_amount=v_total,updated_at=now() where id=master_id;
 return jsonb_build_object('ok',true,'master_order_id',master_id,'booking_code',master_code,'room_count',jsonb_array_length(p_rooms),'subtotal',v_subtotal,'addons',v_addons,'discount',v_discount,'tax',v_tax,'fee',v_fee,'total',v_total,'reservations',arr,'state','payment_pending');
end $$;
revoke all on function public.anaira_create_multi_room_booking_transaction(uuid,text,text,text,date,date,jsonb,text,text,text,uuid) from public;
grant execute on function public.anaira_create_multi_room_booking_transaction(uuid,text,text,text,date,date,jsonb,text,text,text,uuid) to anon,authenticated;

-- Public manage-booking lookup (booking code + phone), with no credential leakage.
create or replace function public.anaira_public_booking_lookup(p_booking_code text,p_guest_phone text)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r record; out jsonb;
begin
 select br.id,br.restaurant_id,br.booking_code,br.check_in,br.check_out,br.adults,br.children,br.guest_name,br.status,br.payment_status,br.subtotal,br.tax_amount,br.total_amount,br.source,br.room_type_id,br.rate_plan_id,br.cancellation_policy_snapshot,br.special_requests,br.created_at into r from public.booking_reservations br where upper(br.booking_code)=upper(trim(p_booking_code)) and regexp_replace(coalesce(br.guest_phone,''),'\D','','g')=regexp_replace(coalesce(p_guest_phone,''),'\D','','g') limit 1;
 if r.id is null then raise exception 'Booking not found'; end if;
 return jsonb_build_object('ok',true,'booking',to_jsonb(r));
end $$;
grant execute on function public.anaira_public_booking_lookup(text,text) to anon,authenticated;

-- Guest conversion events are intentionally append-only.
grant insert on public.booking_conversion_events to anon,authenticated;
