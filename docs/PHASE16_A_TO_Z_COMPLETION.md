# ANAIRA CRM / Hospitality — Phase 16 A-to-Z Completion

## Implemented in live Supabase
- Transactional hotel booking state: quote -> booking transaction -> inventory hold -> payment intent -> server/webhook verification -> hold consume/release -> PMS reservation -> CRM guest stay -> pre-arrival jobs.
- Idempotency at booking transaction level.
- Hotel rate calculation covering base/BAR, weekday/weekend, occupancy, advance-purchase, last-minute, extra adult/child, meal plan, add-ons, coupon, tax and service charge.
- Restaurant Customer 360 aggregate table and refresh function.
- Restaurant auto-tag rule engine with starter VIP/high-spender/lapsed/reservation-regular/negative-feedback rules.
- Campaign queue and server worker route with WhatsApp + webhook adapters for email/SMS + in-app.
- Hotel pre-arrival job queue and worker endpoint.
- Revenue rate recommendation table with approval state; recommendations do not auto-publish.
- Loyalty earn/redeem transactional functions.
- Feedback action queue foundation.
- Global customer relationship layer while keeping Hotel CRM and Restaurant CRM domain records separate.
- Real analytics daily aggregation function; dashboard consumers should read this table instead of hardcoded KPIs.
- AI action queue for approval-based actions.
- Canonical Anaira POS is not duplicated or moved into this hospitality package.

## Security posture
Sensitive payment confirmation and worker claim functions are not exposed to anon/authenticated. Public booking start and quote functions remain public because direct booking requires them; they use SECURITY DEFINER and must be treated as public API endpoints with validation/rate limiting.

The Supabase security advisor still reports pre-existing SECURITY DEFINER exposure elsewhere in the project and the Auth leaked-password-protection warning. Those are project-level items and are not falsely marked as cleared by this phase.

## Provider-dependent gates
Razorpay/Stripe, WhatsApp, SMS, email, OTA/channel-manager and Google Hotel require real provider credentials, webhook secrets, account IDs and/or contracts. The code paths are provider-ready, but no credential-free environment can honestly be called E2E provider-certified.

## Build gate
The source package has no installed node_modules. `npm run build` was attempted and could not execute because `next` is not installed. A package-lock was attempted but the package-manager operation timed out. Therefore this package is source-complete for the implemented phase but not build-certified.
