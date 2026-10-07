# Property Store Duplicate Slug Fix — 2026-10-07

Fixed the property Store Builder resolution path so an existing tenant/property store is resolved before the provisioning RPC is called. This prevents Save/Reload flows from attempting to create a second `anaira_platform_stores` row for an existing property.

## Changes

- `app/store-builder/page.js`
  - Added `resolvePropertyStore()`.
  - Existing property store is selected by `restaurant_id + store_type + is_platform_store=false` before provisioning.
  - Provisioning RPC is now only used when the property has no store.
  - Existing store identity is reused for all subsequent Store Builder operations.

- `supabase/migrations/20261007_property_specific_store_identity.sql`
  - Property-store provisioning uses a full UUID-derived slug.
  - Existing property store is returned immediately.
  - Unique-violation race is handled safely.
  - A true cross-tenant slug collision receives a UUID-suffixed fallback.

## Live verification

NH3 existing hotel store remains:

- Store ID: `124f0586-8546-40c3-ad0e-14cbba802bdd`
- Slug: `nh3-f65cde1a`
- Enabled: `true`
- Published: `true`

Calling `anaira_ensure_property_store()` for NH3 returned the same existing store ID instead of inserting another store.
