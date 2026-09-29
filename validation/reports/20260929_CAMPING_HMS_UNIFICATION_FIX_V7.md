# 2026-09-29 — Camping/Hospitality HMS Unification Fix v7

## Root cause
The public Book Store and Store Builder were reading the canonical `hms_room_types`, `hms_rate_plans` and `hms_inventory` tables, while the existing camping setup had also created parallel `camp_unit_types`, `camp_rate_plans` and `camp_inventory` tables. Therefore the camping property could be enabled and its legacy records could exist, but the unified store displayed zero accommodation types.

A second issue was that `/camping-management` redirected to `/hotel-management` without preserving `type=camp`, so the hotel context could appear.

A third issue in `app/hotel-management/room-types/page.js` referenced `SelectField`, `useState`, and `useEffect` without importing them.

## Fixes
1. Added `20260929_unify_camping_into_hms.sql` to migrate existing camping units, rates, physical units and inventory into the canonical HMS model.
2. Added a temporary read compatibility fallback in the public Book Store and Store Builder for legacy camping rows.
3. `/camping-management` now opens the same canonical HMS management UI with `type=camp`.
4. `/booking-engine/camping` now opens the same booking control center with `type=camp`.
5. Fixed `room-types/page.js` missing imports.
6. Store Builder preview continues to use the same store and now reads camping data from the canonical HMS source.
7. Existing hotel behavior is preserved; selected hospitality type controls labels/data.

## Expected result
For a property with:
- Hotel only -> hotel management/store data.
- Camping only -> camping management/store data.
- Hotel + Camping -> both contexts available under the same property/store.
- Any combination of Hotel, Camping, Homestay, Guest House, Cottage -> same HMS pages, with data filtered by `type`.

Camping rate plans retain `per_person` pricing.

Existing misclassified camp/tent HMS rows are also corrected to `hospitality_type='camp'` and `pricing_mode='per_person'` when they match legacy camping data.
