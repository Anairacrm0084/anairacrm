# ANAiRA CRM Phase 21 — A-to-Z Source Audit

Catalog plugins: 40
Registry manifests: 40
JS syntax files checked: 158; failures: 0

## 40-plugin contract matrix

| Plugin | Route | Page dir | Data owner | Settings | Permissions | Dependencies |
|---|---|---|---|---:|---:|---:|
| crm | Anaira CRM | customer-360 | True | crm_customers | 14 | 3 | 0 |
| hotel-booking | Hotel Booking Engine | booking | True | crm_booking_transactions | 16 | 3 | 0 |
| hotel-management-suite | Anaira Hotel Management System | hotel-management | True | hms_rooms | 15 | 3 | 0 |
| hotel-pms | Hotel PMS | pms | True | hms_rooms | 14 | 3 | 0 |
| restaurant-reservation | Restaurant Reservation | reservation | True | restaurant_reservations | 14 | 3 | 0 |
| food-delivery | Food Delivery Marketplace | delivery | True | delivery_orders | 15 | 3 | 0 |
| restaurant-store | Restaurant Store Builder | store | True | restaurant_storefronts | 14 | 3 | 0 |
| anaira-pos | Anaira POS | pos | True | anaira_marketplace_orders | 14 | 3 | 0 |
| channel-manager | Channel / OTA Manager | channel-manager | True | ota_channels | 15 | 3 | 0 |
| seo-system | Anaira SEO System | seo | True | crm_seo_sites | 21 | 3 | 0 |
| ai-review-system | Anaira AI Review Automation | ai-reviews | True | crm_reviews | 21 | 3 | 0 |
| customer_360 | Customer 360 | customer-360 | True | crm_customers | 14 | 3 | 0 |
| customer_intelligence | Customer Intelligence | customer-intelligence | True | crm_customer_insights | 13 | 3 | 1 |
| hotel_guest_crm | Hotel Guest CRM | hotel-guest-crm | True | crm_guest_stays | 13 | 3 | 2 |
| restaurant_crm | Restaurant CRM | restaurant-crm | True | crm_restaurant_customer_metrics | 13 | 3 | 1 |
| customer_ltv | Customer Lifetime Value | customer-ltv | True | crm_customer_value_snapshots | 14 | 3 | 1 |
| lead_management | Lead Management | lead-management | True | crm_leads | 13 | 3 | 0 |
| followups | Follow-up Management | followups | True | crm_followup_events | 13 | 3 | 0 |
| corporate_crm | Corporate CRM | corporate-crm | True | crm_corporate_accounts | 13 | 3 | 0 |
| partner_crm | Partner CRM | partner-crm | True | crm_partners | 13 | 3 | 0 |
| loyalty | Loyalty CRM | loyalty | True | crm_loyalty_accounts | 14 | 3 | 0 |
| offers_coupons | Offers & Coupons | offers-coupons | True | crm_coupon_definitions | 13 | 3 | 0 |
| marketing_automation | Marketing Automation | marketing-automation | True | crm_campaigns | 13 | 3 | 0 |
| whatsapp_crm | WhatsApp CRM | whatsapp-crm | True | crm_message_log | 13 | 3 | 0 |
| reputation | Review & Reputation | reputation | True | crm_reviews | 13 | 3 | 1 |
| guest_relations | Guest Relations | guest-relations | True | crm_complaints | 13 | 3 | 1 |
| segmentation | Customer Segmentation | segmentation | True | crm_segments | 13 | 3 | 0 |
| churn | Churn / At-Risk | churn | True | crm_churn_scores | 13 | 3 | 0 |
| vip | VIP Management | vip | True | crm_vip_profiles | 13 | 3 | 0 |
| revenue_management | Revenue Management | revenue-management | True | crm_revenue_rate_recommendations | 14 | 3 | 0 |
| upselling | Upselling Engine | upselling | True | crm_upsell_offers | 13 | 3 | 1 |
| cross_selling | Cross-Selling Engine | cross-selling | True | crm_cross_sell_rules | 13 | 3 | 1 |
| event_crm | Event CRM | event-crm | True | crm_events | 13 | 3 | 0 |
| omnichannel_timeline | Omnichannel Timeline | omnichannel-timeline | True | crm_timeline_events | 13 | 3 | 1 |
| consent_privacy | Consent & Privacy | consent-privacy | True | crm_consents | 13 | 3 | 1 |
| relationship_manager | Relationship Manager | relationship-manager | True | crm_relationship_assignments | 13 | 3 | 1 |
| advanced_analytics | Advanced CRM Analytics | advanced-analytics | True | crm_analytics_daily | 14 | 3 | 1 |
| ai_crm | AI CRM | ai-crm | True | crm_ai_insights | 13 | 3 | 1 |
| revenue_forecasting | Revenue Forecasting | revenue-forecasting | True | crm_revenue_forecasts | 14 | 3 | 1 |
| competitor_intelligence | Competitor Rate Intelligence | competitor-intelligence | True | crm_competitor_rates | 13 | 3 | 1 |

## Runtime truth policy
- No runtime page inserts demo/sample business records.
- Empty datasets show empty state.
- Super Admin KPI page reads live Supabase.
- Every plugin has an explicit local registry manifest, settings schema, permission namespace and data owner mapping.
- Custom plugin settings are tenant-scoped and audited.
- Secrets are not stored in plugin JSON settings.
- Anaira POS remains a bridge and is not reimplemented as CRM-owned POS.

## Remaining environment-dependent verification
- External provider E2E requires real credentials and deployment execution; the source does not fabricate successful provider responses.
- Full Next.js production build could not be certified in this environment because dependency installation did not complete within the execution window.