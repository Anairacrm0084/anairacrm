-- ANAIRA: multi-type store/data repair
-- Backfill hospitality_types for properties that already have real HMS or legacy
-- camping records, so the setup/store selector does not silently fall back to Hotel.

alter table public.restaurants add column if not exists hospitality_types text[] not null default array['hotel']::text[];

update public.restaurants r
set hospitality_types = (
  select array_agg(t order by case t when 'hotel' then 1 when 'camp' then 2 when 'homestay' then 3 when 'guest_house' then 4 when 'cottage' then 5 else 99 end)
  from (
    select unnest(coalesce(nullif(r.hospitality_types,'{}'), array[]::text[])) as t
    union
    select coalesce(r.hospitality_type,'hotel')
    union
    select rt.hospitality_type from public.hms_room_types rt where rt.restaurant_id=r.id and rt.active and rt.hospitality_type in ('hotel','camp','homestay','guest_house','cottage')
    union
    select 'camp' where exists(select 1 from public.camp_unit_types cu where cu.restaurant_id=r.id and cu.active)
  ) q
  where t in ('hotel','camp','homestay','guest_house','cottage')
);

-- Ensure every selected type has canonical HMS metadata when legacy camping exists.
update public.hms_settings hs
set hospitality_type='camp', unit_label_singular='Camp / Tent', unit_label_plural='Camps / Tents', updated_at=now()
from public.restaurants r
where r.id=hs.restaurant_id
  and 'camp'=any(r.hospitality_types)
  and exists(select 1 from public.camp_unit_types cu where cu.restaurant_id=r.id and cu.active);

-- Safe idempotent camping migration into the canonical HMS catalog.
insert into public.hms_room_types
(restaurant_id,hospitality_type,name,code,description,short_description,max_adults,max_children,max_guests,base_rate,number_of_beds,bed_type,image_urls,amenities,active,pricing_mode)
select u.restaurant_id,'camp',u.name,u.code,u.description,u.description,greatest(1,coalesce(u.max_adults,1)),greatest(0,coalesce(u.max_children,0)),greatest(1,coalesce(u.max_guests,1)),coalesce(u.base_rate,0),1,'Camp / Tent',coalesce(u.image_urls,'[]'::jsonb),coalesce(u.amenities,'[]'::jsonb),u.active,'per_person'
from public.camp_unit_types u
where u.active
and not exists(select 1 from public.hms_room_types h where h.restaurant_id=u.restaurant_id and h.hospitality_type='camp' and lower(h.name)=lower(u.name));

insert into public.hms_rate_plans
(restaurant_id,hospitality_type,room_type_id,name,code,board_type,rate,weekend_rate,seasonal_multiplier,active,refundable,deposit_percent,cancellation_policy,min_stay,max_stay,pricing_mode)
select c.restaurant_id,'camp',h.id,c.name,c.code,'Room Only',coalesce(c.rate,0),c.weekend_rate,coalesce(c.seasonal_multiplier,1),c.active,c.refundable,coalesce(c.deposit_percent,0),c.cancellation_policy,c.min_stay,c.max_stay,coalesce(c.pricing_mode,'per_person')
from public.camp_rate_plans c
join public.camp_unit_types u on u.id=c.unit_type_id
join public.hms_room_types h on h.restaurant_id=u.restaurant_id and h.hospitality_type='camp' and lower(h.name)=lower(u.name)
where c.active
and not exists(select 1 from public.hms_rate_plans x where x.restaurant_id=c.restaurant_id and x.room_type_id=h.id and lower(x.name)=lower(c.name));
