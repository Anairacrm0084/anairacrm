-- ANAIRA Unified Hospitality Management
-- Hotel, Camping, Homestay, Guest House and Cottage all use the canonical HMS master tables.
-- This deliberately reuses hms_settings / hms_room_types / hms_rooms / hms_inventory /
-- hms_rate_plans / hms_reservations so every property type gets the exact Hotel Management lifecycle.

alter table public.hms_settings
  add column if not exists hospitality_type text not null default 'hotel',
  add column if not exists unit_label_singular text not null default 'Room',
  add column if not exists unit_label_plural text not null default 'Rooms';

alter table public.hms_settings
  drop constraint if exists hms_settings_hospitality_type_check;
alter table public.hms_settings
  add constraint hms_settings_hospitality_type_check
  check (hospitality_type in ('hotel','camp','homestay','guest_house','cottage'));

alter table public.hms_room_types
  add column if not exists pricing_mode text not null default 'per_unit',
  add column if not exists max_guests integer;

alter table public.hms_room_types
  drop constraint if exists hms_room_types_pricing_mode_check;
alter table public.hms_room_types
  add constraint hms_room_types_pricing_mode_check
  check (pricing_mode in ('per_unit','per_person'));

update public.hms_room_types
set max_guests=greatest(1,coalesce(max_adults,1)+coalesce(max_children,0))
where max_guests is null;

alter table public.hms_rate_plans
  add column if not exists pricing_mode text not null default 'per_unit';
alter table public.hms_rate_plans
  drop constraint if exists hms_rate_plans_pricing_mode_check;
alter table public.hms_rate_plans
  add constraint hms_rate_plans_pricing_mode_check
  check (pricing_mode in ('per_unit','per_person'));

alter table public.hms_reservations
  add column if not exists hospitality_type text not null default 'hotel',
  add column if not exists pricing_mode text not null default 'per_unit',
  add column if not exists guest_count integer;

update public.hms_settings hs
set hospitality_type=coalesce(r.hospitality_type,'hotel'),
    unit_label_singular=case coalesce(r.hospitality_type,'hotel')
      when 'camp' then 'Camp / Tent'
      when 'homestay' then 'Accommodation'
      when 'guest_house' then 'Accommodation'
      when 'cottage' then 'Cottage'
      else 'Room' end,
    unit_label_plural=case coalesce(r.hospitality_type,'hotel')
      when 'camp' then 'Camps / Tents'
      when 'homestay' then 'Accommodations'
      when 'guest_house' then 'Accommodations'
      when 'cottage' then 'Cottages'
      else 'Rooms' end
from public.restaurants r
where r.id=hs.restaurant_id;

update public.hms_room_types rt
set pricing_mode=case when coalesce(r.hospitality_type,'hotel')='camp' then 'per_person' else coalesce(rt.pricing_mode,'per_unit') end,
    max_guests=greatest(1,coalesce(rt.max_guests,coalesce(rt.max_adults,1)+coalesce(rt.max_children,0)))
from public.restaurants r
where r.id=rt.restaurant_id;

update public.hms_rate_plans rp
set pricing_mode=case when coalesce(r.hospitality_type,'hotel')='camp' then 'per_person' else coalesce(rp.pricing_mode,'per_unit') end
from public.restaurants r
where r.id=rp.restaurant_id;

update public.hms_reservations r
set hospitality_type=coalesce(b.hospitality_type,'hotel'),
    pricing_mode=coalesce(rp.pricing_mode,'per_unit'),
    guest_count=greatest(1,coalesce(r.adults,1)+coalesce(r.children,0))
from public.restaurants b
left join public.hms_rate_plans rp on rp.id=r.rate_plan_id
where b.id=r.restaurant_id;

create index if not exists hms_settings_hospitality_type_idx on public.hms_settings(hospitality_type);
create index if not exists hms_reservations_hospitality_type_idx on public.hms_reservations(restaurant_id,hospitality_type,status,check_in,check_out);
create index if not exists hms_rate_plans_pricing_mode_idx on public.hms_rate_plans(restaurant_id,pricing_mode,active);

