# Work 06 — Global Marketplace Direct Property Booking

## Scope
- Confirmed `/super-admin/hotel-marketplace-settings` remains the single Global ANAIRA Hotels marketplace settings page. No duplicate global settings route was introduced.
- Kept the marketplace property detail route at `/property/{id}?stay_type=...`.
- Updated the existing Global Marketplace Settings page to document this canonical journey; no duplicate settings page was created.
- Ensured the requested `stay_type` wins over a generic base restaurant type when the matching camp property is published, and included that selected type in the public property response.
- Replaced the property storefront's `/book/{id}` CTA with an accommodation anchor and a property-owned checkout route: `/property/{id}/checkout`.
- Copied the existing booking checkout lifecycle into the nested property route, preserving guest verification, live availability checks, rate calculation, add-ons, payment selection, booking creation, and confirmation behavior. Back/success navigation returns to `/property/{id}`.
- Bridged legacy `camp_unit_types` and `camp_rate_plans` into the public property catalog through the server-side property API, exposing only whitelisted public booking fields.
- Set the selected storefront hospitality type from the requested type, so a camp URL renders as a camp even when the base restaurant record has a generic hotel type.

## Booking path
`/anaira/hotels` → `/property/{id}?stay_type=camp&...` → choose accommodation → `/property/{id}/checkout?...` → booking confirmation/payment.

## Safety
- No database migration or live data mutation.
- Existing booking start API and tenant/property-scoped checks remain the booking authority.
- Existing `/book` routes remain available for legacy/direct store workflows; the Global Marketplace property storefront no longer links to them.

## Verification
- Added `npm run marketplace:direct-property-booking-check`.
- Production build/browser E2E should be run in the user's installed project environment with dependencies and provider credentials.
