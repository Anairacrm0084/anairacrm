# WORK 12 — Super Admin Domain Routing and Property Custom Domains

## User requirement
- Until a property's custom domain is configured and activated, continue using `crm.anairapos.in` for the Anaira application and admin/login.
- Add a Super Admin sidebar option to manage platform/application hostnames.
- Add property custom domains from Super Admin, verify DNS ownership, and activate them.
- A verified/activated property custom domain serves that property's public storefront; it must not disable the CRM application domain.
- `anaira.com/anaira/hotels` remains the global public ANAIRA Stays marketplace.

## Implemented
1. Added Super Admin **Platform Domain Routing** page at `/super-admin/platform-domains`.
   - Hostnames persist in existing `anaira_platform_settings` under `anaira_platform_hostnames`.
   - `crm.anairapos.in` is protected and cannot be removed.
   - `anaira.com` and `www.anaira.com` are protected as public marketplace/application hosts.
2. Added authenticated Super Admin APIs to read/write platform hostnames.
3. Added a public, read-only hostname endpoint consumed by the Next.js proxy.
4. Updated `proxy.js` so configured platform hosts bypass property-store routing. CRM login/admin remains on `crm.anairapos.in`.
5. Added Super Admin sidebar entry **Property Custom Domains** at `/super-admin/store-domains`.
6. Extended the Super Admin property domain registry to add a domain against a selected property, show the TXT verification record, verify DNS, and activate/suspend the domain.
7. Prevented protected platform hostnames from being assigned to property stores.
8. Extended property-domain proxy rewriting to nested paths, retaining original query parameters.
9. Existing custom-domain resolver still requires `verification_status='verified'`, `domain_status='active'`, an enabled property store/membership and publication state.

## Routing contract
- Platform host `crm.anairapos.in` → Anaira application, login, admin and Super Admin.
- Public marketplace `anaira.com/anaira/hotels` → global ANAIRA Stays marketplace.
- Property custom domain → only the associated property's public storefront after DNS verification and activation.
- Activating a property domain does **not** deactivate CRM or move the admin login to the property domain.

## Verification
- Platform domain routing static checks: 10/10 PASS.
- JavaScript syntax: 753/753 PASS.
- Relative imports: PASS.
- Booking runtime: 29/29 PASS.
- Property custom-domain static checks: 17/17 PASS.
- Public hospitality storefront: PASS.
- Property/Book page parity: PASS.
- `/book` checkout route preservation: PASS.
- No database migration was required; uses existing `anaira_platform_settings` and `anaira_property_store_domains` tables.

## Operational setup still required
- Deploy the updated application to the Vercel project serving `crm.anairapos.in` and `anaira.com`.
- Add each property's custom hostname to the same Vercel project and configure its DNS records as instructed by the hosting provider.
- Add the TXT verification record shown in Super Admin, wait for DNS propagation, click **Verify DNS**, then **Activate**.
- Confirm SSL is provisioned by Vercel before sharing the custom domain.
- No live DNS, Vercel domain attachment, SSL issuance, or production browser test was performed by this source update.
