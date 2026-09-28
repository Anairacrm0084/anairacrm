# Anaira Hotel Marketplace V4 Audit & Changes

## Scope
Audited the V3 Hotel Marketplace source and aligned it with the Restaurant Marketplace store presentation model.

## Fixed
- `/anaira/hotels` is now a standalone full-width customer store, not wrapped in the CRM/AnairaShell page-width container.
- Added a dedicated customer-store header with ANAIRA brand and `ANAIRA Platform` navigation.
- Kept `/anaira/hotels` hotel-only: discovery uses `anaira_marketplace_hotel_search` and does not consume Restaurant Marketplace catalog data.
- Preserved live HMS-backed room availability and booking links.
- Preserved Top Destinations (five-column desktop presentation) and Super Admin image controls.
- Added dedicated Super Admin route `/super-admin/anaira-store`.
- Added a separate `ANAIRA STORES` sidebar group for Super Admin.
- Existing `/super-admin/stores` now redirects to `/super-admin/anaira-store` for compatibility.
- Added global QR cards for both platform stores:
  - ANAIRA Hotels → `/anaira/hotels`
  - ANAIRA Restaurants → `/store`
- Added direct links from the ANAIRA Store Control Center to each store's global settings.
- Added store-type filtering in Super Admin store membership display so hotel and restaurant marketplace listings are not mixed when canonical listing data is available.

## Source of truth
- Hotel rooms/rates/inventory/availability/bookings remain HMS-owned.
- Restaurant menu/order operations remain Restaurant SaaS-owned.
- Marketplace pages are presentation/commerce layers.

## Verification
- JavaScript syntax: 279/279 PASS.
- Required public/admin routes present.
- Hotel public page contains only the canonical hotel search RPC and hotel destination/banner sources.
- Both global store QR targets present.
- Production `next build` was not run in this audit because dependencies were not installed in the extracted source workspace.
