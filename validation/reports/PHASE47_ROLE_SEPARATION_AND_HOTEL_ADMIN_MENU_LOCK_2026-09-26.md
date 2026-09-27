# Phase 47 — Role Separation + Business Admin Hotel Menu Lock

## Locked architecture

### Super Admin
Platform scope only:
- Platform Dashboard
- Properties / Tenants
- Business Admins
- Users / Roles governance
- Plugin Control Center
- Global Integrations
- Platform SEO / AI controls
- Audit Logs
- Platform Settings
- Marketplace platform controls

### Business Admin
Tenant/property scope only:
- Hotel Dashboard
- Hotel Profile / Property
- Room Types
- Rooms
- Room Inventory
- Rate Plans
- Reservations
- PMS / Front Desk
- Housekeeping
- Business CRM
- Payments / reconciliation available to tenant scope
- Marketplace listing / booking engine for its property
- OTA / channels when enabled
- Staff / roles within tenant
- Business Settings

### Staff
Only assigned operational modules and permissions.

## Security contract

1. `/platform-settings`, `/properties`, `/business-admins`, `/system`, `/audit`, `/admin` remain Super Admin only.
2. Business Admin does not receive platform/global settings in the sidebar.
3. Direct URL access is blocked by AppShell route guards as well as database RLS/server authorization where applicable.
4. Hotel management pages remain tenant scoped through `restaurant_id` / selected property.
5. Room Management is a core Business Admin capability, not optional.

## Business Admin Hotel Management menu

- Hotel Dashboard
- Hotel Profile
- Room Types
- Rooms
- Room Inventory
- Rate Plans
- Reservations
- PMS / Front Desk
- Housekeeping

Only routes that currently exist in the application are exposed. Future menu items are to be added only when their real runtime exists; no dead navigation is introduced.

## Phase 47 implementation

- Reorganized Business Admin sidebar into a dedicated HOTEL MANAGEMENT group.
- Kept Super Admin platform controls separate.
- Fixed Business Admin dashboard Hotel Management link to `/hotel-management`.
- Fixed Business Settings link to `/business-settings`.
- Preserved plugin and permission gates.
- Preserved tenant/property scoping.

## Certification status

Data Model: VERIFIED (existing tenant/property model)
Security/RLS: VERIFIED at route/RLS foundation level
API/Runtime: VERIFIED for role gating/navigation
UI: IMPLEMENTED
Provider: N/A
Persistence/History: N/A
Error/Retry: N/A
E2E: PENDING browser execution
Production Build: PENDING clean environment build

Therefore this point is **IMPLEMENTED / VERIFIED at source level**, not falsely marked production certified until browser E2E + production build pass.
