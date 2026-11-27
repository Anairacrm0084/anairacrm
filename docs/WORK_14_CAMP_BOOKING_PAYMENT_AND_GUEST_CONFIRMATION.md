# WORK 14 — Camping Booking Finalization, Inventory and Guest PDF

## Live Supabase audit
- Project `bhptqdoteucuymmdzsmg` is `ACTIVE_HEALTHY`.
- Property `NH3 Camping` (`3f2cc4ae-f4d9-4123-8db9-30d861adb624`) is active.
- The matching `camp_properties` row is active and marketplace-visible.
- Active accommodation: `2 Man Tent` (`6af78017-0b43-49bf-85bf-3cb493a7f435`).
- Two active rate plans exist: `Tent Only` (INR 1,000, per person) and `With Breakfast` (INR 1,300, per person).
- Camp inventory rows exist for the requested dates; the unit has 1 total unit.
- The recent test attempt `ANC-EB70AC4FF0` was inserted successfully for 2026-11-27 to 2026-11-29, amount INR 4,000. It was initially `payment_pending`; a later read showed it `cancelled` / transaction `rejected` and its hold `released`. It is not a confirmed booking and no active hold remains from that attempt.

## Root cause found
- Public booking start correctly creates camping reservations in `camp_reservations`.
- The generic payment API incorrectly looked up every booking in `booking_reservations` and called `anaira_submit_hotel_payment`, which only updates `hms_reservations`.
- Thus camp reservation creation could succeed, but the subsequent camp payment/finalization step could not find or update the camp reservation.
- The existing database function `anaira_finalize_public_camp_booking` already implements the camp-specific finalization lifecycle, including consuming the inventory hold and moving the camp reservation to confirmed. It was not wired into the public payment API.
- Vercel Production deployment was `READY`, with `crm.anairapos.in` listed as an alias. No Vercel runtime error clusters were returned in the inspected window. The browser-native error itself could not be reproduced from this network environment.

## Implemented
- Added a camp-specific branch to `/api/public/booking/payment`.
- The API looks up the reservation in `camp_reservations` using exact booking code + property ID, validates the guest's previously verified OTP challenge and matching phone/email, then calls the existing `anaira_finalize_public_camp_booking` RPC.
- `Pay at Property` is mapped to `pay_at_camp` for camping; bank transfer / QR continue to require an uploaded proof.
- For the default `Pay at Property` choice, clicking the guest's first `Confirm Booking` button now creates and immediately finalizes the camp reservation, then displays the confirmation screen.
- Confirmation screen now shows booking reference, reservation UUID, accommodation, dates, total and payment status.
- Added guest-authorized PDF endpoint `/api/public/booking/confirmation/pdf`; it validates booking code, property, guest contact and OTP verification before returning the confirmation PDF.
- Added one safe retry for transient start API failures using the same idempotency key, so a committed booking can be recovered without creating a duplicate.
- Added robust client error handling for booking and payment fetches.

## Database safety
- No schema migration was required; the existing `anaira_finalize_public_camp_booking` RPC was reused.
- No existing reservation was modified by this source patch.
- The inspected test reservation was already cancelled/released by the time of the final read; this patch did not change it.

## Tests
- Camp public booking finalization checks: 10/10 PASS.
- JavaScript syntax: 754/754 PASS.
- Relative imports: PASS.
- Booking runtime closure: 29/29 PASS.
- Public hospitality storefront: PASS.
- `/book` checkout route preservation: PASS.
- Booking confirmation / marketplace UI: PASS.
- ZIP integrity: PASS.

## Not run
- Full Next.js production build and browser visual QA were not run because this extracted project has no `node_modules` directory.
- No live OTP/payment-provider end-to-end booking was performed, to avoid creating another reservation or payment.

## Production verification required
- Deploy the updated source to Vercel Production.
- Then test one new booking: OTP → Confirm Booking → confirmed reservation → PDF download.
