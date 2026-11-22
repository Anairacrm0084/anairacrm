import fs from 'node:fs';
import assert from 'node:assert/strict';

const root = fs.readFileSync('app/page.js', 'utf8');
const builder = fs.readFileSync('app/store-builder/page.js', 'utf8');

assert.match(root, /supportedTypes\s*=\s*new Set\(\['hotel','camp','homestay','guest_house','cottage'\]\)/);
assert.match(root, /window\.location\.replace\(`\/store-builder\?\$\{storeParams\.toString\(\)\}`\)/);
assert.match(root, /Do not carry tenant IDs from a public\/root URL/);
assert.doesNotMatch(root, /storeParams\.set\('restaurant_id'/);
assert.match(builder, /router\.replace\('\/super-admin\/hotel-marketplace-settings'\)/);
assert.match(builder, /const targetRestaurantId=p\?\.restaurant_id\|\|''/);
assert.doesNotMatch(builder, /list\.find\(x=>x\.hospitality_type==='homestay'/);

console.log('Homestay store routing regression: PASS');

const shell = fs.readFileSync('app/components.js', 'utf8');
assert.doesNotMatch(builder, /useSearchParams/, 'Store Builder must not re-run its auth bootstrap when it normalizes the URL');
assert.match(builder, /const params=new URLSearchParams\(typeof window!=='undefined'\?window\.location\.search:''\)/, 'Store Builder must snapshot route params once');
assert.ok(builder.includes('})()},[]);'), 'Store Builder auth/profile bootstrap must run once, not loop on search params');
assert.match(shell, /supabase\.auth\.onAuthStateChange/, 'AppShell must follow Supabase auth state changes');
assert.match(shell, /from\('profiles'\)\.select\('is_super_admin,role,restaurant_id,full_name,status'\)/, 'AppShell must fall back to canonical profiles when the legacy view misses a profile');
