# WORK 13 — ANAIRA Platform Super Admin Navigation & About Redirect

- Added **ANAIRA Platform** to the Super Admin Command Center sidebar, linking to the existing `/anaira/super-admin` control center.
- Changed the ANAIRA Hotels header **About ANAIRA** link to open `https://graphics.anairapos.in` in a new tab.
- Changed the Hotels footer About link to the same destination.
- Converted the legacy `/anaira/platform` route into a server-side redirect to `https://graphics.anairapos.in`, so old bookmarks and stale links also reach the company website.
- No database migration or environment variable is required.
