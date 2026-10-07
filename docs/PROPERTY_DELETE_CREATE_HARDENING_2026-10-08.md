# Property Delete + Create Hardening — 2026-10-08

## Delete
- Super Admin deletion remains email-confirmed and authenticated.
- Tenant-owned storage objects are removed before Auth cleanup.
- Canonical `anaira_hospitality_properties_master` rows are explicitly removed before the tenant.
- Legacy `anaira_hotel_properties` rows are explicitly removed before the tenant.
- `anaira_marketplace_bookings.property_id` and `anaira_marketplace_orders.restaurant_id` are hardened to `ON DELETE CASCADE`.
- The tenant `restaurants` delete remains the final data-engine deletion point; tenant FKs using `CASCADE` remove related operational, booking, HMS, store, CRM-bridge and integration data.

## Create
- Existing `anaira_sync_business_capabilities()` creates/updates the canonical hospitality property master from `restaurants` on hotel business creation/update.
- Store membership and booking-engine settings are created/reused through the same tenant lifecycle.
- Property store identity is resolved through the hardened property-store RPC, preventing duplicate global/platform store creation.

## Legacy cleanup
The migration removes the two known orphaned NH3 hospitality-master records and the known legacy `anaira_hotel_properties` row whose parent tenant no longer exists.
