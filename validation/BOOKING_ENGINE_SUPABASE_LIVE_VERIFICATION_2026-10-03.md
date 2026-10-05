# Anaira Booking Engine — Supabase Live Verification — 2026-10-03

## Connected project
- Supabase project: `bhptqdoteucuymmdzsmg`
- Region: `ap-south-1`
- PostgreSQL: `17.6.1.166`
- Status: ACTIVE_HEALTHY

## Live database closure applied
The premium booking closure migration was applied successfully as:
`booking_engine_premium_live_closure_20261003`

Created/closed:
- `booking_master_orders`
- `booking_conversion_events`
- `booking_abandoned_sessions`
- `booking_rate_parity_snapshots`
- `booking_group_requests`
- `booking_member_rates`
- premium booking columns on `booking_reservations`
- premium quote RPC
- multi-room transaction RPC
- public booking lookup RPC
- RLS/grants for public booking conversion, parity reads and group requests

## Live verification
Confirmed installed RPCs:
- `anaira_calculate_hotel_premium_quote(uuid,uuid,uuid,date,date,integer,integer,text,jsonb)`
- `anaira_create_multi_room_booking_transaction(uuid,text,text,text,date,date,jsonb,text,text,text,uuid)`
- `anaira_public_booking_lookup(text,text)`

Confirmed tables exist:
- all 6 premium closure tables above

Current live rows at verification time:
- booking master orders: 0
- conversion events: 0
- abandoned sessions: 0

## Security observation
Supabase security advisors still report pre-existing SECURITY DEFINER exposure across the project. The new public booking quote and multi-room RPCs are also SECURITY DEFINER because they are public booking endpoints and must access protected hospitality data transactionally. Their bodies validate tenant/property IDs and guest verification before mutating booking state.

The advisor also reports one unrelated table with RLS enabled and no policy: `crm_corporate_ledger`.

## Build status
- JavaScript syntax: 365/365 PASS
- Premium static checks: 21/21 PASS
- Full Next.js build: NOT CERTIFIED in this environment because `node_modules` is absent and `next` is not installed.

## Important production certification still requiring real data/provider credentials
- Real guest OTP booking
- Real payment capture/refund/reconciliation
- Real OTA provider sync
- Real abandoned-booking recovery delivery
- Real multi-room checkout against populated inventory/rate data
