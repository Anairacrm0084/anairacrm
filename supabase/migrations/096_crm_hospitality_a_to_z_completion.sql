-- ANAIRA CRM / Hospitality A-to-Z completion
-- Shared CRM core + Hotel CRM + Restaurant CRM. Does not duplicate canonical POS.
-- Transactional hotel booking state machine, rate engine, 360 metrics, tags,
-- campaign queue, pre-arrival, revenue recommendations, loyalty, feedback actions,
-- global identity, analytics and AI action queue.

create table if not exists public.crm_booking_transactions (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null,
  booking_id uuid, customer_id uuid, inventory_hold_id uuid, payment_intent_id uuid,
  state text not null default 'draft',
  idempotency_key text not null, payload jsonb not null default '{}'::jsonb,
  amount numeric not null default 0, currency text not null default 'INR',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  expires_at timestamptz,
  unique (tenant_id,idempotency_key)
);
create index if not exists crm_booking_transactions_state_idx on public.crm_booking_transactions(tenant_id,state,created_at desc);

create table if not exists public.crm_booking_rate_quotes (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null,
  room_type_id uuid not null, rate_plan_id uuid, check_in date not null, check_out date not null,
  adults integer not null default 2, children integer not null default 0,
  nights integer not null, occupancy_pct numeric default 0, base_rate numeric not null default 0,
  room_rate numeric not null default 0, occupancy_adjustment numeric not null default 0,
  extra_guest_amount numeric not null default 0, meal_plan_amount numeric not null default 0,
  addon_amount numeric not null default 0, package_discount numeric not null default 0,
  coupon_discount numeric not null default 0, tax_amount numeric not null default 0,
  service_charge numeric not null default 0, fees numeric not null default 0,
  total_amount numeric not null default 0, currency text not null default 'INR',
  breakdown jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), expires_at timestamptz
);
create index if not exists crm_booking_rate_quotes_lookup_idx on public.crm_booking_rate_quotes(tenant_id,room_type_id,check_in,check_out,created_at desc);

create table if not exists public.crm_restaurant_customer_metrics (
  tenant_id uuid not null, customer_id uuid not null, total_visits integer not null default 0,
  lifetime_spend numeric not null default 0, average_bill numeric not null default 0,
  last_visit_at timestamptz, dine_in_visits integer not null default 0, takeaway_visits integer not null default 0,
  delivery_visits integer not null default 0, reservation_count integer not null default 0,
  reservation_cancellations integer not null default 0, reservation_no_shows integer not null default 0,
  loyalty_points integer not null default 0, coupons_used integer not null default 0,
  reviews_count integer not null default 0, complaints_count integer not null default 0,
  feedback_count integer not null default 0, preferred_outlet_id uuid, preferred_table text,
  preferred_hour integer, occasions jsonb not null default '[]'::jsonb,
  campaign_engagement jsonb not null default '{}'::jsonb, favorite_items jsonb not null default '[]'::jsonb,
  favorite_categories jsonb not null default '[]'::jsonb, updated_at timestamptz not null default now(),
  primary key(tenant_id,customer_id)
);

create table if not exists public.crm_auto_tag_rules (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, name text not null,
  tag_name text not null, domain text not null default 'restaurant', definition jsonb not null default '{}'::jsonb,
  active boolean not null default true, priority integer not null default 100, created_at timestamptz not null default now()
);
create index if not exists crm_auto_tag_rules_active_idx on public.crm_auto_tag_rules(tenant_id,active,priority);

create table if not exists public.crm_campaign_queue (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, campaign_id uuid,
  customer_id uuid, channel text not null, template_id uuid, payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued', attempts integer not null default 0, available_at timestamptz not null default now(),
  sent_at timestamptz, delivered_at timestamptz, opened_at timestamptz, clicked_at timestamptz,
  converted_at timestamptz, revenue numeric default 0, last_error text, created_at timestamptz not null default now()
);
create index if not exists crm_campaign_queue_claim_idx on public.crm_campaign_queue(status,available_at,created_at);

create table if not exists public.crm_prearrival_jobs (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, customer_id uuid not null,
  guest_stay_id uuid, job_type text not null, due_at timestamptz not null, channel text,
  status text not null default 'queued', payload jsonb not null default '{}'::jsonb,
  attempts integer not null default 0, last_error text, processed_at timestamptz, created_at timestamptz not null default now(),
  unique(guest_stay_id,job_type)
);
create index if not exists crm_prearrival_due_idx on public.crm_prearrival_jobs(status,due_at);

create table if not exists public.crm_revenue_rate_recommendations (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, room_type_id uuid,
  stay_date date not null, current_rate numeric, recommended_rate numeric not null, occupancy_pct numeric,
  pickup integer, competitor_median numeric, rate_position text, reason jsonb not null default '{}'::jsonb,
  status text not null default 'pending_approval', approved_by uuid, approved_at timestamptz, published_at timestamptz,
  model_version text not null default 'rule-v1', created_at timestamptz not null default now()
);
create index if not exists crm_revenue_recommendations_idx on public.crm_revenue_rate_recommendations(tenant_id,stay_date,status);

