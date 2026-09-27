# Phase 62 — Business Admin Hotel Sidebar / Inventory Visibility Fix

## Fix
- Business Admin is recognized by either `profiles.role=admin` or `anaira_user_profiles.profile_key=business_admin`.
- Business Admin receives the BUSINESS_GROUPS navigation.
- `/hotel-management/inventory` is explicitly present as `HOTEL MANAGEMENT → Room Inventory`.
- Business Admin is not incorrectly filtered out when a tenant permission row is incomplete; plugin activation remains enforced.
- Business Admin route guards recognize the same role/profile mapping.

## Verified source facts
- Inventory route: `/hotel-management/inventory`
- Sidebar label: `Room Inventory`
- Plugin: `hotel-management-suite`
- Required permission: `hms.room.view`
- Live `hms_inventory.closed` column exists.

## Validation
- `node --check app/components.js` PASS
- Full production build NOT certified because dependency installation timed out in the working environment.
