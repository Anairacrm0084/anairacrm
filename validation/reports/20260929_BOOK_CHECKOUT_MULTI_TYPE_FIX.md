# Book ID / Checkout Multi-Hospitality Fix — 2026-09-29

## Fixed
- Public `/book/[id]` no longer requires a hard-coded hotel platform store when resolving a property.
- Store resolution order: assigned published store -> enabled membership store -> published hospitality marketplace store.
- Hotel, camping, homestay, guest house and cottage share the same customer-facing store architecture.
- Checkout now resolves the effective hospitality type from the selected accommodation record instead of trusting a stale `stay_type=hotel` query parameter.
- Rate plans are filtered against the selected accommodation's effective hospitality type.
- Booking idempotency/source context follows the resolved hospitality type.
- Existing store UI/layout is preserved.

## Validation
- `node --check app/book/[id]/page.js` PASS
- `node --check app/book/[id]/checkout/page.js` PASS
