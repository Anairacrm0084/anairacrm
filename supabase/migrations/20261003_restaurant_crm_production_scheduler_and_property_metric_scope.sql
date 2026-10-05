-- Restaurant CRM production closure: scheduler + strict property metric scope
-- Applies to live Supabase project as part of the production closure.

create extension if not exists pg_cron with schema extensions;

alter table public.crm_restaurant_customer_metrics
  alter column property_id set not null;

create unique index if not exists crm_restaurant_customer_metrics_property_unique
  on public.crm_restaurant_customer_metrics(tenant_id, customer_id, property_id);

create index if not exists crm_restaurant_customer_metrics_property_idx
  on public.crm_restaurant_customer_metrics(tenant_id, property_id, customer_id);

do $$
begin
  if not exists (select 1 from cron.job where jobname='anaira_restaurant_automation_worker') then
    perform cron.schedule('anaira_restaurant_automation_worker','* * * * *','select public.anaira_process_restaurant_automation_jobs(25);');
  end if;
  if not exists (select 1 from cron.job where jobname='anaira_restaurant_campaign_worker') then
    perform cron.schedule('anaira_restaurant_campaign_worker','* * * * *','select public.anaira_process_restaurant_campaign_jobs(10);');
  end if;
end $$;
