create extension if not exists pgcrypto;

create table if not exists public.salon_service_categories (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, description text, image_url text, active boolean not null default true,
 sort_order int not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.salon_services (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 category_id uuid references public.salon_service_categories(id) on delete set null, name text not null, slug text,
 description text, image_url text, price numeric(12,2) not null default 0, duration_minutes int not null default 30,
 buffer_minutes int not null default 0, tax_percent numeric(6,2) not null default 0, commission_type text not null default 'percent', commission_value numeric(8,2) not null default 0,
 online_booking boolean not null default true, active boolean not null default true, metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.salon_staff (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, role text, bio text, photo_url text, phone text, email text, commission_type text not null default 'percent', commission_value numeric(8,2) not null default 0,
 tips_enabled boolean not null default true, target_amount numeric(12,2) not null default 0, active boolean not null default true, metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.salon_staff_services (
 staff_id uuid not null references public.salon_staff(id) on delete cascade, service_id uuid not null references public.salon_services(id) on delete cascade,
 custom_price numeric(12,2), custom_duration_minutes int, primary key(staff_id,service_id)
);
create table if not exists public.salon_staff_schedules (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 staff_id uuid not null references public.salon_staff(id) on delete cascade, weekday int not null check(weekday between 0 and 6), start_time time not null, end_time time not null,
 break_start time, break_end time, active boolean not null default true
);
create table if not exists public.salon_staff_leaves (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 staff_id uuid not null references public.salon_staff(id) on delete cascade, start_at timestamptz not null, end_at timestamptz not null, reason text
);
create table if not exists public.salon_resources (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, resource_type text not null default 'chair', capacity int not null default 1, image_url text, active boolean not null default true, metadata jsonb not null default '{}'::jsonb
);
create table if not exists public.salon_service_resources (
 service_id uuid not null references public.salon_services(id) on delete cascade, resource_id uuid not null references public.salon_resources(id) on delete cascade, primary key(service_id,resource_id)
);
create table if not exists public.salon_products (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, sku text, brand text, category text, image_url text, unit text not null default 'unit', cost_price numeric(12,2) not null default 0, sale_price numeric(12,2) not null default 0,
 stock_qty numeric(12,3) not null default 0, reorder_level numeric(12,3) not null default 0, active boolean not null default true, metadata jsonb not null default '{}'::jsonb
);
create table if not exists public.salon_inventory_movements (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 product_id uuid not null references public.salon_products(id) on delete cascade, movement_type text not null, quantity numeric(12,3) not null,
 reference_type text, reference_id uuid, note text, created_at timestamptz not null default now()
);
create table if not exists public.salon_membership_plans (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, description text, price numeric(12,2) not null default 0, billing_interval text not null default 'monthly', benefits jsonb not null default '[]'::jsonb,
 active boolean not null default true, image_url text
);
create table if not exists public.salon_packages (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 name text not null, description text, price numeric(12,2) not null default 0, expiry_days int not null default 30, image_url text, active boolean not null default true,
 included_services jsonb not null default '[]'::jsonb
);
create table if not exists public.salon_gift_cards (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 code text not null, value numeric(12,2) not null default 0, balance numeric(12,2) not null default 0, expires_at timestamptz, active boolean not null default true
);
create table if not exists public.salon_loyalty_settings (
 business_id uuid primary key references public.restaurants(id) on delete cascade, enabled boolean not null default true,
 points_per_rupee numeric(8,4) not null default 1, redemption_value numeric(8,4) not null default 0.1, tiers jsonb not null default '[]'::jsonb, rewards jsonb not null default '[]'::jsonb
);
create table if not exists public.salon_marketing_settings (
 business_id uuid primary key references public.restaurants(id) on delete cascade, whatsapp_enabled boolean not null default true, sms_enabled boolean not null default false,
 email_enabled boolean not null default true, birthday_offer text, anniversary_offer text, rebooking_days int not null default 30, winback_days int not null default 60,
 automation_rules jsonb not null default '[]'::jsonb
);
create table if not exists public.salon_landing_sections (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 section_key text not null, title text, subtitle text, content jsonb not null default '{}'::jsonb, image_url text, sort_order int not null default 0, enabled boolean not null default true,
 unique(business_id,section_key)
);

create index if not exists salon_services_business_active_idx on public.salon_services(business_id,active);
create index if not exists salon_staff_business_active_idx on public.salon_staff(business_id,active);
create index if not exists salon_products_business_idx on public.salon_products(business_id,active);
create index if not exists salon_resources_business_idx on public.salon_resources(business_id,active);

alter table public.salon_service_categories enable row level security;
alter table public.salon_services enable row level security;
alter table public.salon_staff enable row level security;
alter table public.salon_staff_services enable row level security;
alter table public.salon_staff_schedules enable row level security;
alter table public.salon_staff_leaves enable row level security;
alter table public.salon_resources enable row level security;
alter table public.salon_service_resources enable row level security;
alter table public.salon_products enable row level security;
alter table public.salon_inventory_movements enable row level security;
alter table public.salon_membership_plans enable row level security;
alter table public.salon_packages enable row level security;
alter table public.salon_gift_cards enable row level security;
alter table public.salon_loyalty_settings enable row level security;
alter table public.salon_marketing_settings enable row level security;
alter table public.salon_landing_sections enable row level security;

DO $$
DECLARE t text;
BEGIN
 FOREACH t IN ARRAY ARRAY['salon_service_categories','salon_services','salon_staff','salon_staff_schedules','salon_staff_leaves','salon_resources','salon_products','salon_inventory_movements','salon_membership_plans','salon_packages','salon_gift_cards','salon_landing_sections'] LOOP
  EXECUTE format('drop policy if exists %I_tenant on public.%I', t||'_tenant', t);
  EXECUTE format('create policy %I_tenant on public.%I for all to authenticated using (public.anaira_current_is_super_admin() or business_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or business_id=public.anaira_current_restaurant_id())', t||'_tenant', t);
 END LOOP;
END $$;

create policy salon_staff_services_tenant on public.salon_staff_services for all to authenticated using (
 public.anaira_current_is_super_admin() or exists(select 1 from public.salon_staff s where s.id=staff_id and s.business_id=public.anaira_current_restaurant_id())
) with check (
 public.anaira_current_is_super_admin() or exists(select 1 from public.salon_staff s where s.id=staff_id and s.business_id=public.anaira_current_restaurant_id())
);
create policy salon_service_resources_tenant on public.salon_service_resources for all to authenticated using (
 public.anaira_current_is_super_admin() or exists(select 1 from public.salon_services s where s.id=service_id and s.business_id=public.anaira_current_restaurant_id())
) with check (
 public.anaira_current_is_super_admin() or exists(select 1 from public.salon_services s where s.id=service_id and s.business_id=public.anaira_current_restaurant_id())
);
create policy salon_loyalty_settings_tenant on public.salon_loyalty_settings for all to authenticated using (public.anaira_current_is_super_admin() or business_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or business_id=public.anaira_current_restaurant_id());
create policy salon_marketing_settings_tenant on public.salon_marketing_settings for all to authenticated using (public.anaira_current_is_super_admin() or business_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or business_id=public.anaira_current_restaurant_id());

insert into storage.buckets(id,name,public) values ('salon-assets','salon-assets',true) on conflict (id) do nothing;
drop policy if exists salon_assets_public_read on storage.objects;
create policy salon_assets_public_read on storage.objects for select using (bucket_id='salon-assets');
drop policy if exists salon_assets_upload on storage.objects;
create policy salon_assets_upload on storage.objects for insert to authenticated with check (bucket_id='salon-assets' and (public.anaira_current_is_super_admin() or (storage.foldername(name))[1]=public.anaira_current_restaurant_id()::text));
drop policy if exists salon_assets_update on storage.objects;
create policy salon_assets_update on storage.objects for update to authenticated using (bucket_id='salon-assets' and (public.anaira_current_is_super_admin() or (storage.foldername(name))[1]=public.anaira_current_restaurant_id()::text));


create table if not exists public.salon_customers (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 customer_id uuid, name text not null, phone text, email text, birthday date, anniversary date, gender text, photo_url text,
 notes text, allergies text, preferences jsonb not null default '{}'::jsonb, loyalty_points numeric(12,2) not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.salon_appointments (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 customer_id uuid references public.salon_customers(id) on delete set null, staff_id uuid references public.salon_staff(id) on delete set null, resource_id uuid references public.salon_resources(id) on delete set null,
 start_at timestamptz not null, end_at timestamptz not null, status text not null default 'booked', source text not null default 'admin', payment_status text not null default 'unpaid', deposit numeric(12,2) not null default 0,
 notes text, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.salon_appointment_items (
 id uuid primary key default gen_random_uuid(), appointment_id uuid not null references public.salon_appointments(id) on delete cascade,
 service_id uuid references public.salon_services(id) on delete set null, name text not null, price numeric(12,2) not null default 0, duration_minutes int not null default 30, quantity int not null default 1, staff_id uuid references public.salon_staff(id) on delete set null, metadata jsonb not null default '{}'::jsonb
);
create table if not exists public.salon_pos_tickets (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 appointment_id uuid references public.salon_appointments(id) on delete set null, customer_id uuid references public.salon_customers(id) on delete set null,
 status text not null default 'open', subtotal numeric(12,2) not null default 0, discount numeric(12,2) not null default 0, tax numeric(12,2) not null default 0, tip numeric(12,2) not null default 0, total numeric(12,2) not null default 0,
 created_at timestamptz not null default now(), closed_at timestamptz
);
create table if not exists public.salon_pos_items (
 id uuid primary key default gen_random_uuid(), ticket_id uuid not null references public.salon_pos_tickets(id) on delete cascade,
 item_type text not null, item_id uuid, name text not null, quantity numeric(12,3) not null default 1, unit_price numeric(12,2) not null default 0, discount numeric(12,2) not null default 0, total numeric(12,2) not null default 0, staff_id uuid references public.salon_staff(id) on delete set null
);
create table if not exists public.salon_payments (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 ticket_id uuid references public.salon_pos_tickets(id) on delete cascade, method text not null, amount numeric(12,2) not null, reference text, status text not null default 'paid', paid_at timestamptz not null default now()
);
create table if not exists public.salon_commissions (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade,
 staff_id uuid not null references public.salon_staff(id) on delete cascade, ticket_id uuid references public.salon_pos_tickets(id) on delete set null, appointment_item_id uuid references public.salon_appointment_items(id) on delete set null,
 base_amount numeric(12,2) not null default 0, commission_amount numeric(12,2) not null default 0, status text not null default 'pending', created_at timestamptz not null default now()
);
create table if not exists public.salon_tips (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade, staff_id uuid references public.salon_staff(id) on delete set null,
 ticket_id uuid references public.salon_pos_tickets(id) on delete set null, amount numeric(12,2) not null default 0, created_at timestamptz not null default now()
);
create table if not exists public.salon_waitlist (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade, customer_id uuid references public.salon_customers(id) on delete set null,
 service_id uuid references public.salon_services(id) on delete set null, preferred_staff_id uuid references public.salon_staff(id) on delete set null, preferred_date date, preferred_time time, status text not null default 'waiting', notes text, created_at timestamptz not null default now()
);
create table if not exists public.salon_review_requests (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.restaurants(id) on delete cascade, customer_id uuid references public.salon_customers(id) on delete set null,
 appointment_id uuid references public.salon_appointments(id) on delete set null, channel text not null default 'whatsapp', status text not null default 'pending', sent_at timestamptz, review_url text
);

DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['salon_customers','salon_appointments','salon_pos_tickets','salon_payments','salon_commissions','salon_tips','salon_waitlist','salon_review_requests'] LOOP
  EXECUTE format('alter table public.%I enable row level security',t);
  EXECUTE format('drop policy if exists %I_tenant on public.%I',t||'_tenant',t);
  EXECUTE format('create policy %I_tenant on public.%I for all to authenticated using (public.anaira_current_is_super_admin() or business_id=public.anaira_current_restaurant_id()) with check (public.anaira_current_is_super_admin() or business_id=public.anaira_current_restaurant_id())',t||'_tenant',t);
 END LOOP;
END $$;

alter table public.salon_appointment_items enable row level security;
alter table public.salon_pos_items enable row level security;
drop policy if exists salon_appointment_items_tenant on public.salon_appointment_items;
create policy salon_appointment_items_tenant on public.salon_appointment_items for all to authenticated using (public.anaira_current_is_super_admin() or exists(select 1 from public.salon_appointments a where a.id=appointment_id and a.business_id=public.anaira_current_restaurant_id())) with check (public.anaira_current_is_super_admin() or exists(select 1 from public.salon_appointments a where a.id=appointment_id and a.business_id=public.anaira_current_restaurant_id()));
drop policy if exists salon_pos_items_tenant on public.salon_pos_items;
create policy salon_pos_items_tenant on public.salon_pos_items for all to authenticated using (public.anaira_current_is_super_admin() or exists(select 1 from public.salon_pos_tickets t where t.id=ticket_id and t.business_id=public.anaira_current_restaurant_id())) with check (public.anaira_current_is_super_admin() or exists(select 1 from public.salon_pos_tickets t where t.id=ticket_id and t.business_id=public.anaira_current_restaurant_id()));

create index if not exists salon_appointments_calendar_idx on public.salon_appointments(business_id,start_at,status);
create index if not exists salon_waitlist_idx on public.salon_waitlist(business_id,preferred_date,status);
create index if not exists salon_pos_business_idx on public.salon_pos_tickets(business_id,status,created_at);
create index if not exists salon_commissions_business_idx on public.salon_commissions(business_id,staff_id,status);
