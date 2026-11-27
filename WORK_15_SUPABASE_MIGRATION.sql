-- No existing reservations, payments, or inventory are modified by this migration.
-- A legacy camp plan is matched to its canonical HMS plan by tenant, accommodation
-- code/name and rate-plan code/name. Ambiguous mappings fail closed.
create or replace function public.anaira_calculate_camp_calendar_quote(
 p_restaurant_id uuid,p_unit_type_id uuid,p_rate_plan_id uuid,
 p_check_in date,p_check_out date,p_adults integer default 1,p_children integer default 0
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare
 c public.camp_rate_plans%rowtype; u public.camp_unit_types%rowtype;
 h public.hms_room_types%rowtype; hp public.hms_rate_plans%rowtype;
 n integer; mapping_count integer; day date; dayrow public.hms_daily_rate_calendar%rowtype;
 rate numeric; subtotal numeric:=0; guests integer; applied_calendar integer:=0;
 day_lines jsonb:='[]'::jsonb; occupancy integer;
begin
 if p_check_in is null or p_check_out is null or p_check_out<=p_check_in or p_check_out-p_check_in>90 then raise exception 'Invalid stay dates'; end if;
 if p_adults<1 or p_children<0 then raise exception 'Invalid guest count'; end if;
 select * into u from public.camp_unit_types where id=p_unit_type_id and restaurant_id=p_restaurant_id and active;
 if not found then raise exception 'Camping unit not available'; end if;
 guests:=p_adults+p_children;
 if guests>u.max_guests or p_adults>u.max_adults or p_children>u.max_children then raise exception 'Guest occupancy exceeds camping capacity'; end if;
 select * into c from public.camp_rate_plans where id=p_rate_plan_id and unit_type_id=u.id and restaurant_id=p_restaurant_id and active;
 if not found then raise exception 'Camping rate plan not found'; end if;
 n:=p_check_out-p_check_in;
 if n<c.min_stay or (c.max_stay is not null and n>c.max_stay) then raise exception 'Stay duration outside rate plan limits'; end if;
 select count(*) into mapping_count from public.hms_room_types x
 where x.restaurant_id=p_restaurant_id and x.hospitality_type='camp' and x.active
 and ((nullif(trim(u.code),'') is not null and lower(trim(x.code))=lower(trim(u.code))) or lower(trim(x.name))=lower(trim(u.name)));
 if mapping_count>1 then raise exception 'Ambiguous HMS camping room mapping. Contact property administrator'; end if;
 if mapping_count=1 then
  select * into h from public.hms_room_types x where x.restaurant_id=p_restaurant_id and x.hospitality_type='camp' and x.active
  and ((nullif(trim(u.code),'') is not null and lower(trim(x.code))=lower(trim(u.code))) or lower(trim(x.name))=lower(trim(u.name))) limit 1;
  select count(*) into mapping_count from public.hms_rate_plans x where x.restaurant_id=p_restaurant_id and x.room_type_id=h.id and x.active
   and ((nullif(trim(c.code),'') is not null and lower(trim(x.code))=lower(trim(c.code))) or lower(trim(x.name))=lower(trim(c.name)));
  if mapping_count>1 then raise exception 'Ambiguous HMS camping rate plan mapping. Contact property administrator'; end if;
  if mapping_count=1 then select * into hp from public.hms_rate_plans x where x.restaurant_id=p_restaurant_id and x.room_type_id=h.id and x.active
   and ((nullif(trim(c.code),'') is not null and lower(trim(x.code))=lower(trim(c.code))) or lower(trim(x.name))=lower(trim(c.name))) limit 1; end if;
 end if;
 for day in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
  dayrow:=null;
  if hp.id is not null then
   select * into dayrow from public.hms_daily_rate_calendar x where x.restaurant_id=p_restaurant_id and x.rate_plan_id=hp.id and x.stay_date=day;
  end if;
  if dayrow.id is not null then
   if dayrow.closed then raise exception 'Rate plan is closed for %',day; end if;
   applied_calendar:=applied_calendar+1;
   -- Calendar occupancy tiers are the authoritative bulk rates. For a
   -- two-adult stay, use double_rate (not single_rate multiplied by 2).
   occupancy:=least(4,p_adults);
   rate:=case occupancy when 1 then dayrow.single_rate when 2 then dayrow.double_rate when 3 then dayrow.triple_rate else dayrow.quad_rate end;
   rate:=rate+greatest(0,p_adults-4)*dayrow.extra_adult+p_children*dayrow.extra_child;
  else
   rate:=(case when extract(isodow from day) in (6,7) and coalesce(c.weekend_rate,0)>0 then c.weekend_rate else c.rate end)*coalesce(c.seasonal_multiplier,1);
   if c.pricing_mode='per_person' then rate:=rate*guests; end if;
  end if;
  subtotal:=subtotal+rate;
  day_lines:=day_lines||jsonb_build_array(jsonb_build_object('date',day,'amount',round(rate,2),'source',case when dayrow.id is null then 'camp_rate_plan' else 'hms_daily_rate_calendar' end));
 end loop;
 return jsonb_build_object('ok',true,'total',round(subtotal,2),'subtotal',round(subtotal,2),'room_total',round(subtotal,2),
  'nights',n,'nightly_rate',round(subtotal/n,2),'pricing_mode',c.pricing_mode,'rate_plan_id',c.id,
  'calendar_nights',applied_calendar,'tax_total',0,'addons_total',0,'discount_total',0,'currency','INR',
  'daily_rates',day_lines,'rate_basis',case when c.pricing_mode='per_person' then 'per person' else 'per tent' end);
end $$;
revoke all on function public.anaira_calculate_camp_calendar_quote(uuid,uuid,uuid,date,date,integer,integer) from public,anon;
grant execute on function public.anaira_calculate_camp_calendar_quote(uuid,uuid,uuid,date,date,integer,integer) to authenticated;
-- API uses server-side DB client, so service_role may invoke this function.

-- Reprice only newly created camping reservations, within the same transaction
-- as the legacy reservation creation. Existing/idempotent bookings are immutable.
create or replace function public.anaira_start_public_camp_booking_calendar(
 p_restaurant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,
 p_check_in date,p_check_out date,p_unit_type_id uuid,p_rate_plan_id uuid,
 p_adults integer,p_children integer,p_idempotency_key text,p_source text default 'anaira-camping-store',p_verification_id uuid default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare q jsonb; result jsonb; rid uuid; amount numeric; updated_count integer;
begin
 -- Verify availability, OTP and idempotency through the existing booking RPC.
 q:=public.anaira_calculate_camp_calendar_quote(p_restaurant_id,p_unit_type_id,p_rate_plan_id,p_check_in,p_check_out,p_adults,p_children);
 result:=public.anaira_start_public_camp_booking(p_restaurant_id,p_guest_name,p_guest_phone,p_guest_email,p_check_in,p_check_out,p_unit_type_id,p_rate_plan_id,p_adults,p_children,p_idempotency_key,p_source,p_verification_id);
 if coalesce((result->>'idempotent')::boolean,false) then return result; end if;
 if not coalesce((result->>'ok')::boolean,false) then return result; end if;
 rid:=nullif(result->>'reservation_id','')::uuid;
 if rid is null then raise exception 'Camping booking did not return a reservation'; end if;
 amount:=(q->>'total')::numeric;
 update public.camp_reservations set total_amount=amount,balance_amount=amount,nightly_rate=round(amount/(p_check_out-p_check_in),2),
  metadata=coalesce(metadata,'{}'::jsonb)||jsonb_build_object('calendar_quote',q)
 where id=rid and restaurant_id=p_restaurant_id and status='payment_pending';
 get diagnostics updated_count=row_count;
 if updated_count<>1 then raise exception 'Booking price synchronization failed'; end if;
 update public.camp_booking_transactions set amount=amount,
  payload=coalesce(payload,'{}'::jsonb)||jsonb_build_object('quote',q)
 where reservation_id=rid and restaurant_id=p_restaurant_id;
 return result||jsonb_build_object('amount',amount,'quote',q);
end $$;
revoke all on function public.anaira_start_public_camp_booking_calendar(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text,uuid) from public,anon;
grant execute on function public.anaira_start_public_camp_booking_calendar(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text,uuid) to authenticated;
