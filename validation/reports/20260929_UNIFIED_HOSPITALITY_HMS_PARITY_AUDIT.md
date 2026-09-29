# Anaira Unified Hospitality HMS Parity Audit — 2026-09-29

## Scope
Audited the uploaded Anaira CRM / Hotel Marketplace ZIP for Hotel Management parity across:
- Hotel
- Camping
- Homestay
- Guest House
- Cottage

## Existing hotel canonical flow found
Hotel Management already owns the operational master data and lifecycle:
1. Property Profile / Setup
2. Room Types
3. Individual Rooms
4. Rate Plans
5. Automatic Room Inventory
6. Reservations / Booking Admin
7. PMS / Front Desk
8. Housekeeping
9. Store Builder / Hotel Store Preview
10. Marketplace / Booking Engine

Automatic inventory is derived from physical HMS rooms plus reservations through `anaira_sync_hotel_inventory_range` and `anaira_inventory_dashboard`.

## Defects / parity gaps found before this change
- Camping had a separate booking-engine UI/data model instead of the canonical HMS tables.
- Homestay / Guest House / Cottage had a separate `anaira_stay_*` model instead of the canonical HMS setup.
- Hotel Management sidebar was hotel-specific.
- Property Setup had a hospitality type field, but the type was not consistently driving the entire Management UI.
- Store Builder's non-restaurant preview was hotel-specific and the Save action was restricted to restaurant mode.
- Marketplace search for Camp / Homestay / Guest House / Cottage used separate search RPCs and therefore could diverge from HMS master data.
- Rate Plans did not expose a common per-unit / per-person mode in the canonical HMS UI.
- Super Admin plugin catalog did not contain dedicated Camping / Homestay / Guest House / Cottage management plugin entries.

## Implemented parity
### Canonical HMS model
All five hospitality types now use the same Hotel Management routes and canonical tables:
- `hms_settings`
- `hms_room_types`
- `hms_rooms`
- `hms_rate_plans`
- `hms_inventory`
- `hms_reservations`

The UI changes terminology according to `restaurants.hospitality_type`, while retaining the Hotel Management layout and code path.

### Property type
Supported values:
- `hotel`
- `camp`
- `homestay`
- `guest_house`
- `cottage`

### Rate mode
`hms_rate_plans.pricing_mode` supports:
- `per_unit`
- `per_person`

Camping defaults to `per_person` during backfill. The Rate Plan screen allows either mode.

### Automatic inventory
The existing canonical HMS inventory engine is reused. Physical units in `hms_rooms` are the source of total inventory; confirmed / checked-in reservations reduce availability; maintenance and out-of-order units are blocked.

### Management UI
The following pages now render with type-specific labels while using the same hotel code/layout:
- Dashboard
- Property Profile
- Unit Types (Room Types / Camp-Tent Types / Accommodation Types / Cottage Types)
- Physical Units
- Inventory
- Rate Plans
- Reservations
- PMS / Front Desk
- Housekeeping
- Store Preview

### Super Admin plugin control
Added dedicated plugin catalog entries:
- `camping-management`
- `homestay-management`
- `guest-house-management`
- `cottage-management`

The sidebar resolves the management plugin from the property's `hospitality_type`, so Super Admin activation can control the appropriate management workspace.

### Marketplace search
Non-hotel marketplace search is moved toward the canonical HMS search RPC:
`anaira_marketplace_hms_hospitality_search`

This means the selected property type and its HMS units/rates/inventory are the source of marketplace discovery.

### Store preview
Business Admin Store Builder now treats non-restaurant hospitality as a hospitality store, uses the Hotel/HMS source, and permits Save/Preview for all hospitality types. The preview labels adapt to the property's type.

## Supabase status
The following live schema migration was successfully applied to the connected Supabase project:
- `20260929_unified_hms_hospitality_management_schema`

Live changes include canonical hospitality type fields, pricing mode, max guest capacity, indexes, data backfill, and the unified HMS marketplace search RPC.

Dedicated booking transaction runtime SQL is included in:
`supabase/migrations/20260929_unified_hms_hospitality_management_full.sql`

The full booking-runtime migration was **not claimed as live-applied** in this audit because the database tool blocked the booking-transaction function operation. It must be applied in a controlled deployment/migration run before treating the non-hotel public checkout runtime as production-certified.

## Validation
- JavaScript syntax: **291/291 PASS**
- Existing P2 hotel booking static audit: **10 checks, 0 failures**
- P0 foundation audit: **8 checks, 0 failures**
- Full production certification remains blocked by the archive's existing environment requirements: clean dependency install/build, browser E2E, provider E2E and cross-tenant negative E2E.

## Important production boundary
The management/data/inventory parity is implemented in the ZIP. The full non-hotel transactional booking runtime is supplied as a migration but is not represented as live-applied in this audit. Do not mark the camping/homestay/guest-house/cottage public checkout as production-certified until that migration and browser/payment/OTP E2E are run in the deployment environment.
