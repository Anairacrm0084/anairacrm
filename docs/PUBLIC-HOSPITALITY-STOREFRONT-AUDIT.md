# Public Hospitality Storefront — Audit & Fixes

## Required customer journey
- Public discovery: no CRM/property login and no customer account required.
- Public property details and availability: no operator login.
- Booking checkout: collect guest details; authentication/OTP may be required only at the booking/verification step.
- Property management, rates, inventory, reservations and store publishing: authenticated property staff only.
- Super Admin controls platform-wide publication and moderation.

## Changes in this patch
1. `/hotel-store` now routes customers to the public unified hospitality marketplace at `/anaira/hotels` instead of rendering an admin-shell placeholder.
2. `/stays` is a customer-friendly alias for the same public marketplace.
3. Public `/book/[property-id]` profile resolution no longer requires an `anaira_store_memberships` row just to resolve an active property. This removes a hidden dependency on a property admin first logging in / provisioning a store.
4. The property-admin Alternative Stay Engine now starts in a loading state, avoiding a false “Sign in required” flash before Supabase session resolution.
5. Public marketplace result cards now route Camps to `/camping/[restaurant-id]` and Homestays / Guest Houses / Cottages to `/stay/[type]/[property-id]` instead of incorrectly sending every category to the Hotel HMS `/book/[id]` route. Selected dates and guest counts are preserved, including on the camp detail page.

## Existing architecture found
- `/anaira/hotels` is already the public hotel / camp / homestay / guest-house / cottage discovery experience. It calls public marketplace RPCs and links to `/book/[restaurant_id]`.
- `/booking-engine` and `/booking-engine/stays` are operator administration screens and correctly require an authenticated property user.
- `/camping/[id]`, `/stay/[type]/[id]`, and `/book/[id]` are public customer-facing property journeys.
- `/store` is the restaurant/food marketplace; it should remain separate from hospitality stays.

## Live Supabase advisor findings (checked 2026-11-05)
- Security advisor: **34 `SECURITY DEFINER` functions** are executable by `anon`. Some are intentionally public booking/search endpoints; the list also includes internal provisioning helpers such as `anaira_ensure_property_store`, which should not be callable by unauthenticated customers. Review each function individually; do not blanket-revoke public execution because that would break public search/booking flows.
- Auth advisor: leaked-password protection is disabled. Enable it in Supabase Auth settings.
- Performance advisor: **54 RLS policies** repeatedly evaluate auth/current-setting functions per row; optimize stable calls using `(select auth.uid())` / `(select auth.jwt())` where appropriate.
- Performance advisor: one missing FK index on `anaira_platform_stores.parent_platform_store_id`.

## Remaining issues requiring database/runtime verification
- Confirm the deployed Supabase project has all migrations through `20261024_public_camping_store_ota_hardening.sql` and the latest property/store identity migrations.
- Confirm `anon` can execute the public hotel/HMS/camping search and booking RPCs, and public SELECT RLS exposes only active + marketplace-visible properties, active unit/rate catalogues, and safe availability fields.
- Confirm the public booking RPCs enforce inventory holds atomically, prevent overbooking under concurrent checkout, validate property publication and rate validity, and expire abandoned holds.
- `anaira_platform_stores` currently models `hotel` and `restaurant` platform store types. Alternative stays also have separate `anaira_stay_properties` / `camp_properties` records; these should remain the inventory source of truth rather than requiring a second duplicate Store record.
- The hospitality marketplace UI currently searches one stay type at a time. A unified “All stays” search and filters across all stay types are a product enhancement, not a login fix.

## Source archive / release blockers
- The uploaded archive contains `.env.local` with `SUPABASE_SERVICE_ROLE_KEY`. This file is intentionally excluded from the patched delivery ZIP so a privileged database key is not redistributed. Copy your existing private `.env.local` into the extracted project locally; never commit or share it. `.env.example` remains included.
- P0 scan found 1 failure caused by the secret-bearing `.env.local` file in the original upload and 14 environment-secret reference warnings that require deployment-variable review.
- P1 static certification is blocked because `docs/P1_CRM_MARKET_PARITY_STATUS.md` is missing.
- P4 AI Review static certification has 1 missing master-checklist document. SEO certification cannot run because root `MASTER_CHECKLIST.md` is missing.
- Production build was not completed: clean dependency installation timed out and `next` was unavailable. Re-run `npm ci` and `npm run build` after restoring the private environment file.

## Full-app audit observations
- The project contains a large surface area (118+ app route directories, 238 migration files, 14 test files and 32 scripts). Static route/file presence is not proof of completed end-to-end workflows.
- `app/marketplace` and `/store` are restaurant-focused; do not use them as the customer hotel/camping store.
- `app/hotel-store` was only a shell/links placeholder and did not provide a public customer catalogue.
- `resolveRestaurantId()` previously rejected public property URLs when no enabled store membership existed, even though alternative stay properties have their own public publication records.
- A static source audit cannot certify the connected Supabase schema, RLS policies, live records, payment provider callbacks, or production booking concurrency. Those require the correct project connection and runtime tests.
