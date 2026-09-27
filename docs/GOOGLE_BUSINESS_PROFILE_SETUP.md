# Anaira CRM — Google Business Profile Setup

## 1. Google Cloud
Create/choose a Google Cloud project for Anaira. Enable the Google Business Profile APIs required by your approved project. Google requires OAuth 2.0 credentials for protected Business Profile data.

## 2. OAuth consent
Configure the OAuth consent screen and add the Business Profile scope:
`https://www.googleapis.com/auth/business.manage`

## 3. OAuth client
Create a Web application OAuth client and set the exact redirect URI:
`https://YOUR-CRM-DOMAIN/api/reviews/source/callback`

## 4. Server environment
Set:
- GOOGLE_CLIENT_ID
- GOOGLE_CLIENT_SECRET
- ANAiRA_SECRET_KEY / ANAIRA_SECRET_KEY
- NEXT_PUBLIC_APP_URL

## 5. In Anaira
Open **AI Reviews → Connect Google**.
Then click **Discover Google Locations**. Anaira uses the authorized Google account to list administered Business Profile locations and stores tenant-scoped review source records.

## 6. Sync / automation
Use **Sync Google Reviews Now** for immediate sync. The deployment also schedules the Google review sync hourly. New reviews can then be processed by the AI Review engine every 10 minutes.

## 7. AI reply flow
Google review → `crm_reviews` → AI classification/draft → human approval by default → Google `updateReply` publish. Auto-publish should only be enabled deliberately and only after required production provider testing.

## 8. Data entry
Customers and CRM entities can be added from their modules or bulk imported from CSV through **Data Operations → CRM Data Import**. Google reviews should normally come from the real provider integration rather than manual entry.
