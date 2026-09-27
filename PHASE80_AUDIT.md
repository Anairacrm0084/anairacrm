# Phase 80 - Hotel Booking Live Records Connection Fix

The Booking Engine admin records are now backed by a live HMS-aware view. It joins booking transactions to HMS reservations, guest/customer data, room types, individual rooms, rate plans and latest payment submission. The generic create/delete UI is disabled for this transactional module. Server Supabase access is token-aware and uses the public publishable key fallback when a service-role key is absent. Pay-at-hotel remains payment-pending rather than being falsely marked paid.