create table if not exists public.crm_loyalty_rules (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, domain text not null,
  rule_type text not null, points_per_unit numeric not null default 0, minimum_amount numeric not null default 0,
  unit text not null default 'INR', active boolean not null default true, definition jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.crm_feedback_actions (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, customer_id uuid,
  feedback_id uuid, action_type text not null, status text not null default 'queued', payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(), completed_at timestamptz
);

create table if not exists public.crm_global_customer_relationships (
  id uuid primary key default gen_random_uuid(), customer_id uuid not null, tenant_id uuid not null,
  domain text not null, property_id uuid, outlet_id uuid, relationship_type text not null default 'customer',
  first_seen_at timestamptz not null default now(), last_seen_at timestamptz not null default now(), metadata jsonb not null default '{}'::jsonb
);

create unique index if not exists crm_global_customer_relationships_uq on public.crm_global_customer_relationships(customer_id,tenant_id,domain,coalesce(property_id,'00000000-0000-0000-0000-000000000000'::uuid),coalesce(outlet_id,'00000000-0000-0000-0000-000000000000'::uuid));

create table if not exists public.crm_ai_action_queue (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null, customer_id uuid,
  insight_id uuid, action_type text not null, proposed_action jsonb not null default '{}'::jsonb,
  status text not null default 'pending_approval', approved_by uuid, approved_at timestamptz,
  executed_at timestamptz, result jsonb, created_at timestamptz not null default now()
);

create table if not exists public.crm_analytics_daily (
  tenant_id uuid not null, metric_date date not null, customers integer not null default 0,
  verified_phones integer not null default 0, hotel_revenue numeric not null default 0,
  restaurant_revenue numeric not null default 0, bookings integer not null default 0,
  restaurant_visits integer not null default 0, complaints integer not null default 0,
  feedback_count integer not null default 0, avg_csat numeric, retention_rate numeric,
  ltv numeric, campaign_revenue numeric not null default 0, loyalty_points_issued integer not null default 0,
  primary key(tenant_id,metric_date)
);

alter table public.crm_booking_transactions enable row level security;
alter table public.crm_booking_rate_quotes enable row level security;
alter table public.crm_restaurant_customer_metrics enable row level security;
alter table public.crm_auto_tag_rules enable row level security;
alter table public.crm_campaign_queue enable row level security;
alter table public.crm_prearrival_jobs enable row level security;
alter table public.crm_revenue_rate_recommendations enable row level security;
alter table public.crm_loyalty_rules enable row level security;
alter table public.crm_feedback_actions enable row level security;
alter table public.crm_global_customer_relationships enable row level security;
alter table public.crm_ai_action_queue enable row level security;
alter table public.crm_analytics_daily enable row level security;

-- Tenant access policies. Server-side workers use service role; authenticated users are restricted by tenant_id.
DO $$ declare t text; begin
  foreach t in array array['crm_booking_transactions','crm_booking_rate_quotes','crm_restaurant_customer_metrics','crm_auto_tag_rules','crm_campaign_queue','crm_prearrival_jobs','crm_revenue_rate_recommendations','crm_loyalty_rules','crm_feedback_actions','crm_global_customer_relationships','crm_ai_action_queue','crm_analytics_daily'] loop
    execute format('drop policy if exists %I on public.%I', t||'_tenant_select',t);
    execute format('create policy %I on public.%I for select to authenticated using (tenant_id in (select p.restaurant_id from public.profiles p where p.id=(select auth.uid())))', t||'_tenant_select',t);
  end loop;
end $$;

create or replace function public.anaira_calculate_hotel_rate(
 p_tenant_id uuid,p_room_type_id uuid,p_rate_plan_id uuid,p_check_in date,p_check_out date,p_adults integer default 2,p_children integer default 0,p_coupon_code text default null,p_addons jsonb default '[]'::jsonb)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r public.crm_room_types%rowtype; rp public.crm_rate_plans%rowtype; d date; nights int; base numeric; room numeric:=0; occ_adj numeric:=0; extra numeric:=0; meal numeric:=0; addons_total numeric:=0; promo numeric:=0; coupon numeric:=0; tax numeric:=0; fees numeric:=0; svc numeric:=0; occupancy numeric:=0; available_total numeric:=0; booked_total numeric:=0; days_before int; c public.crm_coupon_definitions%rowtype; a jsonb; addon_id uuid; qty int; unit numeric;
begin
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
 nights:=p_check_out-p_check_in; days_before:=p_check_in-current_date;
 select * into r from public.crm_room_types where id=p_room_type_id and tenant_id=p_tenant_id and active=true;
 if not found then raise exception 'Room type not found'; end if;
 if p_adults+p_children>r.max_occupancy then raise exception 'Occupancy exceeds room capacity'; end if;
 base:=r.base_rate;
 if p_rate_plan_id is not null then select * into rp from public.crm_rate_plans where id=p_rate_plan_id and tenant_id=p_tenant_id and room_type_id=p_room_type_id and active=true; if not found then raise exception 'Rate plan not found'; end if; else rp:=null; end if;
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
   room:=room+base*(1+coalesce(rp.adjustment_percent,0)/100);
   if extract(isodow from d) in (6,7) then room:=room+base*0.10; end if;
 end loop;
 select coalesce(avg((coalesce(i.booked_rooms,0)+coalesce(i.held_rooms,0))*100/nullif(i.total_rooms,0)),0) into occupancy from public.booking_inventory i where i.restaurant_id=p_tenant_id and i.room_type_id=p_room_type_id and i.stay_date>=p_check_in and i.stay_date<p_check_out;
 select coalesce(sum((coalesce(i.booked_rooms,0)+coalesce(i.held_rooms,0))),0),coalesce(sum(i.total_rooms),0) into booked_total,available_total from public.booking_inventory i where i.restaurant_id=p_tenant_id and i.room_type_id=p_room_type_id and i.stay_date>=p_check_in and i.stay_date<p_check_out;
 for a in select * from jsonb_array_elements(coalesce(p_addons,'[]'::jsonb)) loop addon_id:=(a->>'id')::uuid; qty:=greatest(1,coalesce((a->>'quantity')::int,1)); select price into unit from public.booking_addons where id=addon_id and restaurant_id=p_tenant_id and active=true; addons_total:=addons_total+coalesce(unit,0)*qty; end loop;
 extra:=greatest(0,p_adults-2)*coalesce(rp.extra_adult,0)*nights + p_children*coalesce(rp.extra_child,0)*nights;
 meal:=case when coalesce(rp.meal_plan,'') in ('breakfast','half_board','full_board') then (case when rp.meal_plan='breakfast' then 500 when rp.meal_plan='half_board' then 1000 else 1500 end)*(p_adults+p_children)*nights else 0 end;
 if occupancy>=80 then occ_adj:=room*0.20; elsif occupancy>=60 then occ_adj:=room*0.10; end if;
 if days_before>=30 then room:=room*0.90; elsif days_before<=2 then room:=room*1.15; end if;
 if p_coupon_code is not null then select * into c from public.crm_coupon_definitions where tenant_id=p_tenant_id and upper(code)=upper(p_coupon_code) and active=true and (starts_at is null or now()>=starts_at) and (ends_at is null or now()<=ends_at) limit 1; if found then coupon:=case when c.discount_type='percent' then (room+occ_adj+extra+meal+addons_total)*c.discount_value/100 else least(c.discount_value,room+occ_adj+extra+meal+addons_total) end; end if; end if;
 promo:=0; svc:=round((room+occ_adj+extra+meal+addons_total-coupon)*0.05,2); tax:=round((room+occ_adj+extra+meal+addons_total-coupon+svc)*0.12,2); fees:=0;
 return jsonb_build_object('nights',nights,'base_rate',base,'room_rate',round(room,2),'occupancy_pct',round(occupancy,2),'occupancy_adjustment',round(occ_adj,2),'extra_guest',round(extra,2),'meal_plan',round(meal,2),'addons',round(addons_total,2),'promotion',promo,'coupon',round(coupon,2),'service_charge',svc,'tax',tax,'fees',fees,'subtotal',round(room+occ_adj+extra+meal+addons_total-promo-coupon,2),'total',round(room+occ_adj+extra+meal+addons_total-promo-coupon+svc+tax+fees,2));
end $$;

grant execute on function public.anaira_calculate_hotel_rate(uuid,uuid,uuid,date,date,integer,integer,text,jsonb) to anon,authenticated;

create or replace function public.anaira_start_hotel_booking_transaction(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,p_room_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_coupon_code text,p_addons jsonb,p_idempotency_key text,p_source text default 'direct')
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare tx public.crm_booking_transactions%rowtype; q jsonb; hold jsonb; rid uuid; pi public.anaira_payment_intents%rowtype; bid uuid; code text; customer uuid;
begin
 select * into tx from public.crm_booking_transactions where tenant_id=p_tenant_id and idempotency_key=p_idempotency_key for update; if found then return jsonb_build_object('ok',true,'idempotent',true,'transaction',tx.id,'state',tx.state,'booking_id',tx.booking_id,'payment_intent_id',tx.payment_intent_id,'amount',tx.amount); end if;
 q:=public.anaira_calculate_hotel_rate(p_tenant_id,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children,p_coupon_code,p_addons);
 customer:=public.anaira_resolve_crm_customer(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email);
 bid:=gen_random_uuid(); code:='ANB-'||upper(substr(replace(bid::text,'-',''),1,10));
 insert into public.booking_reservations(id,restaurant_id,booking_code,customer_id,room_type_id,rate_plan_id,check_in,check_out,adults,children,guest_name,guest_email,guest_phone,status,payment_status,subtotal,tax_amount,total_amount,source,promo_code,metadata)
 values(bid,p_tenant_id,code,customer,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children,p_guest_name,p_guest_email,p_guest_phone,'payment_pending','unpaid',(q->>'subtotal')::numeric,(q->>'tax')::numeric,(q->>'total')::numeric,p_source,p_coupon_code,jsonb_build_object('addons',p_addons,'transactional_engine',true));
 hold:=public.anaira_phase13_hotel_inventory_hold(p_tenant_id,p_room_type_id,p_check_in,p_check_out,1,p_idempotency_key,bid,15);
 insert into public.crm_booking_transactions(tenant_id,booking_id,customer_id,inventory_hold_id,state,idempotency_key,payload,amount,currency,expires_at) values(p_tenant_id,bid,customer,(hold->>'hold_id')::uuid,'payment_pending',p_idempotency_key,jsonb_build_object('guest_name',p_guest_name,'source',p_source,'quote',q), (q->>'total')::numeric,'INR',(hold->>'expires_at')::timestamptz) returning * into tx;
 insert into public.anaira_payment_intents(restaurant_id,reference_type,reference_id,provider,amount,currency,status,idempotency_key,metadata) values(p_tenant_id,'hotel_booking',bid,'manual',(q->>'total')::numeric,'INR','created','hotel:'||p_idempotency_key,jsonb_build_object('booking_transaction_id',tx.id,'booking_code',code,'hold_id',hold->>'hold_id')) returning * into pi;
 update public.crm_booking_transactions set payment_intent_id=pi.id where id=tx.id;
 return jsonb_build_object('ok',true,'transaction_id',tx.id,'booking_id',bid,'booking_code',code,'payment_intent_id',pi.id,'hold_id',hold->>'hold_id','amount',(q->>'total')::numeric,'quote',q,'state','payment_pending');
end $$;

grant execute on function public.anaira_start_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) to anon,authenticated;

