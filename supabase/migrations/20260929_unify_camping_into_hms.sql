-- ANAIRA: UNIFY LEGACY CAMPING DATA INTO CANONICAL HMS
-- Existing camping management records become first-class HMS records.
-- This keeps Hotel/Camping/Homestay/Guest House/Cottage on the same
-- management, inventory, rate-plan and booking data model.

-- Ensure canonical columns required by the unified runtime exist.
alter table public.hms_room_types add column if not exists pricing_mode text not null default 'per_unit';
alter table public.hms_room_types add column if not exists max_guests integer;
alter table public.hms_rate_plans add column if not exists pricing_mode text not null default 'per_unit';

-- Mark camping properties in the canonical HMS settings.
update public.hms_settings hs
set hospitality_type='camp',
    unit_label_singular='Camp / Tent',
    unit_label_plural='Camps / Tents',
    updated_at=now()
from public.restaurants r
where r.id=hs.restaurant_id
  and coalesce(r.hospitality_type,'')='camp';

-- Correct any previously-created HMS rows that actually belong to camping.
-- This is important for existing properties where a camp/tent was accidentally
-- saved with the default Hotel type.
update public.hms_room_types h
set hospitality_type='camp',
    pricing_mode='per_person'
where exists (
  select 1 from public.camp_unit_types u
  where u.restaurant_id=h.restaurant_id
    and lower(u.name)=lower(h.name)
);

update public.hms_rate_plans rp
set hospitality_type='camp',
    pricing_mode=coalesce(rp.pricing_mode,'per_person')
where exists (
  select 1
  from public.camp_rate_plans cr
  join public.camp_unit_types u on u.id=cr.unit_type_id
  where cr.restaurant_id=rp.restaurant_id
    and cr.name=rp.name
    and u.name=(select h.name from public.hms_room_types h where h.id=rp.room_type_id limit 1)
);

-- Copy legacy camp unit types into HMS room types.
insert into public.hms_room_types
(restaurant_id,hospitality_type,name,code,description,short_description,
 max_adults,max_children,max_guests,base_rate,number_of_beds,bed_type,
 image_urls,amenities,active,pricing_mode)
select
 u.restaurant_id,'camp',u.name,u.code,u.description,u.description,
 greatest(1,coalesce(u.max_adults,1)),
 greatest(0,coalesce(u.max_children,0)),
 greatest(1,coalesce(u.max_guests,1)),
 coalesce(u.base_rate,0),1,'Camp / Tent',
 coalesce(u.image_urls,'[]'::jsonb),coalesce(u.amenities,'[]'::jsonb),
 u.active,'per_person'
from public.camp_unit_types u
where not exists (
  select 1 from public.hms_room_types h
  where h.restaurant_id=u.restaurant_id
    and h.hospitality_type='camp'
    and (h.code is not distinct from u.code)
    and lower(h.name)=lower(u.name)
);

-- Copy camping rate plans and attach them to their canonical HMS type.
insert into public.hms_rate_plans
(restaurant_id,hospitality_type,room_type_id,name,code,board_type,rate,weekend_rate,
 seasonal_multiplier,active,refundable,deposit_percent,cancellation_policy,
 min_stay,max_stay,pricing_mode)
select
 r.restaurant_id,'camp',h.id,r.name,r.code,'Room Only',coalesce(r.rate,0),
 r.weekend_rate,coalesce(r.seasonal_multiplier,1),r.active,r.refundable,
 coalesce(r.deposit_percent,0),r.cancellation_policy,r.min_stay,r.max_stay,
 coalesce(r.pricing_mode,'per_person')
from public.camp_rate_plans r
join public.camp_unit_types u on u.id=r.unit_type_id
join public.hms_room_types h on h.restaurant_id=u.restaurant_id
  and h.hospitality_type='camp'
  and lower(h.name)=lower(u.name)
where not exists (
  select 1 from public.hms_rate_plans x
  where x.restaurant_id=r.restaurant_id
    and x.room_type_id=h.id
    and lower(x.name)=lower(r.name)
);

-- Create canonical physical camp units from unit_count.
insert into public.hms_rooms
(restaurant_id,hospitality_type,room_type_id,room_number,status,housekeeping_status,active,notes)
select
 u.restaurant_id,'camp',h.id,
 'CAMP-'||upper(coalesce(nullif(u.code,''),substr(replace(u.id::text,'-',''),1,6)))||'-'||gs.n,
 'available','clean',true,'Migrated from camp_unit_types'
from public.camp_unit_types u
join public.hms_room_types h on h.restaurant_id=u.restaurant_id
  and h.hospitality_type='camp'
  and lower(h.name)=lower(u.name)
cross join lateral generate_series(1,greatest(0,coalesce(u.unit_count,1))) gs(n)
where not exists (
  select 1 from public.hms_rooms x
  where x.restaurant_id=u.restaurant_id
    and x.room_type_id=h.id
    and x.room_number='CAMP-'||upper(coalesce(nullif(u.code,''),substr(replace(u.id::text,'-',''),1,6)))||'-'||gs.n
);

-- Copy date-wise camping inventory to canonical HMS inventory.
insert into public.hms_inventory
(restaurant_id,room_type_id,stay_date,total_rooms,sold_rooms,blocked_rooms,closed)
select
 i.restaurant_id,h.id,i.stay_date,
 greatest(0,i.total_units),greatest(0,i.sold_units),greatest(0,i.blocked_units),coalesce(i.closed,false)
from public.camp_inventory i
join public.camp_unit_types u on u.id=i.unit_type_id
join public.hms_room_types h on h.restaurant_id=u.restaurant_id
  and h.hospitality_type='camp'
  and lower(h.name)=lower(u.name)
where not exists (
  select 1 from public.hms_inventory x
  where x.restaurant_id=i.restaurant_id
    and x.room_type_id=h.id
    and x.stay_date=i.stay_date
);

create index if not exists hms_room_types_camp_lookup
on public.hms_room_types(restaurant_id,hospitality_type,active);

create index if not exists hms_rooms_camp_lookup
on public.hms_rooms(restaurant_id,hospitality_type,room_type_id,active);

create index if not exists hms_inventory_camp_lookup
on public.hms_inventory(restaurant_id,room_type_id,stay_date);
