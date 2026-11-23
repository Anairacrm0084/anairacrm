# Anaira OTA — Dual Existing Listing Connection Routes

Every accommodation property (hotel, homestay, cottage, resort, villa, camp, guest house, lodge, hostel, farm stay, glamping) can link an already-listed OTA property using one of two routes. The flow does not create a duplicate OTA listing.

## Route A — Anaira Super Admin managed API
1. Property admin chooses `Anaira Super Admin API / central provider account`.
2. Property enters OTA, existing listing/property ID, account email, current management method and owner authorization.
3. Super Admin reviews the request and checks that Anaira has an active, approved provider account for that OTA.
4. Super Admin/provider completes the official partner authorization and assigns the central provider account.
5. Anaira maps the property’s existing external listing, room/unit types and rate plans.
6. Only after provider approval, verified mappings and inbound/outbound tests can live sync be activated.

## Route B — Property-owned OTA account
1. Property admin chooses `Property-owned OTA account / direct authorization`.
2. Property enters the existing OTA listing ID and the email used on the OTA account; confirms owner/authorized representative consent.
3. Super Admin reviews the request and sends the owner through the provider’s official OAuth/extranet/connectivity process where supported.
4. Provider/partner authorization is verified, then rooms, units, rates and inventory are mapped.
5. Live sync remains disabled until the provider permits the integration and tests pass.

## Security and truthfulness
- Never request the owner's normal OTA password.
- Do not put provider secrets in browser code or ordinary property settings.
- Route selection is not proof of API access. `authorization_requested` remains pending until a real approved connection exists.
- No new OTA listing is created; preserve listing ID, reviews and existing OTA content.
- If provider access is unavailable, retain the record in Manual Mode / pending approval.
- Google Hotel Ads is metasearch, not a normal OTA reservation channel.

## Migration
Apply `20261123150000_ota_dual_connection_routes.sql` after confirming the previous existing-listing migrations are already applied. It is additive and preserves existing rows.
