-- Tenant isolation hardening for CRM and hospitality plugin tables.
-- Existing tenant policies are preserved where present; this migration documents the canonical rule:
-- authenticated users may access rows belonging to their profile.restaurant_id; Super Admin may access all tenants.
create index if not exists idx_profiles_restaurant_id on public.profiles(restaurant_id);
create index if not exists idx_crm_customers_tenant_id on public.crm_customers(tenant_id);
create index if not exists idx_crm_complaints_tenant_id on public.crm_complaints(tenant_id);
create index if not exists idx_booking_reservations_restaurant_id on public.booking_reservations(restaurant_id);
create index if not exists idx_pms_reservations_restaurant_id on public.pms_reservations(restaurant_id);
create index if not exists idx_delivery_orders_restaurant_id on public.delivery_orders(restaurant_id);
