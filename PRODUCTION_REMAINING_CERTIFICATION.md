# Anaira Production Closure — Remaining Certification Matrix

Generated: 2026-10-03

## Source-side closure completed in this package
- JavaScript syntax: 379/379 PASS
- Relative imports: 0 failures
- Booking runtime closure: 29/29 PASS
- P3 restaurant reservation: 13/13 PASS
- P4 AI review: 15/15 PASS
- P5 SEO: 12/12 PASS
- P6 Integration Hub: 12/12 PASS
- Hotel Guest CRM static: 67/67 PASS
- CRM Enterprise static: 103/103 PASS
- Corporate CRM: 25/25 PASS
- Partner CRM: 7/7 PASS
- WhatsApp CRM: 19/19 PASS
- Restaurant Marketplace PRO: 12/12 PASS
- Live Supabase closure: `crm_corporate_ledger` now has tenant-scoped authenticated RLS policies.
- Added booking assistant API with explicit search/quote/book/manage guardrails; booking execution still requires normal verification/payment workflow.
- Added critical-path E2E harness and cross-tenant negative E2E harness.
- Added production preflight npm script.

## Must be certified in the user's environment
These are environment/provider assertions and are intentionally NOT marked PASS here:
1. `package-lock.json` + clean `npm ci`
2. `npm run build` + `npm start`
3. Browser E2E against deployed app
4. Cross-tenant negative browser/API E2E with two real tenant identities
5. Razorpay live payment/webhook/refund/reconciliation
6. Stripe live payment/webhook/refund/reconciliation
7. OTA provider certification and reservation/cancel/modify reconciliation
8. GDS live contract/provider certification
9. Metasearch feed/price/landing/conversion certification
10. WhatsApp provider delivery + callback/retry
11. Email/SMS provider delivery + callback/retry
12. External SEO provider OAuth/API certification
13. Competitor-rate provider live feed
14. Native Android/iOS/Capacitor certification

## Run after `npm run dev`
Set `BASE_URL` and the E2E fixture variables documented in `.env.example`, then:
- `npm run e2e:critical`
- `npm run e2e:tenant-negative`
- `npm run production:preflight`
- `npm run build`
- `npm start`

A skipped E2E is not a pass. A provider adapter is not a provider certification.
