# Super Admin Setup & Store Visibility Audit — 2026-09-29

## Findings

1. Super Admin Hotel Setup and Restaurant Setup depended on a `?property=` query to select a tenant. With no query and no `restaurant_id` on the Super Admin profile, the pages could open without a selected property and show an unusable empty state.
2. Restaurant Setup was not constrained to restaurant-capable tenants, so the property selector could point at non-restaurant hospitality businesses.
3. Business Store Builder's `saveStore()` always wrote `enabled: true`, so a disabled business store could be re-enabled simply by saving settings.
4. Super Admin already had store controls in `/super-admin/anaira-store` through `PlatformStoreControl`, including global platform-store enable/disable and per-business listing visibility. The per-business action was labeled `Hide from Store` / `List in Store`, which obscured that it was the business-store availability control.

## Changes

- Super Admin setup now auto-selects a valid property when none is specified.
- Restaurant Setup now uses only restaurant / hotel+restaurant properties in the Super Admin selector.
- Business Store Builder preserves membership `enabled` state when saving instead of forcing it to true.
- Business Store Builder now exposes `Disable My Store` / `Enable My Store` for the business membership.
- Super Admin per-business marketplace control is labeled `Disable Business Store` / `Enable Business Store`.
- Global Hotel Store / Restaurant Store enable-disable remains available in ANAIRA Store Control Center.

## Validation

Node syntax checks passed for all modified JS files.
