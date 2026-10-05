-- Hotel Guest CRM source synchronization and idempotent lifecycle events.
alter table public.crm_guest_stay_events add column if not exists event_key text;
create unique index if not exists crm_guest_stay_events_event_key_uq on public.crm_guest_stay_events(tenant_id,event_key) where event_key is not null;
create index if not exists crm_guest_stays_booking_lookup_idx on public.crm_guest_stays(tenant_id,external_booking_id);

-- Private guest-document storage. Files are never public.
insert into storage.buckets (id,name,public)
values ('crm-guest-documents','crm-guest-documents',false)
on conflict (id) do update set public=false;

drop policy if exists crm_guest_docs_select on storage.objects;
create policy crm_guest_docs_select on storage.objects for select to authenticated
using (bucket_id='crm-guest-documents' and (storage.foldername(name))[1] = public.anaira_current_restaurant_id()::text);

drop policy if exists crm_guest_docs_insert on storage.objects;
create policy crm_guest_docs_insert on storage.objects for insert to authenticated
with check (bucket_id='crm-guest-documents' and (storage.foldername(name))[1] = public.anaira_current_restaurant_id()::text);

drop policy if exists crm_guest_docs_update on storage.objects;
create policy crm_guest_docs_update on storage.objects for update to authenticated
using (bucket_id='crm-guest-documents' and (storage.foldername(name))[1] = public.anaira_current_restaurant_id()::text)
with check (bucket_id='crm-guest-documents' and (storage.foldername(name))[1] = public.anaira_current_restaurant_id()::text);

drop policy if exists crm_guest_docs_delete on storage.objects;
create policy crm_guest_docs_delete on storage.objects for delete to authenticated
using (bucket_id='crm-guest-documents' and (storage.foldername(name))[1] = public.anaira_current_restaurant_id()::text);

-- Tighten the audit ledger to the active tenant/property.
drop policy if exists "crm_audit_authenticated" on public.crm_audit_logs;
drop policy if exists crm_audit_tenant on public.crm_audit_logs;
create policy crm_audit_tenant on public.crm_audit_logs
for all to authenticated
using (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin())
with check (tenant_id=public.anaira_current_restaurant_id() or public.anaira_current_is_super_admin());
