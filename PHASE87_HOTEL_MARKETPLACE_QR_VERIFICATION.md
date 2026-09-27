# Phase 87 — Hotel Marketplace QR + Customer Verification

## Admin + Super Admin
- Business Admin → My Hotel Store shows a direct hotel booking QR and shareable link.
- Super Admin → ANAIRA Store Control → Hotel Marketplace shows the QR for every listed hotel.
- QR opens `/book/{restaurant_id}` for that hotel.
- QR/link uses `NEXT_PUBLIC_SITE_URL` when configured; otherwise the current browser origin.

## Customer booking verification
- Customer must verify either phone OTP or email OTP before the booking transaction can start.
- The verified contact must match the phone/email entered on the booking.
- The booking is then created through the existing HMS-connected transactional booking engine.
- Supabase Auth SMS/email OTP provider/template configuration is required for the selected channel.

## Data model
- `anaira_store_memberships.marketplace_qr_enabled` defaults true.
- `anaira_store_memberships.marketplace_booking_verification` defaults `email_or_phone`.
