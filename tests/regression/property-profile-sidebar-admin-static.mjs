import fs from 'node:fs';
import assert from 'node:assert/strict';

const shell = fs.readFileSync('app/components.js', 'utf8');
const setup = fs.readFileSync('app/hotel-management/setup-components.js', 'utf8');
const profilePage = fs.readFileSync('app/hotel-management/setup/page.js', 'utf8');

for (const [type, label] of [
  ['hotel', 'Hotel'],
  ['camp', 'Camping'],
  ['homestay', 'Homestay'],
  ['guest_house', 'Guest House'],
  ['cottage', 'Cottage'],
]) {
  assert.ok(shell.includes(`Edit ${'${m.label}'} Property Profile`) || shell.includes('Edit ${m.label} Property Profile'), 'profile menu label must be dynamic');
  assert.ok(shell.includes(`/hotel-management/setup?type=${type}`) || shell.includes("`/hotel-management/setup?type=${type}`"), `${type} profile route must be present in the dynamic sidebar builder`);
}
for (const role of ['property_admin','hospitality_admin','hotel_admin','homestay_admin','guest_house_admin','cottage_admin','camp_admin']) {
  assert.ok(shell.includes(`'${role}'`), `${role} must be recognized as a tenant admin`);
}
assert.ok(shell.includes('isTenantAdminContext(ctx.role,ctx.profileKey)'), 'sidebar and route guards must share tenant-admin recognition');
assert.ok(shell.includes('effectiveHospitalityTypes'), 'role-derived hospitality type must be accepted by route guard');
assert.ok(setup.includes("from('profiles').select('restaurant_id,is_super_admin,role,status')"), 'setup must fall back to canonical tenant profile');
assert.ok(profilePage.includes("from('hms_settings').upsert(payload,{onConflict:'restaurant_id'})"), 'existing property profile save workflow must remain wired');
console.log('Property profile sidebar admin static checks: PASS');
console.log('Hospitality types: hotel, camp, homestay, guest_house, cottage');
console.log('Tenant admin roles: PASS');
console.log('Canonical profile fallback: PASS');
