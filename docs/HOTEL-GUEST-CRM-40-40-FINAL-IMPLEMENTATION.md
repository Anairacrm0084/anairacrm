# Anaira Hotel Guest CRM — Final 40/40 Implementation Baseline

## Scope
This build implements the Hotel Guest CRM relationship layer while preserving source ownership:
- Booking Engine: reservations
- PMS: room, check-in, check-out and stay operations
- POS: restaurant transactions
- CRM: guest identity, relationship, service context, timeline, loyalty, communication and retention
- Accounting: financial books
- Revenue Management: pricing recommendations

## Completed capability areas
1. Dashboard / Command Center
2. Guest 360
3. Guest Master
4. Stay History
5. Booking History + source customer linkage
6. Guest Lifecycle
7. Pre-Arrival + tenant-scoped worker
8. Arrival / Check-in context
9. In-Stay
10. Post-Stay
11. Requests + SLA
12. Complaints + Recovery
13. Preferences
14. VIP
15. Loyalty
16. Upselling
17. Cross-selling
18. Feedback
19. Reviews / reputation request history
20. Communication
21. WhatsApp
22. Email
23. SMS
24. Consent / Privacy + consent history
25. Segmentation
26. Churn / Retention
27. Tasks / Follow-ups
28. Corporate
29. Partners / Agents
30. Documents / Verification + signed URL + storage deletion
31. Guest Merge
32. Unified Timeline
33. Revenue / LTV
34. Analytics
35. Automation
36. AI Intelligence + approved action execution
37. Multi-property tenant/property switching
38. Dedicated Hotel Guest CRM permissions
39. Audit / Security + canonical CRM RLS
40. Integrations

## Important implementation additions
- `crm_hotel_cross_sell_opportunities`
- `crm_consent_events`
- canonical `crm_timeline_events` source uniqueness
- relationship-layer timeline triggers
- booking/PMS -> CRM customer linking
- tenant-scoped pre-arrival RPC
- tenant-scoped manual automation endpoint
- tenant-scoped manual campaign endpoint
- AI approved-action execution endpoint
- secure guest document signed URLs
- storage object deletion before document metadata deletion
- dedicated `hotel_guest_crm.view/manage/configure` permissions
- canonical CRM tenant RLS hardening
- restaurant/POS visits included in Guest 360 timeline

## Validation
- TypeScript JSX parser: all 359 JS/JSX source files parsed successfully.
- P0 static foundation: 8/8 PASS.
- P1 static CRM parity: 10/10 PASS.
- Hotel Guest CRM completion static checks: 67/67 PASS.
- Production Next build: not certified in this clean archive environment because dependency installation timed out. Run `npm install` and `npm run build` in the target environment.
- Live Supabase/provider E2E: requires the deployed project's credentials and data.
