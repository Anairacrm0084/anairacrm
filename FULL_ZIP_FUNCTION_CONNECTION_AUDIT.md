# Anaira CRM ZIP — Full Source Inventory & Hospitality/Booking Connection Audit

**Reviewed package:** `Anaira_CRM_Booking_Engine_A2Z_Approval_Payment_Inventory_Fix_20261105.zip`  
**Archive size:** ~5.9 MB; **1,123 archive entries**.  
**Source inventory:** 497 page route files; 185 API route files; 246 SQL migration files; 32 scripts; 16 test files (counts are source-file inventory, not certification).

## 1. Admin identity and property scope — confirmed behavior

`app/booking-engine/page.js`:
1. Calls `supabase.auth.getSession()`.
2. Reads `anaira_my_profile` for the logged-in user: `restaurant_id,is_super_admin,role`.
3. If `is_super_admin` is true, loads all `restaurants` and lets the user select a property.
4. Otherwise, sets `rid = profile.restaurant_id` and does not load the `properties` array.
5. `load()` scopes room types, rate plans, inventory, HMS reservations, add-ons, promotions, packages, engine settings and camping reservations with `.eq('restaurant_id', rid)`.

**Screenshot diagnosis:** The logged-in Property Admin is not being treated as Super Admin. The property ID is assigned from the admin profile. The header select is nevertheless rendered for every signed-in user, disabled for non-Super-Admin, and its options are empty. Consequently it displays the placeholder “Select property” while data can still be loaded for the assigned `rid`. This is a UI/context-display defect, not evidence of Super Admin login.

`app/hotel-management/setup-components.js` already implements the better pattern: it fetches the single assigned restaurant for a tenant admin, builds a one-property context, and only renders the property selector for Super Admin. Booking Engine should use the same tenant-property context/pattern.

## 2. Main booking modules and routes found

### Booking Engine UI
- `app/booking-engine/page.js` — 11 tabs: Dashboard, Room Catalog, Reservations, Availability, Rates, Promotions, Packages, Add-ons, Engine Design, Policies, Reports. Reads/writes the tenant's HMS and booking-engine tables. Reservation actions call SQL RPCs.
- `app/booking-engine/camping/page.jsx` — camping configuration/reservation view; routes users to unified Booking Engine for payment collection.
- `app/booking-engine/stays/page.jsx` — stay/homestay booking configuration.
- `app/HotelBookingAdmin.js` — older advance/full-payment UI component; not mounted as an active route in this package.

### Hotel/HMS management
- `app/hotel-management/page.js` — front desk dashboard, arrivals/in-house/departures, confirmation, check-in, room move, checkout, no-show, cancellation, payment verification.
- `app/hotel-management/pms/page.js` — PMS reservation and room lifecycle.
- `app/hotel-management/rooms/page.js` — physical room/unit master.
- `app/hotel-management/room-types/page.js` — room type master.
- `app/hotel-management/rates/page.js` and `rate-calendar/page.js` — rate plans and date-wise rates.
- `app/hotel-management/inventory/page.js` — date-wise sellable inventory.
- `app/hotel-management/room-rate-mapping/page.js` — distribution channel mapping.
- `app/hotel-management/booking-source/page.js` — booking-source economics and source setup.
- `app/hotel-management/housekeeping/page.js` — housekeeping task lifecycle.
- `app/hotel-management/setup/page.js` — property identity, hospitality type, policies, timings, media and store settings.
- `app/hotel-management/setup-components.js` — shared property context and hospitality navigation.

### Guest-facing booking routes
- `/book/[id]` — property landing/search and room/unit availability.
- `/book/[id]/room/[room_type]` — room/unit detail and rate selection.
- `/book/[id]/checkout` — guest details, quote, payment mode and checkout.
- `/book/[id]/multi-room` — multi-room selection.
- `/api/public/booking/availability`, `/rates/compare`, `/start`, `/payment`, `/manage`, plus search, invoice, localization, preferences, group, parity, abandoned booking and related routes.
- `/api/public/camping/*` — camping search and availability.
- `/api/public/stay/*` — homestay/guest-house/cottage search and availability.

## 3. Primary booking lifecycle — call graph

