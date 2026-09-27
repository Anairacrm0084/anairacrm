# Phase 31 import-resolution hotfix

Screenshot root cause: `app/anaira/customer/page.jsx` referenced `../../lib/supabase` from a three-level nested route; corrected to `../../../lib/supabase`.

Additional unresolved imports found and corrected:
- `app/api/seo/local/oauth/route.js`: provider and seoRuntime imports changed from `../../../../lib/server/` to `../../../../../lib/server/`.
- `app/api/seo/local/callback/route.js`: provider import corrected to `../../../../../lib/server/` and crypto switched to ESM import.

Verification: 365 relative static imports scanned; 0 unresolved by local file existence check. `npm run check:js`: 212/212 PASS. This is NOT a verified Next.js production build; dependencies, environment, provider E2E and database migration certification remain outstanding.
