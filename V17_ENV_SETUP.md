# Anaira V17 Environment Setup

Create `.env.local` in the project root before running the server.

```env
NEXT_PUBLIC_SUPABASE_URL=https://bhptqdoteucuymmdzsmg.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<your publishable/anon key>
SUPABASE_SERVICE_ROLE_KEY=<your server-only service role key>
```

Never commit `.env.local` or expose `SUPABASE_SERVICE_ROLE_KEY` to browser code.
The V17 ZIP intentionally does not contain live credentials.

The Salon storefront API was patched to:
- avoid querying the non-existent `restaurants.logo_url` column;
- use the live `anaira_salon_*` domain tables;
- normalize domain records for the Salon landing UI.
