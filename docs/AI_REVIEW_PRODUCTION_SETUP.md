# Anaira AI Review — Production Setup

## 1. Required credentials

Put these in the **server/deployment environment variables**, not in Supabase tables, browser code, plugin JSON, or the repository:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `ANAIRA_SECRET_KEY`
- `CRON_SECRET`
- `NEXT_PUBLIC_APP_URL`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `OPENAI_API_KEY`
- `OPENAI_MODEL`

Optional communication providers:

- WhatsApp: `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`
- SMS: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM`
- Email: `RESEND_API_KEY`, `RESEND_FROM`

## 2. Google Business Profile setup

Google requires Business Profile API access approval and an OAuth 2.0 client for protected Business Profile data.

Official setup: https://developers.google.com/my-business/content/basic-setup

### Google Cloud

1. Create/select the Google Cloud project.
2. Request Business Profile API access if the project has not been approved.
3. Enable the Business Profile APIs required by your integration.
4. Configure OAuth consent screen.
5. Create an OAuth **Web application** client.
6. Add this exact redirect URI:

`https://YOUR_CRM_DOMAIN/api/reviews/source/callback`

For local development:

`http://localhost:3000/api/reviews/source/callback`

7. Put the generated Client ID/Secret into `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`.

### OAuth scope

Anaira uses:

`https://www.googleapis.com/auth/business.manage`

The merchant must sign in and explicitly grant access.

## 3. Connect inside Anaira

1. Open **AI Reviews**.
2. Click **Connect Google**.
3. Complete Google consent.
4. Click **Discover Google Locations**.
5. Select/activate the discovered Business Profile locations.
6. Click **Sync Google Reviews Now**.

The integration stores the provider refresh token encrypted server-side.

## 4. AI Review workflow

`Google Review`
→ `crm_reviews`
→ `AI classification`
→ `topics/sentiment`
→ `AI reply draft`
→ `Human approval`
→ `Google reply publish`

Negative reviews can additionally enter:

`Recovery Case → Owner → SLA → Escalation → Resolution`

## 5. Automatic Google replies

Automatic reply publishing is **not enabled merely by setting `auto_publish=true`**.

Anaira also requires the tenant's explicit reply-automation consent flag.

Recommended production setting:

- Human approval: ON
- Auto publish: OFF

Only enable automatic replies after the business owner has given the required specific consent and your Google Business Profile API usage complies with Google's current policies.

## 6. Real-time Google notifications

For near-real-time review events, create a Google Cloud Pub/Sub topic and configure Business Profile Notifications API.

Google requires the Business Profile service account to have publish permission on the topic. The account notification setting is linked to the Pub/Sub topic.

Anaira endpoint:

`POST /api/reviews/webhook/google?token=YOUR_GOOGLE_PUBSUB_WEBHOOK_SECRET`

Set `GOOGLE_PUBSUB_WEBHOOK_SECRET` in the server environment. Do not expose it in the application UI.

Use a Google Pub/Sub push subscription to deliver the Pub/Sub message to that endpoint through your authenticated gateway/HTTPS setup.

Anaira deduplicates webhook events by provider/event key and schedules a source sync.

## 7. Communication credentials

### WhatsApp

Set:

`WHATSAPP_ACCESS_TOKEN`
`WHATSAPP_PHONE_NUMBER_ID`

Then enable WhatsApp in AI Review settings.

### SMS

Set Twilio credentials and enable SMS.

### Email

Set Resend credentials and enable Email.

If no provider credentials exist, Anaira returns a provider configuration error rather than pretending a message was sent.

## 8. Review-request automation

A completed hotel stay or restaurant visit can create a review-request job only when:

- a Google review URL exists;
- customer contact information exists;
- communication consent is verified;
- the idempotency key has not already been used.

Templates are now tenant-scoped and versioned.

Supported variables:

- `{{customer_name}}`
- `{{review_url}}`

## 9. AI Review Templates

Go to:

`AI Reviews → Templates`

You can:

- create a template;
- select channel;
- set trigger;
- edit/version the template;
- activate/deactivate;
- delete it.

Templates are stored in `crm_review_templates` and versions in `crm_review_template_versions`.

## 10. Automation Rules

Go to:

`AI Reviews → Automation`

Rules support tenant-scoped trigger/condition/action JSON. The UI provides starter rules for:

- New Review
- Negative Review
- Review Request Due
- SLA Overdue

The runtime remains provider-gated: missing provider credentials produce a real failure/dead-letter path.

## 11. Google content retention

Google Business Profile API content has specific storage restrictions. Anaira records an expiry time for synced Google review content and runs a nightly retention worker to clear expired Google review content.

Do not use Google-sourced review content as a permanent independent content archive.

## 12. Cron / scheduled automation

Configured scheduled jobs include:

- Google review sync — every 10 minutes
- AI review processing — every 10 minutes
- review-request automation — hourly
- message delivery worker — every 10 minutes
- SLA worker — every 15 minutes
- Google content retention — daily

Your deployment platform must actually execute the configured cron jobs; declaring a cron route alone is not proof of execution.

## 13. Production verification

After deploying:

1. Sign in as a real CRM tenant user.
2. Connect Google.
3. Discover a Business Profile location you actually manage.
4. Sync one or more real reviews.
5. Confirm the review appears in the Inbox.
6. Run AI processing with a real OpenAI key.
7. Confirm an AI action record exists.
8. Approve a draft with the signed-in user.
9. Publish the approved reply to Google.
10. Confirm provider action/audit records.
11. Test a negative review recovery case.
12. Test an overdue recovery SLA.
13. Create a review-request template.
14. Test a consented review-request job with a real provider.
15. Verify retry/dead-letter behavior with intentionally invalid provider credentials in a non-production tenant.
