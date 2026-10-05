# ANAIRA HOTEL GUEST CRM — ENTERPRISE COMPLETION — 2026-09-30

## Scope

This release upgrades `/hotel-guest-crm` from a generic guest-stay table view into a dedicated Hotel Guest CRM relationship layer.

### Route coverage

- Dashboard / Guest Command Center
- Guests / Guest 360
- Stays
- Lifecycle
- Pre-Arrival
- Arrival / Check-in
- In-Stay
- Check-out / Post-Stay
- Guest Requests
- Complaints / Service Recovery
- Preferences
- Upselling
- Feedback & Reviews
- Loyalty
- Segments
- Churn / Retention
- Tasks / Follow-ups
- Guest Timeline
- Corporate Guests
- Travel Agents / Partners
- Documents / Verification
- Analytics
- Automation
- AI Guest Intelligence
- Consent / Privacy
- Integrations
- Settings

## Data model

The UI reads live Supabase records from CRM relationship tables and, where available, linked Booking Engine, PMS, and restaurant-visit records. Manual CRUD is provided for relationship-layer records that staff need to create directly.

### Automatic/source-system data

- `crm_customers`
- `crm_guest_stays`
- `booking_reservations`
- `pms_reservations`
- `crm_restaurant_visits`
- `crm_prearrival_jobs`
- `crm_churn_scores`
- `crm_ai_insights`
- `crm_ai_action_queue`
- `crm_workflows`
- `crm_workflow_runs`
- `crm_analytics_daily`

### Manual CRM actions

- Add guest
- Add stay
- Add request
- Add complaint/service recovery
- Add pre-check-in record
- Add preference
- Add upsell
- Add feedback
- Add task
- Add consent
- Add guest document metadata
- Add loyalty transaction
- Add reward
- Add corporate account/contact/contract
- Add partner
- Add partner booking
- Add interaction
- Add lifecycle/stay event

## Guest 360

Guest profiles aggregate:

- profile/contact
- booking history
- stay history
- restaurant-linked visits
- preferences
- requests
- complaints
- feedback
- upsells
- loyalty
- consent
- tasks
- interactions
- unified timeline
- guest revenue

Duplicate guest detection and merge remain available through the existing transactional merge RPC.

## Automation

The CRM UI exposes:

- pre-arrival queue execution
- functional CRM worker execution
- campaign worker execution
- workflow status
- workflow run history
- manual lifecycle event creation

## Ownership boundary

- Booking Engine owns reservations.
- PMS owns rooms, check-in and check-out operations.
- POS owns restaurant transactions.
- CRM owns guest relationship/profile/timeline/service context.
- Accounting owns financial books.
- Revenue Management owns pricing recommendations.

## Security / hardening

Migration `099_hotel_guest_crm_enterprise_hardening.sql` adds operational indexes and tenant-scoped policies for newly exposed corporate and partner relationship records.

## Validation

`npm run check:js` => 319/319 JavaScript files PASS.

`npm run p1:check` => required files 5/5, checks 10/10, failed 0.

A full production `next build` still requires project dependencies to be installed in the deployment environment.
