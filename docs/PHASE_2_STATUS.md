# ANAIRA PHASE 2 — STORE → POS → PAYMENT → DELIVERY

## Live in Supabase
- 076 payment intent/event/refund tables and delivery-order payment linkage
- 076 payment-intent creation RPC
- 076 coupon validation RPC
- 077 verified payment status RPC
- 077 payment-paid → POS sync queue handoff
- Phase-1 delivery, reservation and settlement RPCs remain live

## Source/UI wiring
- Restaurant Store checkout validates coupons server-side before creating the order.
- Restaurant Store creates a payment session after order creation.
- POS bridge API exposes queued canonical POS contract events.

## Intentionally not marked complete
- Actual canonical Anaira POS runtime/KOT/KDS acknowledgement is external to this hospitality package.
- Razorpay/Stripe require real server credentials and webhook configuration.
- Browser E2E has not been run in this environment.
