# Anaira Supabase Migration Index

Existing CRM migrations: 001–021.

New modular platform migrations:

- 022_plugin_registry_contracts.sql — plugin catalog, activation uniqueness, tenant plugin RLS
- 023_hotel_booking_engine.sql — room types, rate plans, inventory, reservations, add-ons
- 024_hotel_pms.sql — rooms, operational reservations, housekeeping
- 025_restaurant_reservations.sql — table inventory, reservations, waitlist
- 026_food_delivery_marketplace.sql — delivery orders, items, riders, assignments
- 027_restaurant_store_builder.sql — auto storefronts, domains, POS sync state
- 028_channel_ota_manager.sql — OTA channels, room/rate mappings, sync events
- 029_platform_events_contracts.sql — cross-plugin event bus and optional dependencies
- 030_plugin_rls_hardening.sql — tenant RLS for the new modules

Apply in numeric order after 001–021. Do not skip migrations in production.

- 032_public_reservation_delivery_api.sql — public restaurant reservation and delivery checkout RPCs

## 039–042 — Granular RBAC + CRM RLS finalization
- `039_granular_roles_profiles_permissions.sql` — job profiles, granular permission catalog, profile-permission mapping, tenant-scoped user profile assignment.
- `040_user_role_assignment_controls.sql` — controlled admin/manager/staff role changes inside a tenant.
- `041_granular_rbac_function_execute_hardening.sql` — anonymous EXECUTE revoked from new RBAC SECURITY DEFINER RPCs.
- `042_crm_rls_canonicalization.sql` — canonical tenant RLS across every `crm_*` table; relationship tables inherit tenant access from their parent aggregate.
- `043_user_permission_precedence.sql` — explicit user overrides now take precedence over role/profile grants.
- `044_profile_template_edit_superadmin_only.sql` — global job-profile templates can only be edited by Super Admin; Business Admin uses tenant user-level overrides.
- `045_crm_rls_legacy_policy_cleanup.sql` — drops all historical CRM policies before recreating the single canonical tenant policy, preventing old permissive policies from surviving a fresh migration replay.
- `046_legacy_security_definer_execute_cleanup.sql` — removes public RPC execution from legacy privileged helpers while preserving intentional public commerce endpoints.
- `047_store_function_execute_scope.sql` — scopes the restaurant-store enable RPC to authenticated callers instead of PUBLIC.

061_unified_store_source_control.sql

- 062_professional_store_catalog_and_settings.sql — professional restaurant catalog: categories, item media/pricing/tags, variants, add-ons, store settings, offers and tenant/public RLS.
- 063_hms_store_booking_bridge.sql — Hotel Store live HMS availability and booking bridge with CRM linkage and folio creation.

- 20260925_phase28_seo_atoz_completion.sql — SEO A-to-Z completion hardening

- `20260929_hotel_marketplace_destination_assignment_and_slider.sql` — canonical hotel-to-destination assignment on `hms_settings`, destination-aware marketplace hotel search, and legacy city/address fallback for free-text search.
- `20260929_hotel_property_marketplace_media.sql` — property/global hotel marketplace background media and overlay controls.

- `20260929_camping_booking_engine.sql` — parallel Camping Marketplace and Booking Engine: camp properties, tent/camp unit catalog, per-person/per-unit rates, date inventory, inventory holds, guest reservations, booking transactions, public search/availability RPCs and payment/confirmation lifecycle.
