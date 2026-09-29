# Multi-Type v8 — Super Admin Property Selector Fix

## Root cause
The setup property selector in `app/hotel-management/setup-components.js` used `window.location.href` when a Super Admin selected a property. That forced a complete browser navigation. The application shell/route guard could run during that navigation before the selected property context had settled, making the setup page appear to jump back.

## Fix
The selector now:
1. updates the page's `rid` state immediately;
2. updates the `property` query parameter with `history.replaceState`;
3. keeps the current setup page mounted.

The setup page's existing `ensureSelected(ctx,rid)` then resolves the selected property and its existing data-loading effect runs normally.

## Scope
This patch changes only the property-selector navigation behavior. Hotel/Camping/Homestay/Guest House/Cottage data models, store UI, and booking flow are not intentionally changed.

## Expected
On Super Admin:
- open Hotel Setup or Restaurant Setup;
- choose a property;
- remain on the same setup page;
- selected property's fields load without returning to the previous page.