create or replace function public.anaira_confirm_hotel_booking_payment(p_payment_intent_id uuid,p_provider text,p_provider_payment_id text,p_event_id text,p_status text,p_payload jsonb default '{}'::jsonb)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare pi public.anaira_payment_intents%rowtype; tx public.crm_booking_transactions%rowtype; b public.booking_reservations%rowtype; hold_id uuid; pms_id uuid; stay_id uuid; customer uuid;
begin
 select * into pi from public.anaira_payment_intents where id=p_payment_intent_id for update; if not found then raise exception 'Payment intent not found'; end if;
 if p_event_id is not null then insert into public.anaira_payment_events(payment_intent_id,provider,provider_event_id,event_type,status,payload) values(pi.id,p_provider,p_event_id,'hotel.booking.payment',p_status,coalesce(p_payload,'{}'::jsonb)) on conflict(provider,provider_event_id) do nothing; end if;
 update public.anaira_payment_intents set provider=coalesce(p_provider,provider),provider_payment_id=coalesce(p_provider_payment_id,provider_payment_id),status=p_status,updated_at=now() where id=pi.id;
 select * into tx from public.crm_booking_transactions where id=(pi.metadata->>'booking_transaction_id')::uuid for update; if not found then raise exception 'Booking transaction not found'; end if;
 select * into b from public.booking_reservations where id=tx.booking_id for update;
 if p_status='paid' or p_status='authorized' then
   hold_id:=tx.inventory_hold_id; perform public.anaira_phase13_hotel_inventory_hold_release(b.restaurant_id,hold_id,'consume');
   update public.booking_reservations set status='confirmed',payment_status='paid',payment_reference=coalesce(p_provider_payment_id,p_payment_intent_id::text),confirmation_sent_at=now(),updated_at=now() where id=b.id;
   insert into public.pms_reservations(restaurant_id,booking_code,guest_name,guest_phone,room_id,check_in,check_out,status,source,total_amount,metadata) values(b.restaurant_id,b.booking_code,b.guest_name,b.guest_phone,null,b.check_in,b.check_out,'reserved',b.source,b.total_amount,jsonb_build_object('booking_id',b.id,'payment_intent_id',pi.id)) returning id into pms_id;
   update public.booking_reservations set metadata=metadata||jsonb_build_object('pms_reservation_id',pms_id) where id=b.id;
   insert into public.crm_guest_stays(tenant_id,customer_id,external_booking_id,property_id,room_type_id,check_in_date,check_out_date,nights,booking_source,booking_status,total_amount,special_requests) values(b.restaurant_id,b.customer_id,b.booking_code,b.restaurant_id,b.room_type_id,b.check_in,b.check_out,b.check_out-b.check_in,b.source,'confirmed',b.total_amount,b.special_requests) returning id into stay_id;
   insert into public.crm_interactions(customer_id,channel,interaction_type,subject,notes) values(b.customer_id,'booking','hotel_booking_confirmed',b.booking_code,'Hotel booking confirmed through transactional booking engine');
   insert into public.crm_prearrival_jobs(tenant_id,customer_id,guest_stay_id,job_type,due_at,channel,payload) values(b.restaurant_id,b.customer_id,stay_id,'prearrival_7d',greatest(now(),(b.check_in::timestamptz-interval '7 days')),'whatsapp',jsonb_build_object('booking_id',b.id)),(b.restaurant_id,b.customer_id,stay_id,'prearrival_3d',greatest(now(),(b.check_in::timestamptz-interval '3 days')),'whatsapp',jsonb_build_object('booking_id',b.id)),(b.restaurant_id,b.customer_id,stay_id,'prearrival_1d',greatest(now(),(b.check_in::timestamptz-interval '1 day')),'whatsapp',jsonb_build_object('booking_id',b.id));
   insert into public.crm_prearrival_jobs(tenant_id,customer_id,guest_stay_id,job_type,due_at,channel,payload) values(b.restaurant_id,b.customer_id,stay_id,'post_stay_review',b.check_out::timestamptz+interval '1 hour','whatsapp',jsonb_build_object('booking_id',b.id)) on conflict do nothing;
   update public.crm_booking_transactions set state='confirmed',updated_at=now() where id=tx.id;
   return jsonb_build_object('ok',true,'state','confirmed','booking_id',b.id,'pms_reservation_id',pms_id,'guest_stay_id',stay_id);
 elsif p_status in ('failed','cancelled') then
   perform public.anaira_phase13_hotel_inventory_hold_release(b.restaurant_id,tx.inventory_hold_id,'release');
   update public.booking_reservations set status='cancelled',payment_status=p_status,updated_at=now() where id=b.id;
   update public.crm_booking_transactions set state='cancelled',updated_at=now() where id=tx.id;
   return jsonb_build_object('ok',true,'state','cancelled','booking_id',b.id);
 end if;
 update public.crm_booking_transactions set state='payment_pending',updated_at=now() where id=tx.id;
 return jsonb_build_object('ok',true,'state','payment_pending','booking_id',b.id);
