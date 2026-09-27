# Anaira Phase 85 — Hotel Lifecycle + India Date Inventory

Base: Phase 84 FINAL Hotel Booking + Smart Inventory.

Changes:
- Inventory uses Asia/Kolkata date as default/current business date.
- Physical room cards derive effective reservation status for the selected date: reserved/occupied.
- Checked-in room is occupied/unavailable and housekeeping is dirty.
- Checkout requires zero reservation balance and changes room to dirty.
- Added manual housekeeping transitions dirty -> cleaning -> clean/inspected; clean/inspected makes the room sellable again.
- HMS folio creation during check-in now supplies restaurant_id and reservation total/balance, avoiding the restaurant_id NOT NULL error.
- Booking admin hides Check-out until the balance is zero.
