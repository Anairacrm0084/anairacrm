-- ANAIRA: Checkout pricing must use the selected EP / CP / MAP / AP plan,
-- daily occupancy rates, extra-adult and extra-child charges.

create or replace function public.anaira_calculate_hms_daily_booking_quote(
  p_tenant_id uuid,
  p_room_type_id uuid,
  p_rate_plan_id uuid,
  p_check_in date,
  p_check_out date,
  p_adults integer default 2,
  p_children integer default 0
) returns jsonb
language plpgsql
security definer
set search_path=public,pg_temp
as $$
declare
  rt public.hms_room_types%rowtype;
  rp public.hms_rate_plans%rowtype;
  s public.hms_settings%rowtype;
  d date;
  nights integer;
  adults integer := greatest(1,coalesce(p_adults,1));
  children integer := greatest(0,coalesce(p_children,0));
  base_occ integer;
  selected_occ integer;
  extra_adults integer;
  pricing text;
  day_rate numeric;
  extra_adult_rate numeric;
  extra_child_rate numeric;
  subtotal numeric := 0;
  tax numeric := 0;
  total numeric := 0;
  tax_pct numeric := 0;
  day jsonb;
begin
  if p_check_out <= p_check_in then raise exception 'Invalid stay dates'; end if;
  nights := p_check_out - p_check_in;

  select * into rt from public.hms_room_types
  where id=p_room_type_id and restaurant_id=p_tenant_id and active=true;
  if not found then raise exception 'Accommodation type not found'; end if;

  if adults > coalesce(rt.max_adults,999) or children > coalesce(rt.max_children,999)
     or adults+children > greatest(1,coalesce(rt.max_guests,rt.max_adults+rt.max_children)) then
    raise exception 'Guest occupancy exceeds accommodation capacity';
  end if;

  select * into rp from public.hms_rate_plans
  where id=p_rate_plan_id and restaurant_id=p_tenant_id and room_type_id=p_room_type_id and active=true
    and (active_from is null or active_from<=p_check_in)
    and (active_to is null or active_to>=p_check_out-1);
  if not found then raise exception 'Selected rate plan is not active for these dates'; end if;

  pricing := coalesce(rp.pricing_mode,rt.pricing_mode,'per_unit');
  base_occ := greatest(1,least(4,coalesce(rp.occupancy,2)));
  selected_occ := least(adults,base_occ);
  extra_adults := greatest(0,adults-base_occ);

  select * into s from public.hms_settings where restaurant_id=p_tenant_id limit 1;
  tax_pct := coalesce(rt.tax_percent,s.default_tax_percent,s.tax_percent,0);

  for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
    select to_jsonb(x) into day
    from public.hms_daily_rate_calendar x
    where x.restaurant_id=p_tenant_id
      and x.rate_plan_id=p_rate_plan_id
      and x.stay_date=d
    limit 1;

    if day is not null and coalesce((day->>'closed')::boolean,false) then
      raise exception 'Selected rate plan is closed for %', d;
    end if;

    if pricing='per_person' then
      day_rate := coalesce(nullif(day->>'single_rate','')::numeric, rp.rate, 0) * adults;
      extra_adult_rate := 0;
      extra_child_rate := coalesce(nullif(day->>'extra_child','')::numeric, rp.extra_child, 0);
      day_rate := day_rate + extra_child_rate * children;
    else
      day_rate := case selected_occ
        when 1 then coalesce(nullif(day->>'single_rate','')::numeric, rp.rate, 0)
        when 2 then coalesce(nullif(day->>'double_rate','')::numeric, rp.rate, 0)
        when 3 then coalesce(nullif(day->>'triple_rate','')::numeric, rp.rate, 0)
        else coalesce(nullif(day->>'quad_rate','')::numeric, rp.rate, 0)
      end;
      if day is null then
        day_rate := case selected_occ
          when 1 then coalesce(rp.rate,0)
          when 2 then coalesce(rp.rate,0)
          when 3 then coalesce(rp.rate,0)
          else coalesce(rp.rate,0)
        end;
      end if;
      extra_adult_rate := coalesce(nullif(day->>'extra_adult','')::numeric, rp.extra_adult, 0);
      extra_child_rate := coalesce(nullif(day->>'extra_child','')::numeric, rp.extra_child, 0);
      day_rate := day_rate + (extra_adult_rate * extra_adults) + (extra_child_rate * children);
    end if;

    subtotal := subtotal + coalesce(day_rate,0);
  end loop;

  subtotal := round(subtotal,2);
  tax := round(subtotal*tax_pct/100,2);
  total := round(subtotal+tax,2);

  return jsonb_build_object(
    'nights',nights,
    'adults',adults,
    'children',children,
    'pricing_mode',pricing,
    'base_occupancy',base_occ,
    'extra_adults',extra_adults,
    'subtotal',subtotal,
    'tax',tax,
    'tax_percent',tax_pct,
    'total',total,
    'rate_plan_id',rp.id,
    'rate_plan_name',rp.name,
    'board_type',rp.board_type
  );
