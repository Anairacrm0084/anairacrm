# Anaira Hotel + Camping Booking Engine Parity Audit — 2026-09-29

## Scope

Audited the existing public hotel marketplace, hotel direct booking page, hotel checkout/payment flow, public booking APIs/RPCs and Booking Engine Control Center, then added a parallel camping workflow without replacing hotel inventory ownership.

## Hotel flow retained

- Marketplace hotel search remains backed by `anaira_marketplace_hotel_search`.
- Hotel property pages remain `/book/[id]`.
- Hotel checkout remains `/book/[id]/checkout`.
- Hotel room availability remains HMS-driven.
- Existing OTP guest verification and hotel payment proof flow remain intact.
- Existing hotel booking engine administration remains `/booking-engine`.

## Camping flow added

- Marketplace search has Hotels/Camps mode switch.
- Hotel mode calls the hotel search RPC; Camp mode calls `anaira_marketplace_camp_search`.
- Camping catalog is separate from HMS room inventory.
- Camping supports:
  - camp/tent types
  - max adults/children/guests
  - per-person pricing
  - per-unit pricing
  - weekend rates
  - seasonal multiplier
  - minimum/maximum stay
  - date inventory
  - inventory holds
  - single-person booking
  - guest OTP verification
  - pay-at-camp
  - bank transfer / QR proof
  - booking confirmation
  - reservation and transaction records
- Public camping pages:
  - `/camp/[id]`
  - `/camp/[id]/checkout`
- Camping admin:
  - `/camping-booking-engine`
- Hotel Booking Engine now links directly to the Camping Engine.

## UI fixes

- Removed the black quote card from the About media section.
- Removed the green background behind the destination/banner carousel.
- Removed forced hero background overlay from the marketplace presentation layer.
- Fixed empty `<img src="">` rendering in hero/About media so missing URLs render `null` instead of empty `src` attributes.
- Marketplace search now clearly separates Hotel and Camp search modes.

## Static validation

- JavaScript syntax: 284/284 PASS.
- Existing P2 hotel booking static audit: FOUNDATION, 10 checks, 0 failures.
- Full Next.js production build could not be executed in this environment because dependencies were not installed; an attempted `npm install` exceeded the execution timeout. No build result is being represented as verified.

## Supabase migration

`supabase/migrations/20260929_camping_booking_engine.sql`

This migration must be applied to the connected Supabase project before Camping search/booking becomes live.
