# Anaira Phase 86 — Hotel lifecycle time + inventory

- India timezone: Asia/Kolkata.
- Default hotel check-in: 12:00 PM; checkout: 11:00 AM, read from hms_settings.
- Early check-in is an explicit hotel-admin override.
- Check-in writes restaurant_id to hms_stays and hms_folios, marks reservation checked_in, room occupied + dirty.
- Checkout requires zero reservation balance, marks stay/reservation checked_out, room dirty, and creates a housekeeping task.
- Inventory dashboard derives physical-room effective status from reservation + housekeeping state.
