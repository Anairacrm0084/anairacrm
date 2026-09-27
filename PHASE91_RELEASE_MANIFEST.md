# ANAIRA PHASE 91 — PERMISSION SCOPE LOCKED RELEASE

Date: 2026-09-27
Source baseline: PHASE90 guest OTP complete fixed package

## Locked authority model
- SUPER ADMIN: platform/all-tenant settings, marketplace global controls, plugin activation, global integrations, global payments/commissions/OTA/security/audit.
- BUSINESS ADMIN: only its own hotel's/restaurant's operational data and business settings.
- STAFF: assigned operations only.

## Security enforcement layers implemented
1. Sidebar/menu separation.
2. Client route guard for Super Admin routes.
3. Page-level use through AppShell on global settings pages.
4. Supabase RLS for tenant/global data.
5. Database triggers for platform-owned marketplace/store/plugin activation fields.

## Database migrations applied live
- 20260927_phase91_permission_scope_lock
- 20260927_phase91_hotel_marketplace_hms_inventory_bridge
- 20260927_phase91_security_followup

## Source changes
- Super Admin global Marketplace Settings route.
- Super Admin Global Booking Engine route.
- Super Admin global Integrations navigation.
- Business Admin Plugin Control Center removed from sidebar.
- `/super-admin/*` and `/anaira/super-admin/*` protected by the application route guard.
- Locked permission-scope source document included under `docs/LOCKED_BASELINES/`.

## Verification
- JS syntax: 226/226 PASS.
- Live migration history contains all three Phase 91 migrations.
- Live HMS inventory rows: 180.
- Hotel marketplace search now calls canonical HMS availability.
- Production Next.js build: NOT RUN; source archive has no package-lock and dependency installation timed out in this environment.
- Browser E2E: NOT RUN in this environment.
- External OTA/payment provider live E2E: NOT certified.

This release must not be described as full production certification until the remaining build/browser/provider gates are executed.
