# WORK 08 — Keep `/book/{id}/checkout` Directly Accessible

## Root cause found
`app/book/[id]/checkout/page.js` was a server component that immediately redirected the established `/book/{id}/checkout` URL to `/property/{id}/checkout`. The parent `/book/{id}` page also redirected to `/property/{id}`. This contradicted the required booking URL family and could fail when the property route was unavailable or not deployed consistently.

## Implemented
- Extracted the existing complete hospitality checkout UI into `components/booking/HotelBookingCheckout.jsx`.
- `/property/{id}/checkout` now renders that shared checkout with `routeBase="/property"`.
- `/book/{id}/checkout` now renders the same checkout directly with `routeBase="/book"`; it does not redirect.
- `/book/{id}` now renders the same property storefront directly with `routeBase="/book"`; it does not redirect.
- Checkout Back and post-payment Back to Hotel actions preserve the route family they entered from (`/book` remains `/book`, `/property` remains `/property`).
- The existing booking-start, guest OTP, live availability, quote, payment submission and confirmation state logic are retained in the shared checkout component.
- The legacy `/camping/{id}/checkout` entry remains a compatibility route into the hospitality checkout and preserves its selected unit/rate query parameters.
- Updated static regression checks to inspect the shared checkout source and explicitly verify that `/book` routes do not redirect.

## Verification
- JavaScript syntax: 751/751 PASS
- Relative imports: PASS
- Booking runtime closure: 29/29 PASS
- Public hospitality storefront: PASS
- Homestay routing regression: PASS
- Property profile/sidebar regression: PASS
- Booking confirmation regression: PASS
- Book checkout route preservation: PASS
- ZIP integrity: PASS

## Not run / external dependency
- Full Next.js production build and browser E2E were not run because this extracted source package does not contain `node_modules`.
- The screenshot's browser-native "This page couldn't load" screen may also indicate a DNS, SSL, hosting, or network problem for the deployed domain. The source route fix does not itself deploy the application or repair DNS/SSL.
- No Supabase migration or live booking/payment/inventory data changes were made.