end $$;

revoke all on function public.anaira_calculate_hms_daily_booking_quote(uuid,uuid,uuid,date,date,integer,integer) from public;
grant execute on function public.anaira_calculate_hms_daily_booking_quote(uuid,uuid,uuid,date,date,integer,integer) to anon,authenticated;

-- Unified hospitality transaction now persists the same quote shown by checkout.
create or replace function public.anaira_start_hms_hospitality_booking_transaction(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,
 p_room_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_idempotency_key text,p_source text default 'anaira-hospitality-store'
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare
 rt public.hms_room_types%rowtype; rp public.hms_rate_plans%rowtype; s public.hms_settings%rowtype;
 tx public.crm_booking_transactions%rowtype; hg uuid; cid uuid; bid uuid; code text; h jsonb; pi public.anaira_payment_intents%rowtype; q jsonb;
begin
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
 select * into rt from public.hms_room_types where id=p_room_type_id and restaurant_id=p_tenant_id and active=true;
 if not found then raise exception 'Accommodation type not found'; end if;
 select * into rp from public.hms_rate_plans where id=p_rate_plan_id and restaurant_id=p_tenant_id and room_type_id=p_room_type_id and active=true;
 if not found then raise exception 'Selected rate plan is not active'; end if;
 if (p_check_out-p_check_in)<coalesce(rp.min_stay,1) then raise exception 'Minimum stay for this rate plan is % night(s)',rp.min_stay; end if;
 if rp.max_stay is not null and (p_check_out-p_check_in)>rp.max_stay then raise exception 'Maximum stay for this rate plan is % night(s)',rp.max_stay; end if;
 q:=public.anaira_calculate_hms_daily_booking_quote(p_tenant_id,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children);
 select * into s from public.hms_settings where restaurant_id=p_tenant_id limit 1;
 select * into tx from public.crm_booking_transactions where tenant_id=p_tenant_id and idempotency_key=p_idempotency_key for update;
 if found then return jsonb_build_object('ok',true,'idempotent',true,'transaction_id',tx.id,'booking_id',tx.booking_id,'amount',tx.amount,'state',tx.state,'quote',tx.payload->'quote'); end if;
 cid:=public.anaira_resolve_crm_customer(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email);
 select id into hg from public.hms_guests where restaurant_id=p_tenant_id and ((nullif(trim(p_guest_phone),'') is not null and phone=trim(p_guest_phone)) or (nullif(trim(p_guest_email),'') is not null and lower(email)=lower(trim(p_guest_email)))) order by updated_at desc limit 1;
 if hg is null then insert into public.hms_guests(restaurant_id,crm_customer_id,full_name,phone,email) values(p_tenant_id,cid,p_guest_name,p_guest_phone,p_guest_email) returning id into hg;
 else update public.hms_guests set crm_customer_id=coalesce(cid,crm_customer_id),full_name=p_guest_name,phone=p_guest_phone,email=p_guest_email,updated_at=now() where id=hg; end if;
 bid:=gen_random_uuid(); code:='ANH-'||upper(substr(replace(bid::text,'-',''),1,10));
 insert into public.hms_reservations(id,restaurant_id,reservation_code,guest_id,room_type_id,source,status,check_in,check_out,adults,children,rate,total_amount,notes,crm_customer_id,rate_plan_id,booking_reference,source_reference,deposit_amount,paid_amount,balance_amount,hospitality_type,pricing_mode,guest_count)
 values(bid,p_tenant_id,code,hg,p_room_type_id,p_source,'inquiry',p_check_in,p_check_out,p_adults,p_children,round((q->>'subtotal')::numeric/nullif((q->>'nights')::numeric,0),2),(q->>'total')::numeric,'Created by Anaira unified hospitality booking engine',cid,p_rate_plan_id,code,p_idempotency_key,0,0,(q->>'total')::numeric,s.hospitality_type,q->>'pricing_mode',greatest(1,p_adults+p_children));
 h:=public.anaira_phase13_hotel_inventory_hold(p_tenant_id,p_room_type_id,p_check_in,p_check_out,1,p_idempotency_key,bid,15);
 insert into public.crm_booking_transactions(tenant_id,booking_id,customer_id,inventory_hold_id,state,idempotency_key,payload,amount,expires_at)
 values(p_tenant_id,bid,cid,(h->>'hold_id')::uuid,'payment_pending',p_idempotency_key,jsonb_build_object('quote',q,'hms_reservation_id',bid,'source',p_source),(q->>'total')::numeric,(h->>'expires_at')::timestamptz) returning * into tx;
 insert into public.anaira_payment_intents(restaurant_id,reference_type,reference_id,provider,amount,currency,status,idempotency_key,metadata)
 values(p_tenant_id,'hospitality_booking',bid,'manual',(q->>'total')::numeric,coalesce(s.currency,'INR'),'created','hospitality:'||p_idempotency_key,jsonb_build_object('booking_transaction_id',tx.id,'hms_reservation_id',bid,'booking_code',code,'hold_id',h->>'hold_id','rate_plan_id',p_rate_plan_id,'hospitality_type',s.hospitality_type)) returning * into pi;
 update public.crm_booking_transactions set payment_intent_id=pi.id where id=tx.id;
 return jsonb_build_object('ok',true,'transaction_id',tx.id,'booking_id',bid,'hms_reservation_id',bid,'booking_code',code,'payment_intent_id',pi.id,'hold_id',h->>'hold_id','amount',(q->>'total')::numeric,'quote',q,'rate_plan',jsonb_build_object('id',rp.id,'name',rp.name,'code',rp.code,'board_type',rp.board_type,'pricing_mode',q->>'pricing_mode','refundable',rp.refundable,'deposit_percent',rp.deposit_percent),'state','payment_pending');
end $$;
revoke all on function public.anaira_start_hms_hospitality_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text) from public;
grant execute on function public.anaira_start_hms_hospitality_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text) to anon,authenticated;

