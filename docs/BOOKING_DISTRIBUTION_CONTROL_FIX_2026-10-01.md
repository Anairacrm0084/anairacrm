# Anaira Booking + Distribution Control Fix — 2026-10-01

## Changes
- Canonicalized the Anaira Booking Engine to `/booking-engine`.
- `/booking` is now only a compatibility redirect to `/booking-engine`.
- `/camping-booking-engine` and `/booking-engine/camping` are compatibility redirects to the same canonical engine.
- Plugin Catalog/Registry now point `hotel-booking` to `/booking-engine` and name it `Anaira Booking Engine`.
- Distribution property configuration now requires the `channel-manager` plugin to be activated for that property.
- Universal Distribution global platform activation remains a Super Admin/global control.
- Property-level distribution configuration/test is blocked when Channel / OTA Manager is disabled.
- First-party integration map explicitly documents the Plugin -> Property Connection -> Channel -> Mapping -> Sync chain.

## Control model
1. Plugin Control Center: activates/deactivates the Channel / OTA Manager capability for a property.
2. Universal Distribution Integrations: Super Admin enables global platforms and configures property connections.
3. Room/Rate Mapping: maps the connected channel to canonical HMS/PMS rooms and rate plans.
4. Sync worker/webhooks: execute ARI/reservation synchronization after a real provider connection is verified.

## Important
External OTA E2E still requires real provider credentials/API contracts and callback tests.
