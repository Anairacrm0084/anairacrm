-- Preserve each marketplace FK's actual parent table while making deletion deterministic.
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

-- Delete only the three audited legacy orphan rows.
delete from public.anaira_hotel_properties
where id = 'e1a6fff7-dd51-46f2-875d-3ed4115fcd8d'::uuid;
delete from public.anaira_hospitality_properties_master m
where m.id in (
  '85563161-4e3b-404d-bae7-aeff84fd0b15'::uuid,
  '2c23030c-6931-4f05-a20c-5c22c716f709'::uuid
)
and not exists (select 1 from public.restaurants r where r.id=m.tenant_id);

-- Forward repair: align live foreign keys, remove audited orphan rows, and keep HMS settings present.
create or replace function public.anaira_ensure_hms_settings_for_hospitality()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(new.business_type,'') in ('hotel_resort','hotel_restaurant')
     or coalesce(new.hospitality_type,'') in ('hotel','camp','homestay','guest_house','cottage')
     or coalesce(new.hospitality_types, array[]::text[]) && array['hotel','camp','homestay','guest_house','cottage']::text[] then
    insert into public.hms_settings (restaurant_id, hotel_name, phone, email, address, city, state, country, hospitality_type, hospitality_types)
    values (new.id, new.name, new.phone, new.email, new.address, new.city, new.state, coalesce(new.country,'India'), coalesce(nullif(new.hospitality_type,''),'hotel'), coalesce(nullif(new.hospitality_types,array[]::text[]), array[coalesce(nullif(new.hospitality_type,''),'hotel')]))
    on conflict (restaurant_id) do update set
      hotel_name=coalesce(nullif(public.hms_settings.hotel_name,''),excluded.hotel_name),
      phone=coalesce(public.hms_settings.phone,excluded.phone),
      email=coalesce(public.hms_settings.email,excluded.email),
      address=coalesce(public.hms_settings.address,excluded.address),
      city=coalesce(public.hms_settings.city,excluded.city),
      state=coalesce(public.hms_settings.state,excluded.state),
      country=coalesce(public.hms_settings.country,excluded.country),
      hospitality_type=coalesce(public.hms_settings.hospitality_type,excluded.hospitality_type),
      hospitality_types=case when coalesce(array_length(public.hms_settings.hospitality_types,1),0)=0 then excluded.hospitality_types else public.hms_settings.hospitality_types end,
      updated_at=now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_anaira_ensure_hms_settings on public.restaurants;
create trigger trg_anaira_ensure_hms_settings
after insert or update of name, phone, email, address, city, state, country, business_type, hospitality_type, hospitality_types
on public.restaurants
for each row execute function public.anaira_ensure_hms_settings_for_hospitality();

insert into public.hms_settings (restaurant_id, hotel_name, phone, email, address, city, state, country, hospitality_type, hospitality_types)
select r.id, r.name, r.phone, r.email, r.address, r.city, r.state, coalesce(r.country,'India'), coalesce(nullif(r.hospitality_type,''),'hotel'), coalesce(nullif(r.hospitality_types,array[]::text[]), array[coalesce(nullif(r.hospitality_type,''),'hotel')])
from public.restaurants r
where coalesce(r.business_type,'') in ('hotel_resort','hotel_restaurant')
   or coalesce(r.hospitality_type,'') in ('hotel','camp','homestay','guest_house','cottage')
   or coalesce(r.hospitality_types,array[]::text[]) && array['hotel','camp','homestay','guest_house','cottage']::text[]
on conflict (restaurant_id) do update set
  hotel_name=coalesce(nullif(public.hms_settings.hotel_name,''),excluded.hotel_name),
  phone=coalesce(public.hms_settings.phone,excluded.phone),
  email=coalesce(public.hms_settings.email,excluded.email),
  address=coalesce(public.hms_settings.address,excluded.address),
  city=coalesce(public.hms_settings.city,excluded.city),
  state=coalesce(public.hms_settings.state,excluded.state),
  country=coalesce(public.hms_settings.country,excluded.country),
  hospitality_type=coalesce(public.hms_settings.hospitality_type,excluded.hospitality_type),
  hospitality_types=case when coalesce(array_length(public.hms_settings.hospitality_types,1),0)=0 then excluded.hospitality_types else public.hms_settings.hospitality_types end,
  updated_at=now();
