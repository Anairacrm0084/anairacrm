# Anaira Booking Engine A-to-Z Audit — 2026-11-05

## Scope
Reviewed the supplied Anaira CRM source ZIP and its hotel/camping booking routes, admin pages, payment routes, inventory RPCs, and hospitality migrations. The working package is based on the supplied `Anaira_CRM_Camping_Approval_HMS_Sync_Fix_20261105.zip` and retains its existing project files/migrations.

## Confirmed gaps in the supplied source
1. `app/booking-engine/page.js` Reservation Control Center was list-only: it had no approve, reject, cancel, or payment collection actions.
2. `app/hotel-management/page.js` rendered a Confirm action but sent it to `anaira_hms_reservation_transition`; that RPC does not implement `confirm`. The actual `anaira_hotel_confirm_reservation` RPC existed.
3. `app/HotelBookingAdmin.js` contained advance/full-payment UI but was not mounted by any route. It could not serve as the active control center.
4. Camping approval UI exposed Verify Payment but had no partial-payment collection UI.
5. The unified Booking Engine loaded `hms_reservations` and `camp_reservations` independently, so a camping booking linked to an HMS reservation could appear twice.
6. The existing hotel confirmation RPC did not consume its checkout inventory hold. Active holds could therefore continue reducing availability after confirmation, and the no-hold confirmation path did not subtract other active holds.
7. The hotel payment ledger already exists (`hms_payments`) and the hotel advance/full-balance RPCs already exist; the UI was simply not exposing them in the main Booking Engine Control Center.

## Implemented in this package
- Added Approve / Reject / Cancel actions to the unified Reservation Control Center.
- Added Add Payment modal with partial payment and Collect Full Balance, method, reference, optional proof URL, and notes.
- Hotel approval calls the existing `anaira_hotel_confirm_reservation` RPC.
- Camping approval calls the existing `anaira_admin_manage_camp_reservation` RPC.
- Hotel payments call the existing `anaira_record_hotel_advance` RPC.
- Camping payments use a new secure `anaira_admin_record_camp_payment` RPC, which records the payment in `hms_payments` and synchronizes camp reservation, linked HMS reservation, folio, and transaction balance.
- Fixed Hotel Management's Confirm button to call the existing confirmation RPC rather than the unsupported transition action.
- Added a route from Camping reservations to the unified Reservation & Payment Control Center.
- Deduplicated the linked camping/HMS row in the unified list.
- Added migration `20261105000400_booking_engine_approval_payment_inventory_closure.sql`:
  - commits the hotel inventory hold only on admin confirmation;
  - validates active holds and prevents confirming against an expired hold;
  - checks other active holds for manual/no-hold reservations;
  - reconciles sold inventory after confirmation;
  - adds tenant-scoped camping payment ledger support.
- Added migration `20261105000410_booking_engine_property_context_and_hold_recovery.sql`:
  - adds a tenant-authorized hotel inventory revalidation RPC;
  - reuses a still-valid hold or checks all stay dates and creates a fresh temporary hold;
  - expired reservations return to inquiry only after a fresh hold is successfully acquired;
  - does not approve the booking or increment sold inventory.
- Fixed Property Admin property context in `app/booking-engine/page.js`: fetches the assigned restaurant row and displays its name as a read-only label; only Super Admin receives a selectable property dropdown.
- Added `Recheck Inventory` action for pending hotel reservations; it requests a fresh hold before the admin can approve an expired-hold booking.

## Inventory lifecycle
- Public hotel booking creation creates an `inquiry` reservation and a temporary inventory hold. That hold protects against concurrent overbooking; it is not a sold room.
- Admin approval consumes the hold and reconciles `hms_inventory.sold_rooms`.
- Camping public booking creates a temporary `camp_inventory_holds` hold. Admin approval consumes it and increments `camp_inventory.sold_units`.
- Rejection releases a pending camping hold. Hotel cancellation uses the existing hotel cancellation RPC and inventory reconciliation.
- Payment collection is separate from approval. A confirmed booking can remain partially paid with a balance due.

## Validation performed
- Booking runtime closure static checks: 29/29 PASS.
- P2 hotel booking static checks: 10/10, status FOUNDATION (not production certification).
- JavaScript syntax: 732/732 PASS.
- Relative import checks: PASS.
- Property Admin context and expired-hold revalidation are packaged in migrations/source; live Supabase deployment is not claimed.
- JSX/TSX parser checks for the 3 modified pages: PASS.
- Production build: NOT run because this ZIP has no installed `node_modules`.
- Browser E2E / live reservation lifecycle: NOT run. No production booking or inventory row was mutated as part of this audit.

