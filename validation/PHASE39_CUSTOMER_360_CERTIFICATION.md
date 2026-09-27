# Phase 39 — Customer 360 Master Data Certification

## Scope
Customer 360 (`/customer-360`) is treated as master-data management plus derived customer value refresh.

## Contract
- Editable: full_name, phone, email, gender, date_of_birth, anniversary_date, address_line1, city, state, country, preferred_language, customer_type, vip, notes.
- Derived/system: total_hotel_revenue, total_restaurant_revenue, total_stays, total_restaurant_visits, created_at, updated_at.
- Derived values are displayed but are not included in the create/update form.
- Refresh Value is executed through the authenticated plugin action API and recalculates/persists customer value snapshots.
- Tenant scoping remains enforced by the plugin action API and Supabase RLS.

## 10-layer status
1. Data Model: VERIFIED — live `crm_customers` contains the master and derived fields.
2. Security/RLS: VERIFIED — `crm_customers` has RLS and runtime tenant scoping.
3. API/Runtime: VERIFIED — Customer 360 `refresh_value` delegates to the real customer-value calculation.
4. UI: VERIFIED — registry now exposes only master fields for editing while retaining derived values for display.
5. Provider: N/A — no external provider required for master profile CRUD.
6. Persistence/History: VERIFIED — customer value snapshots are persisted by refresh runtime.
7. Error/Retry: VERIFIED — action route returns explicit runtime errors; refresh can be safely retried.
8. E2E: PENDING — requires authenticated browser execution against the deployed app.
9. Production Build: PENDING — clean install/build has not yet been executed in this environment.
10. Documentation: VERIFIED — this certification record is included in the release package.

## Certification
Customer 360 is **not marked PRODUCTION CERTIFIED** until browser E2E and production build evidence are attached. The implementation contract itself is closed for this phase.
