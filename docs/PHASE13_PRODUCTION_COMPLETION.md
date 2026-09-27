# ANAIRA Phase 13 — Production Completion

This release upgrades the source with a real PMS/front-desk action surface and a non-destructive Phase 13 migration.

## Included
- PMS reservation action console: confirm, check-in, room move, checkout, no-show, cancellation.
- Room status and housekeeping visibility.
- Hotel inventory hold table with idempotency and expiry.
- Inventory hold release/consume functions.
- PMS transition function for check-in, room move and checkout.
- Release-check evidence table.
- Safe `search_path` declarations on Phase 13 security-definer functions.

## Live verification boundary
The production Supabase project already has Phase 12 live. The Phase 13 SQL is included here but could not be applied through the current database execution safety gate in this session. Do not claim Phase 13 live until the migration is successfully applied and verified.

## External release gates that cannot be fabricated
1. Canonical Anaira POS runtime.
2. KOT → KDS → Billing runtime.
3. Razorpay signed webhook using a real test transaction.
4. Stripe signed webhook using a real test transaction.
5. Bluetooth/thermal printer physical test.
6. OTA provider credentials and reservation sync.
7. Notification provider credentials and worker delivery.
8. CRM automation worker execution.
9. AI/forecasting/competitor production data sources.

The application must remain honest about these boundaries.
