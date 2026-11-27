import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';

const root = process.cwd();
const read = (p) => fs.readFileSync(path.join(root, p), 'utf8');
const helper = read('lib/legacyPropertyRoute.js');
const bookPage = read('app/book/[id]/page.js');
const bookCheckout = read('app/book/[id]/checkout/page.js');
const bookRoom = read('app/book/[id]/room/[room_type]/page.js');
const campCheckout = read('app/camping/[id]/checkout/page.js');
const propertyCheckout = read('app/property/[id]/checkout/page.js');

assert.match(helper, /URLSearchParams/);
assert.match(helper, /params\.append\(key, String\(value\)\)/);
assert.match(helper, /\/property\/\$\{encodeURIComponent/);
assert.match(bookPage, /canonicalPropertyUrl\(id, '', query\)/);
assert.match(bookCheckout, /canonicalPropertyUrl\(id, '\/checkout', query\)/);
assert.match(bookRoom, /const routeBase = pathname\?\.startsWith\('\/property\/'\) \? '\/property' : '\/book'/);
assert.match(campCheckout, /canonicalPropertyUrl\(id, '\/checkout', checkoutQuery\)/);
assert.match(campCheckout, /stay_type: 'camp'/);
assert.match(propertyCheckout, /router\.push\(`\/property\/\$\{key\}/);
assert.doesNotMatch(bookCheckout, /HotelBookingCheckout/);
console.log('PASS: legacy /book and /camping routes canonicalize to /property and preserve query parameters');
