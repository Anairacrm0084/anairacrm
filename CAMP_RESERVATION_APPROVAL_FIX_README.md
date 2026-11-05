# Anaira Camping Reservation Approval + HMS Sync

## Changes
- Added authenticated admin actions to `/booking-engine/camping?property=<tenant-id>`:
  - Approve & Confirm
  - Verify Payment
  - Reject / Release Hold
- Added a dedicated Supabase migration:
  `supabase/migrations/20261105000300_camp_reservation_admin_approval_hms_sync.sql`
- Added idempotent camp-to-HMS linkage through `camp_reservations.hms_reservation_id`.
- Approval consumes the camp inventory hold and increments `camp_inventory.sold_units` in the same transaction.
- Creates/links `hms_guests`, `hms_reservations`, and `hms_folios`.
- Payment verification updates camp reservation, HMS reservation, folio, and transaction state.
- The RPC checks `auth.uid()` against active `profiles` and tenant/admin ownership. It is not executable by anon/public.

## Apply
1. Back up the Supabase project.
2. Apply the migration using Supabase CLI migration workflow or paste the SQL into Supabase SQL Editor.
3. Confirm the migration succeeds.
4. Deploy the updated Next.js source.
5. Open Booking Engine -> Camping / Hospitality Mode -> Reservations.
6. Approve only after verifying the booking details. Use Verify Payment only after money is actually received.

## Important existing-booking finding
Live query for `ANC-1B5AEDE94B` returned no matching `camp_inventory_holds` row, while its two date inventory rows showed `held_units=1`.
The approval RPC intentionally refuses to approve it without a valid hold; this avoids consuming inventory twice or fabricating a reservation. Reconcile this booking/hold first, or create a fresh booking after the migration is installed.

## Verification status
- Static UI/RPC wiring checks: performed.
- SQL migration: packaged but NOT applied to live Supabase (migration execution was blocked).
- Production build: not run; node_modules are not present in the provided ZIP.
- Live approve/payment/reject E2E: not run; no reservation was mutated.
