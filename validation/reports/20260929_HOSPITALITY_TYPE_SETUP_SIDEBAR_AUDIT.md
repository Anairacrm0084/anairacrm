# Hospitality Type Setup + Dynamic Sidebar Audit — 2026-09-29

Implemented unified property-type management for Hotel, Camping, Homestay, Guest House and Cottage.

## Business flow
- `restaurants.hospitality_type` is the master property type.
- Hotel keeps the existing Hotel Management navigation.
- Camp gets Camping Management navigation.
- Homestay gets Homestay Management navigation.
- Guest House gets Guest House Management navigation.
- Cottage gets Cottage Management navigation.

## Type-specific setup links
Each non-hotel type now exposes:
- Dashboard
- Property
- Accommodation / Unit Types
- Rate Plans
- Inventory
- Reservations
- Booking Policies

Camping exposes Camp / Tent Types and Camping Inventory.

## URL state
Camping and Alternative Stay engines now read `tab` from the URL. Alternative Stay engine also reads `type` from the URL, so sidebar links open the correct property type and tab directly.

## Validation
- `app/components.js`: Node syntax check PASS.
- Sidebar route definitions include all five hospitality types.
- Existing Hotel Management links retained.
- Existing Camping and Alternative Stay engine pages retained.
