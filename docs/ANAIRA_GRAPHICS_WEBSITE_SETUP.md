# Anaira Graphics — Public Website / SEO Production Setup

The V18 build now includes a dedicated public landing page at:

`/anaira-graphics`

## Included

- Premium responsive Anaira Graphics landing page using the supplied Anaira logo.
- SEO metadata: title, description, keywords, canonical path, Open Graph and Twitter metadata.
- Local business / professional-service JSON-LD with Kullu, Himachal Pradesh address and service catalog.
- Services covering graphic design, posters/banners, social media, website development, SEO, software/app development, digital printing and signage.
- Public enquiry form.
- Public enquiry API that creates/updates a CRM customer, creates a `crm_leads` record and attempts to write the CRM timeline event.
- No fake Google ratings, fake review counts or fake testimonials are embedded.

## CRM tenant binding

Create a dedicated business tenant named:

`Anaira Graphics & Digital Solution`

Do not reuse the Super Admin identity as the business tenant. The website should operate as the business tenant while Super Admin remains the platform owner.

Set the server-side environment variable:

`ANAIRA_GRAPHICS_BUSINESS_ID=<dedicated Anaira Graphics restaurant/business UUID>`

The lead API will use this ID first. As a fallback it searches for the exact business name plus the known business email `anairagraphicsdigitalsolution@gmail.com`.

Never expose `ANAIRA_GRAPHICS_BUSINESS_ID` as a `NEXT_PUBLIC_*` variable.

## Google production setup

1. Connect the actual production domain to this page.
2. In Anaira SEO, create the website property for that production domain.
3. Complete DNS verification.
4. Connect Google Search Console using the Google account that owns/manages the website property.
5. Submit the production sitemap.
6. Connect GA4.
7. Connect Google Business Profile using the business admin's Google OAuth identity.
8. Run the SEO crawl and resolve real technical issues.
9. Sync Search Console and GA4 data into Anaira.
10. Enable AI Review CRM only after the Google Business Profile OAuth/API connection is configured.

## Important

The public website itself does not create Google credentials or claim a Google Business Profile. Google OAuth, Search Console property access, GA4 property access and Business Profile API access must be configured with the appropriate Google Cloud project and production redirect URIs.
