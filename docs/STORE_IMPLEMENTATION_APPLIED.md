# ANAIRA Store Implementation Applied — 2026-09-24

## Platform stores
Exactly two Super Admin controlled platform stores remain:
- Hotel Store
- Restaurant Store

Business Admin only edits their own property store.

## Restaurant Store
- ANAIRA POS source
- External Software source via integration connection
- Manual Catalog source
- Store profile / branding / gallery / SEO
- Categories
- Menu items
- Images, discount price, veg/non-veg/egg, tags, prep time, tax, featured, availability
- Variants
- Add-ons
- Delivery / Pickup / Dine-in
- Minimum order, delivery fee, radius, tax, timings, payment method settings
- Offers / coupon codes
- Customer-facing marketplace UI with search, categories, item detail, cart and checkout
- Existing delivery order RPC remains the order capture boundary; POS remains operational owner.

## Hotel Store
- ANAIRA HMS/PMS source
- External Hotel Software source via integration connection
- Manual store source
- Store profile / branding / gallery / SEO
- Live HMS room availability bridge
- HMS reservation creation bridge
- HMS guest + CRM customer linkage
- HMS folio creation
- Public hotel store UI with date/guest search, room selection and booking capture

## Routing / safety
- Removed duplicate `[slug]` dynamic route groups that conflict with `[id]` routes.
- `[id]` routes resolve either UUID or public slug where applicable.
- Public stores verify the corresponding platform store is enabled/published and the property is listed.
- No Hotplot branding added; public branding is ANAIRA.

## POS boundary
Anaira POS remains the canonical restaurant operational source. Store catalog/ordering does not replace the existing POS engine.

## Verification
- Live Supabase migrations for store catalog/settings and HMS booking bridge were applied successfully.
- Live tables confirmed: `anaira_store_categories`, `anaira_store_item_variants`, `anaira_store_item_addons`, `anaira_store_settings`, `anaira_store_offers`.
- Full Next.js production build was not completed in this environment because `npm install` exceeded the execution timeout; do not treat this ZIP as build-certified until `npm install` and `npm run build` are run locally.
