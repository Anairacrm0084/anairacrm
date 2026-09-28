# Anaira P1 — CRM Market Parity

## Scope
P1 implements the real CRM market-parity data/runtime foundation for:
- Customer 360 identity links and auditable merge lifecycle
- Sales CRM pipelines, stages and opportunities
- Service CRM tickets and ticket event history
- Workflow action definitions and retry policy storage
- Tenant-safe RLS for all P1-owned records
- Transactional Customer 360 summary and customer merge RPCs

## Certification state
`FOUNDATION` — database/runtime code is implemented in the ZIP. Supabase migration execution, browser E2E, provider delivery, and production build require the target deployment environment and are intentionally not marked PASS from static source inspection.

## Required verification before E2E certification
1. Apply the P1 migration to the target Supabase project.
2. Verify all P1 tables have RLS and tenant isolation.
3. Verify customer merge under same tenant and reject cross-tenant merge.
4. Verify pipeline → stage → opportunity lifecycle.
5. Verify ticket → assignment/SLA → resolution → CSAT lifecycle.
6. Verify workflow action definitions execute through the existing workflow queue/worker and retry correctly.
7. Run clean install and production build.
8. Run authenticated browser E2E against a seeded test tenant.
