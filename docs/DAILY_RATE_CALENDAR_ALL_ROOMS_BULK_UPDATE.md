# Daily Rate Calendar — All Rooms & Bulk Update

## Changes
- Added an `All Rooms` selector option and made it the default when switching property.
- In All Rooms mode, renders each active room type separately, with its EP / CP / MAP / AP calendars.
- Single-room selection continues to show only that room type.
- Initialize now creates/initializes the four board plans for every visible room type without creating duplicate board plans for the same room type.
- Bulk Update supports all visible rooms, one selected room type, or an individual rate plan.
- Preserved individual date editor, occupancy rates, extra adult/child rates, and Stop Sell.
- Existing `anaira_bulk_set_daily_rate` RPC is retained; live database inspection confirmed the RPC exists with the expected signature.

## Safety
- No existing rates, reservations, room types, or database records were deleted.
- No new database migration is required for this UI change.
- Bulk update continues to show a confirmation before overwriting daily rates.

## Verification
- Static test: 12/12 PASS.
- Live Supabase RPC presence verified.
- Full Next.js production build not run in this environment.
