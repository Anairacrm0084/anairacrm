# Anaira Production Closure — 2026-10-01

This closure pass fixes source/database issues that can be safely completed without fabricating provider credentials or live external test evidence.

## Closed in this pass
- Sensitive SECURITY DEFINER RPCs used for admin, distribution verification, payments, inventory controls, permissions and folio operations are revoked from `anon`.
- Canonical Booking Engine routing remains `/booking-engine`; `/booking` preserves query parameters safely under Next.js 15/16 async `searchParams` semantics.
- Delivery has a guarded transition state machine with rider validation and transition logging.
- Existing static suites were rerun after the source audit.

## Environment gates that cannot be honestly completed from a source ZIP
- npm registry installation / reproducible lockfile generation when the environment has no registry access.
- Production Next.js build in a clean dependency environment.
- Real Razorpay/Stripe credentials and webhook callbacks.
- Real OTA credentials/API callbacks for Booking.com, Expedia, Agoda, MMT, Goibibo, etc.
- Google Business Profile/GSC/GA4 credentials.
- Real email/SMS/WhatsApp provider credentials.
- Browser E2E against a deployed environment.
- Cross-tenant negative E2E against isolated users/tenants.
- 10k+ URL scale/concurrency benchmarks.

These are release gates, not source-code placeholders, and are intentionally not marked PASS without evidence.