### Hotel direct booking
1. Guest opens `/book/[propertyId]` and selects stay dates/unit/rate.
2. Availability is checked through `anaira_public_hospitality_room_availability_by_id` (or the matching hotel availability RPC).
3. Checkout obtains pricing/rate/add-on context and submits to `POST /api/public/booking/start`.
4. API selects `anaira_start_verified_hotel_booking_transaction_v3` for `hospitality_type=hotel`.
5. V3 calls V2, then applies member/corporate/negotiated/personalized/direct-benefit pricing and synchronizes the quote into booking transaction, HMS reservation and payment intent.
6. Booking starts as pending/inquiry/payment_pending with a temporary inventory hold; the hold is not sold inventory.
7. Property Admin approves from Booking Engine or Hotel Management. The intended RPC is `anaira_hotel_confirm_reservation`.
8. Confirmation consumes the matching hold, confirms HMS reservation, writes reservation event, updates booking transaction and reconciles `hms_inventory.sold_rooms`.
9. Payment is collected/verified separately through hotel payment RPCs and `hms_payments` / `hms_booking_payment_submissions` / folio.
10. PMS then manages check-in, room assignment/move, checkout, no-show and cancellation.

### Camping direct booking
1. Guest selects camp unit/date/rate; availability calls `anaira_public_camp_availability`.
2. `POST /api/public/booking/start` selects `anaira_start_public_camp_booking`.
3. Camp reservation, camp booking transaction and temporary `camp_inventory_holds` row are created.
4. Property Admin approval calls `anaira_admin_manage_camp_reservation('approve')`.
5. Approval consumes hold, increments `camp_inventory.sold_units`, creates/links `hms_guests`, `hms_reservations`, `hms_folios`, and updates camp reservation/transaction.
6. Payment collection uses `anaira_admin_record_camp_payment` from migration `20261105000400`; it writes `hms_payments` and syncs camp reservation, HMS reservation, folio and transaction balances.

### Homestay / guest house / cottage
- Public start routes to `anaira_start_public_stay_booking`; availability uses `anaira_public_stay_availability` or unified hospitality availability wrapper; finalize uses `anaira_finalize_public_stay_booking`; expired holds are handled by `anaira_release_expired_stay_holds`.
- This is a separate stay inventory/reservation domain, not the same camp or hotel inventory table.

## 4. Key tables and ownership

### Hotel/HMS core
- `restaurants` — tenant/property identity.
- `anaira_my_profile` / `profiles` — logged-in user's tenant and role.
- `hms_settings` — hospitality property configuration.
- `hms_room_types`, `hms_rooms` — sellable room type and physical room master.
- `hms_rate_plans`, `hms_daily_rate_calendar` — rate plans and date rates.
- `hms_inventory`, `hms_room_inventory_blocks`, `anaira_hotel_inventory_holds` — sellable, blocked and temporarily held inventory.
- `hms_guests`, `hms_reservations`, `hms_reservation_events` — guest, canonical reservation and lifecycle audit.
- `crm_booking_transactions`, `anaira_payment_intents` — checkout transaction/payment intent bridge.
- `hms_booking_payment_submissions`, `hms_payments`, `hms_folios` — payment proof, payment ledger and folio balance.

### Camping
- `camp_properties`, `camp_unit_types`, `camp_rate_plans`, `camp_inventory`.
- `camp_reservations`, `camp_inventory_holds`, `camp_booking_transactions`.
- Approved camping booking links into canonical HMS through `camp_reservations.hms_reservation_id`.

### Booking engine commercial layer
- `booking_engine_settings`, `booking_addons`, `booking_packages`, `booking_promotions`.
- Additional feature tables include booking restrictions, personalized offers, direct benefits, corporate/negotiated rates, group allocations, conversion/abandoned sessions, invoices/credit notes, parity snapshots, reconciliation cases and revenue rollups.

## 5. Main RPC/function groups discovered

The hospitality/booking migrations contain **151 function declaration occurrences** matching booking, reservation, hotel, HMS, camping, inventory, rate, stay, payment, guest, room, availability or folio terms. This count includes duplicate/replacement declarations across historical migrations; it is not 151 unique live functions.

