# STORE / ID — ADMIN RESTAURANT REFERENCE LAYOUT LOCK

## Ownership boundary

- `/store` remains the Super Admin / global Restaurant Marketplace store.
- `/store/[id]` is the individual restaurant's Admin-controlled customer-facing store.
- `/store-builder` is the Admin control panel for that restaurant's `/store/[id]`.
- Marketplace Settings remain global and do not control individual `/store/[id]` content.
- Restaurant SaaS / POS remains the operational source of truth for menu items, prices, variants, add-ons, availability and orders.

## `/store/[id]` locked layout

1. Header
2. Hero Slider
3. Highlight Strip
4. Popular Dishes
5. Menu Categories
6. About Us
7. Restaurant Gallery
8. Special Offer
9. Customer Reviews
10. Book a Table
11. Footer

The default visual baseline follows the supplied restaurant reference image: forest green, gold, cream and maroon palette; premium serif headings; full-width hero; dark category band; restaurant gallery; maroon offer section; dark reservation block; and green footer.

## Store Builder controls

The Admin Store Builder persists `store_page` inside the restaurant's `anaira_store_memberships.store_config` and controls:

- section visibility
- section ordering
- hero slides
- highlight cards
- about features
- gallery presentation
- offer presentation
- testimonials
- reservation copy
- footer copy
- reference labels/theme

Hero slides use `anaira_store_banners` scoped by both `restaurant_id` and `store_id`.

Popular dishes remain connected to real restaurant menu data and featured-item selection. The public page does not use Super Admin global banner rows for restaurant-specific content.

## Ordering

The reference page presents Popular Dishes and category entry points. Full menu opens as a customer drawer so the reference layout is preserved. Dish details support variants/add-ons and feed the existing Restaurant SaaS order API.

## Reservation

The Book a Table form submits through the existing restaurant reservation runtime (`anaira_create_restaurant_reservation_v2`).

## Isolation

Restaurant-specific queries are scoped to the current restaurant and Restaurant Store membership. Super Admin `/store` code is not changed by this implementation.
