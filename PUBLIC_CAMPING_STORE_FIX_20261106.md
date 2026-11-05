# Public Camping Store Fix — 2026-11-06

## Changes
- Public UUID property resolution no longer fails when anonymous RLS hides optional `anaira_store_memberships` enrichment. The canonical active `restaurants` record remains sufficient to resolve a direct hospitality booking page.
- Store Builder public booking/QR URL now uses `NEXT_PUBLIC_SITE_URL` when configured, otherwise the production origin `https://crm.anairapos.in` in production and current origin in local development.
- Camping reservation KPI now de-duplicates the canonical HMS mirror code suffix `-CAMP` against the legacy camping reservation code, preferring the more advanced reservation status. This prevents one physical reservation being counted twice.

## Deployment configuration
Set this Vercel environment variable for Production (and Preview if required):
`NEXT_PUBLIC_SITE_URL=https://crm.anairapos.in`

Then redeploy. Local development continues to use the local origin unless the variable is explicitly set.

## Verification
- `node --check lib/publicProperty.js` — PASS
- `node --check app/store-builder/page.js` — PASS
- `tests/public-hospitality-storefront-static.mjs` — PASS (14/14)
- `tests/camp-business-creation-static.mjs` — PASS (7/7)

Note: this ZIP has not been deployed to the user's local machine or Vercel. Replace the project source with this updated project, set the environment variable, then run a production build and test the public URL in an incognito browser.
