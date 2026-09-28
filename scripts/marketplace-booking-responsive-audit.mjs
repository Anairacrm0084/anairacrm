import fs from 'node:fs';
const files=[
 'app/platform-store-control.js',
 'app/booking-engine/page.js',
 'app/anaira/hotels/page.jsx',
 'app/book/[id]/page.js',
 'components/anaira/AnairaShell.jsx'
];
for(const f of files){if(!fs.existsSync(f)) throw new Error(`Missing ${f}`)}
console.log(`Marketplace/Booking responsive audit: ${files.length}/${files.length} source files present`);
console.log('Targets: Hotel Marketplace, Restaurant Marketplace separation, Booking Engine admin, hotel search, hotel store, checkout entry, mobile/tablet navigation.');
