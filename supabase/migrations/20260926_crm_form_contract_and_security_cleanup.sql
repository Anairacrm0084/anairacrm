-- Phase 36: CRM form contract + Supabase security cleanup
create policy "tenant_access"
on public.crm_review_google_connections
as permissive
for all
to authenticated
using (anaira_tenant_access(tenant_id))
with check (anaira_tenant_access(tenant_id));

create or replace function public.anaira_audit_plugin_settings()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
begin
  insert into public.anaira_plugin_config_audit(restaurant_id,plugin_code,actor_id,config)
  values (new.restaurant_id,new.plugin_code,(select auth.uid()),new.config);
  return new;
end;
$function$;

drop index if exists public.crm_seo_automation_job_identity_idx;
drop index if exists public.crm_seo_ga4_metrics_site_date_idx;
drop index if exists public.crm_seo_gsc_metrics_site_date_idx;
