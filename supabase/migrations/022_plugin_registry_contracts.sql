-- Anaira Plugin Registry & isolation contract
create table if not exists public.anaira_plugin_catalog (
  plugin_key text primary key,
  display_name text not null,
  category text not null,
  description text,
  route text,
  core boolean not null default false,
  created_at timestamptz not null default now()
);

create unique index if not exists restaurant_plugins_restaurant_plugin_code_uidx
  on public.restaurant_plugins(restaurant_id, plugin_code);

insert into public.anaira_plugin_catalog(plugin_key,display_name,category,description,route,core) values
('crm','Anaira CRM','Customer','Customer 360, guest history, loyalty and relationship intelligence.','/customer-360',false),
('hotel-booking','Hotel Booking Engine','Hotel','Direct hotel booking, availability, rates, add-ons and confirmations.','/booking',false),
('hotel-pms','Hotel PMS','Hotel','Front desk, room inventory, housekeeping and stay operations.','/pms',false),
('restaurant-reservation','Restaurant Reservation','Restaurant','Tables, slots, reservations and waitlist.','/reservation',false),
('food-delivery','Food Delivery Marketplace','Commerce','Online ordering, dispatch and delivery lifecycle.','/delivery',false),
('restaurant-store','Restaurant Store Builder','Commerce','Auto-generated branded restaurant storefront.','/store',false),
('anaira-pos','Anaira POS','Operations','Billing, KOT, KDS, menu and restaurant operations.','/pos',true),
('channel-manager','Channel / OTA Manager','Distribution','OTA inventory, rate and reservation synchronization.','/channel-manager',false)
on conflict (plugin_key) do update set display_name=excluded.display_name,category=excluded.category,description=excluded.description,route=excluded.route,core=excluded.core;

alter table public.anaira_plugin_catalog enable row level security;
drop policy if exists "plugin catalog authenticated read" on public.anaira_plugin_catalog;
create policy "plugin catalog authenticated read" on public.anaira_plugin_catalog for select to authenticated using (true);

alter table public.restaurant_plugins enable row level security;
drop policy if exists "restaurant plugin tenant read" on public.restaurant_plugins;
drop policy if exists "restaurant plugin tenant write" on public.restaurant_plugins;
create policy "restaurant plugin tenant read" on public.restaurant_plugins for select to authenticated
using (restaurant_id = (select restaurant_id from public.profiles where id = auth.uid()));
create policy "restaurant plugin tenant write" on public.restaurant_plugins for all to authenticated
using (restaurant_id = (select restaurant_id from public.profiles where id = auth.uid()))
with check (restaurant_id = (select restaurant_id from public.profiles where id = auth.uid()));
