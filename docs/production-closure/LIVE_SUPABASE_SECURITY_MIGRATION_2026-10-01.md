# Live Supabase Security Migration

Project: Anairacrm0084's Project
Migration applied: `20261001_security_definer_role_matrix_v4`

Result:
- Internal SECURITY DEFINER functions no longer inherit EXECUTE from PUBLIC.
- Authenticated EXECUTE is explicit.
- Public search/availability/marketplace/public-booking RPCs retain anon EXECUTE.
- Post-change audit: 29 SECURITY DEFINER functions are callable by anon.

This migration is also included under `supabase/migrations/`.
