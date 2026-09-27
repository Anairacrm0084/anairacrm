# Phase 54 — Housekeeping

## Runtime
- Room Board / housekeeping task list
- Cleaning workflow: pending → in_progress → completed
- Inspection workflow: completed → inspected
- Reopen workflow
- Maintenance task fields and priority support
- Room status synchronization on completion and inspection
- Tenant-scoped RLS
- Authenticated transition RPC

## Verification
- Supabase migration: APPLIED
- Source syntax: PASS (node --check)
- Authenticated browser E2E: NOT RUN
- Production deployment smoke: NOT RUN
