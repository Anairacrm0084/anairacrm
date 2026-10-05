# Anaira Universal Multi-Business CRM — Completion

The CRM is no longer conceptually limited to hotel guests or restaurant customers. Existing hospitality and restaurant CRM modules remain intact, while a universal business context layer supports arbitrary customer-facing businesses.

## Supported verticals

Hotel, resort, restaurant, cafe, bakery, bar, salon, barber, spa, clinic, hospital, dentist, doctor, pharmacy, gym, yoga, retail, grocery, fashion, jewellery, electronics/mobile, automotive, real estate, travel, education/coaching, legal, accounting/CA/tax, agency/professional services, IT/software/digital, repair, cleaning, pet/veterinary, photography, events, coworking, logistics, construction/home services, ecommerce, SaaS/subscription, creator/personal brand, nonprofit and other business.

## Universal layers

- `crm_business_profiles`: tenant-level business vertical and platform context.
- `crm_universal_interactions`: generic lead/inquiry/appointment/booking/purchase/service/consultation/visit/order/support/review/payment lifecycle events.
- `crm_universal_service_profiles`: vertical-specific service catalog without changing the CRM core.
- `anaira_crm_record_universal_interaction(...)`: tenant-authorized interaction ingestion RPC.
- `/api/crm/universal/config`: authenticated tenant-scoped CRM context/config API.

## Design rule

Hospitality-specific data remains available for hotel/camp/homestay/guest-house/cottage operations. Universal CRM data handles every other business without forcing hospitality fields onto unrelated businesses.

External provider E2E (WhatsApp, email/SMS, review providers, payment systems, etc.) remains environment/provider gated.
