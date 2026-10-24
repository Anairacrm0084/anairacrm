# Anaira OTA / Channel Manager Connection Guide

## What the included connector does

- Stores provider credentials encrypted at rest using `ANAIRA_SECRET_KEY` (AES-256-GCM).
- Requires an HTTPS provider base URL and a successful provider-defined test endpoint before marking a connection `connected`.
- Supports bearer/API-token, OAuth2 access-token, Basic auth, API-key header, and extra provider headers via the credentials JSON object.
- Uses provider-specific endpoint paths configured by the property admin for test, inventory, rates, reservations, and availability.
- Queues and retries sync events through the existing distribution worker; webhook events are signature-checked and idempotency-keyed.
- Never treats the local mock-server test as real provider certification.

## Required production environment

Set these in the deployment platform's secret manager (not in source control):

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `ANAIRA_SECRET_KEY` — strong random secret, keep stable or previously encrypted credentials cannot be decrypted
- `CRON_SECRET` — protect the sync worker/cron routes

Configure payment, email, WhatsApp and Google credentials separately if those features are enabled. Run `npm run production:env` after setting variables.

## Provider onboarding checklist

1. Obtain a signed partner contract / approved channel-manager account and API documentation from the provider.
2. Request sandbox and production base URLs, account/property identifiers, authentication method, endpoint paths, webhook URL/event documentation, signing secret, rate limits and certification requirements.
3. Select the provider in **OTA & Channel Manager** and enter its HTTPS base URL, auth type, credentials JSON, and the exact test/inventory/rates/reservations/availability paths from that provider's docs.
4. Click **Test & Save Connection**. A successful test proves only the configured test endpoint responds; it does not prove booking synchronization.
5. Map every Anaira room/tent type and rate plan to external provider IDs. Verify occupancy, currency, taxes, meal plans, cancellation rules, timezone and allotment semantics.
6. Configure provider webhook delivery to `/api/distribution/webhook/<provider_code>`. Store its signing secret in the deployment secret manager as `OTA_<PROVIDER_CODE_UPPERCASE>_WEBHOOK_SECRET` (for example `OTA_BOOKING_COM_WEBHOOK_SECRET`) or `OTA_WEBHOOK_SECRET`. Configure the provider signature header/format to match the verifier. Do not disable signature verification in production.
7. In sandbox, test rate push, inventory push, reservation create, modification, cancellation, duplicate webhook, retry after 429/5xx, timeout and reconciliation. Compare provider and Anaira reservation IDs.
8. Obtain provider certification/approval and switch to production credentials. Keep auto-sync disabled until all applicable tests pass.
9. Monitor sync queue failures, last sync time, webhook inbox, external reservation IDs and inventory drift daily.

## Provider-specific adapter limitation

The configurable REST transport is a safe setup framework, not an assertion that every provider speaks the same API. Some partners require signed requests, OAuth client-credential flows, XML/OTA payloads, proprietary schemas, IP allow-listing, or provider certification. For those providers, implement the dedicated adapter/serializer against the approved API contract before enabling live sync. Google Hotel Ads is a metasearch / booking-link integration and should not be treated as a normal OTA reservation inbox.

## Release gate

Do not advertise an OTA as production-connected based only on a green Test Connection result. Production readiness requires provider sandbox E2E, production credentials, real webhook delivery, two-way booking/rate/inventory validation, duplicate/overbooking tests, database migrations applied, production build passing, and an operational rollback/reconciliation plan.
