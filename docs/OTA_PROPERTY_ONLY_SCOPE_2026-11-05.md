# OTA Property-Only Scope — 2026-11-05

## Product rule

Anaira CRM supports multiple business types. OTA / Channel Manager is an accommodation-only capability and must not list or connect general business tenants.

Eligible `restaurants.business_type` values:
- `hotel_resort` — Hotel / Resort and accommodation property profiles
- `hotel_restaurant` — Hotel + Restaurant
- `camping` — Camping property

All other business types (including restaurant-only, clinic/hospital, salon, retail, IT agency, etc.) are excluded.

## Enforcement added

- `/ota` Super Admin property selector filters by the eligible business types.
- `/ota` refuses to load a non-accommodation tenant even if a stale or manually edited property query parameter is supplied.
- Business admins must have an eligible accommodation business assigned.
- `/channel-manager` exposes only eligible property choices and shows a clear restriction notice otherwise.
- Super Admin Universal Distribution Integrations lists and configures only eligible properties.
- Connection-test, inbox-processing and sync-worker API routes validate the business type server-side.
- Webhook routing filters provider connections to eligible properties before resolving provider account/property references.
- Supabase restrictive RLS policies enforce the same scope on OTA channels, distribution connections, reservation inbox, sync events, room mappings and rate mappings.

## Database migration

`supabase/migrations/20261105130000_ota_property_only_scope.sql`

Applied to Supabase project `bhptqdoteucuymmdzsmg` (Mumbai region). Six restrictive policies verified in `pg_policies`.

## Validation

- `tests/ota/property-only-scope.mjs`: 7 checks passed.
- `tests/ota/inbound-reservation-normalization.mjs`: 11 checks passed.
- `tests/ota/inbox-runtime-static.mjs`: 14 checks passed.
- `scripts/ota-provider-configuration-guard.mjs`: 3 checks passed.
- Targeted Node syntax checks passed for API routes, channel manager page, integrations control and helper modules.
- Full Next.js build not run in this environment because `node_modules` is not installed.
