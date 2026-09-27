# Phase 36 — CRM Form Contract + Supabase Audit

Date: 2026-09-26

## Implemented
- Master-data CRM modules retain create/update forms.
- Derived, provider/external, transactional and system CRM modules are read-only in the generic CRUD layer.
- Customer 360 exposes only master fields for editing; revenue/stay totals and timestamps are not editable.
- Loyalty, analytics, revenue, forecasting, AI insights, customer intelligence, competitor rates, OTA performance and timeline no longer expose generic CRUD forms.
- Guest stays, restaurant visits and complaints are treated as transactional/read-only data at the generic CRUD layer.
- The UI now states the canonical data owner for non-master modules instead of presenting a misleading Create/Edit form.

## Supabase audit findings and changes
Verified against project `bhptqdoteucuymmdzsmg`:
- Migration history is present through Phase 35 closure.
- Security advisor found two RLS-enabled review tables without policies: `crm_review_google_connections` and `crm_review_webhook_events`.
- `crm_review_google_connections` was given authenticated tenant RLS using `anaira_tenant_access(tenant_id)`.
- `anaira_audit_plugin_settings` had mutable search_path; it is now explicitly `search_path = public`.
- Three duplicate SEO indexes were removed: `crm_seo_automation_job_identity_idx`, `crm_seo_ga4_metrics_site_date_idx`, `crm_seo_gsc_metrics_site_date_idx`.

## Important remaining review
The Supabase security advisor still reports public/anon EXECUTE on multiple SECURITY DEFINER functions. Public booking/availability functions may intentionally be callable anonymously, but internal operational functions should be reviewed and revoked from `anon` where not required. This Phase does not blindly revoke public functions because that could break the public booking/store surface.

## Certification status
This phase is implemented at source and database migration level. It is NOT a claim of full A-to-Z production certification: browser E2E, production build, provider credentials, and live transaction tests still require environment execution.
