# Anaira Production Certification Matrix

This document separates source/runtime completion from external-provider certification.

## Source/runtime closure

- Relative imports: must pass `npm run check:imports`.
- JavaScript syntax: `npm run check:js`.
- Booking runtime: `npm run booking:runtime-check`.
- P0–P6 static checks: run the corresponding package scripts.
- Temporary `.tmp` / `.bak` production artifacts: none.

## Environment gates

The following cannot honestly be marked PASS from source inspection alone:

1. Clean dependency installation and `next build`.
2. Live Supabase/RLS negative tests.
3. Razorpay live payment → webhook → refund.
4. Stripe live payment → webhook → refund.
5. Provider-certified OTA reservation/cancel/modify/reconciliation.
6. WhatsApp/Email/SMS delivery and callback/retry.
7. Browser E2E against a deployed application.
8. Cross-tenant negative E2E across booking, PMS, CRM, invoices and analytics.
9. GDS/metasearch partner certification.
10. Native Android/iOS certification, if the native-app target is enabled.

A missing credential is an environment blocker, not a source-level feature PASS.
