# Phase 53 — PMS / Front Desk

Implemented the Front Desk runtime over the existing HMS reservation/stay/room tables.

## Runtime
- Arrivals / confirmed reservations
- Automatic matching of an available room by room type for check-in
- Check-in through `anaira_pms_check_in`
- No-show / cancellation through reservation transition RPC
- In-house stay listing
- Check-out sends the room to dirty/housekeeping state
- Tenant-scoped HMS stays RLS
- Room move RPC: `anaira_pms_room_move`

## Verification
- Source syntax: PASS (`node --check`)
- Supabase PMS schema migration: APPLIED
- Authenticated browser E2E: NOT RUN
- Production deployment smoke: NOT RUN