-- Canonical public marketplace search for every HMS-backed hospitality type.
create or replace function public.anaira_marketplace_hms_hospitality_search(
 p_hospitality_type text,
 p_check_in date,
 p_check_out date,
 p_adults integer default 1,
 p_children integer default 0,
 p_destination text default null
)
returns table(
 restaurant_id uuid,
 property_name text,
 city text,
 address text,
 cover_image text,
 unit_type_id uuid,
 unit_name text,
 rate_plan_id uuid,
 rate_plan_name text,
 pricing_mode text,
 rate numeric,
 available_units integer,
 max_adults integer,
 max_children integer,
 max_guests integer
)
language sql stable security definer set search_path=public,pg_temp as $$
 with base as (
   select r.id as restaurant_id,r.name as property_name,r.city,r.address,coalesce(r.cover_image,hs.cover_image_url) as cover_image,
          rt.id as unit_type_id,rt.name as unit_name,rp.id as rate_plan_id,rp.name as rate_plan_name,
          coalesce(rp.pricing_mode,rt.pricing_mode,'per_unit') as pricing_mode,rp.rate,
          rt.max_adults,rt.max_children,greatest(1,coalesce(rt.max_guests,coalesce(rt.max_adults,1)+coalesce(rt.max_children,0))) as max_guests,
          greatest(0,coalesce((select min(i.total_rooms-i.sold_rooms-i.blocked_rooms)
             from public.hms_inventory i
             where i.restaurant_id=r.id and i.room_type_id=rt.id and i.stay_date>=p_check_in and i.stay_date<p_check_out and not i.closed),
             (select count(*) from public.hms_rooms rm where rm.restaurant_id=r.id and rm.room_type_id=rt.id and rm.active=true and lower(coalesce(rm.status,'')) not in ('maintenance','out_of_order'))::integer,0))::integer as available_units
   from public.restaurants r
   join public.hms_settings hs on hs.restaurant_id=r.id
   join public.hms_room_types rt on rt.restaurant_id=r.id and rt.active=true
   join lateral (
      select x.* from public.hms_rate_plans x
      where x.restaurant_id=r.id and x.room_type_id=rt.id and x.active=true
        and (x.active_from is null or x.active_from<=p_check_in)
        and (x.active_to is null or x.active_to>=p_check_out-1)
      order by x.rate asc
      limit 1
   ) rp on true
   where coalesce(r.hospitality_type,hs.hospitality_type,'hotel')=p_hospitality_type
     and hs.hospitality_type=p_hospitality_type
     and r.status is distinct from 'inactive'
     and (p_destination is null or trim(p_destination)='' or lower(concat_ws(' ',r.name,r.city,r.address)) like '%'||lower(trim(p_destination))||'%')
 )
 select * from base
 where p_adults>=1 and p_adults<=max_adults
   and p_children>=0 and p_children<=max_children
   and p_adults+p_children<=max_guests
   and available_units>0
 order by property_name,unit_name;
$$;
revoke all on function public.anaira_marketplace_hms_hospitality_search(text,date,date,integer,integer,text) from public;
grant execute on function public.anaira_marketplace_hms_hospitality_search(text,date,date,integer,integer,text) to anon,authenticated;

