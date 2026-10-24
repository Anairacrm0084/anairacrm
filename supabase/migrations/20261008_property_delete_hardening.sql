-- Property deletion hardening aligned with the live Supabase foreign-key graph.
-- Keep marketplace references pointed at their actual parent tables; make child rows
-- follow deletion of those parents instead of retargeting unrelated IDs.

alter table public.anaira_marketplace_bookings
  drop constraint if exists anaira_marketplace_bookings_property_id_fkey;
alter table public.anaira_marketplace_bookings
  add constraint anaira_marketplace_bookings_property_id_fkey
  foreign key (property_id) references public.anaira_hotel_properties(id) on delete cascade;

alter table public.anaira_marketplace_orders
  drop constraint if exists anaira_marketplace_orders_restaurant_id_fkey;
alter table public.anaira_marketplace_orders
  add constraint anaira_marketplace_orders_restaurant_id_fkey
  foreign key (restaurant_id) references public.anaira_marketplace_restaurants(id) on delete cascade;

-- Exact legacy rows identified by audit; only remove canonical rows whose tenant is gone.
delete from public.anaira_hotel_properties
where id = 'e1a6fff7-dd51-46f2-875d-3ed4115fcd8d'::uuid;

delete from public.anaira_hospitality_properties_master m
where m.id in (
  '85563161-4e3b-404d-bae7-aeff84fd0b15'::uuid,
  '2c23030c-6931-4f05-a20c-5c22c716f709'::uuid
)
and not exists (select 1 from public.restaurants r where r.id=m.tenant_id);
