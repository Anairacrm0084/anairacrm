# Anaira CRM — Real Data + Google Business Profile Guide

## Add data manually
- Customer 360 → + New Record
- Leads / Corporate / Partners / other modules → + New Record

## Import bulk data
- Open /import-export
- Select Customers, Leads, Corporate, Partners or Reviews
- Download the CSV template
- Fill the template with real records
- Upload and Import
- Server-side allow-listing, tenant checks, deduplication and audit logging are applied

## Google reviews
1. Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET on the server.
2. Set ANAIRA_SECRET_KEY and NEXT_PUBLIC_APP_URL.
3. Configure OAuth redirect URI exactly as `/api/reviews/source/callback`.
4. Open AI Reviews → Connect Google.
5. Complete Google consent.
6. Click Discover Google Locations.
7. Click Sync Google Reviews Now for an immediate sync.
8. Scheduled sync runs hourly.
9. New reviews are processed by the AI Review engine every 10 minutes when OPENAI_API_KEY is configured.
10. By default AI replies require human approval. Approved replies can be published to Google.

## Provider credentials
AI: OPENAI_API_KEY
WhatsApp: WHATSAPP_ACCESS_TOKEN + WHATSAPP_PHONE_NUMBER_ID
SMS: Twilio variables
Email: RESEND_API_KEY + RESEND_FROM

No fake success state is generated when a real provider is not configured.