-- Same transactional booking engine as Hotel Booking, with per-person pricing for Camping.
create or replace function public.anaira_start_hms_hospitality_booking_transaction(
 p_tenant_id uuid,p_guest_name text,p_guest_phone text,p_guest_email text,p_check_in date,p_check_out date,
 p_room_type_id uuid,p_rate_plan_id uuid,p_adults integer,p_children integer,p_idempotency_key text,p_source text default 'anaira-hospitality-store'
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare rt public.hms_room_types%rowtype; rp public.hms_rate_plans%rowtype; s public.hms_settings%rowtype;
 tx public.crm_booking_transactions%rowtype; hg uuid; cid uuid; bid uuid; code text; h jsonb; pi public.anaira_payment_intents%rowtype;
 d date; nights int; guests int; unit_nightly numeric; unit_total numeric:=0; billable_total numeric:=0; tax numeric:=0; total numeric:=0; tax_pct numeric:=0; pricing text;
begin
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
 if p_adults<1 or p_children<0 then raise exception 'At least 1 adult is required'; end if;
 nights:=p_check_out-p_check_in; guests:=p_adults+p_children;
 select * into s from public.hms_settings where restaurant_id=p_tenant_id limit 1;
 if not found then raise exception 'Hospitality property settings not found'; end if;
 select * into rt from public.hms_room_types where id=p_room_type_id and restaurant_id=p_tenant_id and active=true;
 if not found then raise exception 'Accommodation type not found'; end if;
 if p_adults>rt.max_adults or p_children>rt.max_children or guests>greatest(1,coalesce(rt.max_guests,rt.max_adults+rt.max_children)) then raise exception 'Guest occupancy exceeds accommodation capacity'; end if;
 select * into rp from public.hms_rate_plans where id=p_rate_plan_id and restaurant_id=p_tenant_id and room_type_id=p_room_type_id and active=true
   and (active_from is null or active_from<=p_check_in) and (active_to is null or active_to>=p_check_out-1);
 if not found then raise exception 'Selected rate plan is not active for these dates'; end if;
 pricing:=coalesce(rp.pricing_mode,rt.pricing_mode,'per_unit');
 if nights<coalesce(rp.min_stay,1) then raise exception 'Minimum stay for this rate plan is % night(s)',rp.min_stay; end if;
 if rp.max_stay is not null and nights>rp.max_stay then raise exception 'Maximum stay for this rate plan is % night(s)',rp.max_stay; end if;
 perform public.anaira_sync_hotel_inventory_range(p_tenant_id,p_check_in,p_check_out);
 tax_pct:=coalesce(rt.tax_percent,s.default_tax_percent,s.tax_percent,0);
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
   unit_nightly:=case when extract(isodow from d) in (6,7) and coalesce(rp.weekend_rate,0)>0 then rp.weekend_rate else rp.rate end;
   unit_nightly:=unit_nightly*coalesce(nullif(rp.seasonal_multiplier,0),1);
   unit_total:=unit_total+unit_nightly;
 end loop;
 if pricing='per_person' then billable_total:=unit_total*guests; else billable_total:=unit_total; end if;
 billable_total:=round(billable_total,2); tax:=round(billable_total*tax_pct/100,2); total:=round(billable_total+tax,2);
 select * into tx from public.crm_booking_transactions where tenant_id=p_tenant_id and idempotency_key=p_idempotency_key for update;
 if found then return jsonb_build_object('ok',true,'idempotent',true,'transaction_id',tx.id,'booking_id',tx.booking_id,'amount',tx.amount,'state',tx.state,'quote',tx.payload->'quote'); end if;
 cid:=public.anaira_resolve_crm_customer(p_tenant_id,p_guest_name,p_guest_phone,p_guest_email);
 select id into hg from public.hms_guests where restaurant_id=p_tenant_id and ((nullif(trim(p_guest_phone),'') is not null and phone=trim(p_guest_phone)) or (nullif(trim(p_guest_email),'') is not null and lower(email)=lower(trim(p_guest_email)))) order by updated_at desc limit 1;
 if hg is null then insert into public.hms_guests(restaurant_id,crm_customer_id,full_name,phone,email) values(p_tenant_id,cid,p_guest_name,p_guest_phone,p_guest_email) returning id into hg;
 else update public.hms_guests set crm_customer_id=coalesce(cid,crm_customer_id),full_name=p_guest_name,phone=p_guest_phone,email=p_guest_email,updated_at=now() where id=hg; end if;
 bid:=gen_random_uuid(); code:='ANH-'||upper(substr(replace(bid::text,'-',''),1,10));
 insert into public.hms_reservations(id,restaurant_id,reservation_code,guest_id,room_type_id,source,status,check_in,check_out,adults,children,rate,total_amount,notes,crm_customer_id,rate_plan_id,booking_reference,source_reference,deposit_amount,paid_amount,balance_amount,hospitality_type,pricing_mode,guest_count)
 values(bid,p_tenant_id,code,hg,p_room_type_id,p_source,'inquiry',p_check_in,p_check_out,p_adults,p_children,round(unit_total/nights,2),total,'Created by Anaira unified hospitality booking engine',cid,p_rate_plan_id,code,p_idempotency_key,0,0,total,s.hospitality_type,pricing,guests);
 h:=public.anaira_phase13_hotel_inventory_hold(p_tenant_id,p_room_type_id,p_check_in,p_check_out,1,p_idempotency_key,bid,15);
 insert into public.crm_booking_transactions(tenant_id,booking_id,customer_id,inventory_hold_id,state,idempotency_key,payload,amount,expires_at)
 values(p_tenant_id,bid,cid,(h->>'hold_id')::uuid,'payment_pending',p_idempotency_key,jsonb_build_object('quote',jsonb_build_object('nights',nights,'guests',guests,'pricing_mode',pricing,'unit_rate',round(unit_total/nights,2),'subtotal',billable_total,'tax',tax,'total',total),'hms_reservation_id',bid,'source',p_source),total,(h->>'expires_at')::timestamptz) returning * into tx;
 insert into public.anaira_payment_intents(restaurant_id,reference_type,reference_id,provider,amount,currency,status,idempotency_key,metadata)
 values(p_tenant_id,'hospitality_booking',bid,'manual',total,coalesce(s.currency,'INR'),'created','hospitality:'||p_idempotency_key,jsonb_build_object('booking_transaction_id',tx.id,'hms_reservation_id',bid,'booking_code',code,'hold_id',h->>'hold_id','rate_plan_id',p_rate_plan_id,'hospitality_type',s.hospitality_type)) returning * into pi;
 update public.crm_booking_transactions set payment_intent_id=pi.id where id=tx.id;
 return jsonb_build_object('ok',true,'transaction_id',tx.id,'booking_id',bid,'hms_reservation_id',bid,'booking_code',code,'payment_intent_id',pi.id,'hold_id',h->>'hold_id','amount',total,'quote',jsonb_build_object('nights',nights,'guests',guests,'pricing_mode',pricing,'unit_rate',round(unit_total/nights,2),'subtotal',billable_total,'tax',tax,'total',total),'rate_plan',jsonb_build_object('id',rp.id,'name',rp.name,'code',rp.code,'pricing_mode',pricing,'refundable',rp.refundable,'deposit_percent',rp.deposit_percent),'state','payment_pending');
end $$;
revoke all on function public.anaira_start_hms_hospitality_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text) from public;
grant execute on function public.anaira_start_hms_hospitality_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,text) to anon,authenticated;

