create or replace function public.anaira_calculate_hms_daily_booking_quote(
  p_tenant_id uuid,p_room_type_id uuid,p_rate_plan_id uuid,p_check_in date,p_check_out date,p_adults integer default 2,p_children integer default 0
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare rt public.hms_room_types%rowtype; rp public.hms_rate_plans%rowtype; s public.hms_settings%rowtype; d date; nights int; adults int:=greatest(1,coalesce(p_adults,1)); children int:=greatest(0,coalesce(p_children,0)); base_occ int; selected_occ int; extra_adults int; pricing text; day jsonb; day_rate numeric; extra_adult_rate numeric; extra_child_rate numeric; subtotal numeric:=0; tax numeric:=0; tax_pct numeric:=0;
begin
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if; nights:=p_check_out-p_check_in;
 select * into rt from public.hms_room_types where id=p_room_type_id and restaurant_id=p_tenant_id and active=true; if not found then raise exception 'Accommodation type not found'; end if;
 if adults>coalesce(rt.max_adults,999) or children>coalesce(rt.max_children,999) or adults+children>greatest(1,coalesce(rt.max_guests,rt.max_adults+rt.max_children)) then raise exception 'Guest occupancy exceeds accommodation capacity'; end if;
 select * into rp from public.hms_rate_plans where id=p_rate_plan_id and restaurant_id=p_tenant_id and room_type_id=p_room_type_id and active=true and (active_from is null or active_from<=p_check_in) and (active_to is null or active_to>=p_check_out-1); if not found then raise exception 'Selected rate plan is not active for these dates'; end if;
 pricing:=coalesce(rp.pricing_mode,rt.pricing_mode,'per_unit'); base_occ:=greatest(1,least(4,coalesce(rp.occupancy,2))); selected_occ:=least(adults,base_occ); extra_adults:=greatest(0,adults-base_occ); select * into s from public.hms_settings where restaurant_id=p_tenant_id limit 1; tax_pct:=coalesce(rt.tax_percent,s.default_tax_percent,s.tax_percent,0);
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
  select to_jsonb(x) into day from public.hms_daily_rate_calendar x where x.restaurant_id=p_tenant_id and x.rate_plan_id=p_rate_plan_id and x.stay_date=d limit 1;
  if day is not null and coalesce((day->>'closed')::boolean,false) then raise exception 'Selected rate plan is closed for %',d; end if;
  if pricing='per_person' then
    day_rate:=coalesce(nullif(day->>'single_rate','')::numeric,rp.rate,0)*adults;
    day_rate:=day_rate+coalesce(nullif(day->>'extra_child','')::numeric,rp.extra_child,0)*children;
  else
    day_rate:=case selected_occ when 1 then coalesce(nullif(day->>'single_rate','')::numeric,rp.rate,0) when 2 then coalesce(nullif(day->>'double_rate','')::numeric,rp.rate,0) when 3 then coalesce(nullif(day->>'triple_rate','')::numeric,rp.rate,0) else coalesce(nullif(day->>'quad_rate','')::numeric,rp.rate,0) end;
    extra_adult_rate:=coalesce(nullif(day->>'extra_adult','')::numeric,rp.extra_adult,0); extra_child_rate:=coalesce(nullif(day->>'extra_child','')::numeric,rp.extra_child,0);
    day_rate:=day_rate+extra_adult_rate*extra_adults+extra_child_rate*children;
  end if;
  subtotal:=subtotal+coalesce(day_rate,0);
 end loop;
 subtotal:=round(subtotal,2); tax:=round(subtotal*tax_pct/100,2);
 return jsonb_build_object('nights',nights,'adults',adults,'children',children,'pricing_mode',pricing,'base_occupancy',base_occ,'extra_adults',extra_adults,'subtotal',subtotal,'tax',tax,'tax_percent',tax_pct,'total',round(subtotal+tax,2),'rate_plan_id',rp.id,'rate_plan_name',rp.name,'board_type',rp.board_type);
end $$;
revoke all on function public.anaira_calculate_hms_daily_booking_quote(uuid,uuid,uuid,date,date,integer,integer) from public;
grant execute on function public.anaira_calculate_hms_daily_booking_quote(uuid,uuid,uuid,date,date,integer,integer) to anon,authenticated;

create or replace function public.anaira_start_hms_hospitality_booking_transaction_v2(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,p_room_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_idempotency_key text,p_source text default 'anaira-hospitality-store'
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare r jsonb; q jsonb; tx public.crm_booking_transactions%rowtype; hr public.hms_reservations%rowtype; br public.booking_reservations%rowtype; pi public.anaira_payment_intents%rowtype;
begin
 q:=public.anaira_calculate_hms_daily_booking_quote(p_tenant_id,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children);
 r:=public.anaira_start_hms_hospitality_booking_transaction(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email,p_check_in,p_check_out,p_room_type_id,p_rate_plan_id,p_adults,p_children,p_idempotency_key,p_source);
 if coalesce((r->>'ok')::boolean,false) then
   if r->>'booking_id' is not null then update public.hms_reservations set rate=round((q->>'subtotal')::numeric/nullif((q->>'nights')::numeric,0),2),total_amount=(q->>'total')::numeric where id=(r->>'booking_id')::uuid and restaurant_id=p_tenant_id; end if;
   if r->>'booking_id' is not null then update public.booking_reservations set subtotal=(q->>'subtotal')::numeric,tax_amount=(q->>'tax')::numeric,total_amount=(q->>'total')::numeric,metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('rate_calendar_quote',q) where id=(r->>'booking_id')::uuid and restaurant_id=p_tenant_id; end if;
   select * into tx from public.crm_booking_transactions where id=coalesce((r->>'transaction_id')::uuid,(r->>'transaction')::uuid) and tenant_id=p_tenant_id for update;
   if found then update public.crm_booking_transactions set amount=(q->>'total')::numeric,payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object('quote',q) where id=tx.id; if tx.payment_intent_id is not null then update public.anaira_payment_intents set amount=(q->>'total')::numeric where id=tx.payment_intent_id; end if; end if;
 end if;
 return coalesce(r,'{}'::jsonb)||jsonb_build_object('quote',q,'amount',(q->>'total')::numeric);
end $$;
revoke all on function public.anaira_start_hms_hospitality_booking_transaction_v2(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text) from public;
grant execute on function public.anaira_start_hms_hospitality_booking_transaction_v2(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text) to anon,authenticated;

create or replace function public.anaira_start_verified_hotel_booking_transaction_v2(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,p_room_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_coupon_code text,p_addons jsonb,p_idempotency_key text,p_source text default 'anaira-hotel-store',p_verification_id uuid default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v_ok boolean:=false; v_channel text; v_hash text; r jsonb; q jsonb; tx public.crm_booking_transactions%rowtype;
begin
 if p_verification_id is null then raise exception 'Customer verification is required before booking'; end if;
 if nullif(trim(coalesce(p_guest_email,'')),'') is not null then v_channel:='email'; v_hash:=encode(digest(lower(trim(p_guest_email)),'sha256'),'hex'); v_ok:=public.anaira_verify_guest_otp_challenge(p_verification_id,p_tenant_id,v_channel,v_hash); end if;
 if not v_ok and nullif(trim(coalesce(p_guest_phone,'')),'') is not null then v_channel:='phone'; v_hash:=encode(digest(regexp_replace(p_guest_phone,'\D','','g'),'sha256'),'hex'); v_ok:=public.anaira_verify_guest_otp_challenge(p_verification_id,p_tenant_id,v_channel,v_hash); end if;
 if not v_ok then raise exception 'The guest contact could not be verified for this booking'; end if;
 q:=public.anaira_calculate_hms_daily_booking_quote(p_tenant_id,p_room_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children);
 r:=public.anaira_start_hotel_booking_transaction(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email,p_check_in,p_check_out,p_room_type_id,p_rate_plan_id,p_adults,p_children,p_coupon_code,p_addons,p_idempotency_key,p_source);
 if coalesce((r->>'ok')::boolean,false) then
   if r->>'booking_id' is not null then update public.booking_reservations set subtotal=(q->>'subtotal')::numeric,tax_amount=(q->>'tax')::numeric,total_amount=(q->>'total')::numeric,metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('rate_calendar_quote',q) where id=(r->>'booking_id')::uuid and restaurant_id=p_tenant_id; end if;
   select * into tx from public.crm_booking_transactions where id=(r->>'transaction_id')::uuid and tenant_id=p_tenant_id for update;
   if found then update public.crm_booking_transactions set amount=(q->>'total')::numeric,payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object('quote',q) where id=tx.id; if tx.payment_intent_id is not null then update public.anaira_payment_intents set amount=(q->>'total')::numeric where id=tx.payment_intent_id; end if; end if;
 end if;
 return coalesce(r,'{}'::jsonb)||jsonb_build_object('quote',q,'amount',(q->>'total')::numeric);
end $$;
revoke all on function public.anaira_start_verified_hotel_booking_transaction_v2(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) from public;
grant execute on function public.anaira_start_verified_hotel_booking_transaction_v2(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text,uuid) to anon,authenticated;
-- The v2 verified wrapper is intentionally defined in a follow-up migration in source builds.
