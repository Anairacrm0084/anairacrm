# ANAiRA Phase 48 — Point 2 Property Master Implementation
Date: 2026-09-26

## Locked scope
Business Admin Property module:
- Hotel Profile
- Property Details / contact / location
- Photos & Media
- Policies
- Operations defaults
- Booking Engine / CRM property switches

## Implementation
`app/hotel-management/setup/page.js` was upgraded from a flat form to a structured property master workflow.

### Real persisted fields
Uses live `hms_settings` via Supabase upsert keyed by `restaurant_id`.

- Identity: hotel_name, short_name, legal_name, star_rating, description
- Contact: phone, whatsapp, email, website
- Location: address, landmark, city, state, country, postal_code, latitude, longitude
- Operations: currency, timezone, check_in_time, check_out_time, tax_percent
- Policies: early_checkin_policy, late_checkout_policy, cancellation_policy, child_policy, pet_policy, smoking_policy
- Media: logo_url, cover_image_url, gallery
- Features: booking_engine_enabled, crm_integration_enabled

## Runtime safeguards
- Required-field validation before save
- Numeric validation for latitude/longitude/tax/star rating
- Latitude/longitude bounds validation
- Tax 0–100 validation
- Star rating 0–5 validation
- Saving state and explicit success/error feedback
- Property selector retained for Super Admin oversight
- Tenant property resolution retained for Business Admin

## Security
`hms_settings` already has tenant RLS policy `hms_settings_tenant_access` in the live database. The UI uses the authenticated property context and `restaurant_id` scoping.

## Verification
- JavaScript syntax: 222/222 PASS
- Live `hms_settings` schema inspected and matches the fields used by the property master.
- Live RLS policy verified.
- Production build/browser E2E remain separate gates and are not marked PASS by this source-level change alone.

## Certification state
POINT 2: IMPLEMENTED / VERIFIED at source + live-schema level.
Not production-certified until browser E2E and clean production build/deployment smoke pass.
