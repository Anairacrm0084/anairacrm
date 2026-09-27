# Anaira CRM / Booking / Restaurant Market Benchmark — 2026-09-25

## Benchmark scope

Compared the current Anaira Hotel + Restaurant CRM / Booking / Restaurant reservation architecture against publicly documented capabilities from Revinate, SevenRooms, Toast, SiteMinder and Cloudbeds.

## Market capabilities verified

- Revinate: unified hospitality guest profiles, data unification, segmentation, loyalty and decision-intelligence/activation across hotel guest touchpoints.
- SevenRooms: restaurant CRM with 100+ guest data points, order/POS spend, reservations/waitlist, segmentation, marketing automation, loyalty/perks, reputation management, table management and integrations.
- Toast Guest CRM: unified orders, visits, reservations, feedback and loyalty/marketing context in guest profiles, with AI insights.
- SiteMinder: direct booking engine, promotions, multi-language/currency, payments, reservations and broad integrations.
- Cloudbeds: branded mobile-first booking engine, rate/promo/upsell flow and booking-engine integration with real-time inventory/rates/policies.

## Anaira gaps identified and addressed in this package

### 1. Customer identity vs domain lifecycle
Shared identity remains `crm_customers`.
Hotel lifecycle remains `crm_guest_stays`.
Restaurant lifecycle remains `crm_restaurant_visits`.
Cross-domain visibility is exposed through Customer 360/events rather than copying hotel functions into Restaurant CRM or restaurant functions into Hotel CRM.

### 2. Hotel booking transaction
The public hotel booking RPC now:
- validates guest counts and room capacity;
- locks each requested inventory date with `FOR UPDATE`;
- rejects missing/closed/out-of-stock nights;
- increments inventory atomically only after all nights pass validation;
- resolves the CRM customer;
- creates PMS linkage and CRM stay history;
- emits booking/payment authorization events.

### 3. Restaurant reservation transaction
The public restaurant reservation RPC now:
- rejects past dates and invalid party sizes;
- verifies marketplace reservation enablement;
- checks the actual restaurant reservation slot/table availability function;
- resolves the shared CRM customer;
- stores `customer_id` on the restaurant reservation;
- emits CRM interaction and platform events.

### 4. Customer 360
Added `anaira_get_customer_360(tenant_id, customer_id)` to return one customer identity plus separate Hotel and Restaurant lifecycle sections.

### 5. Tenant-safe CRM API
The `/api/crm/customers` route now obtains the authenticated user/profile context, scopes reads to the tenant and requires a tenant for writes.

## Important remaining production gates

These are intentionally NOT marked complete merely because source/database structures exist:

- Razorpay/Stripe live provider credentials and webhook E2E.
- Full payment/refund/reconciliation E2E.
- WhatsApp/SMS/email provider worker delivery and retry proof.
- OTA provider adapters and real reservation sync.
- Full browser E2E test matrix.
- Production build certification: this source package still has no generated `package-lock.json`; dependency installation/build could not be completed within the audit runtime.
- Supabase Security Advisor still reports intentionally public SECURITY DEFINER endpoints plus the Auth leaked-password-protection warning. Public booking/marketplace functions should remain public only where required; internal functions need continued EXECUTE privilege review.

## Architectural rule

Anaira CRM is the relationship/intelligence layer. PMS, POS, Booking Engine, Restaurant Store, Restaurant Reservation, OTA and payment systems retain operational ownership and communicate with CRM through explicit records/events/contracts.
