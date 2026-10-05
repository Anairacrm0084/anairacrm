# Anaira Hotel Guest CRM — Enterprise Completion Patch

## Migration order
1. `102_hotel_guest_crm_dependency_repair.sql` — repairs the missing `crm_customer_merge_events` dependency and installs the final CRM timeline/cross-sell/consent completion layer.
2. `103_hotel_guest_crm_enterprise_completion.sql` — adds the multi-property master/link layer, source event inbox + delivery log, segment rule table, cross-sell rule fields, loyalty reversal metadata, AI action registry, provider config/webhook tables, and scheduler metadata.

Both migrations are idempotent.

## Important
The live Supabase project was repaired and the enterprise completion migration was applied during this turn. The source ZIP also contains these migrations so the same database state can be reproduced in another environment.

## Remaining certification
The implementation is not considered production-certified until `npm run build`, browser E2E, provider webhook E2E, scheduler execution, and cross-tenant/property isolation tests pass in the deployment environment.
