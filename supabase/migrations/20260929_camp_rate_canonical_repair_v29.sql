-- ANAIRA v29: canonical camping rate repair
-- Safe/idempotent: does not delete or overwrite existing records.
-- Ensures legacy camp/tent data is also represented in the unified HMS catalog.

alter table public.hms_room_types add column if not exists pricing_mode text not null default 'per_unit';
alter table public.hms_room_types add column if not exists max_guests integer;
alter table public.hms_rate_plans add column if not exists pricing_mode text not null default 'per_unit';

-- 1) Missing canonical camp/tent accommodation types.
insert into public.hms_room_types
(restaurant_id,hospitality_type,name,code,description,short_description,max_adults,max_children,max_guests,base_rate,number_of_beds,bed_type,image_urls,amenities,active,pricing_mode)
select
 u.restaurant_id,'camp',u.name,u.code,u.description,coalesce(u.short_description,u.description),
 greatest(1,coalesce(u.max_adults,1)),greatest(0,coalesce(u.max_children,0)),
 greatest(1,coalesce(u.max_guests,coalesce(u.max_adults,1)+coalesce(u.max_children,0))),
 coalesce(u.base_rate,u.rate,0),coalesce(u.number_of_beds,u.beds,1),'Camp / Tent',
 coalesce(u.image_urls,'[]'::jsonb),coalesce(u.amenities,'[]'::jsonb),u.active,coalesce(u.pricing_mode,'per_person')
from public.camp_unit_types u
where u.active
and not exists (
 select 1 from public.hms_room_types h
 where h.restaurant_id=u.restaurant_id
   and h.hospitality_type='camp'
   and ((nullif(h.code,'') is not null and h.code=u.code) or lower(h.name)=lower(u.name))
);

-- 2) Missing canonical rate plans, linked to the correct canonical camp type.
insert into public.hms_rate_plans
(restaurant_id,hospitality_type,room_type_id,name,code,board_type,rate,weekend_rate,seasonal_multiplier,active,refundable,deposit_percent,cancellation_policy,min_stay,max_stay,pricing_mode)
select
 c.restaurant_id,'camp',h.id,c.name,c.code,'Room Only',coalesce(c.rate,0),c.weekend_rate,
 coalesce(c.seasonal_multiplier,1),c.active,c.refundable,coalesce(c.deposit_percent,0),
 c.cancellation_policy,c.min_stay,c.max_stay,coalesce(c.pricing_mode,'per_person')
from public.camp_rate_plans c
join public.camp_unit_types u on u.id=c.unit_type_id
join public.hms_room_types h on h.restaurant_id=u.restaurant_id
 and h.hospitality_type='camp'
 and ((nullif(h.code,'') is not null and h.code=u.code) or lower(h.name)=lower(u.name))
where c.active
and not exists (
 select 1 from public.hms_rate_plans x
 where x.restaurant_id=c.restaurant_id
   and x.room_type_id=h.id
   and lower(x.name)=lower(c.name)
);

-- 3) Make sure the property remains explicitly multi-hospitality when camping exists.
update public.restaurants r
set hospitality_types = (
 select array_agg(t order by case t when 'hotel' then 1 when 'camp' then 2 when 'homestay' then 3 when 'guest_house' then 4 when 'cottage' then 5 else 99 end)
 from (
   select unnest(coalesce(nullif(r.hospitality_types,'{}'),array[]::text[])) t
   union select 'camp'
 ) q
 where t in ('hotel','camp','homestay','guest_house','cottage')
)
where exists(select 1 from public.camp_unit_types u where u.restaurant_id=r.id and u.active);
