# Anaira Camping, Public Store and OTA Implementation

## Changes in this package

1. **Store Builder tenant resolution**
   - Uses the authorized `anaira_store_builder_resolve` RPC first.
   - If that RPC is unavailable or fails, it uses a tenant-scoped query filtered by `restaurant_id`, `store_type`, and `is_platform_store=false` and returns at most one row.
   - It never uses an unscoped `.maybeSingle()` against all platform stores, avoiding the `JSON object requested, multiple (or no) rows returned` failure mode.

2. **Public guest booking paths**
   - Hospitality stores use `/book/{restaurant_id}?stay_type=camp` (and the corresponding stay type for hotels/homestays/etc.).
   - Existing booking start API requires verified guest contact and routes to the correct hotel/camp/stay RPC.
   - Fixed camping checkout's Back links to return to `/camping/{restaurant_id}` instead of the nonexistent `/camp/{restaurant_id}` path.
   - No customer account is required by the public guest booking UI; phone/email OTP verification is retained.

3. **OTA & Channel Manager page**
   - Replaced the generic OTA page entry point with a property-scoped Channel Manager.
   - Includes Booking.com, Expedia Group, Agoda, Airbnb, MakeMyTrip, Goibibo, Trip.com, Hostelworld, Google Hotel Ads, SiteMinder and STAAH.
   - Adds channel register creation, status visibility, auto-sync preference, room/tent and rate mapping forms, and sync event visibility.
   - New channel records are explicitly marked as pending credentials/not connected. The UI does not claim live API connectivity or successful sync until provider credentials and adapters exist.
   - Secrets must not be stored in browser code or plain JSON settings.

4. **Supabase migration**
   - Adds public read policies for active/published camp profiles and active unit/rate catalog rows.
   - Backfills camping profile records from existing restaurant records without overriding populated operator data.
   - Adds OTA channel compatibility columns and tenant-scoped RLS policies.
   - Does **not** invent tent counts, prices, or date inventory.

## Required deployment steps

1. Apply `supabase/migrations/20261024_public_camping_store_ota_hardening.sql` to the intended Supabase project after reviewing it in staging.
2. Deploy the updated Next.js project.
3. In Hotel Management, select the Camping property type and configure real tent/unit types, rates and date-wise inventory for each camp. The previous database audit showed zero active camping units, rate plans and inventory days, so bookings cannot be completed until the operator supplies these values.
4. Test each public `/book/{property-id}?stay_type=camp` URL in a private/incognito browser window, without an admin session.
5. Configure OTP delivery provider credentials and test send/verify/expiry/rate-limit behavior.
6. For each OTA, obtain partner/API access and configure a server-side provider adapter before marking the channel connected or enabling real sync.

## Validation performed

- `node scripts/verify-js-syntax.mjs`: 726/726 passed.
- `node scripts/verify-relative-imports.mjs`: passed with no missing relative imports.
- `node scripts/booking-runtime-closure.mjs`: passed 29/29 checks.
- TypeScript transpile syntax check passed for changed JSX/JS entry points.
- A full Next.js production build and live guest/OTA E2E test were not run in this workspace because project dependencies and production provider credentials are not present.
