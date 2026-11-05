# Camping checkout premium restore

- Legacy `/camping/[id]/checkout` now redirects to the canonical styled `/book/[id]/checkout` flow.
- Preserves selected camp unit (`unit_type` -> `room_type`), rate plan, dates and guest counts.
- If no unit is selected in the URL, sends the customer back to the public property page with `stay_type=camp` so they can select a tent first.
- The canonical checkout already supports legacy `camp_unit_types` and `camp_rate_plans` when `stay_type=camp`.

No booking/payment business logic was replaced in the canonical checkout.
