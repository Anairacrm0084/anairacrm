create table if not exists public.booking_competitor_rate_sources(
 id uuid primary key default gen_random_uuid(),restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 source_code text not null,source_name text not null,base_url text,config jsonb not null default '{}',active boolean not null default true,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(restaurant_id,source_code));
create table if not exists public.booking_competitor_rates(
 id uuid primary key default gen_random_uuid(),restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 source_code text not null,property_name text,room_name text,stay_date date not null,rate numeric(14,2) not null,currency text not null default 'INR',
 refundable boolean,raw jsonb not null default '{}',collected_at timestamptz not null default now(),expires_at timestamptz,
 unique(restaurant_id,source_code,room_name,stay_date));
create table if not exists public.booking_funnel_daily(
 id uuid primary key default gen_random_uuid(),restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 metric_date date not null,searches int not null default 0,comparisons int not null default 0,checkout_starts int not null default 0,
 payment_starts int not null default 0,payment_failures int not null default 0,confirmed_bookings int not null default 0,abandoned int not null default 0,
 revenue numeric(14,2) not null default 0,unique(restaurant_id,metric_date));
create table if not exists public.booking_channel_reconciliation(
 id uuid primary key default gen_random_uuid(),restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 provider_code text not null,external_reference text not null,booking_id uuid,payment_amount numeric(14,2) default 0,commission numeric(14,2) default 0,
 inventory_status text,external_status text,anaira_status text,mismatch jsonb not null default '{}',status text not null default 'open',
 created_at timestamptz not null default now(),resolved_at timestamptz,resolution text,unique(restaurant_id,provider_code,external_reference));


-- Canonical booking transaction now uses the premium quote/restriction engine.
create or replace function public.anaira_start_hotel_booking_transaction(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,
 p_room_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_coupon_code text,p_addons jsonb,
 p_idempotency_key text,p_source text default 'direct'
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare tx public.crm_booking_transactions%rowtype;q jsonb;hold jsonb;pi public.anaira_payment_intents%rowtype;
 bid uuid;code text;customer uuid;s public.hms_settings%rowtype;
begin
 select * into tx from public.crm_booking_transactions where tenant_id=p_tenant_id and idempotency_key=p_idempotency_key for update;
 if found then return jsonb_build_object('ok',true,'idempotent',true,'transaction_id',tx.id,'state',tx.state,'booking_id',tx.booking_id,'payment_intent_id',tx.payment_intent_id,'amount',tx.amount,'quote',tx.payload->'quote');end if;
 q:=public.anaira_calculate_hotel_premium_quote(p_tenant_id,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children,p_coupon_code,coalesce(p_addons,'[]'::jsonb));
 select * into s from public.hms_settings where restaurant_id=p_tenant_id limit 1;
 customer:=public.anaira_resolve_crm_customer(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email);
 bid:=gen_random_uuid();code:='ANB-'||upper(substr(replace(bid::text,'-',''),1,10));
 insert into public.booking_reservations(id,restaurant_id,booking_code,customer_id,room_type_id,rate_plan_id,check_in,check_out,adults,children,guest_name,guest_email,guest_phone,status,payment_status,subtotal,tax_amount,total_amount,source,promo_code,metadata)
 values(bid,p_tenant_id,code,customer,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children,p_guest_name,p_guest_email,p_guest_phone,'payment_pending','unpaid',(q->>'subtotal')::numeric,(q->>'tax')::numeric,(q->>'total')::numeric,p_source,p_coupon_code,jsonb_build_object('addons',coalesce(p_addons,'[]'::jsonb),'transactional_engine',true,'premium_quote',q));
 hold:=public.anaira_phase13_hotel_inventory_hold(p_tenant_id,p_room_type_id,p_check_in,p_check_out,1,p_idempotency_key,bid,15);
 insert into public.crm_booking_transactions(tenant_id,booking_id,customer_id,inventory_hold_id,state,idempotency_key,payload,amount,currency,expires_at)
 values(p_tenant_id,bid,customer,(hold->>'hold_id')::uuid,'payment_pending',p_idempotency_key,jsonb_build_object('guest_name',p_guest_name,'source',p_source,'quote',q),(q->>'total')::numeric,coalesce(s.currency,'INR'),(hold->>'expires_at')::timestamptz) returning * into tx;
 insert into public.anaira_payment_intents(restaurant_id,reference_type,reference_id,provider,amount,currency,status,idempotency_key,metadata)
 values(p_tenant_id,'hotel_booking',bid,'manual',(q->>'total')::numeric,coalesce(s.currency,'INR'),'created','hotel:'||p_idempotency_key,jsonb_build_object('booking_transaction_id',tx.id,'booking_code',code,'hold_id',hold->>'hold_id','rate_plan_id',p_rate_plan_id)) returning * into pi;
 update public.crm_booking_transactions set payment_intent_id=pi.id where id=tx.id;
 return jsonb_build_object('ok',true,'transaction_id',tx.id,'booking_id',bid,'booking_code',code,'payment_intent_id',pi.id,'hold_id',hold->>'hold_id','amount',(q->>'total')::numeric,'quote',q,'state','payment_pending');
end $$;
revoke all on function public.anaira_start_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) from public;
grant execute on function public.anaira_start_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) to anon,authenticated;
