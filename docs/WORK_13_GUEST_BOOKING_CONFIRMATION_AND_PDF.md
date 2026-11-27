# WORK 13 — Guest Booking Confirmation Screen + PDF

## What changed
- Kept the existing phone/email OTP verification flow and booking/payment sequence.
- Immediately after OTP verification and successful reservation creation, checkout now shows a reservation-created/booking-confirmed panel before the payment step.
- This first panel displays the booking reference and reservation ID and offers a booking confirmation PDF download.
- After payment submission succeeds, checkout shows a full guest-facing result screen with booking state, booking reference, reservation ID, property, accommodation, guest, stay dates, guest count, total, payment status, and PDF download.
- Added guest-safe PDF endpoint: `POST /api/public/booking/confirmation/pdf`.
- The PDF endpoint requires both booking reference and guest phone, uses the existing `anaira_public_booking_lookup` RPC (also used by the public payment endpoint), and is rate-limited.
- PDF labels the actual booking/payment status; pending payment is not falsely labelled confirmed.
- Improved booking-start response handling so RPC-level error payloads are not treated as successful reservations.

## Route behavior
- Checkout URL remains `/property/{id}/checkout` or `/book/{id}/checkout`, according to the route used.
- No redirects were added.
- OTP verification, booking creation, and payment submission endpoints remain in place.

## Tests
- Added `npm run booking:guest-confirmation-check`.
- Static verification covers the immediate reservation panel, guest confirmation screen, public lookup inputs, PDF response headers, booking reference, and reservation ID.

## Safety / limitations
- No database schema changes or migrations.
- No existing booking, payment, rate, or inventory data was modified.
- A real OTP, payment provider, and live Supabase booking test still needs to be run in the deployed environment.
- The screenshot's browser-native “This page couldn't load” screen is a network/hosting-level error, not an application confirmation component. Deploy this patch and retest; if it persists, inspect hosting deployment, DNS/TLS, and runtime logs.
