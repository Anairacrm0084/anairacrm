# Anaira Daily Rate Calendar — Bulk Update

## Added
- `Bulk Update Rates` action on Hotel Management → Daily Rate Calendar.
- Date-range selection with a 366-date maximum.
- Apply to all active EP/CP/MAP/AP plans for the selected room type, or one selected rate plan.
- Single, double, triple, quad, extra-adult, and extra-child pricing.
- Optional Stop Sell for all selected dates.
- Confirmation prompt before overwriting existing daily overrides.
- Tenant-checked Supabase RPC with one bulk upsert per rate plan.

## Deployment
Apply `supabase/migrations/20261024_bulk_daily_rate_calendar.sql` to the connected Supabase project before using the new bulk action. Then restart/redeploy the Next.js app. The normal single-day editor remains available.

## Safety
The bulk operation is limited to 366 dates, rejects negative prices, requires an active rate plan belonging to the selected tenant, and overwrites only the chosen plan/date range. It does not create guessed prices or change dates outside the selected range.