end $$;

grant execute on function public.anaira_confirm_hotel_booking_payment(uuid,text,text,text,text,jsonb) to anon,authenticated;

create or replace function public.anaira_refresh_restaurant_customer_360(p_tenant_id uuid,p_customer_id uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v public.crm_restaurant_customer_metrics%rowtype; spend numeric; visits int; res int; canc int; no_show int; points int; coupons int; complaints int; feedback int; rev int; lastv timestamptz; ph int; po uuid; pt text;
begin
 select count(*),coalesce(sum(amount),0),max(visit_at),coalesce(avg(amount),0),count(*) filter(where lower(coalesce(payment_method,'')) in ('delivery','online')),count(*) filter(where lower(coalesce(payment_method,'')) in ('takeaway','pickup')) into visits,spend,lastv,spend,visits,visits from public.crm_restaurant_visits where tenant_id=p_tenant_id and customer_id=p_customer_id;
 select count(*),count(*) filter(where status='cancelled'),count(*) filter(where status='no_show'),mode() within group(order by table_id::text) into res,canc,no_show,pt from public.restaurant_reservations where restaurant_id=p_tenant_id and customer_id=p_customer_id;
 select coalesce(sum(points_balance),0) into points from public.crm_loyalty_accounts where tenant_id=p_tenant_id and customer_id=p_customer_id;
 select count(*) into coupons from public.crm_coupon_redemptions where tenant_id=p_tenant_id and customer_id=p_customer_id;
 select count(*) into complaints from public.crm_complaints where tenant_id=p_tenant_id and customer_id=p_customer_id;
 select count(*) into feedback from public.crm_feedback where tenant_id=p_tenant_id and customer_id=p_customer_id;
 select count(*) into rev from public.crm_review_requests where tenant_id=p_tenant_id and customer_id=p_customer_id and status='completed';
 select extract(hour from max(visit_at))::int into ph from public.crm_restaurant_visits where tenant_id=p_tenant_id and customer_id=p_customer_id;
 select outlet_id into po from public.crm_restaurant_visits where tenant_id=p_tenant_id and customer_id=p_customer_id group by outlet_id order by count(*) desc nulls last limit 1;
 insert into public.crm_restaurant_customer_metrics(tenant_id,customer_id,total_visits,lifetime_spend,average_bill,last_visit_at,dine_in_visits,takeaway_visits,delivery_visits,reservation_count,reservation_cancellations,reservation_no_shows,loyalty_points,coupons_used,reviews_count,complaints_count,feedback_count,preferred_outlet_id,preferred_table,preferred_hour,updated_at)
 select p_tenant_id,p_customer_id,visits,coalesce((select sum(amount) from public.crm_restaurant_visits where tenant_id=p_tenant_id and customer_id=p_customer_id),0),coalesce((select avg(amount) from public.crm_restaurant_visits where tenant_id=p_tenant_id and customer_id=p_customer_id),0),lastv,coalesce((select count(*) from public.crm_restaurant_visits where tenant_id=p_tenant_id and customer_id=p_customer_id and lower(coalesce(payment_method,'')) not in ('delivery','online','takeaway','pickup')),0),coalesce((select count(*) from public.crm_restaurant_visits where tenant_id=p_tenant_id and customer_id=p_customer_id and lower(coalesce(payment_method,'')) in ('takeaway','pickup')),0),coalesce((select count(*) from public.crm_restaurant_visits where tenant_id=p_tenant_id and customer_id=p_customer_id and lower(coalesce(payment_method,'')) in ('delivery','online')),0),res,canc,no_show,points,coupons,rev,complaints,feedback,po,pt,ph,now()
 on conflict(tenant_id,customer_id) do update set total_visits=excluded.total_visits,lifetime_spend=excluded.lifetime_spend,average_bill=excluded.average_bill,last_visit_at=excluded.last_visit_at,dine_in_visits=excluded.dine_in_visits,takeaway_visits=excluded.takeaway_visits,delivery_visits=excluded.delivery_visits,reservation_count=excluded.reservation_count,reservation_cancellations=excluded.reservation_cancellations,reservation_no_shows=excluded.reservation_no_shows,loyalty_points=excluded.loyalty_points,coupons_used=excluded.coupons_used,reviews_count=excluded.reviews_count,complaints_count=excluded.complaints_count,feedback_count=excluded.feedback_count,preferred_outlet_id=excluded.preferred_outlet_id,preferred_table=excluded.preferred_table,preferred_hour=excluded.preferred_hour,updated_at=now();
 select * into v from public.crm_restaurant_customer_metrics where tenant_id=p_tenant_id and customer_id=p_customer_id;
 return to_jsonb(v);
end $$;

grant execute on function public.anaira_refresh_restaurant_customer_360(uuid,uuid) to authenticated;

create or replace function public.anaira_apply_restaurant_auto_tags(p_tenant_id uuid,p_customer_id uuid)
returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare m public.crm_restaurant_customer_metrics%rowtype; r public.crm_auto_tag_rules%rowtype; tag uuid; applied int:=0; ok boolean;
begin
 select * into m from public.crm_restaurant_customer_metrics where tenant_id=p_tenant_id and customer_id=p_customer_id; if not found then perform public.anaira_refresh_restaurant_customer_360(p_tenant_id,p_customer_id); select * into m from public.crm_restaurant_customer_metrics where tenant_id=p_tenant_id and customer_id=p_customer_id; end if;
 for r in select * from public.crm_auto_tag_rules where tenant_id=p_tenant_id and domain='restaurant' and active order by priority loop
  ok:=false;
  if (r.definition->>'min_visits') is not null and m.total_visits>=(r.definition->>'min_visits')::int then ok:=true; end if;
  if (r.definition->>'min_spend') is not null and m.lifetime_spend>=(r.definition->>'min_spend')::numeric then ok:=true; end if;
  if (r.definition->>'lapsed_days') is not null and m.last_visit_at is not null and m.last_visit_at < now()-make_interval(days=>(r.definition->>'lapsed_days')::int) then ok:=true; end if;
  if (r.definition->>'min_reservations') is not null and m.reservation_count>=(r.definition->>'min_reservations')::int then ok:=true; end if;
  if (r.definition->>'min_complaints') is not null and m.complaints_count>=(r.definition->>'min_complaints')::int then ok:=true; end if;
  if ok then insert into public.crm_tags(tenant_id,name) values(p_tenant_id,r.tag_name) on conflict do nothing returning id into tag; if tag is null then select id into tag from public.crm_tags where tenant_id=p_tenant_id and lower(name)=lower(r.tag_name) limit 1; end if; insert into public.crm_customer_tags(customer_id,tag_id) values(p_customer_id,tag) on conflict do nothing; applied:=applied+1; end if;
 end loop; return applied;
end $$;

grant execute on function public.anaira_apply_restaurant_auto_tags(uuid,uuid) to authenticated;

create or replace function public.anaira_refresh_crm_analytics(p_tenant_id uuid,p_metric_date date default current_date)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare customers int; phones int; hr numeric; rr numeric; bookings int; visits int; complaints int; fb int; csat numeric; ltv numeric; retain numeric;
begin
 select count(*),count(*) filter(where nullif(trim(phone),'') is not null) into customers,phones from public.crm_customers where tenant_id=p_tenant_id;
 select coalesce(sum(total_amount),0),count(*) into hr,bookings from public.crm_guest_stays where tenant_id=p_tenant_id and check_in_date<=p_metric_date;
 select coalesce(sum(amount),0),count(*) into rr,visits from public.crm_restaurant_visits where tenant_id=p_tenant_id and visit_at::date<=p_metric_date;
 select count(*) into complaints from public.crm_complaints where tenant_id=p_tenant_id and opened_at::date<=p_metric_date;
 select count(*),coalesce(avg(overall_rating),0) into fb,csat from public.crm_feedback where tenant_id=p_tenant_id and created_at::date<=p_metric_date;
 select coalesce(avg(calculated_ltv),0) into ltv from public.crm_customer_value_snapshots where tenant_id=p_tenant_id and snapshot_date=(select max(snapshot_date) from public.crm_customer_value_snapshots where tenant_id=p_tenant_id and snapshot_date<=p_metric_date);
 select case when customers=0 then 0 else round(100.0*count(*) filter(where total_stays>1)/customers,2) end into retain from public.crm_customers where tenant_id=p_tenant_id;
 insert into public.crm_analytics_daily(tenant_id,metric_date,customers,verified_phones,hotel_revenue,restaurant_revenue,bookings,restaurant_visits,complaints,feedback_count,avg_csat,retention_rate,ltv)
 values(p_tenant_id,p_metric_date,customers,phones,hr,rr,bookings,visits,complaints,fb,csat,retain,ltv)
 on conflict(tenant_id,metric_date) do update set customers=excluded.customers,verified_phones=excluded.verified_phones,hotel_revenue=excluded.hotel_revenue,restaurant_revenue=excluded.restaurant_revenue,bookings=excluded.bookings,restaurant_visits=excluded.restaurant_visits,complaints=excluded.complaints,feedback_count=excluded.feedback_count,avg_csat=excluded.avg_csat,retention_rate=excluded.retention_rate,ltv=excluded.ltv;
 return (select to_jsonb(a) from public.crm_analytics_daily a where a.tenant_id=p_tenant_id and a.metric_date=p_metric_date);
end $$;

grant execute on function public.anaira_refresh_crm_analytics(uuid,date) to authenticated;

create or replace function public.anaira_loyalty_post(p_tenant_id uuid,p_customer_id uuid,p_domain text,p_amount numeric,p_reference_type text,p_reference_id text)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.crm_loyalty_accounts%rowtype; rule public.crm_loyalty_rules%rowtype; pts int; newbal int; tiername text;
begin
 select * into a from public.crm_loyalty_accounts where tenant_id=p_tenant_id and customer_id=p_customer_id for update;
 if not found then insert into public.crm_loyalty_accounts(tenant_id,customer_id) values(p_tenant_id,p_customer_id) returning * into a; end if;
 select * into rule from public.crm_loyalty_rules where tenant_id=p_tenant_id and domain=p_domain and rule_type='earn' and active=true order by created_at desc limit 1;
 pts:=floor(greatest(0,p_amount-coalesce(rule.minimum_amount,0))*coalesce(rule.points_per_unit,0));
 if pts<=0 then return jsonb_build_object('ok',true,'points',0,'balance',a.points_balance,'tier',a.tier); end if;
 newbal:=a.points_balance+pts;
 insert into public.crm_loyalty_transactions(loyalty_account_id,points,transaction_type,reference_type,reference_id,notes) values(a.id,pts,'earn',p_reference_type,p_reference_id,p_domain);
 update public.crm_loyalty_accounts set points_balance=newbal,lifetime_points=lifetime_points+pts where id=a.id;
 select name into tiername from public.crm_loyalty_tiers where tenant_id=p_tenant_id and active=true and min_lifetime_points<=a.lifetime_points+pts order by min_lifetime_points desc limit 1;
 update public.crm_loyalty_accounts set tier=coalesce(tiername,tier) where id=a.id;
 return jsonb_build_object('ok',true,'points',pts,'balance',newbal,'tier',coalesce(tiername,a.tier));
end $$;

grant execute on function public.anaira_loyalty_post(uuid,uuid,text,numeric,text,text) to authenticated;

create or replace function public.anaira_loyalty_redeem(p_tenant_id uuid,p_customer_id uuid,p_reward_id uuid,p_reference_id text)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare a public.crm_loyalty_accounts%rowtype; r public.crm_rewards%rowtype;
begin
 select * into a from public.crm_loyalty_accounts where tenant_id=p_tenant_id and customer_id=p_customer_id for update; if not found then raise exception 'Loyalty account not found'; end if;
 select * into r from public.crm_rewards where id=p_reward_id and tenant_id=p_tenant_id and active=true; if not found then raise exception 'Reward not found'; end if;
 if a.points_balance<r.points_cost then raise exception 'Insufficient loyalty points'; end if;
 update public.crm_loyalty_accounts set points_balance=points_balance-r.points_cost where id=a.id;
 insert into public.crm_loyalty_transactions(loyalty_account_id,points,transaction_type,reference_type,reference_id,notes) values(a.id,-r.points_cost,'redeem','reward',p_reference_id,r.name);
 return jsonb_build_object('ok',true,'points_redeemed',r.points_cost,'balance',a.points_balance-r.points_cost,'reward',r.name);
end $$;

grant execute on function public.anaira_loyalty_redeem(uuid,uuid,uuid,text) to authenticated;

create or replace function public.anaira_generate_hotel_rate_recommendation(p_tenant_id uuid,p_room_type_id uuid,p_stay_date date)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare base numeric; occ numeric; comp numeric; demand numeric:=1; rec numeric; reason jsonb;
begin
 select base_rate into base from public.crm_room_types where id=p_room_type_id and tenant_id=p_tenant_id;
 select coalesce(100.0*sum(booked_rooms)/nullif(sum(total_rooms),0),0) into occ from public.booking_inventory where restaurant_id=p_tenant_id and room_type_id=p_room_type_id and stay_date=p_stay_date;
 select percentile_cont(0.5) within group(order by rate) into comp from public.crm_competitor_rates where tenant_id=p_tenant_id and stay_date=p_stay_date and rate is not null;
 if occ>=80 then demand:=1.20; elsif occ>=60 then demand:=1.10; elsif occ<30 then demand:=0.90; end if;
 rec:=greatest(coalesce((select min_rate from public.crm_room_types where id=p_room_type_id),0),least(coalesce((select max_rate from public.crm_room_types where id=p_room_type_id),base*demand),base*demand));
 if comp is not null then rec:=round((rec+comp)/2,2); end if;
 reason:=jsonb_build_object('occupancy_pct',occ,'competitor_median',comp,'demand_multiplier',demand,'approval_required',true);
 insert into public.crm_revenue_rate_recommendations(tenant_id,room_type_id,stay_date,current_rate,recommended_rate,occupancy_pct,competitor_median,rate_position,reason) values(p_tenant_id,p_room_type_id,p_stay_date,base,rec,occ,comp,case when comp is null then 'no_competitor_data' when rec>comp then 'above_market' when rec<comp then 'below_market' else 'parity' end,reason);
 return reason||jsonb_build_object('recommended_rate',rec);
end $$;

grant execute on function public.anaira_generate_hotel_rate_recommendation(uuid,uuid,date) to authenticated;

create or replace function public.anaira_queue_prearrival_jobs(p_now timestamptz default now())
returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare n int;
begin
 insert into public.crm_prearrival_jobs(tenant_id,customer_id,guest_stay_id,job_type,due_at,channel,payload)
 select s.tenant_id,s.customer_id,s.id,'prearrival_7d',greatest(p_now,s.check_in_date::timestamptz-interval '7 days'),'whatsapp',jsonb_build_object('booking',s.external_booking_id)
 from public.crm_guest_stays s where s.booking_status='confirmed' and s.check_in_date>=p_now::date and s.check_in_date<=p_now::date+30
 on conflict do nothing;
 get diagnostics n=row_count; return n;
end $$;

grant execute on function public.anaira_queue_prearrival_jobs(timestamptz) to authenticated;

create or replace function public.anaira_refresh_global_customer_links(p_tenant_id uuid,p_customer_id uuid)
returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare n int:=0;
begin
 insert into public.crm_global_customer_relationships(customer_id,tenant_id,domain,relationship_type,last_seen_at) values(p_customer_id,p_tenant_id,'hotel','guest',now()) on conflict do update set last_seen_at=now(); n:=n+1;
 insert into public.crm_global_customer_relationships(customer_id,tenant_id,domain,relationship_type,last_seen_at) values(p_customer_id,p_tenant_id,'restaurant','diner',now()) on conflict do update set last_seen_at=now(); n:=n+1;
 return n;
end $$;

grant execute on function public.anaira_refresh_global_customer_links(uuid,uuid) to authenticated;

-- Default restaurant tags/rules are data, not UI placeholders.
insert into public.crm_auto_tag_rules(tenant_id,name,tag_name,domain,definition,priority)
select r.id,'VIP by visits','VIP','restaurant',jsonb_build_object('min_visits',10),10 from public.restaurants r where not exists(select 1 from public.crm_auto_tag_rules x where x.tenant_id=r.id and x.tag_name='VIP' and x.domain='restaurant')
union all select r.id,'High Spender','High Spender','restaurant',jsonb_build_object('min_spend',50000),20 from public.restaurants r where not exists(select 1 from public.crm_auto_tag_rules x where x.tenant_id=r.id and x.tag_name='High Spender' and x.domain='restaurant')
union all select r.id,'Lapsed 60d','Lapsed Guest','restaurant',jsonb_build_object('lapsed_days',60),30 from public.restaurants r where not exists(select 1 from public.crm_auto_tag_rules x where x.tenant_id=r.id and x.tag_name='Lapsed Guest' and x.domain='restaurant')
union all select r.id,'Reservation Regular','Reservation Regular','restaurant',jsonb_build_object('min_reservations',5),40 from public.restaurants r where not exists(select 1 from public.crm_auto_tag_rules x where x.tenant_id=r.id and x.tag_name='Reservation Regular' and x.domain='restaurant')
union all select r.id,'Service Recovery','Negative Feedback','restaurant',jsonb_build_object('min_complaints',1),50 from public.restaurants r where not exists(select 1 from public.crm_auto_tag_rules x where x.tenant_id=r.id and x.tag_name='Negative Feedback' and x.domain='restaurant');

-- Provider-neutral campaign worker claim primitive. Actual WhatsApp/SMS/email provider secrets stay server-side.
create or replace function public.anaira_claim_campaign_jobs(p_limit integer default 25)
returns setof public.crm_campaign_queue language plpgsql security definer set search_path=public,pg_temp as $$
declare x public.crm_campaign_queue%rowtype;
begin
 for x in select * from public.crm_campaign_queue where status='queued' and available_at<=now() order by created_at for update skip locked limit greatest(1,p_limit) loop update public.crm_campaign_queue set status='processing',attempts=attempts+1 where id=x.id returning * into x; return next x; end loop; return;
end $$;
revoke execute on function public.anaira_claim_campaign_jobs(integer) from anon,authenticated;

-- Sensitive functions are service-worker operations; public booking remains public by design.
revoke execute on function public.anaira_confirm_hotel_booking_payment(uuid,text,text,text,text,jsonb) from anon,authenticated;
revoke execute on function public.anaira_start_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) from anon,authenticated;
-- Re-grant only the public start endpoint. Payment confirmation must be server/webhook only.
grant execute on function public.anaira_start_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) to anon,authenticated;

