# Anaira CRM Menu Full Function Audit — 2026-10-01

Visible CRM menu: 22 items.

## Runtime mapping

| Menu | Route | Runtime | Data/Workflow | Status |
|---|---|---|---|---|
| Customer 360 | /customer-360 | Dedicated Customer 360 | customer master + stays + restaurant + loyalty + service + AI + timeline + identity | IMPLEMENTED / E2E PENDING |
| Hotel Guest CRM | /hotel-guest-crm | Dedicated HGC | 31 operational subviews + live CRM data | IMPLEMENTED / E2E PENDING |
| Restaurant CRM | /restaurant | Restaurant CRM plugin | live restaurant customer metrics + refresh/tag/segment actions | IMPLEMENTED / E2E PENDING |
| Timeline / Interactions | /timeline | Omnichannel Timeline plugin | live timeline + rebuild/filter actions | IMPLEMENTED / E2E PENDING |
| Leads & Sales | /leads | Lead Management plugin | qualify/convert/follow-up/lost | IMPLEMENTED / E2E PENDING |
| Corporate CRM | /corporate | Corporate CRM plugin | account/contract/review workflow | IMPLEMENTED / E2E PENDING |
| Partners | /partners | Partner CRM plugin | onboarding/commission/settlement | IMPLEMENTED / E2E PENDING |
| Quotes | /quotes | Dedicated Quote Studio | create/calculate/approve/accept/reject | IMPLEMENTED / E2E PENDING |
| Partner Bookings | /partner-bookings | Dedicated operations page | booking/commission/lifecycle/settlement | IMPLEMENTED / E2E PENDING |
| Guest Relations | /guest-relations | Guest Relations plugin | assign/SLA/escalate/resolve/recovery | IMPLEMENTED / E2E PENDING |
| Complaints | /complaints | Guest Relations plugin | complaint + service recovery lifecycle | IMPLEMENTED / E2E PENDING |
| Service Recovery | /complaints | Same canonical recovery workspace | recovery is handled in complaint workflow | IMPLEMENTED |
| VIP | /vip | VIP plugin | qualification/manager/amenities | IMPLEMENTED / E2E PENDING |
| Loyalty | /loyalty | Loyalty plugin | issue/redeem/reverse/tier refresh | IMPLEMENTED / E2E PENDING |
| Segments | /segmentation | Segmentation plugin | preview/recalculate/activate campaign | IMPLEMENTED / E2E PENDING |
| Offers & Coupons | /marketing | Offers plugin | validation/deactivation/redemption | IMPLEMENTED / E2E PENDING |
| Campaigns | /campaigns | Marketing Automation plugin | audience/run/pause/activate/attribution | IMPLEMENTED / E2E PENDING |
| WhatsApp CRM | /whatsapp-crm | WhatsApp plugin | templates/retry/read/conversation actions | IMPLEMENTED / PROVIDER E2E PENDING |
| Workflows / Automation | /workflows | Dedicated Workflow Builder | trigger/steps/create/activate/run/history | IMPLEMENTED / E2E PENDING |
| SEO System | /seo | SEO runtime | crawler/GSC/GA4/rank/content/schema | EXISTING RUNTIME / PROVIDER E2E PENDING |
| AI Review Automation | /ai-reviews | AI Review runtime | sync/classification/reply/approval/publish/workers | EXISTING RUNTIME / PROVIDER E2E PENDING |
| Events / Upselling | /events | Event CRM plugin | quote/proposal/follow-up/deposit | IMPLEMENTED / E2E PENDING |

## Source fixes in this pass

- Converted CRM domain menu routes from generic ModulePage/SimplePage to their corresponding domain plugin runtimes where a real action contract exists.
- Added dedicated Quotes operational page.
- Added dedicated Partner Bookings operational page.
- Added dedicated CRM Workflow Builder backed by `crm_workflows`, `crm_workflow_runs`, and `anaira_start_workflow`.
- Expanded Customer 360 to consume identity links, channels, stays, restaurant visits, requests, complaints, tasks, loyalty ledger, upsell events, AI insights, feedback, timeline, relationship assignments and data requests.
- Added CRM-child plugin fallback to the parent `crm` activation so child CRM workspaces can operate when the parent CRM plugin governs activation.
- Fixed WhatsApp CRM sidebar target from `/integrations` to `/whatsapp-crm`.
- Added Relationship Manager workload rebalance runtime result.
- Fixed malformed Hotel Guest CRM data-loader entry for merge events / segment rules / loyalty lifecycle / AI registry / provider config datasets.

## Verification

- JavaScript syntax: 343/343 PASS
- Hotel Guest CRM static checks: 67/67 PASS
- P1 CRM market parity: 10/10 PASS
- P7 final certification: NOT CERTIFIED because environment-level package-lock, production build, live Supabase/RLS, provider E2E, browser E2E and cross-tenant negative E2E are still blocked.

This report distinguishes source/runtime implementation from production certification.
