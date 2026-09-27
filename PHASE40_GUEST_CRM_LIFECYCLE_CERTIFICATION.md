# Phase 40 — Hotel Guest CRM Lifecycle

## Scope
Booking/reservation → check-in → in-house → room move → check-out → CRM Guest Stay.

## Implemented
- Added `anaira_sync_guest_stay_from_reservation` to create/update the canonical `crm_guest_stays` record from an HMS reservation.
- Wired PMS confirm/no-show/cancel/check-in/room-move/check-out transitions to synchronize the CRM guest stay.
- Added tenant/customer identity checks and reservation identity index.
- Added customer stay-count refresh after lifecycle transitions.
- Removed manual room-ID prompt from front-desk transition; room selection now uses eligible live room inventory.
- Preserved folio-balance protection on checkout and housekeeping handoff.

## Verification
- Live Supabase migration applied successfully.
- PMS transition function uses SECURITY DEFINER with explicit `search_path`.
- Anonymous EXECUTE revoked; authenticated EXECUTE retained.
- Existing source inspection confirms live HMS reservations/rooms and CRM guest-stay tables.

## Remaining certification gates
- Browser E2E with authenticated tenant user: pending.
- Production Next.js build: pending.
- Real payment/provider E2E: not part of this point.
