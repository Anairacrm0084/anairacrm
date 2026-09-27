# Anaira Guest OTP setup

The guest OTP endpoint is `app/api/hotel/guest-otp/route.js`.

## Server secret
`ANAIRA_SECRET_KEY` is the preferred dedicated OTP signing secret. If it is not set, the route derives a separate OTP secret from `SUPABASE_SERVICE_ROLE_KEY`, so the checkout does not fail merely because the optional OTP key was omitted. The secret is never exposed to the browser or WordPress.

## Email OTP
Set `RESEND_API_KEY` and `RESEND_FROM` in the deployed Anaira CRM environment.

## Phone OTP
Set `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_FROM`.

After changing Vercel environment variables, redeploy the CRM.
