-- Phase 30: SEO forensic hardening / reproducibility
alter table public.crm_seo_audits add column if not exists rule_version text;
alter table public.crm_seo_report_runs add column if not exists delivery_error text;
create index if not exists crm_seo_report_configs_due_idx on public.crm_seo_report_configs(enabled,next_run_at);
create index if not exists crm_seo_gsc_inspections_site_url_idx on public.crm_seo_gsc_inspections(site_id,url,inspection_date desc);
create index if not exists crm_seo_ga4_metrics_site_date_idx on public.crm_seo_ga4_metrics(site_id,metric_date desc);
create index if not exists crm_seo_gsc_metrics_site_date_idx on public.crm_seo_gsc_metrics(site_id,metric_date desc);