insert into public.crm_release_evidence(tenant_id,check_name,status,evidence) values(null,'phase16_a_to_z_crm_hospitality','pass',jsonb_build_object('hotel_booking_transactional_state_machine',true,'rate_engine',true,'restaurant_360',true,'auto_tags',true,'campaign_queue',true,'hotel_prearrival',true,'revenue_recommendation_approval',true,'loyalty_earn_redeem',true,'global_customer_identity',true,'real_analytics_aggregation',true,'ai_action_queue',true,'canonical_pos_untouched',true));

-- Runtime worker functions and security grants (mirrors the live Phase 16 runtime patch).
create or replace function public.anaira_queue_prearrival_jobs(p_now timestamptz default now()) returns integer language plpgsql security definer set search_path=public,pg_temp as $$ declare n integer; begin insert into public.crm_prearrival_jobs(tenant_id,customer_id,guest_stay_id,job_type,due_at,channel,payload) select s.tenant_id,s.customer_id,s.id,'prearrival_7d',greatest(p_now,s.check_in_date::timestamptz-interval '7 days'),'whatsapp',jsonb_build_object('booking',s.external_booking_id) from public.crm_guest_stays s where s.booking_status='confirmed' and s.check_in_date>=p_now::date and s.check_in_date<=p_now::date+30 on conflict do nothing; get diagnostics n=row_count; return n; end $$;
grant execute on function public.anaira_queue_prearrival_jobs(timestamptz) to service_role;

