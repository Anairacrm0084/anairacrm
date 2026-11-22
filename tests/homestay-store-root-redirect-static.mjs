import fs from 'node:fs';
import assert from 'node:assert/strict';

const dashboard = fs.readFileSync(new URL('../app/page.js', import.meta.url), 'utf8');
const navigation = fs.readFileSync(new URL('../app/components.js', import.meta.url), 'utf8');

assert.match(dashboard, /new URLSearchParams\(window\.location\.search\)/);
assert.match(dashboard, /supportedTypes\.has\(hospitalityType\)/);
assert.match(dashboard, /supportedTypes\.has\(kind\)/);
assert.match(dashboard, /window\.location\.replace\(`\/store-builder\?/);
assert.match(navigation, /store-builder\?kind='\+encodeURIComponent\(type\)\+'&hospitality_type='\+encodeURIComponent\(type\)/);

console.log('Homestay root-link redirect: PASS');
console.log('Hospitality navigation store-builder target: PASS');
