# Work 02 — Property Store Controls, Domain Management & Marketplace Approval

**Project:** Anaira Universal Platform / Booking Engine  
**Supabase project:** `bhptqdoteucuymmdzsmg`  
**Status:** Source implementation + additive migrations applied; deployment and live-domain certification pending.

## 1. Implemented

### Property-wise store domain management
- Added `anaira_property_store_domains` for custom hostnames and Anaira subdomain requests.
- Domain states: `pending`, `active`, `disabled`; verification states: `pending`, `verified`, `failed`.
- Custom domains use per-domain DNS TXT ownership verification.
- Anaira-managed subdomain requests remain pending until their CNAME points to the configured Anaira hosting target.
- A verified domain still requires explicit activation.
- Only published, enabled property stores with an enabled membership can resolve.
- Domain resolver is server-side (`app/api/public/property-store/resolve-domain/route.js`) and returns only a safe route path. Verification tokens are not returned by public resolution.
- Browser roles cannot insert/update/delete domain records; all mutations go through authenticated server APIs using `adminDb` after explicit user/tenant authorization.

### Host routing
- Added Next.js 16 `proxy.js` for root requests on custom hostnames and configured Anaira subdomains.
- It calls the server-side domain resolver and rewrites to the existing `/property/[id]` or `/stay/[type]/[id]` route.
- Unknown domains receive `/domain-not-found`.
- The main platform hostname can be allowlisted using `ANAIRA_PLATFORM_HOSTNAMES`.

### Store administration
- Added `/store-builder/domains` for tenant domain management.
- Added `/super-admin/store-domains` for the Super Admin domain registry and activation/suspension.
- Added `/super-admin/property-stores` for independent marketplace approval, marketplace publication, direct-store publication, suspension and resume.
- Added links to these screens from the existing Store Builder and ANAIRA Store control center.
- Super Admin APIs validate the authenticated profile before privileged server-side operations.

### Marketplace approval gate
- Added `marketplace_approval_status`, `marketplace_approved_at`, `marketplace_approved_by` to `anaira_platform_stores`.
- New/unpublished stores default to `pending`.
- Previously published tenant hotel stores were backfilled as `approved` to preserve their pre-existing public visibility; this was a status-only update.
- Updated hotel, stay, camping and HMS marketplace search RPCs to require a tenant property store that is enabled, published and explicitly approved.
- Marketplace approval is separate from direct property-store publication.
- The four updated SECURITY DEFINER search RPCs have an empty `search_path`; their public execution is intentional because the central marketplace uses them for public read-only discovery.

## 2. Applied Supabase migrations

All migrations below were applied to the linked project `bhptqdoteucuymmdzsmg`.

| Version | Migration | Purpose |
|---|---|---|
| `20261127141515` | `property_store_domains_and_verification` | Domain registry, tenant RLS and safe verification metadata |
| `20261127141859` | `property_store_domain_resolver_server_only` | Removes the temporary public SECURITY DEFINER domain resolver; routing is server-only |
| `20261127141924` | `property_store_domain_fk_indexes` | Actor foreign-key indexes |
| `20261127142039` | `marketplace_property_store_approval_gate` | Marketplace approval state, legacy-public backfill and four search RPC gates |
| `20261127142133` | `marketplace_approval_function_search_path_hardening` | Empty search paths and service-role grants for search RPCs |
| `20261127142215` | `property_store_domains_server_only_writes` | Prevents browser-side writes to domain verification state |

No existing reservation, guest, room, inventory or payment records were deleted or recreated. No booking/inventory/payment data was modified.

## 3. Live database verification

Observed after migrations:

- `anaira_property_store_domains`: table exists, RLS enabled, 4 tenant policies, 0 domain rows.
- Anonymous role cannot read the domain table.
- Authenticated browser roles cannot INSERT, UPDATE or DELETE domain rows.
- Public domain SECURITY DEFINER resolver was removed; server API performs lookup with `adminDb`.
- Marketplace property stores: 2 approved, 5 pending, 2 published at verification time.
- The 2 already-published stores were retained as approved by the legacy-public backfill.
- Marketplace RPC smoke calls executed without SQL errors:
  - Hotel search: 0 rows for the smoke dates.
  - Homestay search: 0 rows for the smoke dates.
  - Camping search: 2 rows for the smoke dates.
  - HMS hospitality search: 0 rows for the smoke dates.

These are database query smoke tests, not a full customer booking or payment lifecycle test.

## 4. Automated source checks

- Property Store/domain/approval static assertions: **17/17 PASS**.
- Existing public hospitality storefront checks: **PASS**.
- Homestay store routing regression: **PASS**.
- Property profile sidebar/admin regression: **PASS**.
- Booking runtime closure: **29 checks, 0 failures**.
- JavaScript syntax: **745/745 PASS**.
- Relative import validation: **PASS, 0 failures**.
- TypeScript transpile syntax checks for all changed JSX/JS/API/proxy files: **PASS**.

## 5. Security advisor notes

No new domain-table RLS/no-policy finding was reported. The four public marketplace search RPCs are still reported by the advisor as SECURITY DEFINER functions executable by `anon` and `authenticated`; this is intentional for public marketplace discovery. They are read-only SQL functions, use an empty `search_path`, and filter to approved/published/enabled property stores. The project also has pre-existing advisor findings unrelated to this work, including a SECURITY DEFINER view, other SECURITY DEFINER RPCs, multiple permissive policies, and auth leaked-password protection not enabled. Those have not been broadly changed in this work because doing so would exceed the property-store migration scope and risk existing integrations.

## 6. Remaining / blocked production work

1. Configure `ANAIRA_STORE_DOMAIN`, `ANAIRA_STORE_CNAME_TARGET`, and `ANAIRA_PLATFORM_HOSTNAMES` in the deployment environment.
2. Configure wildcard DNS for Anaira subdomains and attach custom hostnames to the Vercel project; hosting-provider SSL issuance must be confirmed there.
3. Perform real TXT/CNAME verification and a live request against a configured domain. No domain records exist yet, so this cannot be certified.
4. Run full Next.js production build and browser E2E after dependencies and deployment environment are available. `npm ci` timed out in this execution environment; no full Next build is claimed.
5. Continue the larger Work 01 backlog: the full 14-category accommodation catalogue, map/wishlist/reviews, complete visual website builder sections/media, extended payment/commission/refund/payout workflows, OTA provider certification, and concurrency/tenant-isolation E2E.
6. Full inventory/booking/payment E2E, concurrent last-unit booking and tenant A/B isolation were not run in this work.

## 7. Production readiness

**Status: PARTIAL — database migration and source-level implementation complete for this workstream; not production-certified.**

The custom-domain feature is not live until DNS, Vercel domain attachment and SSL are configured. The platform's pre-existing shared inventory and booking RPCs were preserved; this work did not claim a new booking engine or payment lifecycle implementation.
