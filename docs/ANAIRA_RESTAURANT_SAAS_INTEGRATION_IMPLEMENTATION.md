# Anaira CRM ↔ Restaurant SaaS Integration

Implemented against the Phase 91 CRM source baseline.

## Canonical ownership
Restaurant SaaS is the operational source of truth for restaurant profile, menu, pricing, availability and restaurant orders. CRM owns Customer 360 and CRM workflows.

## CRM runtime
- `/api/integrations/restaurant` stores the Restaurant SaaS connection for a tenant and encrypts the machine key.
- `/api/integrations/restaurant/events` receives Restaurant SaaS events and updates CRM customer/restaurant-visit data.
- `/api/marketplace/restaurant/[id]` proxies the connected Restaurant SaaS live snapshot to the public marketplace.
- `/api/marketplace/restaurant/[id]/order` proxies marketplace orders to Restaurant SaaS.
- `/integrations` provides the Business Admin connection UI.

## Marketplace behavior
When a connection is established, the restaurant membership is switched to `catalog_source=restaurant_saas` and records the integration connection. The public restaurant store no longer reads `anaira_marketplace_menu_items` for the connected restaurant; it consumes the Restaurant SaaS bridge snapshot.

## Event behavior
Restaurant SaaS can POST `restaurant.order.created` to the CRM event endpoint. CRM authenticates the configured machine key, upserts the customer, records a `crm_restaurant_visits` row idempotently, recalculates restaurant revenue/visit aggregates and stores the raw event in `crm_integration_event_inbox`.

## Security
- Tenant API operations use `requireTenant`.
- Machine credentials are encrypted at rest with `ANAIRA_SECRET_KEY`.
- Public marketplace pages never receive the stored Restaurant SaaS key; server routes perform the machine-to-machine request.
- The new RLS policies scope connection/sync records to the tenant.

## Verification status
New/changed JavaScript files passed `node --check`. A full Next.js production build was not claimed because dependency installation timed out in the execution environment.
