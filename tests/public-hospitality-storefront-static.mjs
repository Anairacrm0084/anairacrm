import fs from 'node:fs';
import assert from 'node:assert/strict';
const read = (p) => fs.readFileSync(new URL(`../${p}`, import.meta.url), 'utf8');
const hotelStore = read('app/hotel-store/page.js');
const staysAlias = read('app/stays/page.js');
const marketplace = read('app/anaira/hotels/page.jsx');
const camp = read('app/camping/[id]/page.js');
const resolver = read('lib/publicProperty.js');
const staysAdmin = read('app/booking-engine/stays/page.jsx');
const membershipPolicy = read('supabase/migrations/20261105084338_fix_public_store_membership_rls_scope.sql');
assert.match(hotelStore, /redirect\('\/anaira\/hotels'\)/, 'hotel-store must be a public customer entry');
assert.match(staysAlias, /redirect\('\/anaira\/hotels'\)/, 'stays alias must lead to public marketplace');
assert.match(marketplace, /\/property\/\$\{x\.restaurant_id\}/, 'camp results must open the business-specific property landing page');
assert.match(marketplace, /\/property\/\$\{x\.restaurant_id\|\|x\.property_id\}/, 'alternative stays must open the business-specific property landing page');
assert.match(camp, /redirect\(`\/book\//, 'legacy camp storefront must redirect to the canonical direct-booking store');
assert.match(resolver, /membership is optional profile enrichment/i, 'public property resolution must not require a store membership');
assert.match(staysAdmin, /useState\(undefined\)/, 'operator stay engine must wait for auth resolution');
assert.match(membershipPolicy, /s\.restaurant_id = anaira_store_memberships\.restaurant_id/, 'public membership policy must match the tenant store owner');
assert.match(membershipPolicy, /s\.published = true/, 'public membership policy must require a published tenant store');

assert.match(marketplace, /anaira_marketplace_camp_search/, 'camp discovery must use the camp inventory engine');
assert.match(marketplace, /anaira_marketplace_stay_search/, 'homestay/guest-house/cottage discovery must use the stay engine');
assert.match(marketplace, /p_stay_type:requestedType|p_stay_type:type/, 'stay search must pass the selected stay type');
assert.match(marketplace, /property_id/, 'stay search results must route by canonical property id');
assert.match(marketplace, /is_platform_store',true/, 'store banners must resolve the platform store, not an arbitrary tenant store');

const publicProfileApi = read('app/api/public/hospitality/property/[id]/route.js');
const publicBookingPage = read('app/book/[id]/page.js');
const hospitalityCheckout = read('app/book/[id]/checkout/page.js');
const campCheckout = read('app/camping/[id]/checkout/page.js');
assert.match(publicBookingPage, /api\/public\/hospitality\/property\//, 'public booking page must load published profile enrichment through server API');
assert.match(publicBookingPage, /profile\.cover_url\|\|profile\.cover_image_url\|\|profile\.cover_image/, 'public hero must use membership/store cover image');
assert.match(publicProfileApi, /cover_url:override\.cover_url/, 'public profile API must return the published membership cover image');
assert.match(publicProfileApi, /published=true|published',true|published', true/, 'public profile API must enforce published content');
assert.match(hospitalityCheckout, /property_type:stayType==='camp'\?'camp':'hotel'/, 'camp checkout OTP must validate against camping property');
assert.match(hospitalityCheckout, /const availabilityOk=available===null\?await check\(\):Number\(available\)>0/, 'hospitality checkout must block if availability check fails');
assert.match(campCheckout, /const availabilityOk=available===null\?await check\(\):Number\(available\)>0/, 'camp checkout must block if availability check fails');

console.log('PUBLIC HOSPITALITY STOREFRONT: 21/21 PASS');
