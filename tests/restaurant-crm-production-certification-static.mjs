import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const required = [
  'app/restaurant-crm/page.js',
  'app/api/integrations/restaurant/events/route.js',
  'supabase/migrations/20261003_restaurant_crm_production_scheduler_and_property_metric_scope.sql',
  'tests/restaurant-crm-full-completion-static.mjs',
];
for (const file of required) {
  if (!fs.existsSync(path.join(root, file))) throw new Error(`Missing ${file}`);
}
const sql = fs.readFileSync(path.join(root, 'supabase/migrations/20261003_restaurant_crm_production_scheduler_and_property_metric_scope.sql'), 'utf8');
for (const token of ['pg_cron','anaira_restaurant_automation_worker','anaira_restaurant_campaign_worker','property_id set not null','crm_restaurant_customer_metrics_property_unique']) {
  if (!sql.includes(token)) throw new Error(`Missing certification token: ${token}`);
}
console.log('Restaurant CRM production certification static: PASS');
