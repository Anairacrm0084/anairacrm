# Anaira SEO — A-to-Z Real Setup

## 1. Add a domain

SEO Command Center → Add Your Website → enter `https://example.com` → Add Domain.

Anaira creates a tenant-scoped SEO property and gives a unique DNS TXT verification token.

Create a TXT record on the exact hostname shown by the UI:

`anaira-seo-verification=<token>`

Then click Verify Domain.

Verification is real DNS TXT verification. No demo/fake verification is used.

## 2. Run the first audit

After adding the site:

1. Run Full Crawl.
2. Anaira respects robots.txt by default.
3. It starts from the home page and sitemap URLs.
4. It stores pages, titles, descriptions, canonicals, robots, H1, JSON-LD, images and internal links.
5. It creates technical SEO issues and an audit score.
6. SEO score history is stored for trend reporting.

For JavaScript-rendered websites set Browserless credentials and enable browser rendering.

## 3. Google Search Console

1. SEO → GSC → Connect Search Console.
2. Sign in with the Google account that has access to the Search Console property.
3. Discover Properties.
4. Select the correct property.
5. Use Property.
6. Sync Search Analytics.
7. Inspect individual URLs when needed.
8. Submit the site's sitemap to Google.

Required environment variables:

`GOOGLE_CLIENT_ID`
`GOOGLE_CLIENT_SECRET`
`ANAIRA_SECRET_KEY`

The GSC OAuth flow uses the `webmasters` scope because sitemap submission and Search Console management need more than read-only analytics access.

## 4. GA4

1. SEO → GA4 → Connect GA4.
2. Discover Properties.
3. Select the GA4 property.
4. Use Property.
5. Sync GA4.

The system stores date, channel, landing page, sessions, users and conversions.

## 5. Keywords

SEO → Keywords → enter a seed such as:

`hotel in Kullu`

Click Research & Save.

DataForSEO is required for live keyword data. If credentials are absent, the API returns a configuration error rather than fake volume.

Required:

`DATAFORSEO_LOGIN`
`DATAFORSEO_PASSWORD`

## 6. Rankings

SEO → Rankings → Sync Rankings.

SerpAPI is used for live Google SERP collection.

Required:

`SERPAPI_KEY`

The result stores position, URL and SERP features in rank history.

## 7. Technical SEO

The crawler checks:

- title
- meta description
- H1
- canonical
- robots/noindex
- image ALT
- Open Graph
- hreflang
- JSON-LD validity
- internal links
- crawl status

## 8. PageSpeed

SEO → PageSpeed.

Set:

`PAGESPEED_API_KEY`

Anaira stores performance, accessibility, best practices, SEO and Core Web Vitals-related measurements.

## 9. AI content

SEO → Content → enter target keyword/topic → Generate Real AI Draft.

OpenAI creates the draft. The workflow is:

Draft → Human Approval → Publish.

Required:

`OPENAI_API_KEY`
`OPENAI_MODEL` (optional; defaults to configured production model)

Publishing can use WordPress or the configured content webhook.

## 10. Internal links

Rules mode creates deterministic keyword-context suggestions.

AI mode uses OpenAI to improve semantic source/target matching and anchor text.

No fake AI response is generated when the provider is unavailable.

## 11. Schema

Generate → validate → approve → publish.

Supported schema families include Organization, LocalBusiness, Hotel, Restaurant, Product, Service, Article, FAQPage, BreadcrumbList, Event, Review and WebPage.

WordPress publishing requires the configured WordPress connector.

## 12. Sitemap and robots

The SEO property stores the canonical sitemap and robots URLs.

Sitemap can be submitted to Google after Search Console is connected.

For a standalone website, the generated policy must ultimately be published at the website's own `/sitemap.xml` and `/robots.txt`. Anaira does not pretend that storing a record inside CRM automatically changes a third-party website.

## 13. Competitors

Enter a competitor domain and run live collection. SerpAPI is required.

## 14. Automation

Each SEO site has its own jobs:

- crawl
- GSC sync
- GA4 sync
- rank sync
- PageSpeed
- competitor sync

Jobs are tenant/site scoped. The SEO worker executes due jobs every 15 minutes. Provider jobs fail explicitly when credentials or provider access is missing.

## 15. Production environment

Required for a complete provider-backed deployment:

- Supabase URL + publishable/anon key
- Supabase service role key on server only
- CRON_SECRET
- ANAiRA_SECRET_KEY
- Google OAuth credentials
- PageSpeed API key
- DataForSEO credentials
- SerpAPI key
- OpenAI key
- optional Browserless key
- optional WordPress publishing credentials

Never expose service-role, Google client secret, provider passwords or API keys to browser/client code.
