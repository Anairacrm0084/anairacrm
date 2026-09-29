# Anaira Multi-Type Hotel/Camping Repair v19

## Scope
- Preserve existing hotel and camping management pages and data models.
- Property `restaurants.hospitality_types` is authoritative for the hospitality management workspace.
- Restaurant management remains controlled by `restaurant_plugins`.
- One canonical hospitality platform store is used; the customer-facing context is Hotel/Camping/Homestay/Guest House/Cottage.

## Repairs
1. Hospitality sidebar no longer disappears because a stale/legacy hospitality plugin row is disabled.
2. `/hotel-management` management routes accept the selected hospitality `type` from the property profile.
3. Store Builder no longer coerces every non-restaurant context to `kind=hotel`.
4. A camping-only property resolves to `kind=camp&hospitality_type=camp` and shows only `My Camping Store`.
5. Multi-type properties can switch between selected hospitality contexts without creating duplicate platform stores.
6. Physical rooms/units, PMS reservations, housekeeping and inventory are scoped to the active hospitality type.
7. Restaurant sidebar remains plugin-gated.

## Supabase contract preserved
No destructive Supabase migration is added and no existing hotel/camping records are deleted or rewritten by this repair. Existing RLS/plugin activation guards remain intact.