-- Hotel verified wrapper ultimately calls this legacy transaction. Make that
-- transaction use the canonical HMS daily-rate quote as well.
create or replace function public.anaira_start_hotel_booking_transaction(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,p_room_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_coupon_code text,p_addons jsonb,p_idempotency_key text,p_source text default 'direct'
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare
 tx public.crm_booking_transactions%rowtype; q jsonb; hold jsonb; pi public.anaira_payment_intents%rowtype; bid uuid; code text; customer uuid; s public.hms_settings%rowtype;
begin
 select * into tx from public.crm_booking_transactions where tenant_id=p_tenant_id and idempotency_key=p_idempotency_key for update;
 if found then return jsonb_build_object('ok',true,'idempotent',true,'transaction',tx.id,'state',tx.state,'booking_id',tx.booking_id,'payment_intent_id',tx.payment_intent_id,'amount',tx.amount,'quote',tx.payload->'quote'); end if;
 q:=public.anaira_calculate_hms_daily_booking_quote(p_tenant_id,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children);
 select * into s from public.hms_settings where restaurant_id=p_tenant_id limit 1;
 customer:=public.anaira_resolve_crm_customer(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email);
 bid:=gen_random_uuid(); code:='ANB-'||upper(substr(replace(bid::text,'-',''),1,10));
 insert into public.booking_reservations(id,restaurant_id,booking_code,customer_id,room_type_id,rate_plan_id,check_in,check_out,adults,children,guest_name,guest_email,guest_phone,status,payment_status,subtotal,tax_amount,total_amount,source,promo_code,metadata)
 values(bid,p_tenant_id,code,customer,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children,p_guest_name,p_guest_email,p_guest_phone,'payment_pending','unpaid',(q->>'subtotal')::numeric,(q->>'tax')::numeric,(q->>'total')::numeric,p_source,p_coupon_code,jsonb_build_object('addons',coalesce(p_addons,'[]'::jsonb),'transactional_engine',true,'rate_calendar_quote',q));
 hold:=public.anaira_phase13_hotel_inventory_hold(p_tenant_id,p_room_type_id,p_check_in,p_check_out,1,p_idempotency_key,bid,15);
 insert into public.crm_booking_transactions(tenant_id,booking_id,customer_id,inventory_hold_id,state,idempotency_key,payload,amount,currency,expires_at) values(p_tenant_id,bid,customer,(hold->>'hold_id')::uuid,'payment_pending',p_idempotency_key,jsonb_build_object('guest_name',p_guest_name,'source',p_source,'quote',q),(q->>'total')::numeric,'INR',(hold->>'expires_at')::timestamptz) returning * into tx;
 insert into public.anaira_payment_intents(restaurant_id,reference_type,reference_id,provider,amount,currency,status,idempotency_key,metadata) values(p_tenant_id,'hotel_booking',bid,'manual',(q->>'total')::numeric,coalesce(s.currency,'INR'),'created','hotel:'||p_idempotency_key,jsonb_build_object('booking_transaction_id',tx.id,'booking_code',code,'hold_id',hold->>'hold_id','rate_plan_id',p_rate_plan_id)) returning * into pi;
 update public.crm_booking_transactions set payment_intent_id=pi.id where id=tx.id;
 return jsonb_build_object('ok',true,'transaction_id',tx.id,'booking_id',bid,'booking_code',code,'payment_intent_id',pi.id,'hold_id',hold->>'hold_id','amount',(q->>'total')::numeric,'quote',q,'state','payment_pending');
end $$;
grant execute on function public.anaira_start_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) to anon,authenticated;
