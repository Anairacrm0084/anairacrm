# Anaira Universal SEO System — Multi-Business / Multi-Platform

The SEO system is intentionally vertical-neutral. Hospitality is one vertical, not the platform boundary.

## Business verticals
Hotel, Restaurant, Cafe/Bakery, Bar/Lounge, Salon, Barber Shop, Spa/Wellness, Clinic/Hospital, Dentist, Doctor/Medical Professional, Pharmacy, Gym/Fitness, Yoga, Retail, Grocery, Fashion, Jewellery, Electronics/Mobile, Automotive, Real Estate, Travel Agency/Tour Operator, Education/Coaching, Legal, Accounting/CA/Tax, IT/Software/Digital Agency, Professional Services, Repair/Maintenance, Cleaning, Pet/Veterinary, Photography, Events/Entertainment, Coworking, Logistics/Delivery, Construction/Home Services, Local Service, Ecommerce, SaaS, Creator/Personal Brand, Non-profit/Organization, School/College/Institute, Other.

## Website/platform types
Custom Website, Next.js, WordPress, WooCommerce, Shopify, Wix, Webflow, Squarespace, Magento, PrestaShop, Static HTML, Mobile App/App Store Landing, Marketplace/Multi-vendor, Other.

## Common SEO engine
Technical crawl, indexability, robots, sitemap, canonical, structured data, keywords, SERP/rank tracking, competitor intelligence, backlinks, content briefs/optimization, internal links, local SEO, GEO/AI visibility, GSC, GA4, attribution, PageSpeed, remediation, automation, reporting and certification.

## Vertical-aware behavior
The engine stores business_vertical, platform_type and seo_profile. This lets schema/entity selection, local-service goals, ecommerce goals, booking/appointment goals, content strategy and AI visibility be configured without hard-coding hotel/restaurant assumptions into the SEO runtime.

## Migration
Run `supabase/migrations/20261004_seo_universal_business_platform.sql` before using the new business/platform profile fields in an existing deployment.
