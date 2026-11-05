# Anaira OTA Distribution Engine — implementation notes

## Implemented in this source update

- Canonical outbound payload builders for HMS inventory, rate plans/rate overrides, and reservations + guest data.
- Verified room/rate mappings are required before those records enter outbound payloads.
- Property-scoped inbound webhook routing. Multi-property provider accounts must include an account/property reference; ambiguous events are rejected rather than broadcast across tenants.
- Signed webhook verification can use the encrypted `webhook_secret` stored with connection credentials (or configured server environment secret).
- Normalized reservation/cancellation webhook parsing and durable inbound queue events.
- Idempotent HMS reservation import/update/cancel RPC with CRM customer + guest-stay linking and inventory reconciliation.
- Auto-sync enqueue function on a 15-minute idempotency bucket; protected worker invokes it and processes queue events with retry/backoff.
- Vercel Cron invokes `/api/distribution/sync/worker` every five minutes. Configure `CRON_SECRET` in the deployment environment.

## Required deployment configuration

1. Apply migration `20261106000100_ota_distribution_engine_completion.sql` (it has been applied to the connected Anaira Supabase project in this task).
2. Deploy this source update and set `CRON_SECRET` in Vercel. The worker rejects calls without `Authorization: Bearer <CRON_SECRET>`.
3. Set `ANAIRA_SECRET_KEY` (or `ANAIRA_SECRET`) consistently across deployments. It must be the same key used to encrypt/decrypt provider credentials.
4. For each provider, enter the provider-approved HTTPS API base URL, credentials, test endpoint, inventory endpoint, rate endpoint, reservation endpoint, and account/property reference where applicable.
5. Save partner room and rate codes, then mark each mapping verified only after comparing it against the provider/channel-manager account.
6. Configure the provider's webhook URL as `/api/distribution/webhook/<provider_code>` and the matching webhook secret. The webhook secret can be included as `webhook_secret` in the Credentials JSON; it is encrypted with the rest of the credentials.
7. Keep auto-sync disabled until sandbox tests confirm the provider's exact request/response schema, availability semantics, rate restrictions, and webhook signature format.

## Normalized inbound webhook contract

The included normalizer supports common JSON envelopes (`data`, `payload`, `event.data`, `reservation`, `booking`) and common guest, arrival/departure, room/rate code, and reservation identifier fields. Provider-specific XML, OAuth signing, proprietary APIs, or unusual payloads still require a provider-specific adapter/mapping. Events lacking an external room code or a verified room mapping are rejected; they are not silently inserted into the wrong room type.

## Honest certification boundary

Local tests verify source syntax, route wiring, normalization, queue scheduling logic, and mock HTTP transport only. They do not certify live Booking.com, Expedia, Agoda, Airbnb, MakeMyTrip, Goibibo, STAAH, or SiteMinder connectivity. That requires each provider's approved credentials, partner account, sandbox/production endpoint, and successful end-to-end tests. No real OTA bookings were created or modified by this implementation task.
