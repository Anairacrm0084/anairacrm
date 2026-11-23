import fs from 'node:fs';
import assert from 'node:assert/strict';
const read=p=>fs.readFileSync(new URL(p,import.meta.url),'utf8');
const ui=read('../../app/ota/OTAManager.jsx');
const route=read('../../app/api/ota/listing-link/route.js');
const migration=read('../../supabase/migrations/20261123130000_ota_existing_listing_link_requests.sql');
const superAdmin=read('../../app/super-admin/ota-listing-requests/page.jsx');
for(const [name,ok] of [
 ['Existing OTA listing ID form',ui.includes('Existing OTA Property / Listing ID')],
 ['Existing OTA account email field',ui.includes('Existing OTA account email')],
 ['Explicit property owner consent',ui.includes('ownerConsent')&&ui.includes('owner authorization')],
 ['No OTA password requested',!ui.includes('OTA account password')],
 ['Authenticated server endpoint',route.includes('requireTenant(req, restaurantId)')],
 ['Provider allowlist enforced',route.includes('ALLOWED.has(provider)')],
 ['Accommodation profile scope enforced',route.includes('homestay')&&route.includes('guest_house')&&route.includes('cottage')],
 ['Request remains pending until real provider authorization',route.includes("status: 'authorization_requested'")],
 ['RLS tenant scoped table',migration.includes('enable row level security')&&migration.includes('anaira_tenant_access(restaurant_id)')],
 ['No false live-connected state',route.includes('no live sync has been enabled')],
 ['Super Admin request review page',superAdmin.includes('Existing OTA Listing Requests')&&superAdmin.includes('ready_for_oauth')],
 ['Only Super Admin can update review status',migration.includes('using (public.anaira_current_is_super_admin())')]
]) assert.ok(ok,`FAIL: ${name}`);
console.log(JSON.stringify({status:'PASS',checks:12,scope:'existing OTA listing request flow only; OAuth/provider API approval is still external'}));
