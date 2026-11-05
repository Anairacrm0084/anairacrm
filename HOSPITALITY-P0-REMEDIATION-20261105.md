# Anaira Hospitality P0 Remediation — 2026-11-05

## Implemented in source and live Primary Supabase project

- Public camping storefront no longer reads `camp_inventory` directly. It now uses `anaira_public_camp_availability` and receives only sellable unit counts plus occupancy limits.
- Removed `camp_inventory_public_select` and revoked anonymous/public SELECT on `camp_inventory`; authenticated tenant access remains through `camp_inventory_tenant_all`.
- Preserved the existing availability RPC result contract (`unit_type_id`, `available_units`, `max_guests`, `max_adults`, `max_children`) to avoid breaking checkout clients.
- Added bounded, tenant-scoped `anaira_bulk_set_daily_rate` RPC (future dates only; max 366 dates; non-negative values; active tenant rate plan required).
- Added the missing parent-platform-store FK index.
- Restricted trigger-only SECURITY DEFINER functions from direct API execution; `anaira_ensure_property_store` is authenticated/service-role only and retains its in-function tenant/super-admin check.
- Reconciled the 12-item OTA provider setup catalog in `anaira_distribution_platforms`. This is a setup catalog only, not proof of live provider connectivity.
- Replaced direct `camp_inventory` access in the public hospitality booking page with the safe availability RPC.
- Replaced the camping booking-engine redirect placeholder with a dedicated property/unit/rate/inventory/reservations admin workflow. Inventory generation defaults to the saved physical unit count and preserves sold/held/blocked counters.

## Live verification

- `anaira_bulk_set_daily_rate(...)` exists.
- `anaira_public_camp_availability(...)` retains the established TABLE return shape and is executable by `anon`.
- `anon` cannot SELECT `camp_inventory`; authenticated tenant access remains enabled.
- Trigger-only functions are not executable by anon; `anaira_ensure_property_store` is not executable by anon and remains executable by authenticated users.
- Parent store FK index exists.
- 12 expected OTA catalog provider codes are active.
- Live camp data remains operator-dependent: 2 published properties, 0 active unit types, 0 active rate plans, 0 inventory rows. No fictional units, rates, or availability were inserted.

## Static checks run

- JavaScript syntax: 731/731 PASS
- Relative imports: PASS
- Public hospitality storefront: 14/14 PASS
- Booking runtime closure: 29/29 PASS
- OTA configuration guard: 3/3 PASS (mock transport only; not provider certification)
- Responsive source audit: 5/5 PASS

## Remaining external release gates

- Clean install and `next build` could not run: npm registry access failed with DNS `EAI_AGAIN`; no false build PASS is claimed.
- Deployed browser E2E and cross-tenant negative E2E require a running deployed application and isolated test tenants.
- Provider E2E requires approved real OTA credentials, endpoints, and callbacks.
- Leaked-password protection is an Auth dashboard/project Auth configuration setting; the connected database tools do not expose an Auth security-settings update action. Enable it in Supabase Auth > Settings > Password Security.
- Supabase advisors still report remaining SECURITY DEFINER execution warnings and RLS initplan/multiple-permissive-policy performance warnings. They require per-function/policy review; blanket revocation or policy deletion would risk breaking customer booking and tenant operations.
- Production data entry remains required for camping and alternative stays: property admins must configure real unit counts, rate plans, and date-wise inventory before the listings can sell.
