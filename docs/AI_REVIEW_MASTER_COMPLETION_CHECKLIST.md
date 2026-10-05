# Anaira AI Review — Master A-to-Z Multi-Business Completion Checklist

This is the locked checklist for AI Review across hotels, restaurants, retail shops, salons, barber shops, clinics, professional services, local services and other multi-location businesses. An item is not considered complete merely because a UI control exists; it must have a real source implementation, tenant-safe database behavior, error handling, and production verification.

## 0. Multi-Business / Multi-Location Foundation
- business vertical registry
- tenant business profile
- multi-location source registry
- hotel / restaurant / cafe / bakery
- salon / barber / spa / wellness
- clinic / dentist / doctor / hospital / pharmacy
- retail / grocery / fashion / jewellery / electronics / furniture
- automotive / garage / real estate / travel
- education / legal / accounting / agency / professional services
- contractor / home services / pet services / photography / events / entertainment / coworking / repair / cleaning / logistics
- generic completed-interaction review request event
- vertical-aware AI context and templates

## 1. Google Business Profile
- OAuth 2.0 with `business.manage`
- account discovery
- location discovery
- location/source registry
- review list sync
- pagination
- review deduplication
- latest review fields: reply URL, reply state, policy violation, media
- manual sync
- scheduled sync
- Pub/Sub notification setup
- webhook authentication
- webhook deduplication
- webhook → sync → AI processing
- disconnect/unlink flow

## 2. AI Review Intelligence
- OpenAI Responses API
- structured JSON schema output
- sentiment
- sentiment score
- topics
- escalation detection
- draft reply
- model/version tracking
- prompt version tracking
- token/latency logging
- AI failure logging
- plugin enable/disable enforcement

## 3. Approval & Reply Publishing
- human approval
- authenticated approver identity
- edit-before-approval
- rejected state
- approved state
- Google reply publishing
- idempotency
- provider response logging
- provider failure logging
- manual reply authorization
- explicit consent gate for automatic publishing
- reply automation audit

## 4. Service Recovery
- automatic negative-review detection
- recovery case creation
- duplicate prevention
- ownership
- priority
- SLA due time
- open → in progress → resolved → closed
- reopen
- resolution note
- recovery event history
- SLA overdue escalation
- manager notification
- automation hook

## 5. Automation Engine
- tenant-scoped rules
- triggers
- conditions
- action list
- action idempotency
- execution record
- failure record
- retry-safe action execution
- notify
- create recovery
- assign recovery
- create follow-up
- send review request
- AI classify
- Google publish
- test/run-now
- new-review trigger
- negative-review trigger
- review-classified trigger
- review-replied trigger
- review-request-due trigger
- SLA-overdue trigger

## 6. Templates
- create
- edit
- version history
- restore version
- activate/deactivate
- delete
- variables
- preview
- channel/trigger

## 7. Review Requests
- completed customer interaction trigger
- hotel stay trigger
- restaurant visit trigger
- appointment / consultation trigger
- purchase / order trigger
- service completion trigger
- generic vertical trigger
- consent verification
- Google review URL
- queued job
- provider delivery
- retry/backoff
- dead-letter
- delivery log
- idempotency

## 8. Analytics
- date filters
- source filter
- sentiment filter
- rating filter
- total reviews
- average rating
- response rate
- response time
- positive/negative/neutral
- source comparison
- rating distribution
- topic trends
- daily trend
- recovery metrics
- request metrics
- CSV export

## 9. Data & Security
- tenant isolation
- RLS on operational tables
- encrypted Google refresh token
- no secret keys in client bundle
- authenticated action identity
- audit logs
- Google content retention/expiry
- derived Google-content log expiry
- disconnect capability
- no fake/demo runtime business data

## 10. Production Gate
- JavaScript syntax checks
- route smoke checks
- migration verification
- production build
- Google OAuth E2E
- Google sync E2E
- real AI E2E
- human approval E2E
- Google reply E2E
- Pub/Sub E2E
- recovery/SLA E2E
- messaging provider E2E
- multi-tenant isolation E2E
