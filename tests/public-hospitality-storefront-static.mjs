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
assert.match(marketplace, /\/stay\/\$\{stayType\}\/\$\{x\.property_id\}/, 'alternative stays must open the canonical stay-property detail page');
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
assert.match(publicProfileApi, /publishedDirectStay=Boolean\(stayProperty/, 'direct stay publication must use its canonical stay-property record');
assert.match(publicProfileApi, /eq\('marketplace_visible',true\)/, 'direct stay property must be marketplace-visible');
const otpApi = read('app/api/hotel/guest-otp/route.js');
assert.match(otpApi, /anaira_stay_properties/, 'guest OTP must resolve homestay and guest-house property records');
assert.match(otpApi, /eq\('stay_type',propertyType\)/, 'guest OTP must validate the requested stay type');
const marketplaceSettings = read('app/super-admin/hotel-marketplace-settings/page.jsx');
assert.match(marketplaceSettings, /eq\('is_platform_store',true\)\.is\('restaurant_id',null\)/, 'Super Admin settings must resolve only the global platform store');
assert.match(hospitalityCheckout, /property_type:stayType==='camp'\?'camp':'hotel'/, 'camp checkout OTP must validate against camping property');
assert.match(hospitalityCheckout, /const availabilityOk=available===null\?await check\(\):Number\(available\)>0/, 'hospitality checkout must block if availability check fails');
assert.match(campCheckout, /redirect\(`\/book\/\$\{encodeURIComponent\(id\)\}\/checkout\?\$\{values\.toString\(\)\}`\)/, 'legacy camp checkout must route to the canonical hospitality checkout');
const stayDetailApi = read('app/api/public/stay/[type]/[id]/route.js');
assert.match(stayDetailApi, /eq\('restaurant_id',property\.restaurant_id\)/, "stay detail API must scope units and rates to the property tenant");
assert.match(stayDetailApi, /in\('unit_type_id',unitIds\)/, "stay detail API must only return rates for this property unit types");
assert.match(marketplace, /booking_source=anaira-global-marketplace/, 'all marketplace property cards must mark marketplace booking origin');
assert.match(hospitalityCheckout, /source:bookingSource/, 'hotel and camp checkout must preserve booking channel');

assert.match(hospitalityCheckout, /const availabilityOk=available===null\?await check\(\):Number\(available\)>0/, 'canonical hospitality checkout must block if availability check fails');


assert.match(publicProfileApi, /from\('hms_room_types'\)/, 'public profile API must fetch active HMS room catalog server-side for anonymous customers');
assert.match(publicProfileApi, /from\('hms_rate_plans'\)/, 'public profile API must fetch active HMS rates server-side for anonymous customers');
assert.match(publicProfileApi, /catalog:publicCatalog/, 'public profile API must return the property-scoped public catalog');
assert.match(publicBookingPage, /publicPayload\.catalog\?\.rooms/, 'public booking page must render rooms from server-returned catalog, not tenant-only anon table reads');
assert.doesNotMatch(publicBookingPage, /supabase\.from\('hms_room_types'\)/, 'public booking page must not query tenant-protected room catalog directly from anon browser');

console.log('PUBLIC HOSPITALITY STOREFRONT: 30/30 PASS');
