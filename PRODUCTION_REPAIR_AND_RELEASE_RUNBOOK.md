# Anaira CRM — P0 Repair & Production Release Runbook

## Current source verification (2026-11-22)
The static source checks listed in `package.json` pass in this source archive:
- JavaScript syntax and relative imports
- P0/P1/P2/P3/P4/P5/P6 static checks
- Booking runtime closure
- Public hospitality storefront and Homestay routing regression
- CRM, Hotel Guest CRM, Restaurant CRM, Corporate CRM, Partner CRM,
  WhatsApp CRM, Guest Relations, AI Review, SEO and business identity checks

These are static/source checks. They are not proof of a production build,
live Supabase/RLS isolation, provider delivery, payment settlement, or browser E2E.

## P0 deployment order

1. Back up the production Supabase database and storage metadata.
2. Deploy this source release to a staging Vercel environment first.
3. Configure required environment variables in Vercel (see `.env.example`).
   Keep `SUPABASE_SERVICE_ROLE_KEY`, `ANAIRA_SECRET_KEY`, payment secrets,
   provider secrets and `CRON_SECRET` server-side only.
4. Run `npm ci` and `npm run build` in CI/staging. Do not promote if build fails.
5. Verify login, registration, OTP, role redirects and tenant switching.
6. Run tenant A/B negative tests using isolated test tenants and test accounts.
7. Verify Supabase RLS and RPC permissions using anon, authenticated tenant A,
   authenticated tenant B and service-role contexts.
8. Deploy the new server route `app/api/public/stay/finalize/route.js`.
9. Only after step 8 is deployed and verified, apply migration
   `20261122143000_secure_public_stay_finalize.sql`. It revokes direct
   anon/authenticated execution of `anaira_finalize_public_stay_booking`
   and grants it to service_role. Applying it before the server route is live
   can break the existing public Homestay checkout.
10. Test a complete Homestay booking in staging: search -> availability ->
    OTP -> hold -> payment proof/pay-at-stay -> confirmation -> cancellation
    -> inventory release.
11. Test payment webhooks, idempotency, duplicate callbacks, refunds and
    reconciliation in provider sandbox before production credentials.
12. Test OTA sync using provider sandbox/contract credentials. The included
    local mock test is not OTA certification.
13. Promote to production only after all release gates pass.

## Required release gates
- `npm ci`
- `npm run build`
- `npm run check:js`
- `npm run check:imports`
- `npm run p0:check` through `npm run p6:check`
- `npm run booking:runtime-check`
- `npm run e2e:critical` with BASE_URL
- `npm run e2e:tenant-negative` with isolated test tenant credentials
- Live Supabase migration/RLS verification
- Provider sandbox tests for the integrations enabled for the tenant

## Important
- No production migrations were applied as part of this source packaging step.
- No production Vercel deployment or Git push was performed.
- Do not put credentials in source files or commit `.env.local`.
- Do not disable RLS to make a page load.
- Do not copy tenant data into the global platform tenant to work around access issues.