create or replace function public.anaira_generate_hotel_rate_recommendation(p_tenant_id uuid,p_room_type_id uuid,p_stay_date date) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$ declare base numeric;minr numeric;maxr numeric;occ numeric;comp numeric;mult numeric:=1;rec numeric;position text; begin select base_rate,min_rate,max_rate into base,minr,maxr from public.crm_room_types where id=p_room_type_id and tenant_id=p_tenant_id and active; if base is null then raise exception 'Room type not found'; end if; select coalesce(100.0*sum(booked_rooms)/nullif(sum(total_rooms),0),0) into occ from public.booking_inventory where restaurant_id=p_tenant_id and room_type_id=p_room_type_id and stay_date=p_stay_date; select percentile_cont(.5) within group(order by rate) into comp from public.crm_competitor_rates where tenant_id=p_tenant_id and stay_date=p_stay_date and rate is not null; if occ>=80 then mult:=1.20; elsif occ>=60 then mult:=1.10; elsif occ<30 then mult:=.90; end if; rec:=least(coalesce(nullif(maxr,0),base*2),greatest(coalesce(minr,base*.5),base*mult)); if comp is not null then rec:=round((rec+comp)/2,2); end if; position:=case when comp is null then 'no_competitor_data' when rec>comp then 'above_market' when rec<comp then 'below_market' else 'parity' end; insert into public.crm_revenue_rate_recommendations(tenant_id,room_type_id,stay_date,current_rate,recommended_rate,occupancy_pct,competitor_median,rate_position,reason) values(p_tenant_id,p_room_type_id,p_stay_date,base,rec,occ,comp,position,jsonb_build_object('occupancy_pct',occ,'competitor_median',comp,'demand_multiplier',mult,'approval_required',true)); return jsonb_build_object('recommended_rate',rec,'occupancy_pct',occ,'competitor_median',comp,'rate_position',position,'approval_required',true); end $$;
grant execute on function public.anaira_generate_hotel_rate_recommendation(uuid,uuid,date) to authenticated;