## Required deployment steps
1. Verify migration history, then apply `20261105000400_booking_engine_approval_payment_inventory_closure.sql` followed by `20261105000410_booking_engine_property_context_and_hold_recovery.sql` (the earlier camping approval migration `20261105000300_camp_reservation_admin_approval_hms_sync.sql` is a dependency if it is not already deployed).
2. Deploy this source ZIP.
3. Run a staging booking: create -> pending approval/hold -> approve -> confirm sold inventory -> record partial payment -> record final payment -> verify zero balance -> cancellation/refund test in staging.
4. Do not test by mutating a live guest booking without explicit property-owner approval.

## Limitations
This is a focused A-to-Z audit of the hotel/camping reservation, approval, payment, and inventory integration surfaces, not a certification that every one of the CRM's 1,100+ files or every unrelated module is production-complete.


## Follow-up correction — 2026-11-05 (screenshot mismatch)

- Reservation Control Center now displays the `Recheck Inventory` action for every pending hotel **and camping** reservation, plus expired reservations in either domain.
- The action dispatches to the correct domain-specific RPC: hotel -> `anaira_admin_revalidate_hotel_booking_inventory`; camping -> `anaira_admin_revalidate_camp_booking_inventory`.
- Added migration `20261105000420_camp_booking_inventory_revalidation.sql`. It validates every camping stay date under inventory row locks, releases any stale held units for that reservation, creates a new temporary hold, and updates the transaction pointer. It does not approve the booking or increment sold units.
- The Booking Engine clears prior error/success banners when a fresh data load begins and renders only the current error or success message. Removed a duplicate success banner.
- Expired camping reservations are now eligible for the explicit recovery action, subject to server-side status, payment, date, tenant and capacity checks.
- Re-validation is not approval. The admin must still click Approve; only the approval RPC consumes the hold and updates sold inventory.
- Re-ran static checks after this correction: JavaScript syntax 732/732 PASS; relative imports PASS; booking runtime closure 29/29 PASS.
- Live database deployment and browser E2E remain unverified. Apply migration 00420 after its dependencies, then test with staging bookings.


## Follow-up correction — Front Desk check-in / Room ID (2026-11-05)

- Root cause: `app/hotel-management/page.js` asked the operator for a raw database Room ID (UUID), although the screen displays human-readable room/tent numbers such as `0001`.
- The client called `anaira_hms_reservation_transition` with the intended parameter names, but the deployed Supabase schema cache reported that this RPC signature was unavailable. The package had a historical transition function without a `check_in` branch; therefore the UI action and backend lifecycle were not aligned.
- UI now lists clean, available room/tent numbers and asks the operator to enter the visible number. It resolves that number to the corresponding room UUID before calling the RPC.
- Added migration `20261105000430_hms_checkin_room_assignment_and_rpc_fix.sql` to install/replace the exact RPC signature expected by the UI, with tenant authorization, reservation status validation, property/hospitality-type validation, room availability/housekeeping checks, idempotency guard against a second active stay, `hms_stays` creation, reservation room assignment, room occupancy/housekeeping update, and folio creation when missing.
- Check-out checks outstanding balance, closes the active stay, marks the room/tent dirty and creates a housekeeping task. Room move validates the destination and updates the active stay.
- For the screenshot's Camping property, the operator should select the available tent number (e.g. `0001`), not enter a UUID. The backend stores the UUID.
- Validation after this patch: JavaScript syntax 732/732 PASS; relative imports PASS; booking runtime closure 29/29 PASS.
- Production build, live migration application and browser E2E remain pending. Apply migration 00430 after prior booking migrations, then test check-in/check-out in staging.


## Follow-up correction — unsupported hms_rooms.guest_name column (2026-11-05)

- Screenshot error `column "guest_name" does not exist` is caused by the newly added check-in RPC attempting to write `guest_name` on `hms_rooms`. The existing schema does not define that column.
- Removed all `hms_rooms.guest_name` reads/writes from the check-in, room-move and check-out lifecycle RPC.
- Added forward corrective migration `20261105000440_hms_checkin_remove_unsupported_guest_name_column.sql`. It reinstalls the exact same RPC signature and lifecycle with only columns supported by the room schema.
- Also corrected the not-yet-applied 00430 migration in the package so fresh installs do not reproduce the error.
- Apply 00440 if 00430 was already applied; if neither was applied, apply corrected 00430 and do not apply 00440 separately unless desired as an idempotent reinstall.
- This fixes the identified SQL column mismatch; live migration and check-in remain to be tested against the connected database.


## Follow-up correction — /pms PostgREST overload ambiguity (2026-11-05)

