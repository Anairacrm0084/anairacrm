# Anaira Hospitality Multi-Type Store Audit — v15

## Root causes fixed
1. Store Builder was discovering Hotel from stale `hms_room_types` even when the property's explicit `hospitality_types` selected only Camping.
2. The same global hotel marketplace store is intentionally shared by hospitality types, but the UI treated each hospitality type as a separate store. The selector is now driven only by enabled, explicitly selected hospitality types.
3. Store Builder title used the technical `kind=hotel` value, causing `My Hotel Store` to appear for Camping. It now uses the active hospitality type for the display label.
4. HMS inventory and reservations were loaded for the whole property, not scoped to the active accommodation catalog. They are now filtered by active room/unit type IDs.
5. AppShell could resurrect Hotel from stale HMS rows. Explicit profile selections are now authoritative; legacy/HMS inference is only used when the property has no explicit selection.
6. Hospitality sidebar/plugin visibility now respects the selected hospitality types and enabled plugin state.
7. Store type switching uses Next router navigation rather than raw history replacement so the application context refreshes reliably.

## Expected behavior
- Camping-only + Camping plugin enabled: one `My Camping Store`, Camping Management sidebar, camping room/unit/rate/inventory data.
- Hotel-only + Hotel plugin enabled: one `My Hotel Store`, Hotel Management sidebar.
- Hotel + Camping: one shared store identity with type-specific management/data context; switching type changes the management/data context, not the number of stores.
- Restaurant Management appears only when a restaurant management/store/POS/reservation/delivery plugin is enabled.

## Validation
- `node --check app/components.js` PASS
- `node --check app/store-builder/page.js` PASS
- `node scripts/verify-js-syntax.mjs` PASS (291/291)