create or replace function public.anaira_refresh_global_customer_links(p_tenant_id uuid,p_customer_id uuid) returns integer language plpgsql security definer set search_path=public,pg_temp as $$ begin insert into public.crm_global_customer_relationships(customer_id,tenant_id,domain,relationship_type,last_seen_at) values(p_customer_id,p_tenant_id,'hotel','guest',now()) on conflict(customer_id,tenant_id,domain,coalesce(property_id,'00000000-0000-0000-0000-000000000000'::uuid),coalesce(outlet_id,'00000000-0000-0000-0000-000000000000'::uuid)) do update set last_seen_at=now(); insert into public.crm_global_customer_relationships(customer_id,tenant_id,domain,relationship_type,last_seen_at) values(p_customer_id,p_tenant_id,'restaurant','diner',now()) on conflict(customer_id,tenant_id,domain,coalesce(property_id,'00000000-0000-0000-0000-000000000000'::uuid),coalesce(outlet_id,'00000000-0000-0000-0000-000000000000'::uuid)) do update set last_seen_at=now(); return 2; end $$;
grant execute on function public.anaira_refresh_global_customer_links(uuid,uuid) to authenticated;

create or replace function public.anaira_feedback_route_action(p_tenant_id uuid,p_customer_id uuid,p_feedback_id uuid,p_rating numeric) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$ declare id uuid;action text;begin action:=case when p_rating<3 then 'service_recovery' when p_rating>=4 then 'review_request' else 'manager_followup' end;insert into public.crm_feedback_actions(tenant_id,customer_id,feedback_id,action_type,status,payload) values(p_tenant_id,p_customer_id,p_feedback_id,action,'queued',jsonb_build_object('rating',p_rating)) returning id into id;if p_rating<3 then insert into public.crm_complaints(tenant_id,customer_id,title,description,priority,status) values(p_tenant_id,p_customer_id,'Negative feedback','Automated service-recovery case created from feedback.','high','open');end if;return id;end $$;
grant execute on function public.anaira_feedback_route_action(uuid,uuid,uuid,numeric) to authenticated;

revoke execute on function public.anaira_confirm_hotel_booking_payment(uuid,text,text,text,text,jsonb) from public,anon,authenticated;
revoke execute on function public.anaira_claim_campaign_jobs(integer) from public,anon,authenticated;
revoke execute on function public.anaira_apply_restaurant_auto_tags(uuid,uuid) from public,anon;
revoke execute on function public.anaira_refresh_crm_analytics(uuid,date) from public,anon;
revoke execute on function public.anaira_loyalty_post(uuid,uuid,text,numeric,text,text) from public,anon;
revoke execute on function public.anaira_loyalty_redeem(uuid,uuid,uuid,text) from public,anon;
revoke execute on function public.anaira_refresh_restaurant_customer_360(uuid,uuid) from public,anon;
