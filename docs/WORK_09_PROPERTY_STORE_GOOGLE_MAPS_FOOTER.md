# WORK 09 — Property Store Google Maps Footer Setting

## Requirement
Add a Google Maps URL field in Store Builder so each property can configure its own exact map location. The property storefront footer should open that saved location and display an embedded map.

## Implemented
- Added `Google Maps Link` input to Store Builder's `Luxury Property Store — Design & Content Settings` section.
- Supports HTTPS Google Maps share/place URLs, including `maps.app.goo.gl` short links.
- Loads and saves the setting in the existing tenant-scoped `anaira_store_memberships.store_config.google_maps_url` JSON field.
- No database column or migration required.
- Public hospitality API now exposes only a validated HTTPS Google Maps URL from the published store config; arbitrary external hosts are not returned.
- Fixed the storefront config response key: the page now reads `public_store_config` (the actual API response property), so published property theme and location settings are applied.
- Footer's location link opens the configured Google Maps URL. If no custom link is configured, it falls back to an address-based Google Maps search.
- Added a responsive embedded Google Map to the property footer. For short share links, the embed uses the property's address/name while the clickable link opens the exact shared map location.
- The map respects the existing `Show location details` toggle.

## Verification
- Property Store Google Maps settings: 9/9 PASS.
- JavaScript syntax: 751/751 PASS.
- Relative imports: PASS, zero failures.
- Public hospitality storefront static checks: PASS.
- Booking runtime: 29/29 PASS.
- ZIP integrity: PASS.

## Data and deployment safety
- No Supabase migration required.
- No existing booking, payment, room, rate, or inventory data modified.
- Google Maps URL is saved in the existing store configuration JSON for the current tenant/property.
- Full Next.js production build and live browser verification were not run because the extracted project does not contain `node_modules` and no production browser session is available.

## How to use
1. Open `/store-builder` as the property admin.
2. Select the relevant Hotel/Camping/Homestay/Guest House/Cottage store.
3. Open **Luxury Property Store — Design & Content Settings**.
4. Paste the property's Google Maps share link into **Google Maps Link**.
5. Save Luxury Store Settings and open Preview Property Store.
6. Scroll to the footer: the address opens the configured Google Maps location and the map is embedded below the footer content.
