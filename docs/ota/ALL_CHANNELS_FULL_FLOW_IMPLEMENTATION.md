# Anaira Central OTA Distribution — All Channels Full Flow

## Supported provider catalogue

| Provider | Integration route | Supported capability model | External dependency |
|---|---|---|---|
| Booking.com | Approved direct API or channel manager | Rates, availability, reservations, modifications, cancellations | Partner approval and contracted API credentials |
| Airbnb | Approved connectivity partner | Availability and reservation lifecycle | Eligible listing and approved connectivity partner |
| Agoda | Approved direct API or channel manager | Rates, availability, reservations | Partner approval and credentials |
| Expedia Group | Approved direct API or channel manager | Rates, availability, reservations, modifications, cancellations | Partner approval and credentials |
| MakeMyTrip | Partner API or channel manager | Rates, availability, reservations | Commercial/API access |
| Goibibo | Partner API or channel manager | Rates, availability, reservations | Commercial/API access |
| Trip.com | Partner API or channel manager | Rates, availability, reservations | Partner approval and credentials |
| Hostelworld | Partner API or channel manager | Availability and reservations | Eligible accommodation and partner access |
| Google Hotel Ads | Hotel Center/connectivity partner | Rates and booking links | Hotel Center and connectivity eligibility; not a general OTA reservation inbox |
| SiteMinder | Channel-manager API | Multi-channel rates, availability and reservation lifecycle | SiteMinder contract/API access |
| STAAH | Channel-manager API | Multi-channel rates, availability and reservation lifecycle | STAAH contract/API access |
| GDS | Contracted GDS bridge | Configured distribution lifecycle | GDS/bridge contract and schema |
| Custom API Connector | Customer-managed REST | Configurable lifecycle | Customer's API specification and credentials |
| Anaira Booking Engine | Native internal | Rates, availability and reservations | Anaira tenant/property configuration |
| Anaira Marketplace | Native internal | Rates, availability and reservations | Anaira tenant/property configuration |

## End-to-end property workflow

1. Select an existing accommodation property; OTA actions remain blocked for unrelated business types.
2. Register the existing OTA listing ID and account email. Owner authorization is mandatory. Anaira does not create a duplicate OTA listing.
3. Super Admin reviews the authorization request. This approval records workflow authorization; it does not substitute for provider-issued API access.
4. Configure a provider-approved HTTPS base URL, authentication mode, secret, account/property reference and endpoint paths from the provider's current documentation.
5. Run the endpoint connectivity test. A successful HTTP test proves only that the configured endpoint responded; it is not provider certification or production channel approval.
6. Create/select the property's channel instance. Map each Anaira room/unit type and rate plan to the provider's external codes. Verify mappings with the provider/channel manager before sync.
7. Enable inventory, rate and reservation directions only after mappings and connection are verified. Auto-sync defaults off.
8. Outbound worker processes inventory/rate/availability jobs with idempotency, retry backoff and stale-worker recovery.
9. Inbound signed webhooks are rate-limited, tenant/property routed, deduplicated and queued. The inbox processor imports/updates/cancels PMS reservations and reconciles inventory.
10. Monitor connection errors, sync events, reservation inbox and retries. Reconcile provider and PMS reservation references before go-live.

## Endpoint configuration contract

The configurable REST transport intentionally does not invent official provider endpoints. Configure these relative paths using the provider's approved API documentation:

- `test_path` — authenticated health/account test.
- `inventory_path` — inventory/availability update.
- `rate_path` — rate update.
- `reservation_path` — reservation/booking operation where the provider supports it.
- `availability_path` — optional dedicated availability operation.
- Optional method overrides: `test_method`, `inventory_method`, `rate_method`, `reservation_method`, `availability_method`.
- Optional `timeout_ms`.

Credentials are encrypted server-side. Do not put secrets in client code, public environment variables, screenshots, or plain-text settings. For OAuth providers, token issuance, refresh, scopes and callback URLs must follow the actual provider contract; generic bearer-token support alone does not implement a provider OAuth authorization grant.

## Honest activation states

- `not_configured`: no usable provider setup.
- `configured`: configuration saved; no successful live test yet.
- `connected`: configured endpoint test succeeded. This is not certification.
- `error`: last test/operation failed.
- `authorization_requested` (existing-listing workflow): owner has requested linking; provider API access is not implied.

A channel must not be described as production-live until the provider has approved the integration, credentials and mappings are verified, inbound and outbound sandbox tests pass, and the provider's production activation is confirmed.

## Current limitations / external dependencies

This release provides the shared catalogue, configurable connector transport, normalized reservation contract, tenant/property guards, existing-listing request workflow, room/rate mapping, webhook inbox, retry worker and audit surfaces. It does not claim native provider certification, official OAuth grants, or live production connectivity for all providers. Exact provider API schemas, credentials, account approvals, webhook signing rules and sandbox access must be supplied by each provider or contracted channel manager. Google Hotel Ads is metasearch/booking-link distribution and must not be treated as a normal OTA booking inbox.

## Validation

Run:

```bash
node tests/ota/all-provider-catalog.mjs
node tests/ota/existing-listing-link-static.mjs
node tests/ota/inbound-reservation-normalization.mjs
node tests/ota/inbox-runtime-static.mjs
node tests/ota/replay-safety-static.mjs
node tests/ota/property-only-scope.mjs
node scripts/ota-provider-configuration-guard.mjs
node scripts/verify-js-syntax.mjs
node scripts/verify-relative-imports.mjs
```

The provider configuration guard uses a local mock HTTP endpoint. It is a transport test, not a provider sandbox or certification test.
