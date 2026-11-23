import fs from 'node:fs';
import assert from 'node:assert/strict';
const source = fs.readFileSync(new URL('../../app/hotel-management/rate-calendar/page.js', import.meta.url), 'utf8');
const checks = [
  ['All Rooms selector exists', source.includes("[ALL_ROOMS,'All Rooms']")],
  ['All room types are selected in All Rooms mode', source.includes("selectedType===ALL_ROOMS?types:types.filter")],
  ['Calendar renders each room type separately', source.includes('visibleTypes.map(room=>')],
  ['Rate plans are scoped to each room type', source.includes('roomPlans.filter(p=>p.room_type_id===room.id)')],
  ['Initialize loops over visible room types', source.includes('for(const room of visibleTypes)')],
  ['Bulk update supports all visible rooms', source.includes("bulkTarget==='all'?roomPlans.filter")],
  ['Bulk update supports one selected room', source.includes("bulkTarget.startsWith('room:')")],
  ['Bulk modal offers per-room targeting', source.includes('room:${t.id}')],
  ['Individual daily editor remains available', source.includes('DAILY RATE EDITOR')],
  ['Stop-sell remains supported', source.includes('p_closed:!!form.closed')],
  ['Existing bulk RPC remains wired', source.includes("anaira_bulk_set_daily_rate")],
  ['Property change resets to All Rooms', source.includes('setSelectedType(ALL_ROOMS)')],
];
for (const [name, pass] of checks) { console.log(`${pass ? 'PASS' : 'FAIL'} ${name}`); assert.ok(pass, name); }
console.log(`${checks.length}/${checks.length} checks passed`);
