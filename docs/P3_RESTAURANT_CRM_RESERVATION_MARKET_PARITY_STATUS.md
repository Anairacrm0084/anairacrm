# P3 — Restaurant CRM + Reservation Market Parity

## Scope
P3 strengthens the CRM-side restaurant relationship and reservation layer while keeping Restaurant SaaS as the operational POS/KOT/KDS/inventory source of truth.

## Implemented in this phase
- Reservation lifecycle event/audit ledger with idempotency keys.
- Atomic reservation creation RPC with guest-to-CRM identity resolution, optional table selection and conflict detection.
- Real table availability RPC using reservation duration overlap checks.
- Reservation lifecycle transition RPC for confirmed/seated/completed/cancelled/no-show and related event/platform-event history.
- Table-combination data model for future multi-table seating without duplicating POS table authority.
- Guest reservation preference storage linked to CRM customer identity.
- Restaurant experience and reservation add-on catalogs.
- Reservation add-on line items.
- Reservation deposit ledger linked to the existing Anaira payment-intent domain.
- Reservation 360 view joining reservation, CRM guest and table context.
- Existing public reservation flow preserved; new v2 runtime is additive and does not replace Restaurant SaaS operational ownership.

## Certification state
`IMPLEMENTED / FOUNDATION`

This phase is **not** marked production-certified because this package does not execute against the user's live Supabase project, real payment providers, notification providers, or browser E2E environment.

Required next gates:
- Apply migration to the target Supabase project and execute SQL/RLS checks.
- Verify live reservation conflict/locking behavior under concurrency.
- Wire the reservation admin UI to the v2 RPCs and lifecycle controls.
- Execute payment/deposit provider E2E where enabled.
- Execute email/WhatsApp/SMS confirmation/reminder delivery and retry history.
- Validate Restaurant SaaS reservation events and POS/table state through the Integration Hub.
- Browser E2E and production build/deployment certification.