- Screenshot route is `/pms`, not `/hotel-management`. Its client called `anaira_phase13_pms_transition` with five named parameters while the connected database exposes both 5-argument and 6-argument overloads (the latter adds `p_allow_early_checkout`). PostgREST therefore reported that it could not choose the best candidate.
- Updated `app/pms/page.js` to pass `p_allow_early_checkout: false` explicitly, selecting the six-argument overload and keeping early checkout disabled unless explicitly implemented.
- PMS now prompts for the human-readable room/tent number and resolves it to the UUID, displays room/tent number instead of raw UUID, and filters available actions by reservation status (confirmed -> check-in/no-show/cancel; checked-in -> room move/check-out; pending -> confirm/cancel).
- Added `active` to room query and only offers active, available, clean/inspected units.
- No schema migration is required for this frontend overload-selection fix, provided the six-argument RPC shown by the database error is present.
- Static validation: JavaScript syntax 732/732 PASS; relative imports PASS; booking runtime closure 29/29 PASS. Browser E2E/live RPC call remains pending.


## Follow-up correction — Camping HMS inventory + CRM Customer 360 bridge (2026-11-05)

- Screenshot shows physical camp tent `0001` occupied and its PMS reservation checked in, while Smart Inventory still showed `0 booked`. Root cause: camp approval creates the canonical HMS reservation without setting `hms_reservations.room_type_id`; the daily HMS inventory reconciler aggregates by `room_type_id`, so the confirmed camp booking was invisible in that calendar.
- Added migration `20261105000450_camping_hms_inventory_crm_bridge.sql`.
- On camp approval (including a backfill of already-approved records), it matches `camp_unit_types` to the canonical HMS `hms_room_types` by code/name, fills the HMS reservation's `room_type_id`, links `crm_customer_id`, and calls the daily HMS inventory reconciler for the stay dates. The Smart Inventory calendar should then show the booked unit on each occupied night, not on the checkout date.
- It resolves/creates the tenant CRM customer by phone/email, links that customer to `hms_guests` and `hms_reservations`, and upserts a `crm_guest_stays` record plus a deduplicated `crm_guest_stay_events` event.
- A second trigger listens for PMS status/room assignment changes on camping HMS reservations, so CRM stay status/events update on check-in, room move, checkout, cancellation or no-show lifecycle changes.
- This bridge preserves separate camp inventory (`camp_inventory.sold_units`) and HMS daily inventory (`hms_inventory.sold_rooms`) as synchronized views of the same approved booking. It does not double-charge or increment camp sold units.
- Static validation remains: JavaScript syntax 732/732 PASS; relative imports PASS; booking runtime closure 29/29 PASS. The migration has not been executed against the live database and requires staging verification.


## Follow-up correction — Customer 360 loyalty ledger query (2026-11-05)

- Screenshot error `column crm_loyalty_transactions.customer_id does not exist` was caused by Customer 360 querying the loyalty ledger directly by customer_id.
- Live Supabase schema confirms `crm_loyalty_transactions` is keyed by `loyalty_account_id`; customer identity lives on `crm_loyalty_accounts.customer_id`.
- Updated `app/customer-360/page.js` to load the customer's loyalty account(s), then fetch ledger transactions with `.in('loyalty_account_id', accountIds)` while retaining tenant/property scope and newest-first ordering.
- No database migration is required; this is a frontend query correction. Existing live customer record Ram is already linked to NH3 Camping and has one stay.
- Validation: JavaScript syntax 732/732 PASS; relative imports PASS; booking runtime closure 29/29 PASS. Customer 360 browser UI not yet E2E-tested after source replacement.

## OTA Distribution Engine completion update (2026-11-06)

Implemented source and applied live Supabase migration `ota_distribution_engine_completion_20261106`.

- Added normalized inbound reservation import RPC with channel/tenant ownership validation, provider external-ID idempotency, mapped room/rate enforcement, HMS guest + reservation upsert, CRM customer + stay linking, cancellation handling and inventory reconciliation.
- Added property-scoped webhook routing, account reference disambiguation, encrypted webhook-secret lookup and inbound queue processing.
- Added canonical outbound payload builders for date-wise PMS inventory, rate plans/overrides, and reservations with guest/payment summaries.
- Added 15-minute auto-sync queue enqueue function and protected worker processing with retry/backoff; Vercel Cron configured for every 5 minutes.
- Added UI provider account reference field and manual mapping verification controls; auto-sync remains blocked until endpoint paths and verified mappings are present.
- Live DB verified: reservation link table, inbound import RPC, scheduler RPC and queue direction/tenant/property columns exist.
- Local checks: JavaScript syntax 733/733 PASS; relative imports PASS; OTA transport guard 3/3 PASS; OTA distribution runtime check 14/14 PASS.
- Not certified: live external provider connectivity, provider-specific proprietary/XML/OAuth protocols, sandbox/production E2E, and actual OTA booking lifecycle. Requires provider credentials/partner access and deployed CRON_SECRET + stable ANAIRA_SECRET_KEY.
- No real OTA bookings or property inventory records were created/modified during this implementation.
