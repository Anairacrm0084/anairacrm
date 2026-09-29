# Multi-Type v11 — Super Admin Setup Selector + Setup Visibility Fix

## Fixed
- Super Admin Hotel Setup and Restaurant Setup are explicitly present in the AppShell navigation.
- Added Hotel Profile / Setup and Restaurant Profile / Setup entries without removing existing routes.
- Fixed a race condition in `useTenantProperty()`: an initial async property load could overwrite a property selected while the first request was still in flight.
- Property selection now updates React context immediately, updates the URL with `history.replaceState`, and stale async loads are ignored.
- The selected property remains on the current setup page instead of appearing to jump/back out.
- Existing hospitality type resolution is preserved.

## Validation
- Node syntax check passed for setup-components.js, components.js, restaurant-setup/page.js, hotel-management/setup/page.js.