- Availability/search: `anaira_public_hospitality_room_availability_by_id`, `anaira_public_hms_room_availability`, `anaira_public_camp_availability`, `anaira_public_stay_availability`, `anaira_marketplace_hotel_search`, `anaira_marketplace_camp_search`, `anaira_marketplace_stay_search`.
- Quote/rates: `anaira_calculate_hotel_premium_quote`, `anaira_calculate_hms_daily_booking_quote`, `anaira_booking_rule_check`, `anaira_set_daily_rate`, `anaira_bulk_set_daily_rate`, `anaira_seed_daily_rate_calendar`.
- Booking start/finalize: `anaira_start_verified_hotel_booking_transaction_v3` (and v2 lineage), `anaira_start_public_camp_booking`, `anaira_finalize_public_camp_booking`, `anaira_start_public_stay_booking`, `anaira_finalize_public_stay_booking`.
- Approval/front desk: `anaira_hotel_confirm_reservation`, `anaira_admin_manage_camp_reservation`, `anaira_hms_reservation_transition`, `anaira_pms_check_in`/related PMS lifecycle functions, `anaira_hotel_cancel_reservation`.
- Inventory: `anaira_phase13_hotel_inventory_hold`, `anaira_phase13_hotel_inventory_hold_release`, `anaira_reconcile_hotel_inventory`, `anaira_inventory_dashboard`, `anaira_sync_hotel_inventory_range`, `anaira_release_expired_camp_holds`, `anaira_release_expired_stay_holds`.
- Payment: `anaira_submit_hotel_payment`, `anaira_verify_hotel_payment`, `anaira_record_hotel_advance`, `anaira_pay_hotel_balance`, `anaira_admin_record_camp_payment`, `anaira_post_folio_payment`, `anaira_settle_hms_folio`, `anaira_refund_payment` and payment reconciliation functions.
- Guest/commercial: booking lookup/cancel/modify, booking notifications, member context, corporate/negotiated rates, group booking, invoice/credit note, abandoned booking recovery and revenue rollup functions.

## 6. Confirmed defects / risks in this package

1. **Property Admin header bug:** Booking Engine fetches assigned `restaurant_id` but does not fetch the assigned restaurant row for the header. It renders an empty disabled selector. `setup-components.js` already has the correct pattern.
2. **Expired hotel hold:** `anaira_hotel_confirm_reservation` in migration `20261105000400` intentionally refuses approval when the checkout hold is expired. The screen surfaces that RPC error as the red alert. It must not mark the booking sold without fresh availability.
3. **Expired booking state:** Camp and stay expiry workers explicitly set reservation and transaction status to `expired`; hotel hold expiry has a different lineage and must be checked against the deployed scheduler/expiry function before assuming the reservation row status is updated.
4. **Legacy/parallel booking domains:** Older `booking_reservations` / `booking_inventory` objects and newer canonical `hms_reservations` / `hms_inventory` coexist in historical migrations. The current active guest flow uses newer HMS transaction v3, but all old routes/integrations must be traced before deleting or merging legacy tables.
5. **Different inventory engines:** Hotel, camp and homestay/guest-house/cottage have separate inventory/hold tables and lifecycle functions. A generic “inventory sold” update cannot safely be applied across them.
6. **Camping approval dependency:** `anaira_admin_manage_camp_reservation` in migration `20261105000300` performs property-admin authorization against `profiles` (`role='admin'`, matching `restaurant_id`) and consumes the hold. `20261105000400` adds camping payment ledger support. Both migrations must exist in the deployed database for all UI actions to work.
7. **Hotel approval authorization:** `anaira_hotel_confirm_reservation` checks `anaira_current_restaurant_id()` or Super Admin, and then scopes the reservation by `restaurant_id`. The client-supplied `p_user_id` is only used for audit actor; the RPC authorization is based on `auth.uid()` and current tenant context.
8. **Hotel Management confirm path:** Confirm action was previously sent to `anaira_hms_reservation_transition`, which does not implement confirm. The patched page now routes confirm to `anaira_hotel_confirm_reservation`.
9. **Build/E2E not certified:** The ZIP has no installed `node_modules`; production build and browser E2E were not run. Static syntax/import checks passed in the earlier focused validation, but they do not prove live Supabase behavior.

## 7. Scope and verification boundary

This audit inventories the full archive structure and traces the booking/hospitality-related routes, tables, migrations and function connections. It does not claim that all 1,123 files or every non-hospitality CRM module has been manually certified line-by-line. No live guest reservation or inventory record was changed during this review. Migration `20261105000400_booking_engine_approval_payment_inventory_closure.sql` is packaged in the ZIP; do not assume it is deployed until its migration status is checked and it is applied successfully.

## 8. Recommended correction sequence

1. Fix Booking Engine header/context to fetch the assigned property's name for tenant admins and show it as a read-only property label; retain selectable dropdown only for Super Admin.
2. Use the same `useTenantProperty()` context contract as Hotel Management setup so all hospitality routes resolve the same `restaurant_id` and hospitality types.
3. Add an explicit admin action to recheck/reacquire inventory for expired pending bookings. It must lock inventory, revalidate every stay date and capacity, then issue a new hold; only approval may consume the hold and increment sold inventory.
4. Ensure expired bookings cannot be approved from any UI or RPC path.
5. Verify migration history and deployed function definitions; apply missing migrations in order.
6. Run staging E2E for hotel and camp: create -> hold -> wait/expire -> revalidate -> approve -> sold inventory -> partial payment -> full payment -> cancel/refund -> inventory reconciliation.
