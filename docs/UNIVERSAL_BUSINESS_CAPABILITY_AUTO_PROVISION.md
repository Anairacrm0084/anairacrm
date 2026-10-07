# Universal Business Capability Auto-Provisioning

This patch makes Business Type the capability selector.

## Rules

| Business Type | Auto provision |
|---|---|
| `hotel_resort` | Hotel Store + Booking Engine |
| `hotel_restaurant` | Hotel Store + Booking Engine + Restaurant Store |
| `restaurant_cafe` | Restaurant Store |
| Other | No unrelated store |

Existing tenants are backfilled by the migration.

## Important architecture

- Hotel operational data remains in HMS.
- Restaurant operational data remains in Restaurant SaaS/POS.
- Marketplace store membership is only the presentation/distribution capability.
- No duplicate room/menu master is created.
- Camp continues through the existing camping engine.
- `anaira_stay_properties` is only used for its currently supported stay types:
  `homestay`, `guest_house`, `cottage`.

## Nh3

The live Nh3 property was verified after the database trigger was applied:
- Hotel marketplace membership enabled.
- Catalog source: `anaira_hms`.
- Booking Engine direct booking enabled.
- Currency: INR.
- Payment mode: pay at hotel.

The migration in this package is the source-controlled version of the database fix.
