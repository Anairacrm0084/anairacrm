# Anaira Hotel Guest CRM Enterprise Implementation — 2026-09-30

## Scope
The former `/hotel-guest-crm` route was a generic plugin CRUD page over `crm_guest_stays`. It is now a dedicated Hotel Guest CRM application with live Supabase reads, tenant scoping, operational links, automation controls and manual data entry where relationship data needs operator input.

## Routes
- `/hotel-guest-crm` — Guest Command Center
- `/hotel-guest-crm/guests` — Guest Master + Guest 360 + duplicate detection/merge
- `/hotel-guest-crm/stays` — Stay history
- `/hotel-guest-crm/lifecycle` — Guest lifecycle
- `/hotel-guest-crm/pre-arrival` — Pre-arrival queue + pre-check-in
- `/hotel-guest-crm/arrival` — Arrival / check-in context
- `/hotel-guest-crm/in-stay` — In-stay operations
- `/hotel-guest-crm/post-stay` — Check-out / post-stay
- `/hotel-guest-crm/requests` — Guest requests + SLA
- `/hotel-guest-crm/complaints` — Complaints / service recovery
- `/hotel-guest-crm/preferences` — Automatic/manual preferences
- `/hotel-guest-crm/upselling` — Guest offers / upsells
- `/hotel-guest-crm/feedback` — Feedback / review records
- `/hotel-guest-crm/loyalty` — Loyalty accounts and transactions
- `/hotel-guest-crm/segments` — Segments and membership
- `/hotel-guest-crm/retention` — Churn / retention
- `/hotel-guest-crm/tasks` — Guest tasks / follow-ups
- `/hotel-guest-crm/timeline` — Unified timeline
- `/hotel-guest-crm/corporate` — Corporate accounts
- `/hotel-guest-crm/partners` — Travel agents / partners
- `/hotel-guest-crm/documents` — Guest verification metadata
- `/hotel-guest-crm/analytics` — Guest analytics
- `/hotel-guest-crm/automation` — Pre-arrival/campaign/workflow health
- `/hotel-guest-crm/ai` — AI guest insights and action queue
- `/hotel-guest-crm/consent` — Consent ledger
- `/hotel-guest-crm/integrations` — Integration ownership/health
- `/hotel-guest-crm/settings` — Tenant settings

## Live data
The UI reads canonical CRM tables from Supabase. It does not insert demo/sample rows. Manual forms write into the corresponding CRM-owned tables. Operational ownership remains separated:

- Booking Engine — reservation master
- PMS — room/check-in/check-out operations
- Restaurant POS — restaurant transactions
- Accounting — financial books
- Revenue Management — pricing recommendations
- CRM — guest relationship/profile/timeline/service context

## Automatic workflows
The UI exposes the existing pre-arrival worker and functional CRM worker. These can queue pre-arrival jobs, refresh analytics, customer relationships, churn scores and segment membership when the configured server-side worker credentials/cron are available.

## New relationship-layer schema
Migration `098_hotel_guest_crm_enterprise_ui.sql` adds:
- `crm_guest_precheckins`
- `crm_guest_documents`
- `crm_guest_stay_events`
- request SLA fields
- complaint stay/root-cause/recovery fields

The migration deliberately does not replace PMS or Booking Engine operational records.

## Manual entry
Manual creation is available for guest records, stays, requests, complaints, pre-check-ins, preferences, upsells, feedback, tasks, consent, corporate accounts, partners and segments. Guest profiles also support operator edit and exact phone/email duplicate merge.

## Validation
- JavaScript static syntax: PASS (319/319 files)
- Full `next build`: not executed in the supplied ZIP environment because `node_modules` is not included (`next: not found`).
