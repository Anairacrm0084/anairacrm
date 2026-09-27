# Phase 38 — Real CRM Workflow + Security Hardening

## Implemented
- Tenant-scoped RLS for CRM workflow definitions, workflow runs, and notifications.
- Queue claim index for workflow workers.
- Tenant/status indexes for workflow runs and notifications.
- Concurrent workflow claiming uses `FOR UPDATE SKIP LOCKED`.
- Claim batch is bounded to 1–100 jobs.
- Workflow claim function uses `SECURITY INVOKER` and explicit search path.

## Live Supabase
Migration `20260926_phase38_crm_workflow_security` was applied successfully to the configured project during this phase.

## Certification status
This phase does **not** certify the complete CRM or A-to-Z SEO stack. Production certification still requires clean install, production build, browser E2E, real provider credentials, transaction tests, retry/failure verification, and deployment smoke tests.
