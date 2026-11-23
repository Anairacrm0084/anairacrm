# OTA Existing Listing Link — Source Update Report (2026-11-23)

## Implemented
- Property-admin workflow to register an already-live OTA listing without creating a duplicate OTA listing.
- Provider, existing external listing/property ID, OTA account email, current channel-manager selection and explicit owner authorization fields.
- Authenticated API route with tenant authorization, admin-role check, accommodation-property eligibility check and provider allowlist.
- New tenant-scoped `anaira_ota_listing_link_requests` table with RLS and duplicate-safe upsert.
- Request is explicitly stored as `authorization_requested`; the API does not claim OAuth/API connectivity or enable inventory sync.
- Existing-listing request list shown to the property admin.
- Super Admin review page added under Universal Integrations; only Super Admin can change review status.
- Expanded OTA accommodation eligibility to hotel, camp, homestay, guest house, cottage and other supported accommodation profile types; restrictive policies are replaced with equivalent broader accommodation-only guards.
- Added Super Admin guidance link to the property-scoped Channel Manager.
- Fixed inbound OTA reservation normalization for common `totalAmount` and `currencyCode` payload keys; added Airbnb, Trip.com and Hostelworld adapter labels.
- Added OTA property guard to provider connection test, sync worker and webhook tenant routing.

## Verification
- JavaScript syntax: 739/739 PASS.
- Relative import audit: PASS.
- Existing listing link static tests: 10/10 PASS.
- OTA accommodation scope static tests: 7/7 PASS.
- Inbound reservation normalization: 16 assertions PASS.
- Provider configuration guard: 3/3 PASS (local mock transport only).
- API route Node syntax checks: PASS.
- Full Next.js production build: NOT RUN (dependencies not installed in this source workspace).
- Live Supabase migration: NOT APPLIED.
- Provider OAuth, provider approval and real OTA API connectivity: NOT IMPLEMENTED / NOT CERTIFIED in this step.

## Explicit limitations
This update provides a safe existing-listing registration/request workflow. It does not create official OAuth authorization URLs/callbacks because each OTA requires Anaira's approved provider credentials, redirect URI registration and provider-specific contract. A request remains `authorization_requested` until the provider authorization and Super Admin review process is implemented and verified. The existing incoming reservation inbox UI and stale-worker recovery checks also remain separate follow-up work.
