# Public Camping Checkout Routing Fix

## What changed
- Public booking links from the universal property page now use the canonical premium `/book/[id]/checkout` route for camping as well as other stay types.
- Room-detail booking CTA now uses the same canonical route and carries stay type, room type, rate plan, dates and guest counts.
- Legacy `/camping/[id]/checkout` remains supported as a compatibility redirect to the canonical premium checkout.

## Expected result
Login and logout sessions use the same customer-facing checkout page. The public store does not send customers to the old unstyled camping checkout component.

## Validation
- Node syntax checks passed for the three modified route files.
- ZIP integrity should be checked after packaging.
- Full Next.js production build and live guest booking/OTP/payment E2E still need to be run in the target deployment environment.
