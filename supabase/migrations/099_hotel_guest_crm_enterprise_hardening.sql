-- ANAIRA HOTEL GUEST CRM ENTERPRISE PRODUCTION HARDENING
-- Relationship-layer persistence, tenant isolation for newly added records and operational indexes.
-- Booking Engine/PMS/POS remain source-system masters.

create index if not exists crm_guest_stays_guest_dates_idx
  on public.crm_guest_stays(tenant_id,customer_id,check_in_date desc,check_out_date desc);

create index if not exists crm_guest_requests_tenant_sla_idx
  on public.crm_guest_requests(tenant_id,status,priority,sla_due_at);

create index if not exists crm_guest_upsells_tenant_status_idx
  on public.crm_guest_upsells(tenant_id,status,offered_at desc);

create index if not exists crm_guest_documents_customer_idx
  on public.crm_guest_documents(tenant_id,customer_id,verification_status,created_at desc);

create index if not exists crm_guest_stay_events_lookup_idx
  on public.crm_guest_stay_events(tenant_id,customer_id,stay_id,created_at desc);

create index if not exists crm_guest_precheckins_lookup_idx
  on public.crm_guest_precheckins(tenant_id,customer_id,stay_id,status,created_at desc);

create index if not exists crm_partner_bookings_tenant_idx
  on public.crm_partner_bookings(tenant_id,partner_id,customer_id,created_at desc);

create index if not exists crm_corporate_contacts_account_idx
  on public.crm_corporate_contacts(corporate_account_id,created_at desc);

create index if not exists crm_corporate_contracts_account_idx
  on public.crm_corporate_contracts(corporate_account_id,status,end_date desc);

-- Corporate contacts/contracts inherit tenant access from their parent corporate account.
drop policy if exists corporate_contacts_tenant on public.crm_corporate_contacts;
create policy corporate_contacts_tenant on public.crm_corporate_contacts
for all to authenticated
using (
  exists (
    select 1 from public.crm_corporate_accounts a
    where a.id=corporate_account_id
      and (a.tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
  )
)
with check (
  exists (
    select 1 from public.crm_corporate_accounts a
    where a.id=corporate_account_id
      and (a.tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
  )
);

drop policy if exists corporate_contracts_tenant on public.crm_corporate_contracts;
create policy corporate_contracts_tenant on public.crm_corporate_contracts
for all to authenticated
using (
  exists (
    select 1 from public.crm_corporate_accounts a
    where a.id=corporate_account_id
      and (a.tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
  )
)
with check (
  exists (
    select 1 from public.crm_corporate_accounts a
    where a.id=corporate_account_id
      and (a.tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
  )
);

drop policy if exists partner_bookings_tenant on public.crm_partner_bookings;
create policy partner_bookings_tenant on public.crm_partner_bookings
for all to authenticated
using (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());

comment on table public.crm_guest_stay_events is 'Unified hotel guest lifecycle event stream. PMS/Booking Engine remain operational masters.';
comment on table public.crm_guest_documents is 'Guest verification metadata. Use restricted storage policies for document bytes.';
