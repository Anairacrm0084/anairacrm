# Vercel Hobby deployment note

The five-minute Cron entry was removed from `vercel.json` so this project can deploy on Vercel Hobby. Hobby Cron Jobs do not support a five-minute schedule; they are limited to at most one execution per day.

The API route `/api/distribution/sync/worker` remains in the project. To run it every five minutes, use an external scheduler that sends an HTTPS request to the deployed route and supplies the configured `CRON_SECRET` as `Authorization: Bearer <CRON_SECRET>` (or the exact authorization format enforced by the route). Do not expose the secret in client-side code.

If you later upgrade to a Vercel plan that supports the required frequency, restore the cron entry there.
