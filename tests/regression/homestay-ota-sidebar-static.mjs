import fs from 'node:fs';
import assert from 'node:assert/strict';
const shell=fs.readFileSync('app/components.js','utf8');
assert.match(shell,/\['⇄','Channel \/ OTA Manager',`\/channel-manager\?type=\$\{type\}`,'ota\.sync\.view','channel-manager'\]/,'hospitality sidebar must expose OTA manager behind channel-manager plugin');
assert.match(shell,/Edit \$\{m\.label\} Property Profile/,'property profile edit item must remain in the hospitality sidebar');
for(const role of ['homestay_admin','homestay_owner','homestay_manager','property_admin','property_owner']) assert.ok(shell.includes(`'${role}'`),`${role} must be recognized as tenant admin`);
assert.match(shell,/if\(item\.plugin && ctx\.plugins\[item\.plugin\]!==true && !hospitalityItem\) return false;/,'OTA item must be controlled by plugin activation');
console.log('Homestay OTA sidebar static checks: PASS');
console.log('Edit Property Profile sidebar definition: PASS');
