# Phase 37 — CRM Partial Completion / Certification Gate

## Implemented
- Generic CRM module pages now expose domain actions for partial/derived/external modules instead of only generic CRUD.
- Master-data forms remain editable; derived, transaction, system, and provider-owned data remain read-only at the generic CRUD layer.
- Action requests now construct record keys from each module's declared primary-key contract.
- 222/222 JavaScript syntax checks pass.
- SEO A-to-Z static contract passes.
- SEO market-parity static contract passes.
- Supabase migration `20260926_crm_automation_security_hardening` applied to project `bhptqdoteucuymmdzsmg`.
- The missing RLS-policy finding for `crm_review_webhook_events` was addressed with tenant-aware authenticated access; service/application rows with NULL tenant_id remain non-tenant-owned.

## Certification gate still open
This package is **not** marked production-certified because the evidence required by the locked A-to-Z rule is not all available.

Blocking evidence:
1. Production Next.js build could not be completed in this environment: `npm install --no-audit --no-fund` timed out before dependencies became available.
2. Full browser E2E against a running production build has not been executed here.
3. Live provider credentials and real external-provider E2E are not universally available.
4. Supabase security advisor still reports SECURITY DEFINER execute warnings; public booking/availability functions are intentionally public, while the remaining internal functions require per-function call-site review before blanket revocation.
5. Supabase Auth leaked-password protection remains disabled and must be enabled in project Auth settings.

## Certification rule
No A-to-Z COMPLETE / PRODUCTION CERTIFIED claim is issued until build + runtime + E2E + provider evidence is attached for every applicable item.
