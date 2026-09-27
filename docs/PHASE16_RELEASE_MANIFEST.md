# Phase 16 Release Manifest

Source baseline: ANAIRA-PHASE15-REAL-COMPLETION-FULL-2026-09-25
Live project: bhptqdoteucuymmdzsmg

Changed source:
- app/book/[id]/page.js — public hotel booking now starts the transactional hold/payment-intent flow.
- app/booking-engine/page.js — UI copy reflects real transactional payment/coupon state.
- app/api/hotel/payment/webhook/route.js — signed server webhook bridge.
- app/api/crm/campaign-worker/route.js — queue claim + provider adapters/retry.
- app/api/crm/prearrival-worker/route.js — pre-arrival queue scheduler endpoint.

Changed database:
- 096_crm_hospitality_a_to_z_completion.sql
- Live follow-up runtime patch: crm_hospitality_a_to_z_runtime_workers

No Restaurant Core/POS runtime was copied into this hospitality package.
