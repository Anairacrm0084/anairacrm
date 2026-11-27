# WORK 15 — Camp calendar pricing / payment / luxury confirmation

## Findings (source audit, not live DB verification)

- The checkout used `/api/public/booking/premium/quote` for legacy camping units, which invokes the HMS premium quote function; the camping booking RPC used `camp_rate_plans.rate` and weekend rate. These are different rate sources. This explains why the selected plan can show ₹1,000 while the quote shows ₹7,000.
- The HMS bulk rate calendar is `hms_daily_rate_calendar`, updated by `anaira_bulk_set_daily_rate`; the legacy camp booking RPC does not consult it.
- The checkout auto-submitted Pay at Property during Confirm Booking, skipping the requested payment selection step.
- `₹3,500` in a bulk calendar is not necessarily a total stay price: `per_person` for two adults means ₹7,000 before other adjustments. If ₹3,500 is the **entire tent for two people**, the rate plan must be configured `per_unit`, with the relevant `double_rate` set to 3500. Do not silently change rate-plan semantics or previously issued bookings.

## Source changes

1. `components/booking/HotelBookingCheckout.jsx` — use dedicated camp calendar quote endpoint; reset availability on guest/date changes; show step 2 payment selection only after Confirm Booking; remove auto-submission; luxury success / pending-approval page; safe rate mismatch guard; define WhatsApp contact; dynamic displayed rate.
2. `app/api/public/booking/camp/quote/route.js` — rate-limited server-only calendar quote endpoint.
3. `app/api/public/booking/start/route.js` — use atomic calendar-aware camp booking wrapper.
4. `supabase/migrations/20261128_camp_calendar_quote_booking_parity.sql` — new camp quote RPC + atomic wrapper updating new reservation and transaction amount; does not touch existing reservations or inventory.
5. `app/booking-engine/page.js` — Print Invoice action after payment.
6. `app/api/booking/invoice/[id]/route.js` — authenticated PDF invoice route with correct path architecture; relies on existing `anaira_issue_hms_reservation_invoice` RPC.

## Important deployment / database prerequisites

- This is a **ZIP built from the last available local Work 14 source snapshot** with Work 15 edits. It is **not a verified byte-for-byte snapshot of the latest GitHub main**; do not overwrite later commits wholesale. Merge changed files with the latest main and review any conflicts.
- Supabase connector currently provides metadata/list_tables but no SQL execution or apply-migration capability. **The migration was NOT applied to live Supabase.** Run it in the correct project only after reviewing live rate-plan mapping and SQL function definitions. No production pricing change is claimed.
- GitHub connector returned 403 on writes to `Anairacrm0084/anairacrm` in the previous attempt. **No Work 15 commit or Vercel deployment is claimed.**
- Inspect the affected tenant `3f2cc4ae-f4d9-4123-8db9-30d861adb624`, legacy camp unit `6af78017-0b43-49bf-85bf-3cb493a7f435`, plan `dc7683f4-74b1-49b1-b752-f44ff0b78bb0`, stay 2026-11-28 → 2026-11-29, 2 adults. Check HMS canonical unit/rate mapping, `pricing_mode`, calendar `single_rate` and `double_rate`, and compare final quote and booking amount.
- New camp quote intentionally fails on ambiguous canonical HMS mapping. Verify correct mapping before enabling public bookings.
- Booking confirmation remains **pending property approval** after Pay at Property for camp; the guest-facing page does not claim confirmation prematurely.
- Full payment gateway / real email / tax invoice end-to-end verification was not run.

## Local tests

- JavaScript syntax 756/756 PASS.
- Relative import audit PASS.
- Booking runtime static closure 29/29 PASS.
- Booking confirmation + marketplace static assertions PASS.
- Public hospitality storefront static assertions PASS.
- Full Next.js production build and live RPC test NOT run (node_modules and live SQL access unavailable).

## Recommended safe rollout

1. Compare migration with current live function definitions and verify mapping; review whether ₹3,500 is per person or per tent.
2. Apply reviewed migration to a staging Supabase project and test `anaira_calculate_camp_calendar_quote` for the affected dates and guest count.
3. Merge source edits into the latest GitHub main; do not replace newer main with the Work 14 snapshot.
4. Run `npm ci && npm run build`, verify quote = booking transaction amount, and test the three-step flow without creating duplicate bookings.
5. Deploy to Vercel preview, verify guest confirmation, invoice and admin approval, then promote production.


## Work 16 — Manual WhatsApp confirmation PDF sharing

- Added an `Open WhatsApp & Attach PDF` action to the approved booking confirmation page.
- Reads the guest mobile number from the authenticated booking confirmation payload; normalizes a 10-digit Indian number with country code 91.
- Fetches the same authenticated confirmation PDF endpoint, downloads the PDF locally, and opens the guest chat with a prefilled message.
- WhatsApp Web does not permit a normal `wa.me` URL to silently attach or send a PDF. The operator must attach the downloaded PDF and press Send. This is manual sharing, not WhatsApp Business API automation.
- This source package is not a claim of production deployment. The latest Vercel deployment was QUEUED at packaging time.
