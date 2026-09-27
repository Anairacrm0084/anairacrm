# ANAIRA MASTER DELIVERY STATUS

This ZIP is the locked master source baseline for the ANAIRA hospitality platform.

## No fake state rule
The UI must not claim Connected, Live, 100%, Paid, AI-generated, OTA-synced or Production-ready unless the corresponding server-side check/provider execution has succeeded.

## What this source upgrade contains
- Real workflow SQL contracts and transactional RPCs for PMS, restaurant reservation, delivery, payment-intent/status and loyalty.
- Tenant-scoped workflow/audit-event primitives.
- Payment intent/event/refund data model.
- Integration health state model.
- OTA queue model.
- Notification queue model.
- Workflow-run model.
- Razorpay server-side adapter contract.
- System health UI that reports measured states instead of hardcoded percentages.
- Workflow registry with separate implementation/readiness states.

## What cannot honestly be called complete without external configuration
- Razorpay/Stripe: credentials and webhook endpoints must be configured and tested.
- OTA: each OTA requires its own provider contract, credentials, mapping and certification/testing.
- WhatsApp/SMS/email: provider credentials/templates/webhooks must be configured.
- Canonical Anaira POS: the hospitality app requires the actual POS runtime/API contract; it must not clone the POS.
- AI/forecasting/competitor collection: requires the selected model/data-source runtime.

These are intentionally shown as NOT CONFIGURED/NEEDS PROVIDER rather than fake Connected/Live.

## Required deployment sequence
1. Review `supabase_migration_067_real_workflows.sql`.
2. Apply it through Supabase migration tooling.
3. Run SQL/RPC integration tests against a development database.
4. Configure provider secrets only on the server/secret manager.
5. Validate payment webhooks before enabling paid state transitions.
6. Configure OTA/message/POS adapters and run their contract tests.
7. Run browser E2E tests for every critical workflow before production release.
