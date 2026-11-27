import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';

const read = (file) => fs.readFileSync(path.join(process.cwd(), file), 'utf8');
const propertyPage = read('app/property/[id]/page.js');
const bookPage = read('app/book/[id]/page.js');
const shared = read('app/_components/HospitalityStorePage.jsx');
const propertyCheckout = read('app/property/[id]/checkout/page.js');
const propertyRoomAlias = read('app/property/[id]/room/[room_type]/page.js');
const roomDetails = read('app/book/[id]/room/[room_type]/page.js');

assert.match(propertyPage, /HospitalityStorePage routeBase="\/property"/);
assert.match(bookPage, /canonicalPropertyUrl\(id, '', query\)/);
assert.match(shared, /function HospitalityStorePage\(\{routeBase='\/book'\}\)/);
assert.match(shared, /return `\$\{routeBase\}\/\$\{key\}\/checkout\?/);
assert.match(shared, /\$\{routeBase\}\/\$\{key\}\/room\//);
assert.match(shared, /booking_source=\$\{encodeURIComponent\(bookingSource\)\}/);
assert.match(propertyCheckout, /router\.push\(`\/property\/\$\{key\}/);
assert.match(propertyRoomAlias, /PropertyRoomDetails/);
assert.match(roomDetails, /usePathname/);
assert.ok(roomDetails.includes("const routeBase = pathname?.startsWith('/property/') ? '/property' : '/book';"));
assert.match(roomDetails, /\$\{routeBase\}\/\$\{key\}\/checkout/);

console.log('Property /[id] and Book /[id] shared-page parity: PASS');
console.log('Property checkout + accommodation details stay under /property/: PASS');
console.log('Booking source and date/guest query forwarding: PASS');
