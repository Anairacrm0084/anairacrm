# Anaira Universal Business / Tenant / Login Architecture

## Core model
`auth.users` → `anaira_business_memberships` → `restaurants` (Business/Tenant) → `anaira_business_locations` (branches/locations) → vertical modules.

`profiles.restaurant_id` remains the active tenant pointer for backward compatibility with the existing platform and RLS model.

## Supported business verticals
Hotel/Resort, Restaurant/Cafe/Bakery, Salon, Barber Shop, Spa/Wellness, Clinic/Hospital, Dentist/Doctor, Pharmacy, Gym/Yoga, Retail/Grocery, Fashion, Jewellery, Electronics/Mobile, Automotive, Real Estate, Travel, Education/Coaching, Legal, CA/Accounting/Tax, IT/Software/Digital Agency, Repair/Maintenance, Cleaning, Pet/Veterinary, Photography, Events, Coworking, Logistics, Construction/Home Services, E-commerce, SaaS/Subscription, Creator/Personal Brand, Non-profit, Other Business.

## Login lifecycle
1. `/register` creates a Supabase Auth user.
2. If email confirmation is enabled, the user confirms email.
3. `/login` authenticates the user.
4. If no business profile exists, `/business-onboarding` is opened.
5. `anaira_create_universal_business()` creates the business, owner profile, membership and first location atomically.
6. Existing `profiles.restaurant_id` is set to the active business for backward compatibility.
7. Staff can be invited into the business and assigned a role/profile.

## Important distinction
A **business/tenant is not the same thing as a property/location**. Hospitality may have hotel/camp/cottage properties and room inventory. A barber, clinic, agency or retailer may have zero, one or many branches. The universal tenant layer handles both without forcing hospitality concepts onto non-hospitality businesses.
