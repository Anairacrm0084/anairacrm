# Anaira Real Completion Manifest

Date: 2026-09-25

## Source changes in this package

- Tenant-scoped CRM customer API.
- Hotel/Restaurant Customer 360 domain separation.
- Transactional hotel booking inventory locking and CRM/PMS linkage.
- Restaurant reservation validation and CRM linkage.
- Restaurant and Hotel CRM data-source fields updated for actual lifecycle data.
- Market benchmark and remaining production-gate documentation.

## Live database verification

Verified after deployment:
- `anaira_get_customer_360`
- `anaira_create_public_booking`
- `anaira_create_public_booking_by_id`
- `anaira_create_public_restaurant_reservation`
- `anaira_create_public_restaurant_reservation_by_id`

## Do not interpret this package as a certification of external provider E2E

The package is a real source release and live-backend hardening package, not a claim that third-party payment/OTA/messaging credentials or browser E2E have been configured.