-- Front-desk/manual booking uses exactly the same HMS master tables and lifecycle.
create or replace function public.anaira_create_manual_hospitality_booking(
 p_restaurant_id uuid,p_room_type_id uuid,p_rate_plan_id uuid,p_check_in date,p_check_out date,p_adults integer,p_children integer,
 p_guest_name text,p_phone text,p_email text default null,p_room_id uuid default null,p_notes text default null,p_user_id uuid default null
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare s public.hms_settings%rowtype; rt public.hms_room_types%rowtype; rp public.hms_rate_plans%rowtype; bid uuid; hg uuid; cid uuid; d date; nights int; guests int; unit_total numeric:=0; unit_nightly numeric; pricing text; total numeric; code text;
begin
 if p_check_out<=p_check_in then raise exception 'Invalid stay dates'; end if;
 select * into s from public.hms_settings where restaurant_id=p_restaurant_id limit 1;
 select * into rt from public.hms_room_types where id=p_room_type_id and restaurant_id=p_restaurant_id and active=true;
 select * into rp from public.hms_rate_plans where id=p_rate_plan_id and restaurant_id=p_restaurant_id and room_type_id=p_room_type_id and active=true;
 if not found then raise exception 'Room/accommodation type or rate plan not found'; end if;
 guests:=p_adults+greatest(p_children,0); nights:=p_check_out-p_check_in; pricing:=coalesce(rp.pricing_mode,rt.pricing_mode,'per_unit');
 if p_adults<1 or p_adults>rt.max_adults or p_children>rt.max_children or guests>greatest(1,coalesce(rt.max_guests,rt.max_adults+rt.max_children)) then raise exception 'Guest occupancy exceeds capacity'; end if;
 perform public.anaira_sync_hotel_inventory_range(p_restaurant_id,p_check_in,p_check_out);
 for d in select generate_series(p_check_in,p_check_out-1,interval '1 day')::date loop
  unit_nightly:=case when extract(isodow from d) in(6,7) and coalesce(rp.weekend_rate,0)>0 then rp.weekend_rate else rp.rate end;
  unit_total:=unit_total+unit_nightly*coalesce(nullif(rp.seasonal_multiplier,0),1);
 end loop;
 total:=round(case when pricing='per_person' then unit_total*guests else unit_total end,2);
 cid:=public.anaira_resolve_crm_customer(p_restaurant_id,p_guest_name,p_phone,p_email);
 select id into hg from public.hms_guests where restaurant_id=p_restaurant_id and phone=trim(p_phone) order by updated_at desc limit 1;
 if hg is null then insert into public.hms_guests(restaurant_id,crm_customer_id,full_name,phone,email) values(p_restaurant_id,cid,p_guest_name,p_phone,p_email) returning id into hg; end if;
 bid:=gen_random_uuid(); code:='ANH-'||upper(substr(replace(bid::text,'-',''),1,10));
 insert into public.hms_reservations(id,restaurant_id,reservation_code,guest_id,room_type_id,room_id,source,status,check_in,check_out,adults,children,rate,total_amount,notes,crm_customer_id,rate_plan_id,booking_reference,source_reference,deposit_amount,paid_amount,balance_amount,hospitality_type,pricing_mode,guest_count)
 values(bid,p_restaurant_id,code,hg,p_room_type_id,p_room_id,'front_desk','confirmed',p_check_in,p_check_out,p_adults,p_children,round(unit_total/nights,2),total,coalesce(p_notes,'Created manually in unified Hospitality Management'),cid,p_rate_plan_id,code,code,0,0,total,s.hospitality_type,pricing,guests);
 return jsonb_build_object('ok',true,'reservation_id',bid,'booking_code',code,'total',total,'pricing_mode',pricing,'guest_count',guests);
end $$;
revoke all on function public.anaira_create_manual_hospitality_booking(uuid,uuid,uuid,date,date,integer,integer,text,text,text,uuid,text,uuid) from public;
grant execute on function public.anaira_create_manual_hospitality_booking(uuid,uuid,uuid,date,date,integer,integer,text,text,text,uuid,text,uuid) to authenticated;

-- Keep the legacy alternative-stay tables available for backward compatibility, but make the canonical HMS path explicit.
insert into public.crm_release_evidence(check_name,status,evidence)
values('unified_hospitality_management_parity','pass',jsonb_build_object(
 'canonical_tables',jsonb_build_array('hms_settings','hms_room_types','hms_rooms','hms_rate_plans','hms_inventory','hms_reservations'),
 'supported_types',jsonb_build_array('hotel','camp','homestay','guest_house','cottage'),
 'auto_inventory','physical HMS units + reservations',
 'camp_pricing','per_person supported at rate-plan level'
)) on conflict do nothing;
