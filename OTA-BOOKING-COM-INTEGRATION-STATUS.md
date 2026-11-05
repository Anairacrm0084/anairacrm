# Anaira CRM — OTA / Booking.com Integration Work

## Implemented in this source package

- Preserved the existing OTA manager, connection configuration, encrypted credential storage, room/rate mapping, sync queue, webhook signature verification, and retry worker.
- Fixed the inbound webhook execution path: inbound reservation webhooks are no longer sent back out as outbound reservation API calls.
- Added a tenant-scoped, idempotent `anaira_ota_reservation_inbox` table for normalized OTA reservations.
- Added inbound reservation validation/normalization for common reservation payload shapes (confirmation reference, guest, dates, amount, currency, room/rate external codes).
- Added durable import state (`needs_mapping`, `ready`, `imported`, `cancelled`, `error`, `review`) so incoming OTA reservations are not silently auto-confirmed in PMS before room/rate mapping and availability rules are verified.
- Added `ota:inbound-test` test command.

## Required deployment step

Apply this migration to the same Supabase project used by Anaira CRM:

`supabase/migrations/20261105093000_ota_inbound_reservation_inbox.sql`

Then deploy the updated Next.js application and ensure the scheduled/cron worker calls:

`POST /api/distribution/sync/worker`

with the configured cron authorization secret.

## Booking.com live activation — external prerequisites still required

This package does **not** claim a live Booking.com connection. Booking.com connectivity is partner-approved and account-specific. The property must be onboarded/approved for the appropriate Connectivity API access, and Anaira must receive the actual account credentials, assigned API base URL, property identifier, current partner integration specification, and webhook/signature requirements.

The existing generic configurable REST transport is retained as a transport layer, but it is not represented as a certified native Booking.com adapter. Booking.com protocol details and API operations must be implemented against the exact API product and version granted to the account. Do not enter guessed endpoint paths or mark a connection production-ready based only on a local mock test.

## Current operational boundary

Inbound reservations are normalized and stored in the OTA inbox. They are not yet automatically converted into confirmed `hms_reservations`. That final conversion requires verified Booking.com field semantics, valid Anaira room/rate mappings, inventory locking/overbooking policy, and cancellation/modification handling. This deliberate review boundary prevents false confirmations and inventory corruption.

## Verification performed

- `node scripts/ota-provider-configuration-guard.mjs` — PASS (local mock transport checks only)
- `node tests/ota/inbound-reservation-normalization.mjs` — PASS
- `node scripts/verify-js-syntax.mjs` — PASS (733/733)

These checks do not constitute Booking.com sandbox certification or a live provider test.
