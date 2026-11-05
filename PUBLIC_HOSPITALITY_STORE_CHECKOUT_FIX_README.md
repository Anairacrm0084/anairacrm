# Anaira CRM — Public Hospitality Store & Guest Checkout Fix

## Included changes

1. Added `GET /api/public/hospitality/property/[id]`.
   - Uses the server-side Supabase service client to load public-safe property profile data.
   - Requires an active property and a published landing page or a published direct-stay record.
   - Selects an enabled, published platform store matching the property's hospitality type.
   - Returns the published membership listing override, including its cover image, logo and gallery.
   - Does not expose payment credentials or the membership `store_config`.

2. Updated `/book/[id]` to use the public profile API for membership, store and HMS profile enrichment.
   - Public visitors no longer depend on browser access to private membership/HMS settings tables.
   - Hero cover image falls back through listing override, platform store, camping/HMS profile, and gallery.

3. Updated guest checkout.
   - Camping OTP requests identify `property_type: camp`.
   - Availability must return a positive result before the browser starts a booking.
   - The database booking RPC remains the final authority for inventory, capacity, rate and verified-contact checks.

4. Camping OTP issuance checks that the camping property is active and marketplace-visible.

## Environment requirement

The server route uses `adminDb()` and therefore requires `SUPABASE_SERVICE_ROLE_KEY` in local `.env.local` and Vercel Production Environment Variables. Keep this key server-side only; do not prefix it with `NEXT_PUBLIC_`.

## Validation performed

- Node syntax checks passed for new API route, OTP route, booking-start route and public property resolver.
- TypeScript parser JSX checks passed for the three modified client pages.
- Public hospitality static checks: 21/21 passed.
- ZIP integrity check passed.

A full `next build` and a real browser-to-database booking E2E were not run in this environment. OTP delivery additionally requires working Resend or Twilio credentials.
