# Anaira OTA replay-safety patch — 2026-11-05

## Changes in this update

- Distribution worker now reclaims abandoned `processing` leases older than five minutes.
- Worker claims queued events with a conditional `UPDATE ... WHERE status='queued' RETURNING id`; a second worker skips an event it did not claim.
- Inbound `modified` events for already-imported reservations now call `anaira_process_ota_reservation(..., 'modify')`.
- Inbound cancellation events call the PMS cancellation RPC and remain retryable if that RPC fails.
- Cancellation webhooks containing only an OTA confirmation/reference ID are normalized without overwriting the stored guest, stay, rate, or room fields.
- A cancellation without a matching reservation in that property's inbox is rejected rather than creating an incomplete inbox record.
- Added migration `20261105180000_ota_pms_replay_safety.sql`:
  - repeated `import` against an inbox row already linked to a PMS reservation returns the existing reservation ID;
  - completed cancellation retries return a duplicate result without re-running inventory reconciliation;
  - the migration checks for its expected function anchor and aborts rather than blindly rewriting a different function.

## Verification performed

- `node --check` on changed JavaScript modules: PASS
- OTA inbound normalization: 16 assertions PASS
- OTA inbox runtime static checks: 14 assertions PASS
- OTA replay-safety static checks: 10 assertions PASS
- OTA property-only scope checks: 7 assertions PASS
- Project JavaScript syntax: 735/735 PASS
- Relative import verification: PASS

These are source/static checks. No real OTA provider request, live booking creation, modification, cancellation, or inventory mutation was run.

## Apply the database migration

Review and apply `supabase/migrations/20261105180000_ota_pms_replay_safety.sql` to the intended Supabase project after confirming the preceding OTA lifecycle migrations are already applied. Do not blindly apply the entire migration directory to production.

## Important scope boundary

This ZIP contains the Anaira CRM distribution worker, PMS inbox/RPC migrations, and application routes. It does **not** contain the separately deployed `anaira-universal-property-api` Edge Function source that was inspected as version 8. Therefore this patch improves the CRM-side OTA webhook/worker/PMS pipeline; it does not deploy or replace that separate Edge Function. Its receipt-table idempotency and stale-receipt recovery still require a separate Edge Function source update/deployment.

The archive intentionally excludes `.env.local`, `.env` files, local build output, and Git metadata. Rotate any API key that was pasted into chat or stored in a shared archive.
