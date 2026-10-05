# Anaira Graphics — Featured Scroll + Hydration Fix

Date: 2026-10-06

## Applied

1. Added tenant-scoped `featuredImages` to Anaira Graphics landing settings.
2. Added Settings UI to upload multiple Featured Work images, edit title/alt text, and remove images.
3. Added a continuously scrolling Featured Work image strip directly below the Focus Visual section.
4. If no custom Featured Work images exist, the landing falls back to existing portfolio images so the section remains populated.
5. Featured image settings are persisted inside the existing tenant-scoped `anaira_it_agency_portfolio` site-settings row; no new table is required.
6. Removed deleted featured-image storage objects when saved settings remove them.
7. Fixed React/Next hydration mismatch in the JSON-LD schema caused by reading `window.location.origin` during client hydration. The schema now uses deterministic `NEXT_PUBLIC_SITE_URL` or stable relative URLs.
8. Fixed empty `src=""` on Focus Visual images. A placeholder is rendered when a focus image is missing instead of emitting an empty image source.
9. Existing Focus Visual upload controls remain intact.

## Scope

Only the Anaira Graphics tenant landing/settings flow is changed. The universal/Sachkhand IT Agency landing flow remains separate.
