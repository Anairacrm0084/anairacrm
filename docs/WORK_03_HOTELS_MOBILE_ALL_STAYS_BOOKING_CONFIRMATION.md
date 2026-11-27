# Work 03 — ANAIRA Hotels Mobile Hero, All Stays, Property Store Routing & Booking Confirmation

**Status:** Source implementation complete; static/regression checks pass. Production build and live guest checkout E2E remain unverified in this environment.

## Implemented

### 1. Mobile hero media
- Fixed the hero media container condition so a mobile-only hero image or video creates the media wrapper even when the desktop hero image is empty.
- Mobile image falls back to the desktop image when a separate mobile image is not configured.
- Kept the desktop and mobile media variants separate so the mobile CSS visibility switch can work as intended.
- Added a compact horizontally scrollable stay-category rail for small screens.

### 2. All Stays marketplace
- The All Stays search continues to query all five categories in parallel: Hotel, Camping, Homestay, Guest House and Cottage.
- Results are grouped by category and canonical property identity, producing one card per property rather than repeated room/unit-level cards.
- Hotel availability and camping/stay unit counts are normalized for the card UI.
- Simplified the default marketplace layout by hiding long editorial/about/statistics/workflow/technology sections unless explicitly enabled in platform settings.
- Updated the default subtitle and CTA to represent all accommodation types.

**Important live database finding:** The marketplace approval gate is working. On the live project, the current search window returned 2 Camping results and 0 Hotel, Homestay, Guest House or Cottage results. The Homestay `Home By (Justin)` has its direct property store published, but its central marketplace store remains `pending` and unpublished. Other property stores are also pending approval or unpublished. This patch does not bypass the Super Admin approval gate or publish draft properties automatically. Approve/publish the intended listings in `/super-admin/property-stores` for them to appear in Global Marketplace.

### 3. Direct property store routing
- Store Builder's customer preview now opens `/property/{restaurant_id}?stay_type={type}` directly.
- Removed the generic `/book/{id}` detour from the Store Builder preview.
- Removed the new-tab behavior from the main Open Property Store links so the admin goes directly to the selected property storefront.

### 4. Booking confirmation page and PDF
- After a successful booking approval in both Booking Engine Reservation Control Center and Hotel Booking Admin, the admin is redirected to `/booking/confirmation/{reservation_id}`.
- Added tenant-authorized confirmation API using the signed-in admin session and the property's tenant ID.
- Added accommodation name resolution for hotel room types, camping unit types, and canonical ANAIRA Stay unit types.
- Added fallback labels for legacy camp/HMS reservations where the HMS room type reference is not populated, instead of displaying “Accommodation not set”.
- Confirmation page displays booking reference, reservation UUID, property, accommodation, guest, dates, occupancy, payment and balance details.
- Added a downloadable A4-style booking confirmation PDF. PDF download is available only when reservation status is `confirmed`.

## Files added
- `lib/server/bookingConfirmation.js`
- `app/api/booking/confirmation/[id]/route.js`
- `app/api/booking/confirmation/[id]/pdf/route.js`
- `app/booking/confirmation/[id]/page.jsx`
- `tests/booking-confirmation-and-marketplace-ui-static.mjs`

## Files updated
- `app/anaira/hotels/page.jsx`
- `app/store-builder/page.js`
- `app/booking-engine/page.js`
- `package.json`

## Verification
- JavaScript syntax scan: 748/748 PASS
- Relative import validation: PASS, 0 failures
- Booking confirmation + marketplace UI static assertions: PASS
- Public hospitality storefront static assertions: PASS
- Homestay routing regression: PASS
- Property profile/sidebar admin regression: PASS
- Booking runtime closure: 29/29 PASS

## Not verified
- Full Next.js production build was not run because this extracted project has no `node_modules` directory.
- No live guest booking or email-provider E2E test was run.
- No database migration was required or applied for this source-only patch.
- Pending/unpublished marketplace listings remain hidden until explicitly approved and published by Super Admin.
