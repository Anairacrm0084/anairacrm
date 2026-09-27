-- Phase 35: SEO A-to-Z closure hardening.
-- Adds operational indexes, deterministic history lookup, provider telemetry lookup,
-- and safe uniqueness for automation/report/runtime state.
create index if not exists crm_seo_issues_site_status_severity_idx on public.crm_seo_issues(site_id,status,severity,last_seen_at desc);
create index if not exists crm_seo_pages_site_indexability_idx on public.crm_seo_pages(site_id,indexable,http_status);
create index if not exists crm_seo_pages_site_score_idx on public.crm_seo_pages(site_id,total_score,technical_score);
create index if not exists crm_seo_rank_history_site_keyword_date_idx on public.crm_seo_rank_history(site_id,keyword_id,tracked_at desc);
create index if not exists crm_seo_gsc_site_date_idx on public.crm_seo_gsc_metrics(site_id,metric_date desc);
create index if not exists crm_seo_ga4_site_date_idx on public.crm_seo_ga4_metrics(site_id,metric_date desc);
create index if not exists crm_seo_provider_telemetry_provider_time_idx on public.crm_seo_provider_telemetry(site_id,provider,created_at desc);
create index if not exists crm_seo_action_runs_task_time_idx on public.crm_seo_action_runs(site_id,task_id,created_at desc);
create index if not exists crm_seo_operation_jobs_site_status_idx on public.crm_seo_operation_jobs(site_id,status,scheduled_at);
create index if not exists crm_seo_sco_opportunity_score_idx on public.crm_seo_sco_opportunities(site_id,opportunity_score desc);
create index if not exists crm_seo_history_site_time_idx on public.crm_seo_history(site_id,created_at desc);
create unique index if not exists crm_seo_automation_job_identity_idx on public.crm_seo_automation_jobs(site_id,job_type);
create unique index if not exists crm_seo_workflow_name_identity_idx on public.crm_seo_automation_workflows(site_id,name);

-- Keep provider status truthful and easy to inspect without exposing credentials.
create index if not exists crm_seo_integrations_tenant_provider_idx on public.crm_seo_integrations(tenant_id,provider,status);
