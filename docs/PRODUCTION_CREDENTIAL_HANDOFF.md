# Anaira Production Credential Handoff

This package contains source/runtime hardening but intentionally does not contain production secrets.

## Required application secrets

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (or legacy `NEXT_PUBLIC_SUPABASE_ANON_KEY`)
- `SUPABASE_SERVICE_ROLE_KEY`
- `ANAIRA_SECRET_KEY`
- `CRON_SECRET`

## Payments

- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_WEBHOOK_SECRET`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`

## Communications

- `WHATSAPP_ACCESS_TOKEN`
- `WHATSAPP_PHONE_NUMBER_ID`
- `RESEND_API_KEY`
- `RESEND_FROM`
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_FROM`

## Google / AI / SEO

- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `OPENAI_API_KEY`
- `DATAFORSEO_LOGIN`
- `DATAFORSEO_PASSWORD`
- `SERPAPI_KEY`

## Distribution / OTA

Provider credentials are stored encrypted through the existing distribution connection runtime. Provider connection records must also contain the provider's production `base_url` and operation configuration required by the provider contract. Do not commit these values to source control.

Webhook secrets may be supplied through the connection configuration (`webhook_secret`) or provider-specific server environment variables. Distribution webhooks now require HMAC verification and reject expired timestamps/replayed events before queueing.

## Required deployment sequence

1. Configure the environment variables in Vercel/hosting.
2. Apply `supabase/migrations/20261004_production_runtime_hardening.sql` to the target Supabase project.
3. Deploy the Next.js application.
4. Confirm Vercel cron jobs from `vercel.json` are enabled.
5. Run `npm ci` from a network-enabled build environment.
6. Run `npm run build`.
7. Run `npm run production:preflight`.
8. Run `npm run e2e:critical` with real non-production fixtures.
9. Run `npm run e2e:tenant-negative` with two isolated tenant tokens.
10. Configure and certify each external OTA/payment/messaging provider separately.

## Important boundary

A source package cannot honestly certify a provider without its real contract, credentials, callback endpoints and test environment. This package therefore fails closed instead of returning synthetic provider success.
