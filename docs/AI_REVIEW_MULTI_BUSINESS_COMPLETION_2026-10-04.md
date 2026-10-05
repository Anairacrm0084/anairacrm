# Anaira AI Review — Multi-Business Completion

## Scope
AI Review is now designed as a generic multi-business, multi-location reputation platform rather than a hotel/restaurant-only module.

Supported vertical families include:
- Hotel / Resort
- Restaurant / Dining
- Cafe / Bakery / Bar / Catering
- Salon / Barber / Spa / Wellness
- Clinic / Dentist / Doctor / Hospital / Pharmacy
- Gym / Fitness / Yoga
- Retail / Grocery / Fashion / Jewellery / Electronics / Furniture
- Automotive / Auto Service
- Real Estate / Travel
- Education / Coaching
- Legal / Accounting / Agency / Professional Services
- Contractor / Home Services / Pet Services
- Photography / Events / Entertainment / Coworking
- Repair / Cleaning / Logistics
- Other Local Business

## Runtime changes
1. Added tenant-scoped business vertical configuration.
2. Added business context to reviews and review sources.
3. Added generic completed-interaction review request events.
4. Kept existing hotel stay and restaurant visit triggers backward compatible.
5. Added appointment / consultation / purchase / order / service-completion compatible generic trigger path through `crm_review_request_events`.
6. AI classification now receives business vertical, business name and service context.
7. AI reply instruction is no longer hospitality-only; it addresses customer/client/patient/visitor according to context.
8. Dashboard shows the business vertical for each review.
9. Plugin settings expose the business vertical and generic review-request label.
10. Google source sync preserves business context for every location/review.

## Integration contract
Any Anaira module can enqueue a completed customer interaction:
- `tenantId`
- `customerId`
- `referenceType`
- `referenceId`
- `businessVertical`
- `completedAt`
- `delayHours`
- optional `metadata`

The review automation worker then handles source selection, consent, idempotency, channel selection and delivery.

## Important boundary
Google Business Profile remains the provider integration currently implemented for public review ingestion/reply publishing. Other review providers can be added through the same provider/source abstraction without changing the business-vertical model.
