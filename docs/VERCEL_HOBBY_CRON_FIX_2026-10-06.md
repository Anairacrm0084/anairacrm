# Vercel Hobby Cron Fix

## What changed

Vercel `vercel.json` no longer contains scheduled cron jobs. This avoids Vercel Hobby deployment failures caused by sub-daily cron expressions.

The existing worker API routes were not rewritten. They are still protected by `CRON_SECRET` and are now triggered by GitHub Actions.

Added:

- `.github/workflows/anaira-workers.yml`
- Updated `vercel.json`
- This setup document

## GitHub repository secrets

In the GitHub repository go to:

**Settings → Secrets and variables → Actions → New repository secret**

Add:

### `ANAIRA_APP_URL`

Your production Vercel URL, for example:

`https://your-project.vercel.app`

Do not add a trailing slash.

### `CRON_SECRET`

Use the exact same value that is configured as the Vercel environment variable:

`CRON_SECRET`

Keep this secret private.

## Worker schedules

- Distribution sync: every 5 minutes
- CRM functional worker: hourly
- CRM campaign worker: every 10 minutes
- Google reviews sync: every 15 minutes
- Review retention: daily at 02:30 UTC
- SEO automation worker: every 10 minutes
- SEO reports worker: hourly at minute 15

## Important

GitHub Actions scheduled workflows can be delayed by the platform. This is suitable for background workers that already process queued jobs, but it is not a hard real-time scheduler.

The application still requires these Vercel environment variables for the worker routes:

- `NEXT_PUBLIC_SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `CRON_SECRET`

Other provider-specific variables remain unchanged.

## Manual test

After pushing the workflow, open:

**GitHub → Actions → Anaira Workers → Run workflow**

The manual run executes all worker jobs once. This is useful for verifying `ANAIRA_APP_URL` and `CRON_SECRET` before waiting for the schedules.
