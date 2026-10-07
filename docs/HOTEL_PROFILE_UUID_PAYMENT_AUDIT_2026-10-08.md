# Hotel Profile UUID + Payment Runtime Audit — 2026-10-08

## Verified live Supabase findings
- Current hotel tenant: NH3 HOTEL, restaurant UUID `a4569eac-5ed1-4136-b32f-356a02531073`.
- A canonical hospitality master row was missing for this tenant; it was repaired with generated UUID `4faa9d3d-0bea-4cda-9e1e-b4bca8d614af`.
- Existing orphan hospitality-master rows remain for deleted historical tenants and were not blindly deleted because references must be reconciled first.
- `public.anaira_hotel_payment_submissions` does NOT exist in the live database.
- The live canonical payment-submission table is `public.hms_booking_payment_submissions`.
- The application had been querying the missing `anaira_hotel_payment_submissions` table on the Hotel Management dashboard; source was corrected to `hms_booking_payment_submissions`.
- Hotel profile setup had a UUID-risk on `marketplace_destination_id`: stale/non-UUID values or UUIDs not belonging to the current store destination list could be submitted to a UUID column. Source now validates the UUID format and current destination membership and falls back to null.
- Hotel profile setup did not reliably populate the hotel name/contact fields from the canonical `restaurants` row when `hms_settings` was empty. Source now uses restaurant master values as fallbacks.
- The live `anaira_sync_business_capabilities()` trigger was hardened so hotel tenants create/update a canonical `anaira_hospitality_properties_master` row automatically.
- Existing NH3 HOTEL was re-synced; its hotel platform membership is enabled and `catalog_source=anaira_hms`.

## Source/runtime findings
1. Hotel Profile UI saves to `hms_settings` and updates `restaurants`; it does not directly create the hospitality master row.
2. Automatic master-row creation depended on a DB trigger. The previous trigger did not maintain `anaira_hospitality_properties_master` for `restaurants` tenants.
3. Payment source and database had diverged: migrations/RPCs referenced both `anaira_hotel_payment_submissions` and `hms_booking_payment_submissions`, while the live database only contains the latter.
4. Hotel dashboard source was still querying the non-existent `anaira_hotel_payment_submissions` table.
5. The ZIP has no installed `node_modules`; `node --check` passes for the modified files, but `npm run build` cannot run in the extracted audit tree because `next` is not installed. A clean install/build must be run in the real repository/CI.

## Important deletion finding
Two orphaned `anaira_hospitality_properties_master` rows were found with tenants that no longer exist in `restaurants`:
- `85563161-4e3b-404d-bae7-aeff84fd0b15` → old tenant `24d07e93-10dd-44aa-b5c7-3e3e2e638f46`, source `anaira_hotel_properties` / `e1a6fff7-dd51-46f2-875d-3ed4115fcd8d`, NH3 Hotel.
- `2c23030c-6931-4f05-a20c-5c22c716f709` → old tenant `acd26bbd-36ad-427f-8021-639f2db41de5`, source `restaurants` / same tenant UUID, NH3.

They were NOT deleted automatically because historical CRM rows reference these property UUIDs. Deleting them without a retention/repointing plan would risk broken foreign-key relationships or historical CRM data.

## Files changed in this audit
- `app/hotel-management/setup/page.js`
- `app/hotel-management/page.js`
- `supabase/migrations/20261008_hotel_profile_master_payment_alignment.sql`

## Validation
- `node --check app/hotel-management/setup/page.js` — PASS
- `node --check app/hotel-management/page.js` — PASS
- Live Supabase master row for NH3 HOTEL — PRESENT
- Live payment table — `hms_booking_payment_submissions`
- `npm run build` in extracted ZIP — NOT RUNNABLE because `next` is not installed in the extracted environment
