# Anaira Public Hospitality Store & OTA Control Center Patch

## Changes in this patch

1. `/store/[id]` now resolves a published `anaira_platform_stores` record by public slug before running the legacy restaurant-store lookup.
2. Published camp store links redirect to `/camp/<restaurant_id>`; published hotel/homestay/guest-house/cottage links redirect to `/hotel/<restaurant_id>`. This separates public customer URLs from admin authentication routes.
3. `/ota` is now a property-scoped OTA Control Center listing Booking.com, Expedia Group, Agoda, Airbnb, MakeMyTrip, Goibibo, Trip.com, Hostelworld, Google Hotel Ads, SiteMinder and STAAH.
4. OTA directory records can be added to the existing `ota_channels` table with status `not_connected`, `auto_sync=false`, and a setup-only settings payload. The UI explicitly does not claim that adding a channel creates a live integration.
5. Existing syntax checker passed after edits (`node scripts/verify-js-syntax.mjs`, 332/332).

## Verified live database observations

- `NH3 Camping` and `Raghupur Roots Camp and Cafe` exist as active `restaurants` records with `hospitality_type='camp'`.
- Their platform stores were set to `enabled=true` and `published=true`.
- `camp_properties` was activated/created for the two records.
- Current counts in `camp_unit_types`, `camp_rate_plans`, `camp_inventory` and `camp_reservations` were zero for both camps at the time checked. Therefore no actual bookable unit/rate/availability was fabricated.
- `ota_channels` and `anaira_ota_sync_queue` were empty at the time checked. No live OTA credentials or partner connections were supplied.
- RLS policy `anaira_platform_stores_public_read` permits public SELECT only for enabled and published stores, supporting public slug resolution.

## Still required before production booking/OTA certification

- Add the real camping unit/tent types and prices, then generate date-wise inventory for each camp. Do not use guessed prices or quantities.
- Verify public RLS/SECURITY DEFINER functions for camping availability, OTP verification, booking hold/finalization, and payment proof.
- Run anonymous-browser end-to-end tests against the deployed app, including duplicate booking protection and inventory decrement.
- Add provider-approved credentials through server-side secret storage and implement each OTA API/webhook contract. Channel directory records are not live OTA integrations.
- Run a production build with installed dependencies and deployment environment variables; this patch has only passed the repository JavaScript syntax checker.
