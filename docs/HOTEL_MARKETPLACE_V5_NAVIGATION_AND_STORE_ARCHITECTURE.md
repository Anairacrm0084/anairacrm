# Hotel Marketplace V5 — Navigation & Store Architecture

## Public customer store
`/anaira/hotels` is a standalone full-width hotel marketplace. It does not render the admin/customer platform shell header. It is hotel-only and uses the canonical `anaira_marketplace_hotel_search` availability RPC.

## Super Admin
The `ANAIRA STORES` sidebar group is platform control:
- ANAIRA Store & QR -> `/super-admin/anaira-store`
- Hotel Marketplace Store -> `/anaira/hotels`
- Hotel Marketplace Settings -> `/super-admin/hotel-marketplace-settings`
- Restaurant Marketplace Store -> `/store`
- Restaurant Marketplace Settings -> `/super-admin/marketplace-settings`

The old `ANAIRA CUSTOMER PLATFORM` group has been removed from admin sidebars.

## QR
The two global store QR cards are on `/super-admin/anaira-store`:
- ANAIRA Hotels -> `/anaira/hotels`
- ANAIRA Restaurants -> `/store`

## Scope
The Hotel Marketplace only queries published hotel availability and does not use restaurant marketplace catalog data.
