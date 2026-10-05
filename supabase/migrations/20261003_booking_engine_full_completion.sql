-- Anaira Booking Engine full runtime completion layer
-- Credential/provider dependent execution remains configurable; no secrets are embedded.

create table if not exists public.booking_restrictions (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 room_type_id uuid, rate_plan_id uuid, stay_date date not null,
 closed_to_arrival boolean not null default false, closed_to_departure boolean not null default false,
 min_stay integer not null default 1, max_stay integer, reason text, active boolean not null default true,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(restaurant_id,room_type_id,rate_plan_id,stay_date)
);

create table if not exists public.booking_direct_benefits (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 code text not null, name text not null, benefit_type text not null, value numeric(14,2) not null default 0,
 config jsonb not null default '{}'::jsonb, active boolean not null default true, starts_at timestamptz, ends_at timestamptz,
 unique(restaurant_id,code)
);

create table if not exists public.booking_personalized_offers (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 segment_code text not null, offer_code text not null, priority integer not null default 100, config jsonb not null default '{}'::jsonb,
 active boolean not null default true, starts_at timestamptz, ends_at timestamptz,
 unique(restaurant_id,segment_code,offer_code)
);

create table if not exists public.booking_ab_tests (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 experiment_key text not null, name text not null, status text not null default 'draft', variants jsonb not null default '[]'::jsonb,
 allocation jsonb not null default '{}'::jsonb, goal_event text, starts_at timestamptz, ends_at timestamptz,
 unique(restaurant_id,experiment_key)
);
create table if not exists public.booking_ab_assignments (
 id uuid primary key default gen_random_uuid(), experiment_id uuid not null references public.booking_ab_tests(id) on delete cascade,
 session_id text not null, variant_key text not null, assigned_at timestamptz not null default now(), unique(experiment_id,session_id)
);

