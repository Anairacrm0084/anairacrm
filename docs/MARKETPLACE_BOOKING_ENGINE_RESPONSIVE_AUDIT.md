# Anaira Marketplace + Hotel Booking Engine Responsive Audit

## Scope
- Super Admin Hotel Marketplace vs Restaurant Marketplace separation
- Hotel public marketplace search
- Hotel store / room inventory presentation
- Booking Engine administration
- Booking checkout
- Desktop/tablet/mobile layout hardening

## Architecture rules
- Hotel rooms/rates/availability remain owned by HMS.
- Restaurant menus/orders remain owned by Restaurant SaaS.
- A hotel-owned dining outlet is not automatically a standalone Restaurant Marketplace listing.
- Standalone Restaurant Marketplace visibility is controlled by the restaurant marketplace listing configuration.
- No duplicate operational inventory is introduced in CRM.

## Responsive targets
- Desktop: 1280px+
- Tablet landscape/portrait: 768–1100px
- Mobile: <= 760px
- Narrow mobile: <= 520px

## Implemented
- Super Admin marketplace boundary explanation and responsive business grids.
- Hotel marketplace search controls collapse cleanly on tablet/mobile.
- Hotel booking engine admin tabs remain horizontally usable on small screens.
- Booking engine KPI/cards/forms collapse for tablet/mobile.
- Hotel room cards use 4/2/1 column breakpoints.
- Hotel booking panel becomes single-column on tablet/mobile.
- Checkout uses single-column mobile layout and stacked date/guest/payment controls.

## Certification note
Source-level responsive hardening is included. Live browser screenshot/E2E certification still requires running the application with production dependencies and real Supabase/provider configuration.
