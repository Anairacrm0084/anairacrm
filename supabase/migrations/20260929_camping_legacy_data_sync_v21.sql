-- ANAIRA v21: idempotent camping legacy -> canonical HMS sync.
-- No existing rows are deleted or overwritten. Missing canonical records are inserted,
-- and legacy rate plans are attached to the canonical room type by unit code/name.

alter table public.hms_room_types add column if not exists pricing_mode text not null default 'per_unit';
alter table public.hms_room_types add column if not exists max_guests integer;
alter table public.hms_rate_plans add column if not exists pricing_mode text not null default 'per_unit';

update public.restaurants r
set hospitality_types = array(
  select distinct t from unnest(coalesce(nullif(r.hospitality_types,'{}'), array[]::text[]) || array['camp']::text[]) t
  where t in ('hotel','camp','homestay','guest_house','cottage')
)
where exists(select 1 from public.camp_unit_types u where u.restaurant_id=r.id and u.active);

insert into public.hms_room_types
(restaurant_id,hospitality_type,name,code,description,short_description,max_adults,max_children,max_guests,base_rate,number_of_beds,bed_type,image_urls,amenities,active,pricing_mode)
select u.restaurant_id,'camp',u.name,u.code,u.description,u.description,greatest(1,coalesce(u.max_adults,1)),greatest(0,coalesce(u.max_children,0)),greatest(1,coalesce(u.max_guests,1)),coalesce(u.base_rate,0),1,'Camp / Tent',coalesce(u.image_urls,'[]'::jsonb),coalesce(u.amenities,'[]'::jsonb),u.active,'per_person'
from public.camp_unit_types u
where u.active
and not exists(select 1 from public.hms_room_types h where h.restaurant_id=u.restaurant_id and h.hospitality_type='camp' and ((nullif(h.code,'') is not null and h.code=u.code) or (lower(h.name)=lower(u.name))));

insert into public.hms_rate_plans
(restaurant_id,hospitality_type,room_type_id,name,code,board_type,rate,weekend_rate,seasonal_multiplier,active,refundable,deposit_percent,cancellation_policy,min_stay,max_stay,pricing_mode)
select c.restaurant_id,'camp',h.id,c.name,c.code,'Room Only',coalesce(c.rate,0),c.weekend_rate,coalesce(c.seasonal_multiplier,1),c.active,c.refundable,coalesce(c.deposit_percent,0),c.cancellation_policy,c.min_stay,c.max_stay,coalesce(c.pricing_mode,'per_person')
from public.camp_rate_plans c
join public.camp_unit_types u on u.id=c.unit_type_id
join public.hms_room_types h on h.restaurant_id=u.restaurant_id and h.hospitality_type='camp' and ((nullif(h.code,'') is not null and h.code=u.code) or lower(h.name)=lower(u.name))
where c.active
and not exists(select 1 from public.hms_rate_plans x where x.restaurant_id=c.restaurant_id and x.room_type_id=h.id and lower(x.name)=lower(c.name));

insert into public.hms_inventory
(restaurant_id,room_type_id,stay_date,total_rooms,sold_rooms,blocked_rooms,closed)
select i.restaurant_id,h.id,i.stay_date,greatest(0,i.total_units),greatest(0,i.sold_units)+greatest(0,i.held_units),greatest(0,i.blocked_units),coalesce(i.closed,false)
from public.camp_inventory i
join public.camp_unit_types u on u.id=i.unit_type_id
join public.hms_room_types h on h.restaurant_id=u.restaurant_id and h.hospitality_type='camp' and ((nullif(h.code,'') is not null and h.code=u.code) or lower(h.name)=lower(u.name))
where not exists(select 1 from public.hms_inventory x where x.restaurant_id=i.restaurant_id and x.room_type_id=h.id and x.stay_date=i.stay_date);
