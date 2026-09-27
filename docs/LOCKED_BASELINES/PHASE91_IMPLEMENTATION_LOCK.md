# Anaira Phase 91 — Permission Scope Lock
Date: 2026-09-27

## Locked authority model
- Super Admin = platform/all-tenant control.
- Business Admin = own-tenant control.
- Staff = assigned operations.
- Super Admin-only settings are blocked in sidebar, route guard, page access, API/RPC data paths, and Supabase RLS where the data model permits enforcement.

## Implemented in this package
- `/super-admin/*` and `/anaira/super-admin/*` are Super Admin-only in the client route guard.
- Global Marketplace Settings and Global Booking Engine Settings have dedicated Super Admin routes.
- Global Integrations is linked from the Super Admin sidebar without exposing that route as the Business Admin integrations page.
- Business Admin no longer receives the Plugin Control Center menu.
- Booking transactions now allow Super Admin SELECT while preserving tenant isolation.
- Hotel settings write access is limited to Super Admin or Business Admin for the current tenant.
- User permission writes are limited to Super Admin or Business Admin for the current tenant.
- Platform-owned marketplace listing fields and store membership fields are guarded by database triggers for non-Super Admins.
- Plugin activation state is database-guarded as Super Admin-only while tenant plugin configuration remains tenant-scoped.
- Hotel marketplace availability now uses the canonical HMS availability function rather than the obsolete `booking_inventory` source.

## Intentionally not certified by this package
- Full browser E2E certification.
- Production deployment smoke test.
- External OTA provider adapters/live credentials.
- A complete canonical POS order/menu runtime was not invented because the supplied source does not contain a live POS master table; the existing marketplace-order data source remains a legacy integration until the POS runtime is migrated.
