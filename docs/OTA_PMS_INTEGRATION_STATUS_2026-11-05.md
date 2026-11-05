# Anaira OTA → PMS Integration Status (2026-11-05)

## Implemented in this source update
- Super Admin can choose a property from the `/ota` screen; channel, mapping, event and inbox queries are scoped to that property.
- `/ota` now includes an Incoming OTA Reservations inbox with room/rate mapping and explicit PMS import / modification actions.
- The inbox process API requires a valid Supabase user session and verifies tenant access before invoking the privileged database function.
- OTA reservations are normalized, validated and deduplicated by `(restaurant_id, provider_code, external_reference)`.
- External room/rate codes are mapped to Anaira room/rate records and reused for subsequent webhook reservations.
- PMS import creates the guest/CRM link, confirmed HMS reservation and folio; it refuses import if room mapping or inventory is unavailable.
- Cancellation webhook events automatically cancel a linked HMS reservation. Modification events are held for an explicit review/apply action.
- Webhook routing no longer broadcasts one provider event to every tenant connection. Multiple connections require a unique provider account/property reference match.
- The PMS reservation inventory trigger remains the single source of truth; duplicate manual inventory increments are removed.
- Privileged `anaira_process_ota_reservation` RPC execution is granted only to `service_role`; the API route authenticates and authorizes the tenant first.

## Verification
- OTA reservation normalization tests: PASS (11 assertions).
- OTA inbox/PMS static integration tests: PASS (14 assertions).
- OTA provider configuration guard: PASS (3 assertions; local mock transport only).
- Changed API route JavaScript syntax checks: PASS.
- OTA manager JSX parse: PASS.
- Hosted Supabase migration and RPC permission checks: PASS.

## External production gates still required
- Booking.com / Expedia / Agoda / MakeMyTrip connectivity approval and account credentials.
- Provider-specific API contract details, webhook signature scheme, account/property identifiers, room/rate identifiers and sandbox test credentials.
- The existing generic REST transport is not a certified Booking.com Connectivity API adapter. Do not enable production auto-sync based on a generic endpoint health check.
- Run the Next.js production build in the project environment after installing the pinned dependencies; `node_modules` is not included in this source archive.