create table if not exists public.booking_group_allocations (
 id uuid primary key default gen_random_uuid(), group_request_id uuid not null references public.booking_group_requests(id) on delete cascade,
 room_type_id uuid, rate_plan_id uuid, room_count integer not null default 1, guest_names jsonb not null default '[]'::jsonb,
 status text not null default 'allocated', created_at timestamptz not null default now()
);
create table if not exists public.booking_group_folios (
 id uuid primary key default gen_random_uuid(), group_request_id uuid not null references public.booking_group_requests(id) on delete cascade,
 folio_type text not null default 'master', guest_name text, amount numeric(14,2) not null default 0,
 paid_amount numeric(14,2) not null default 0, balance_amount numeric(14,2) not null default 0,
 currency text not null default 'INR', status text not null default 'open', metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

create table if not exists public.booking_corporate_rates (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 corporate_account_id uuid, code text not null, room_type_id uuid, rate_plan_id uuid, adjustment_type text not null default 'percent',
 adjustment_value numeric(14,2) not null default 0, fixed_rate numeric(14,2), min_rooms integer default 1,
 payment_terms text, active boolean not null default true, starts_at date, ends_at date,
 unique(restaurant_id,code)
);
create table if not exists public.booking_negotiated_rates (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 account_id uuid, code text not null, room_type_id uuid, rate_plan_id uuid, nightly_rate numeric(14,2) not null,
 conditions jsonb not null default '{}'::jsonb, active boolean not null default true, starts_at date, ends_at date,
 unique(restaurant_id,code)
);
create table if not exists public.booking_chain_rate_controls (
 id uuid primary key default gen_random_uuid(), chain_key text not null, property_id uuid, room_type_id uuid, rate_plan_id uuid,
 effective_from date not null, effective_to date, base_rate numeric(14,2), multiplier numeric(10,4) default 1,
 restrictions jsonb not null default '{}'::jsonb, approval_required boolean not null default false, status text not null default 'active',
 created_at timestamptz not null default now()
);

create table if not exists public.booking_reconciliation_cases (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 source text not null, external_reference text, booking_id uuid, payment_intent_id uuid, expected jsonb not null default '{}'::jsonb,
 actual jsonb not null default '{}'::jsonb, variance numeric(14,2) default 0, status text not null default 'open',
 resolution text, resolved_by uuid, resolved_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.booking_revenue_daily (
 id uuid primary key default gen_random_uuid(), restaurant_id uuid not null references public.restaurants(id) on delete cascade,
 metric_date date not null, occupancy numeric(8,4) default 0, adr numeric(14,2) default 0, revpar numeric(14,2) default 0,
 room_nights integer default 0, bookings integer default 0, cancellations integer default 0, direct_bookings integer default 0,
 ota_bookings integer default 0, gross_revenue numeric(14,2) default 0, ota_commission numeric(14,2) default 0,
 conversion_rate numeric(10,6) default 0, payment_failures integer default 0, parity_variance numeric(14,2) default 0,
 created_at timestamptz not null default now(), unique(restaurant_id,metric_date)
);

create index if not exists booking_restrictions_lookup on public.booking_restrictions(restaurant_id,stay_date,active);
create index if not exists booking_reconciliation_open on public.booking_reconciliation_cases(restaurant_id,status,created_at desc);

alter table public.booking_restrictions enable row level security;
alter table public.booking_direct_benefits enable row level security;
alter table public.booking_personalized_offers enable row level security;
alter table public.booking_ab_tests enable row level security;
alter table public.booking_ab_assignments enable row level security;
alter table public.booking_group_allocations enable row level security;
alter table public.booking_group_folios enable row level security;
alter table public.booking_corporate_rates enable row level security;
alter table public.booking_negotiated_rates enable row level security;
alter table public.booking_chain_rate_controls enable row level security;
alter table public.booking_reconciliation_cases enable row level security;
alter table public.booking_revenue_daily enable row level security;

create policy booking_restrictions_tenant on public.booking_restrictions for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_direct_benefits_tenant on public.booking_direct_benefits for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_personalized_offers_tenant on public.booking_personalized_offers for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_ab_tests_tenant on public.booking_ab_tests for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_ab_assignments_tenant on public.booking_ab_assignments for all to authenticated using (exists(select 1 from public.booking_ab_tests e where e.id=experiment_id and (e.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()))) with check (exists(select 1 from public.booking_ab_tests e where e.id=experiment_id and (e.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())));
create policy booking_group_allocations_tenant on public.booking_group_allocations for all to authenticated using (exists(select 1 from public.booking_group_requests g where g.id=group_request_id and (g.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()))) with check (exists(select 1 from public.booking_group_requests g where g.id=group_request_id and (g.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())));
create policy booking_group_folios_tenant on public.booking_group_folios for all to authenticated using (exists(select 1 from public.booking_group_requests g where g.id=group_request_id and (g.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()))) with check (exists(select 1 from public.booking_group_requests g where g.id=group_request_id and (g.restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())));
create policy booking_corporate_rates_tenant on public.booking_corporate_rates for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_negotiated_rates_tenant on public.booking_negotiated_rates for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_chain_rate_controls_tenant on public.booking_chain_rate_controls for all to authenticated using (true) with check (true);
create policy booking_reconciliation_tenant on public.booking_reconciliation_cases for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
create policy booking_revenue_daily_tenant on public.booking_revenue_daily for all to authenticated using (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin()) with check (restaurant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

create or replace function public.anaira_booking_rule_check(p_restaurant_id uuid,p_room_type_id uuid,p_rate_plan_id uuid,p_check_in date,p_check_out date)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $fn$
declare d date; r record; result jsonb:='[]'::jsonb;
begin
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
 for d in select generate_series(p_check_in,p_check_out-1,'1 day')::date loop
   select * into r from public.booking_restrictions x where x.restaurant_id=p_restaurant_id and x.stay_date=d and x.active=true and (x.room_type_id is null or x.room_type_id=p_room_type_id) and (x.rate_plan_id is null or x.rate_plan_id=p_rate_plan_id) order by x.rate_plan_id nulls last limit 1;
   if r.id is not null then
     if d=p_check_in and r.closed_to_arrival then raise exception 'Closed to arrival on %',d; end if;
     if d=p_check_out-1 and r.closed_to_departure then raise exception 'Closed to departure on %',d; end if;
     if (p_check_out-p_check_in)<r.min_stay then raise exception 'Minimum stay is % nights',r.min_stay; end if;
     if r.max_stay is not null and (p_check_out-p_check_in)>r.max_stay then raise exception 'Maximum stay is % nights',r.max_stay; end if;
     result:=result||jsonb_build_array(jsonb_build_object('date',d,'cta',r.closed_to_arrival,'ctd',r.closed_to_departure,'min_stay',r.min_stay,'max_stay',r.max_stay));
   end if;
 end loop;
 return jsonb_build_object('ok',true,'rules',result);
end
$fn$;

grant execute on function public.anaira_booking_rule_check(uuid,uuid,uuid,date,date) to anon,authenticated;

create or replace function public.anaira_booking_member_context(p_tenant_id uuid,p_customer_id uuid,p_rate_plan_id uuid,p_base_total numeric)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $fn$
declare tier_code text:='bronze'; mr record; adj numeric:=0; member_total numeric:=coalesce(p_base_total,0); benefits jsonb:='[]'::jsonb;
begin
 if p_customer_id is not null then select lower(coalesce(tier,'bronze')) into tier_code from public.crm_loyalty_accounts where customer_id=p_customer_id and (tenant_id=p_tenant_id or tenant_id is null) limit 1; end if;
 select * into mr from public.booking_member_rates where restaurant_id=p_tenant_id and rate_plan_id=p_rate_plan_id and tier_code=tier_code and active=true limit 1;
 if mr.id is not null then
   if mr.adjustment_type='percent' then adj:=round(p_base_total*mr.adjustment_value/100,2); else adj:=mr.adjustment_value; end if;
   member_total:=greatest(0,p_base_total+adj);
 end if;
 select coalesce(jsonb_agg(to_jsonb(b)), '[]'::jsonb) into benefits from public.booking_direct_benefits b where b.restaurant_id=p_tenant_id and b.active=true and (b.starts_at is null or now()>=b.starts_at) and (b.ends_at is null or now()<=b.ends_at);
 return jsonb_build_object('tier',tier_code,'member_rate',mr.id is not null,'adjustment',adj,'total',member_total,'benefits',benefits);
end
$fn$;
grant execute on function public.anaira_booking_member_context(uuid,uuid,uuid,numeric) to authenticated;

create or replace function public.anaira_booking_ab_assign(p_restaurant_id uuid,p_experiment_key text,p_session_id text)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $fn$
declare e public.booking_ab_tests%rowtype; a public.booking_ab_assignments%rowtype; arr jsonb; chosen text; n numeric; v jsonb;
begin
 select * into e from public.booking_ab_tests where restaurant_id=p_restaurant_id and experiment_key=p_experiment_key and status='running' and (starts_at is null or now()>=starts_at) and (ends_at is null or now()<=ends_at) limit 1;
 if e.id is null then return jsonb_build_object('ok',false,'reason','experiment_not_running'); end if;
 select * into a from public.booking_ab_assignments where experiment_id=e.id and session_id=p_session_id limit 1;
 if a.id is not null then return jsonb_build_object('ok',true,'variant',a.variant_key,'existing',true); end if;
 arr:=e.variants; if jsonb_array_length(arr)=0 then return jsonb_build_object('ok',false,'reason','no_variants'); end if;
 n:=random(); chosen:=coalesce(arr->0->>'key','control');
 for v in select * from jsonb_array_elements(arr) loop if n <= coalesce((v->>'weight')::numeric,1)/greatest(1,jsonb_array_length(arr)) then chosen:=coalesce(v->>'key',chosen); exit; end if; end loop;
 insert into public.booking_ab_assignments(experiment_id,session_id,variant_key) values(e.id,p_session_id,chosen) returning * into a;
 return jsonb_build_object('ok',true,'variant',a.variant_key,'assignment_id',a.id);
end
$fn$;
grant execute on function public.anaira_booking_ab_assign(uuid,text,text) to anon,authenticated;

create or replace function public.anaira_booking_revenue_rollup(p_restaurant_id uuid,p_from date,p_to date)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $fn$
declare r record; rooms integer; revenue numeric; bookings integer; cancels integer; direct integer; ota integer; adr numeric; occ numeric; revpar numeric; days integer;
begin
 for r in select gs::date d from generate_series(p_from,p_to,'1 day') gs loop
   select count(*),coalesce(sum(total_amount),0),count(*) filter(where status='cancelled'),count(*) filter(where lower(coalesce(source,'direct')) in ('direct','anaira_booking_engine')),count(*) filter(where lower(coalesce(source,'')) not in ('direct','anaira_booking_engine','manual')) into bookings,revenue,cancels,direct,ota from public.booking_reservations where restaurant_id=p_restaurant_id and check_in<=r.d and check_out>r.d;
   select coalesce(sum(greatest(1,coalesce(room_count,1))),0) into rooms from public.booking_master_orders where restaurant_id=p_restaurant_id and check_in<=r.d and check_out>r.d and status in ('confirmed','checked_in','completed');
   select count(*) into days from public.hms_rooms where restaurant_id=p_restaurant_id and coalesce(active,true)=true;
   adr:=case when rooms>0 then round(revenue/rooms,2) else 0 end; occ:=case when days>0 then round(rooms::numeric/days,6) else 0 end; revpar:=case when days>0 then round(revenue/days,2) else 0 end;
   insert into public.booking_revenue_daily(restaurant_id,metric_date,occupancy,adr,revpar,room_nights,bookings,cancellations,direct_bookings,ota_bookings,gross_revenue) values(p_restaurant_id,r.d,occ,adr,revpar,rooms,bookings,cancels,direct,ota,revenue) on conflict(restaurant_id,metric_date) do update set occupancy=excluded.occupancy,adr=excluded.adr,revpar=excluded.revpar,room_nights=excluded.room_nights,bookings=excluded.bookings,cancellations=excluded.cancellations,direct_bookings=excluded.direct_bookings,ota_bookings=excluded.ota_bookings,gross_revenue=excluded.gross_revenue;
 end loop;
 return jsonb_build_object('ok',true,'from',p_from,'to',p_to);
end
$fn$;
grant execute on function public.anaira_booking_revenue_rollup(uuid,date,date) to authenticated;

create or replace function public.anaira_booking_reconciliation_case(p_restaurant_id uuid,p_source text,p_external_reference text,p_booking_id uuid,p_payment_intent_id uuid,p_expected jsonb,p_actual jsonb)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $fn$
declare e numeric:=coalesce((p_expected->>'amount')::numeric,0); a numeric:=coalesce((p_actual->>'amount')::numeric,0); c public.booking_reconciliation_cases%rowtype;
begin
 insert into public.booking_reconciliation_cases(restaurant_id,source,external_reference,booking_id,payment_intent_id,expected,actual,variance,status) values(p_restaurant_id,p_source,p_external_reference,p_booking_id,p_payment_intent_id,p_expected,p_actual,round(a-e,2),case when abs(a-e)<0.01 then 'matched' else 'open' end) returning * into c;
 return jsonb_build_object('ok',true,'case',to_jsonb(c));
end
$fn$;
grant execute on function public.anaira_booking_reconciliation_case(uuid,text,text,uuid,uuid,jsonb,jsonb) to authenticated;
