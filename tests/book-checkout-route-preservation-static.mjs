import fs from 'node:fs';
import assert from 'node:assert/strict';

const bookCheckout = fs.readFileSync('app/book/[id]/checkout/page.js', 'utf8');
const propertyCheckout = fs.readFileSync('app/property/[id]/checkout/page.js', 'utf8');
const shared = fs.readFileSync('components/booking/HotelBookingCheckout.jsx', 'utf8');
const bookProperty = fs.readFileSync('app/book/[id]/page.js', 'utf8');

assert.match(bookCheckout, /HotelBookingCheckout\s+routeBase="\/book"/);
assert.doesNotMatch(bookCheckout, /next\/navigation|redirect\s*\(/);
assert.match(propertyCheckout, /HotelBookingCheckout\s+routeBase="\/property"/);
assert.match(shared, /router\.push\(`\$\{routeBase\}\/\$\{key\}/);
assert.match(shared, /export default function HotelBookingCheckoutPage/);
assert.match(bookProperty, /HospitalityStorePage\s+routeBase="\/book"/);
assert.doesNotMatch(bookProperty, /redirect\s*\(/);
assert.match(shared, /api\/public\/booking\/start/);
assert.match(shared, /api\/public\/booking\/payment/);
console.log('BOOK CHECKOUT ROUTE PRESERVATION: PASS (no redirect; shared checkout; /book URLs retained)');
