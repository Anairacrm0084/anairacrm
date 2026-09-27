# Real AI Review Setup — What to Add and Where

## App environment
Put these in the server/deployment environment, not in browser code:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `ANAIRA_SECRET_KEY`
- `CRON_SECRET`

## Google Business Profile
1. Create a Google Cloud project.
2. Request/obtain Business Profile API access as required by Google.
3. Configure OAuth consent screen.
4. Create OAuth Web Application credentials.
5. Add redirect URI:
   `https://YOUR_CRM_DOMAIN/api/reviews/source/callback`
6. Set:
   `GOOGLE_CLIENT_ID`
   `GOOGLE_CLIENT_SECRET`
7. Use OAuth scope:
   `https://www.googleapis.com/auth/business.manage`
8. In Anaira: AI Reviews → Connect Google.
9. Complete Google consent as the business owner/authorized manager.
10. Click Discover Google Locations.
11. Click Sync Reviews Now.

## Google Pub/Sub
1. Create a Pub/Sub topic.
2. Grant the Google Business Profile notification service account the publish permission required by Google.
3. Create a push/pull subscription according to your deployment.
4. Set:
   `GOOGLE_PUBSUB_WEBHOOK_SECRET`
5. In Anaira: AI Reviews → Sources → Configure Pub/Sub.
6. Enter topic resource name such as:
   `projects/YOUR_PROJECT/topics/YOUR_TOPIC`
7. Enable notifications.

## OpenAI
Set:
- `OPENAI_API_KEY`
- `OPENAI_MODEL=gpt-5.6-luna`

AI Review will fail explicitly when the provider credential is missing. It will not create fake AI replies.

## WhatsApp / SMS / Email
WhatsApp:
- `WHATSAPP_ACCESS_TOKEN`
- `WHATSAPP_PHONE_NUMBER_ID`

SMS:
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_FROM`

Email:
- `RESEND_API_KEY`
- `RESEND_FROM`

## Automatic Google replies
Keep human approval enabled by default. To allow automatic replies, explicitly enable the plugin's auto-publish setting and record the business user's reply-automation consent in AI Review → Sources/Google settings.

## Important provider rules
Google Business Profile APIs only permit you to manage listings that you own or are authorized to manage. Google also requires authorization for replies and restricts automated/programmatic changes without the end user's prior specific and express consent. Google API content must be stored temporarily (no more than 30 calendar days) and securely.
