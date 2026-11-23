# Homestay public checkout fix — 2026-11-23

## Root cause
The public homestay storefront uses `anaira_stay_unit_types` and `anaira_stay_rate_plans`, but `/book/[id]/checkout` tried to resolve the selected `room_type` from `hms_room_types`. The HMS catalogue is tenant-RLS protected for authenticated users, and its IDs are not the canonical Stay unit IDs. This produced “Accommodation type is no longer available.” for anonymous guests.

## Changes
- Public hospitality property API now loads active, property-scoped Stay unit types and rate plans server-side and maps them into the storefront catalogue response.
- Public store availability for homestay / guest house / cottage now calls `anaira_public_stay_availability` with the canonical stay property ID.
- Legacy `/book/{restaurant}/checkout` links for homestay / guest house / cottage now resolve the selected unit and rate from the public server catalogue and redirect to the canonical `/stay/{type}/{property}/checkout` flow.
- No broad public policy was added to HMS tables; existing tenant RLS boundaries remain intact.

## Verification
- Homestay public checkout regression test: 8/8 PASS.
- Modified API route Node syntax: PASS.
- Modified storefront and checkout JSX parse via TypeScript transpile: PASS.
- Relative import verification: PASS (no failures).
- Supabase live catalog: 11 active Stay unit types and 11 active Stay rate plans for Home By (Justin).
- Full Next.js production build and live browser booking test still require deployment/environment credentials.
