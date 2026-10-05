# Anaira — 40-Area Market Capability Matrix

Date: 2026-10-03

Status meanings:
- IMPLEMENTED: source contains the operational capability and runtime path.
- PARTIAL: architecture/runtime exists but important provider/product depth remains.
- ENVIRONMENT: source is present but cannot be certified without deployment/credentials/provider callbacks.
- NOT CERTIFIED: no evidence in source of a production certification result.

| # | Capability | Anaira status | Closure evidence / remaining gate |
|---:|---|---|---|
| 1 | Booking Engine | IMPLEMENTED | Search, availability, rates, quote, checkout, manage, cancel, group and multi-room routes/RPCs. |
| 2 | PMS | IMPLEMENTED | HMS/PMS reservations, room inventory and lifecycle integrations. |
| 3 | Channel Manager | ENVIRONMENT | Distribution runtime/worker/connection test exists; production channel certification remains. |
| 4 | OTA connectivity | ENVIRONMENT | Booking.com/Expedia/Agoda/MMT/Goibibo adapter contracts exist; provider credentials/contracts and live callbacks remain. |
| 5 | GDS | ENVIRONMENT | GDS adapter slot exists; live certification remains. |
| 6 | Metasearch | ENVIRONMENT | Distribution/SEO acquisition layers exist; live partner feed certification remains. |
| 7 | RMS / Dynamic Pricing | IMPLEMENTED | Pricing engine, demand/occupancy/season/weekend/LOS/promotion controls and revenue records exist. |
| 8 | CRM | IMPLEMENTED | Customer 360, guest lifecycle, interactions and domain events. |
| 9 | Loyalty | IMPLEMENTED | Member context, benefits, loyalty lifecycle/reversal foundation. |
| 10 | Corporate/B2B | IMPLEMENTED | Corporate and negotiated rates plus corporate CRM runtime. |
| 11 | Group Booking | IMPLEMENTED | Group booking, allocation and folio routes/tables. |
| 12 | Payments | ENVIRONMENT | Razorpay/Stripe/manual flows and webhooks exist; live credentials/E2E remain. |
| 13 | Refunds | ENVIRONMENT | Refund route/ledger/provider adapters exist; settlement certification remains. |
| 14 | GST/Invoice | IMPLEMENTED | Invoice snapshots, sequences, GST/tax and credit-note closure. |
| 15 | Multi-property | IMPLEMENTED | Tenant/property scope and unified hospitality property model. |
| 16 | Multi-language | IMPLEMENTED | Booking localization catalog/runtime now supports language selection and tenant catalog. Translation content breadth remains product-configurable. |
| 17 | Multi-currency | IMPLEMENTED | Supported currency registry, tenant currency catalog and explicit FX-rate runtime added. Provider settlement currency remains separately controlled. |
| 18 | Guest messaging | IMPLEMENTED | CRM communication and guest lifecycle messaging queues. |
| 19 | WhatsApp | ENVIRONMENT | WhatsApp send/runtime exists; provider delivery credentials/callback proof remains. |
| 20 | Marketing automation | IMPLEMENTED | Campaigns, workers, automation schedules and CRM events. |
| 21 | Analytics | IMPLEMENTED | Booking funnel, revenue, CRM, SEO and operational analytics layers. |
| 22 | AI | IMPLEMENTED | AI review, CRM AI actions, telemetry, approval and recovery runtimes. |
| 23 | Marketplace | IMPLEMENTED | Hotel/restaurant marketplace and store flows. |
| 24 | Mobile | IMPLEMENTED | Responsive/mobile-first booking UI; native app certification is a separate deployment concern. |
| 25 | API/Webhooks | IMPLEMENTED | Public APIs, provider webhooks, event inbox/delivery and idempotency patterns. |
| 26 | Security/RLS | PARTIAL | Booking closure RLS/EXECUTE hardening applied; broader platform advisor findings still require full platform remediation. |
| 27 | Audit logs | IMPLEMENTED | CRM/audit/event records across major operational lifecycles. |
| 28 | Reconciliation | IMPLEMENTED | Payment/channel reconciliation cases and ledger foundations. Live provider settlement remains ENVIRONMENT. |
| 29 | Rate parity | IMPLEMENTED | Booking parity/collection and market-parity runtime. |
| 30 | Competitor rate shopping | IMPLEMENTED | Competitor/SEO market-parity and rate-source structures exist; provider data credentials remain environment-dependent. |
| 31 | Upselling | IMPLEMENTED | Upselling/add-on runtime and guest CRM surfaces. |
| 32 | Packages/Add-ons | IMPLEMENTED | Booking packages/add-ons configuration and quote integration. |
| 33 | Direct-booking incentives | IMPLEMENTED | Direct benefits, personalized offers, member/corporate/negotiated rate context. |
| 34 | Abandoned booking recovery | IMPLEMENTED | Abandoned booking endpoint, event/runtime and CRM automation foundations. |
| 35 | Distribution automation | IMPLEMENTED | Queue worker, retries, dead-letter behavior, sync events and provider adapter runtime. Live provider certification remains ENVIRONMENT. |
| 36 | Revenue analytics | IMPLEMENTED | Revenue daily records, funnel/revenue analytics and rate controls. |
| 37 | AI/agentic booking | PARTIAL | AI action/runtime foundation exists; autonomous guest-facing agent certification and policy controls remain product/deployment work. |
| 38 | Enterprise controls | IMPLEMENTED | Super-admin/business-admin control plane, permissions, tenant/property scopes and plugin controls. |
| 39 | White-label/multi-tenant | IMPLEMENTED | Tenant/property-scoped architecture, store builder and hospitality branding controls. |
| 40 | Production certification | ENVIRONMENT | Requires clean install/build, deployed browser E2E, cross-tenant negative E2E, live payments, messaging and provider-certified OTA/GDS/metasearch tests. |

## Verification executed on this package

- JavaScript syntax: 378/378 PASS.
- Booking runtime closure: 29/29 PASS.
- P0 static foundation: 8/8 PASS; production build intentionally not claimed because clean dependency installation is unavailable in the audit environment.
- P3 restaurant reservation: 13/13 PASS.
- P4 AI review: 15/15 PASS.
- P5 SEO market parity: 12/12 PASS.
- P6 Integration Hub: 12/12 PASS.
- P7 remains RELEASE CANDIDATE / NOT PRODUCTION CERTIFIED because environment-only gates are still open.

## Important certification rule

A provider adapter, webhook route or mock/sandbox test is not equivalent to a provider-certified production connection. The package deliberately keeps those gates open until real credentials, deployed callbacks, provider contracts and end-to-end reservation/payment/reconciliation evidence are available.
