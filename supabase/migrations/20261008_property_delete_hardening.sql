-- Property lifecycle hardening:
-- 1) remove the two tenant FK blockers that previously prevented complete deletion
-- 2) make future tenant deletion deterministic
-- 3) clean the known orphaned NH3 legacy property records created by deleted tenants

alter table public.anaira_marketplace_bookings
  drop constraint if exists anaira_marketplace_bookings_property_id_fkey;
alter table public.anaira_marketplace_bookings
  add constraint anaira_marketplace_bookings_property_id_fkey
  foreign key (property_id) references public.anaira_hospitality_properties_master(id) on delete cascade;

alter table public.anaira_marketplace_orders
  drop constraint if exists anaira_marketplace_orders_restaurant_id_fkey;
alter table public.anaira_marketplace_orders
  add constraint anaira_marketplace_orders_restaurant_id_fkey
  foreign key (restaurant_id) references public.restaurants(id) on delete cascade;

-- Known legacy NH3 records whose parent tenants no longer exist.
delete from public.anaira_hospitality_properties_master
where id in (
  '85563161-4e3b-404d-bae7-aeff84fd0b15'::uuid,
  '2c23030c-6931-4f05-a20c-5c22c716f709'::uuid
);

delete from public.anaira_hotel_properties
where id = 'e1a6fff7-dd51-46f2-875d-3ed4115fcd8d'::uuid;
