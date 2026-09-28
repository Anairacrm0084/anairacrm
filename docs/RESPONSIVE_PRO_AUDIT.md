# Anaira CRM — Responsive Pro Audit

## Scope
Global responsive hardening across the CRM application and the Anaira public/platform shell.

## Breakpoints
- Desktop: > 1100px
- Tablet: 761–1100px
- Mobile: <= 760px
- Narrow phone: <= 430px

## Changes
- Added responsive off-canvas CRM sidebar with hamburger control on tablet/mobile.
- Added backdrop, Escape handling, scroll locking and automatic close after navigation.
- Preserved full sidebar labels when the drawer is open.
- Desktop/tablet navigation remains functional without changing route permissions or plugin visibility.
- Added tablet two-column fallback for inline React grids.
- Added mobile one-column fallback for inline React grids.
- Added flex wrapping for inline toolbars and action rows.
- Added viewport-safe modal rules.
- Preserved horizontal scrolling for dense data tables instead of shrinking columns until unreadable.
- Added responsive controls for filters, KPI cards, module cards and quick actions.
- Hardened the separate `AnairaShell` marketplace/platform header with a mobile menu.
- Added narrow-phone single-column rules.

## Source verification
- JavaScript/JSX syntax: PASS (279/279)
- CSS brace balance: PASS
- Production build: NOT RUN in this environment because dependencies could not be installed within the available execution window.

## Important
This is a source-level responsive hardening pass. Final visual certification still requires browser screenshots/E2E at representative viewport sizes:
- 1440x900
- 1280x800
- 1024x768
- 834x1194
- 768x1024
- 430x932
- 390x844
- 360x800


## v3 visual layout hardening
- Tablet (761–1100px) now uses an off-canvas full-label sidebar instead of an icon-only rail.
- Tablet portrait (761–900px) reduces KPI/module density to two columns.
- Global inline React grids are constrained to usable columns at tablet/mobile widths.
- Page-level overflow is suppressed; dense data tables retain horizontal scrolling inside their container.
- Mobile headers/actions, filters and admin toolbars stack into touch-friendly controls.
- Public hotel/store/booking layouts receive additional narrow-width grid protection.
- Narrow phones collapse KPI/module/action grids to one column.
- This remains source-level hardening; browser screenshot/E2E certification is still required.
