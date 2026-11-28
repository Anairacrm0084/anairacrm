-- ANAIRA public List Your Property intake
-- Supabase project: bhptqdoteucuymmdzsmg
create table if not exists public.anaira_property_listing_inquiries (
  id uuid primary key default gen_random_uuid(),
  property_name text not null,
  contact_name text not null,
  email text not null,
  phone text not null,
  property_type text not null check (property_type in ('hotel','homestay','camp','guest_house','cottage')),
  address text not null,
  city text not null,
  state text not null,
  units integer not null check (units between 1 and 10000),
  website text,
  message text,
  status text not null default 'pending' check (status in ('pending','contacted','approved','rejected')),
  created_at timestamptz not null default now()
);

create index if not exists anaira_property_listing_inquiries_created_at_idx
  on public.anaira_property_listing_inquiries (created_at desc);

alter table public.anaira_property_listing_inquiries enable row level security;

revoke all on table public.anaira_property_listing_inquiries from anon, authenticated;
grant insert on table public.anaira_property_listing_inquiries to anon, authenticated;

drop policy if exists "Public can submit property listing inquiry" on public.anaira_property_listing_inquiries;
create policy "Public can submit property listing inquiry"
  on public.anaira_property_listing_inquiries
  for insert
  to anon, authenticated
  with check (
    length(trim(property_name)) between 1 and 150
    and length(trim(contact_name)) between 1 and 120
    and length(trim(email)) between 3 and 254
    and length(trim(phone)) between 7 and 20
    and property_type in ('hotel','homestay','camp','guest_house','cottage')
    and length(trim(address)) between 1 and 1000
    and length(trim(city)) between 1 and 100
    and length(trim(state)) between 1 and 100
    and units between 1 and 10000
    and status = 'pending'
  );

comment on table public.anaira_property_listing_inquiries is
  'Public property partner enquiries submitted from ANAIRA Hotels List Your Property form.';
