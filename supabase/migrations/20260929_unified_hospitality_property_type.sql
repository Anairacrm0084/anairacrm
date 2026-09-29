alter table public.restaurants add column if not exists hospitality_type text;
update public.restaurants set hospitality_type=case when lower(coalesce(business_type,''))='restaurant' then 'restaurant' else 'hotel' end where hospitality_type is null;
alter table public.restaurants alter column hospitality_type set default 'hotel';
alter table public.restaurants drop constraint if exists restaurants_hospitality_type_check;
alter table public.restaurants add constraint restaurants_hospitality_type_check check (hospitality_type in ('hotel','camp','homestay','guest_house','cottage','restaurant'));
create index if not exists idx_restaurants_hospitality_type on public.restaurants(hospitality_type,status);
create or replace function public.anaira_public_hospitality_property_type(p_restaurant_id uuid) returns text language sql stable security definer set search_path=public,pg_temp as $$ select coalesce(r.hospitality_type,'hotel') from public.restaurants r where r.id=p_restaurant_id; $$;
revoke all on function public.anaira_public_hospitality_property_type(uuid) from public;
grant execute on function public.anaira_public_hospitality_property_type(uuid) to anon,authenticated;
