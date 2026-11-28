-- Public, approved featured property IDs for the ANAIRA Hotels homepage.
-- Super Admin controls the existing membership.featured and sort_order fields.
create or replace function public.anaira_marketplace_featured_property_ids()
returns table(restaurant_id uuid, sort_order integer)
language sql
stable
security definer
set search_path = ''
as $function$
  select m.restaurant_id, coalesce(m.sort_order,0)::integer
  from public.anaira_store_memberships m
  join public.anaira_platform_stores s
    on s.id=m.store_id
   and s.store_type='hotel'
   and s.is_platform_store=false
   and s.enabled=true
   and s.published=true
   and s.marketplace_approval_status='approved'
  join public.restaurants r on r.id=m.restaurant_id
  where m.enabled=true
    and m.featured=true
    and coalesce(r.status,'active')='active'
    and coalesce(r.hospitality_type,'hotel') in ('hotel','camp','homestay','guest_house','cottage')
  order by coalesce(m.sort_order,0),r.name;
$function$;
revoke all on function public.anaira_marketplace_featured_property_ids() from public;
grant execute on function public.anaira_marketplace_featured_property_ids() to anon,authenticated;
