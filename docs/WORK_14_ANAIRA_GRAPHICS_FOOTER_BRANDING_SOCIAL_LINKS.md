# WORK 14 — ANAIRA Graphics Footer Branding & Social Links

- Added Super Admin controls under Hotel Marketplace Settings → SEO & Footer for ANAIRA Graphics Facebook, Instagram and LinkedIn URLs.
- Added editable ANAIRA Graphics contact phone numbers with defaults `9736500084` and `9736580084`.
- Updated the global `/anaira/hotels` footer to show the configured social icons as external links and the two phone numbers as `tel:` links.
- Instagram defaults to `https://instagram.com/anairagraphics`; Facebook and LinkedIn are left blank until the official URLs are entered by Super Admin.
- Settings use the existing `anaira_platform_settings` key/value store; no database migration is required.
- The settings page saves these values through its existing Save All Marketplace Settings action.
