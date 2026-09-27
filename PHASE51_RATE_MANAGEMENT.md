# PHASE 51 — RATE MANAGEMENT MASTER
Date: 2026-09-26

## Scope
Point 5 of the locked Hotel Management structure: Rate Management.

## Implemented
- Real `hms_rate_plans` CRUD.
- Property-scoped unique rate-plan code.
- Room-type mapping and meal plans: EP, CP, MAP, AP.
- Base rate, weekend rate, extra adult/child pricing.
- Seasonal multiplier.
- Minimum/maximum stay and booking-window controls.
- Active date range and active/inactive state.
- Refundable flag and deposit percentage.
- Package code, promotion code and add-ons JSON.
- Cancellation policy and description.
- `hms_rate_overrides` for date-specific seasonal pricing, min-stay and closed dates.
- Effective-rate RPC `anaira_get_effective_room_rate`.
- Tenant-isolated RLS on rate plans and overrides.

## Verification
- Supabase migration `20260926_phase51_rate_management_master` applied successfully.
- Browser authenticated E2E and production deployment smoke were not run in this execution; release is therefore not Production Certified.
