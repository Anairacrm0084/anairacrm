# Anaira Hotel CRM — OTA Setup Patch Notes

## Included in this source package

1. OTA manager connection form for provider, HTTPS base URL, auth type, credentials JSON, and test/inventory/rates/reservations/availability endpoint paths.
2. Server-side encrypted credential persistence and a sanitized connection response (ciphertext is not returned to the browser).
3. HTTPS-only public provider host validation to block localhost and common private IPv4 ranges.
4. Configurable REST adapter with no assumed `/health`, `/inventory`, `/rates`, `/reservations`, or `/availability` provider endpoints. Required paths must come from the provider's actual API documentation.
5. Provider catalog migration for Booking.com, Expedia Group, Agoda, Airbnb, MakeMyTrip, Goibibo, Trip.com, Hostelworld, Google Hotel Ads, SiteMinder, STAAH, and a generic contracted channel bridge.
6. Auto-sync guard: it will not be enabled unless a connection is verified and inventory, rates, reservations, and availability paths are configured.
7. Reconnection failures turn off auto-sync and mark the connection as errored.
8. OTA provider onboarding guide and a new local transport guard test.

## Apply before testing

1. Back up the production Supabase project.
2. Apply `supabase/migrations/20261024_ota_provider_setup_catalog.sql` after the existing distribution runtime migrations. Apply all earlier unapplied migrations first, in filename order.
3. Set `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `ANAIRA_SECRET_KEY`, and `CRON_SECRET` in deployment secrets. Keep `ANAIRA_SECRET_KEY` stable: changing it without migrating ciphertext makes saved provider credentials undecryptable.
4. Install dependencies from the project's package manifest/lockfile in CI or deployment and run `npm run build` there. This archive has no `node_modules` or lockfile, so a full Next.js production build was not run in this audit container.
5. Sign a provider/channel-manager agreement, obtain sandbox API documentation and credentials, then use the OTA screen to test the provider's real test endpoint.
6. Test rate and inventory writes, reservation create/update/cancel, webhook signature, retries, duplicate delivery, and reconciliation in sandbox before production.

## Validation performed in this workspace

- JavaScript syntax check: 726/726 PASS.
- Relative import check: PASS.
- Booking runtime closure: 29 checks PASS.
- CRM enterprise static checks: 103 PASS, 0 FAIL.
- CRM Integration Hub: 12/12 PASS.
- Universal CRM: 12/12 PASS.
- Local mock-provider sandbox test: PASS (mock only; not OTA certification).
- New provider configuration guard: PASS (requires explicit paths and exercises local mock endpoints).
- Production gate: source files found; environment variables, production build, deployed browser E2E and provider certification remain pending.

## Important distinction

The code now provides a configurable integration setup and transport. It does not make every OTA API interchangeable. If a provider requires its own OAuth exchange, request signing, XML/proprietary payloads, certified schema, partner account activation, or allow-listed IPs, implement and test that provider-specific adapter using the official contract before enabling live sync. Google Hotel Ads is metasearch/booking-link distribution, not a normal OTA reservation inbox.
