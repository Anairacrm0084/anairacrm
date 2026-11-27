# Work 01 — Central Marketplace + Independent Property Stores

Date: 2026-11-27  
Scope: Source-level implementation on the supplied `components(2).zip` archive.

## Executive result

The supplied project already contained the core hospitality marketplace, property-specific customer journeys, Store Builder, hotel PMS, alternative-stay engine, camping engine and public property profile API. This work extends those components rather than replacing them.

Implemented in this work:

1. The Central Marketplace now defaults to **All Stays** and queries the five existing supported hospitality categories in parallel: hotel, camp, homestay, guest house and cottage.
2. A category RPC failure no longer discards successful category results. The UI displays the available results and reports partial category failures.
3. Every result is tagged with its source accommodation type and routes to its existing canonical property journey: `/property/[id]` for hotel/camp and `/stay/[type]/[id]` for homestay/guest-house/cottage.
4. The hotel/camp property storefront now loads its public profile and room/rate catalogue through the server-side public hospitality API instead of querying tenant-protected HMS tables directly from the anonymous browser.
5. The property storefront now applies the property's published, allowlisted branding settings (theme colors, announcement, gallery visibility and footer text).
6. Direct property-store publication is separated from Central Marketplace publication:
   - Direct property store: requires an enabled tenant store, enabled membership and `anaira_store_settings.published = true`.
   - Central Marketplace: continues to require the tenant store's `anaira_platform_stores.published = true`.
   - Global platform template stores are excluded from tenant property-store resolution.
7. Anonymous API responses expose only a presentation allowlist from `store_config`; draft store settings and arbitrary private configuration are not returned.

## Files changed

- `app/anaira/hotels/page.jsx`
  - Added All Stays search across the five existing hospitality RPCs.
  - Added resilient partial-result aggregation using `Promise.allSettled`.
  - Added per-result category-aware routing and rendering.
  - Updated marketplace copy and search labels to reflect ANAIRA STAYS.

- `app/property/[id]/page.js`
  - Reworked the Hotel/Camp property store to use the public server API.
  - Renders property identity, published rooms/rates, gallery, amenities and direct-booking CTA.
  - Applies the safe property-level theme and announcement configuration.
  - Preserves the direct booking attribution `anaira-property-store`.

- `app/api/public/hospitality/property/[id]/route.js`
  - Resolves only non-platform tenant stores.
  - Separates direct-store publication from central-marketplace publication.
  - Requires the direct store settings record to be explicitly published before exposing the direct storefront.
  - Returns only whitelisted public presentation settings.

- `tests/public-hospitality-storefront-static.mjs`
  - Updated assertions for the category-aware storefront routes.
  - Added checks for All Stays aggregation and independent store publication.

## Existing architecture preserved

- `/anaira/hotels` remains the central customer marketplace.
- `/property/[id]` remains the hotel/camp property-specific storefront.
- `/stay/[type]/[id]` remains the homestay/guest-house/cottage property-specific storefront.
- `/camping/[id]` legacy URLs continue to use the existing canonical booking redirect.
- `/store` remains the restaurant/food marketplace and is not repurposed for hospitality.
- Existing HMS, Stay and Camp inventory and reservation systems remain the operational sources of truth.
- No database migration was created or applied in this work.

## Verification evidence

| Check | Result |
|---|---|
| Public hospitality storefront static assertions | PASS |
| Homestay store routing regression | PASS |
| Property profile/sidebar admin regression | PASS |
| Booking runtime closure | 29 checks, 0 failures |
| JavaScript syntax scan | 740/740 PASS |
| Relative import verification | PASS, 0 failures |
| TypeScript/JSX transpile syntax for 3 changed source files | PASS |

## Not certified / remaining work

The following are not claimed as complete by this source-only patch:

1. Live Supabase RPC execution and live property records were not queried in this run.
2. Actual booking concurrency and cross-channel inventory synchronization require connected-database E2E tests.
3. Full Next.js production build was not run because `node_modules` is not present in the supplied archive.
4. Custom domain and subdomain provisioning/verification/SSL routing are not implemented by this work.
5. The current source's implemented hospitality categories are hotel, camp, homestay, guest house and cottage. Apartments, villas, hostels, farm stays, lodges, private rooms and shared rooms need explicit product/data-model support before they can be represented as verified searchable categories.
6. Property Store Builder's broader page-section editor, reviews, wishlist, recently viewed, and complete analytics still need end-to-end wiring and verification.
7. Central Marketplace publication remains separately controlled by the platform store's published state; this patch does not bypass Super Admin controls.

## Deployment notes

- Apply no migrations for this work; none were added.
- Run `npm ci`, then `npm run build` in the target environment.
- Run `npm run public-hospitality:check`, `npm run booking:runtime-check`, `node tests/regression/homestay-store-routing.mjs` and `node tests/regression/property-profile-sidebar-admin-static.mjs`.
- Verify the direct property's `anaira_store_settings.published` flag and the central marketplace `anaira_platform_stores.published` flag independently in the intended Supabase project before production release.
