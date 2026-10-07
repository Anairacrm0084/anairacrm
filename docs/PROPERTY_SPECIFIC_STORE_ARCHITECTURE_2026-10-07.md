# Anaira V18 — Property-Specific Store Identity

- Existing Hotel Store / Restaurant Store rows remain Super Admin platform/template stores.
- Every property gets its own real store row with `restaurant_id` and `is_platform_store=false`.
- Store memberships/settings/presentation data remain scoped by the exact property store.
- Business Admin Store Builder now resolves/provisions the exact property store.
- Customer `/store/[id]` accepts the new store UUID and remains backward-compatible with a property UUID.
- Restaurant marketplace API resolves the exact property store.
- Hotel Setup and Super Admin property store settings resolve the property's own store.
- Existing tenant memberships are backfilled from global platform stores to property stores.

Property A → Store A → A-only data
Property B → Store B → B-only data

The migration is additive and keeps the existing global platform stores intact.
