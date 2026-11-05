# Anaira CRM + Hospitality — production verification (2026-11-05)

## Completed in this handoff

- Public customer entry routes `/hotel-store` and `/stays` redirect to `/anaira/hotels`; property administration remains on authenticated operator routes.
- Public hospitality marketplace routes hotel, camp, homestay, guest-house and cottage searches to their corresponding public detail/availability flows.
- Public UUID property resolution no longer requires an `anaira_store_memberships` row; an active restaurant/property record is resolved first and membership data is optional enrichment.
- Live Supabase policy `anaira_store_memberships_public_read` was corrected and recorded as migration `20261105084338_fix_public_store_membership_rls_scope`. It now requires an enabled membership whose `store_id` and `restaurant_id` both match an enabled, published, non-platform tenant store.
- Live verification confirmed the new policy predicate is installed. Current enabled, published tenant membership rows: 2; valid owner matches: 2; mismatches: 0.
- Live platform data: 2 camp property profiles; 0 active camp unit types, 0 active camp rate plans, 0 camp inventory rows; 0 active alternative-stay property profiles. No inventory, rates, or property records were fabricated.

## Source checks run

- Public hospitality storefront static test: 12/12 PASS.
- JavaScript syntax: 731/731 PASS.
- Relative import verification: PASS, 0 failures.
- Booking runtime closure: 29/29 PASS.
- Enterprise CRM static: 103/103 PASS.
- Hotel Guest CRM static: 67/67 PASS.
- P3 restaurant reservations: 13/13 PASS.
- P5 SEO static: 12/12 PASS.
- P6 integration hub static: 12/12 PASS.

## Still not production-certified

- Clean dependency installation did not complete in this environment; offline install reports an uncached `tslib` package. Production Next.js build was therefore not run.
- P7 final certification remains `RELEASE CANDIDATE / NOT PRODUCTION CERTIFIED`.
- P1 and P4 certification inputs/reports are still blocked; SEO certification report is still blocked.
- Live deployed browser E2E, tenant-A-to-tenant-B negative tests, real payment/provider callbacks, and full CRM→booking→PMS→customer checkout E2E were not run.
- Camping and alternative-stay customer checkout cannot be certified until operators configure real active unit types, rate plans and dated inventory. Do not insert placeholder stock or prices.
- Source migrations `20261024_bulk_daily_rate_calendar.sql`, `20261024_ota_provider_setup_catalog.sql`, and `20261024_public_camping_store_ota_hardening.sql` are not recorded in live migration history. Their effects are partially present; reconcile each statement against live schema/data before applying any remainder. In particular, `anaira_bulk_set_daily_rate(...)` was absent and only 6 of 12 OTA provider catalog entries were present in the last audit.

## Operator actions required

1. Configure real camp unit types, rate plans and inventory dates in the operator UI.
2. Configure real homestay/guest-house/cottage property profiles, unit types, rate plans and inventory.
3. Restore private `.env.local` locally; never commit service-role or provider secrets.
4. Run clean `npm ci`, `npm run build`, deployed browser E2E and cross-tenant tests in a configured deployment environment.
5. Reconcile the three unrecorded 20261024 migrations statement-by-statement; do not blindly replay the data-seeding migration.
