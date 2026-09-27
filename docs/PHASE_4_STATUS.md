# ANAIRA Phase 4 Status

## Scope
Store → Cart → Coupon → Order → POS → KOT → KDS → Billing → Payment → Delivery
Reservation: Slot → Table → Reservation → Confirmation → Seating → POS → Complete
Delivery: Order → Accept → Prepare → Ready → Rider → Pickup → Delivery → Settlement

## Live migration
079_phase4_atomic_store_reservation_pos_delivery

## Live RPCs
- anaira_phase4_create_store_order
- anaira_phase4_create_reservation
- anaira_phase4_reservation_transition
- anaira_phase4_delivery_release
- anaira_phase4_claim_pos_queue
- anaira_phase4_retry_pos_queue

## Phase 4 improvements
- Server-side coupon validation is part of order creation.
- Server-side totals are authoritative.
- Store order creates a payment intent as part of the transaction flow.
- Reservation creation atomically finds and assigns a suitable table.
- Reservation seating creates a POS handoff event.
- Delivery release requires ready state, eligible payment state, and a real active rider.
- POS queue can be claimed with row locks and processing state to prevent duplicate workers.
- Failed POS events can be retried within an attempt limit.

## Still external/provider dependent
- Razorpay/Stripe credentials and verified provider webhooks must be configured in deployment.
- Canonical Anaira POS must consume/acknowledge the POS bridge events.
- KOT/KDS/Billing/thermal execution is owned by canonical Anaira POS, not duplicated here.
- Browser E2E must still be run against the deployed application.
