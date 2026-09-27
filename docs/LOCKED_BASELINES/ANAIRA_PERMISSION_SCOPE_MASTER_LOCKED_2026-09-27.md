### Sabse important rule ab lock karo

```
```

```
ANAIRA SUPER ADMIN
→ Platform-level settings
→ Marketplace settings
→ All businesses / all hotels / all restaurants
→ Plugin activation
→ Global integrations
→ Platform payments
→ Platform commissions
→ Global OTA / marketplace controls
→ System / security / audit
→ All tenants' operational data

BUSINESS ADMIN
→ Sirf apne business ki settings
→ Apne hotel/restaurant ka data
→ Apne staff/roles
→ Apne rates/menu/inventory
→ Apne booking/payment configuration
→ Apne marketplace/store configuration
```

**Super Admin ki setting Business Admin ko:**

-  sidebar mein nahi dikhni chahiye 
-  page direct URL se nahi khulni chahiye 
-  API se access nahi hona chahiye 
-  RLS se cross-tenant access nahi hona chahiye 

Sirf UI hide karna enough nahi hai.

---

# Maine current Operations ko is rule se map kiya

Current Super Admin Operations mein Hotel Booking, Hotel Marketplace, Booking Engine Control, Hotel Management, PMS, Restaurant Reservation, POS, Food Delivery, Restaurant Marketplace, Store Control, OTA, Hotel Setup aur Restaurant Setup listed hain. 

## 1. Hotel Booking

### Super Admin

```
```

```
ALL HOTELS
ALL BOOKINGS
ALL PAYMENTS
ALL CUSTOMERS
ALL PROPERTIES
```

### Business Admin

```
```

```
ONLY OWN HOTEL
ONLY OWN BOOKINGS
ONLY OWN GUESTS
ONLY OWN PAYMENTS
```

Current audit mein booking data Super Admin ko RLS ki wajah se hide ho raha tha. 

**Status: 🔴 Fix required**

---

# 2. Hotel Marketplace

Ye **platform-level module** hai.

### Super Admin ko:

```
```

```
Marketplace Dashboard
Businesses
Hotels
Restaurants
Listings
Approvals
Featured Listings
Marketplace Visibility
Commissions
Settlements
Marketplace Payments
Marketplace Policies
Marketplace Configuration
```

### Business Admin ko:

```
```

```
My Hotel Store
My Restaurant Store
Store Layout
My Listing
My Products/Rooms
My Store Settings
```

**Business Admin ko global Marketplace Settings nahi dikhni chahiye.**

Current hotel marketplace mein `booking_inventory` vs `hms_inventory` ka mismatch bhi identified hai. 

**Status: 🔴 Architecture + permission fix**

---

# 3. Booking Engine Control

Ye bahut important hai.

### Super Admin

```
```

```
Global Booking Engine Configuration
Platform Defaults
Payment Provider Configuration
Global Booking Rules
Marketplace Booking Rules
Global Notifications
Global Policies
```

### Business Admin

```
```

```
My Hotel
Room Catalog
Rate Plans
Availability
Booking Rules
Payment Options
Pay on Hotel
Pay on Scanner
Bank Details
QR
Booking Notifications
```

Lekin **Business Admin ko global Anaira Booking Engine settings nahi milni chahiye.**

Aur Booking Engine ko Room Type create nahi karna chahiye; HMS canonical master hai. 

**Status: 🟠 Needs strict setting separation**

---

# 4. Hotel Management

Ye **Business Admin ka operational module** hai.

### Business Admin:

```
```

```
Hotel Profile
Property Details
Rooms
Room Types
Rates
Inventory
Reservations
Housekeeping
Payments
Hotel Staff
Business Settings
```

### Super Admin:

```
```

```
All Hotels
Property Selector
Hotel Monitoring
Cross-tenant visibility
Platform-level controls
```

Super Admin ko kisi hotel ka data dekhne ke liye property selector chahiye.

Current audit mein Super Admin scope `profile.restaurant_id` par dependent mila tha. 

**Status: 🔴 Fix required**

---

# 5. PMS

Same rule.

### Super Admin

```
```

```
All Properties
Property A
Property B
Property C
All Arrivals
All In-House
All Departures
All Room Status
```

### Business Admin

```
```

```
Only Own Property
Only Own Guests
Only Own Rooms
Only Own Stays
```

Current audit mein PMS ke liye global Super Admin property scope missing tha. 

**Status: 🔴 Fix required**

---

# 6. Restaurant Reservation

### Super Admin

```
```

```
All Restaurants
All Reservations
All Tables
Global reservation configuration
```

### Business Admin

```
```

```
My Restaurant
My Tables
My Reservations
My Reservation Settings
```

Operational workflow generic CRUD nahi hona chahiye; reservation lifecycle actual workflow hona chahiye. 

**Status: 🟠 Workflow + scope audit**

---

# 7. Anaira POS

Ye especially important hai.

### Super Admin

```
```

```
All Businesses
All POS
All Orders
All KOT
All Payments
All Terminals
All POS Integrations
Platform POS Settings
```

### Business Admin

```
```

```
My POS
My Menu
My Tables
My Orders
My KOT
My Payments
My Printers
My Terminals
My POS Settings
```

Super Admin ki POS global configuration Business Admin ko nahi milni chahiye.

Current audit mein POS ko `anaira_marketplace_orders` ke generic data source se connect kiya gaya tha, jo canonical POS architecture ke liye wrong hai. 

**Status: 🔴 Fix required**

---

# 8. Food Delivery

### Super Admin

```
```

```
All Delivery Orders
All Restaurants
All Riders
All Zones
All Delivery Settings
Platform Delivery Configuration
Commission
Settlement
```

### Business Admin

```
```

```
Own Orders
Own Riders
Own Delivery Zones
Own Delivery Settings
```

Current page generic `delivery_orders` runtime par hai, proper delivery state machine nahi. 

**Status: 🔴 Fix required**

---

# 9. Restaurant Marketplace

### Super Admin

```
```

```
Marketplace
All Restaurants
Approvals
Listings
Categories
Commission
Settlement
Marketplace Settings
Marketplace Payments
```

### Business Admin

```
```

```
My Restaurant Store
My Menu
My Categories
My Prices
My Store Design
My Store Settings
```

Current listing connection hai, lekin live POS menu bridge missing hai. 

**Status: 🔴 Fix required**

---

# 10. Platform Store Control

Ye **100% Super Admin side** ka module hona chahiye.

```
```

```
Super Admin
└── Platform Store Control
    ├── All Hotel Stores
    ├── All Restaurant Stores
    ├── Approve
    ├── Suspend
    ├── Publish
    ├── Unpublish
    ├── Featured
    ├── Marketplace Visibility
    ├── Store Health
    └── Store Readiness
```

Business Admin ko **Platform Store Control** naam ka menu hi nahi milna chahiye.

Business Admin ko sirf:

```
```

```
My Hotel Store
My Restaurant Store
```

milna chahiye.

Current Store Control listing data se connected hai, lekin store readiness/health layer incomplete hai. 

**Status: 🟠 Needs separation**

---

# 11. OTA / Channel Manager

### Super Admin

```
```

```
Global OTA Configuration
Providers
Credentials / Connection Management
Channel Health
All Properties
All Mappings
Sync Logs
Global Sync
```

### Business Admin

```
```

```
My Property
My OTA Connections
My Room Mapping
My Rate Mapping
My Sync Logs
```

**Important:** Business Admin ko doosre hotel ka OTA connection/data kabhi nahi dikhna chahiye.

Current audit mein OTA foundation present hai but actual adapters/sync runtime incomplete hai. 

**Status: 🔴 Foundation only**

---

# 12. Hotel Setup

Ye Business Admin ke liye:

```
```

```
Hotel Profile
Property Details
Policies
Contact
Tax
Booking settings
```

Super Admin ke liye:

```
```

```
All Hotels
View
Monitor
Platform-level control
```

**Super Admin ki platform settings yahan Business Admin ko leak nahi honi chahiye.**

Current audit confirms `hms_settings` canonical Hotel Management source hai. 

---

# 13. Restaurant Setup

Business Admin:

```
```

```
Restaurant Profile
Legal
GST
Address
Timings
Logo
Gallery
Delivery
Pickup
Dine-in
Reservation
Food Ordering
Tables
```

Super Admin:

```
```

```
All Restaurants
View
Monitor
Platform controls
```

Current setup is connected to restaurant master data and includes these business-level configuration areas. 

---

# Ab main sab software ke liye ek MASTER permission model rakhunga

```
```

```
                    ANAIRA
                       │
             ┌─────────┴─────────┐
             │                   │
       SUPER ADMIN          BUSINESS ADMIN
             │                   │
      PLATFORM SCOPE        TENANT SCOPE
             │                   │
      ┌──────┴──────┐       ┌────┴─────┐
      │             │       │          │
   GLOBAL         ALL     OWN DATA   OWN SETTINGS
   SETTINGS      TENANTS
```

### Super Admin-only

```
```

```
Platform Settings
Marketplace Settings
Plugin Control
Global Payment Settings
Global Commission
Global OTA
Global Notification Providers
Global AI Settings
Global SEO Platform
Global Security
Global Feature Flags
Tenant Management
Platform Audit
System Health
```

### Business Admin-only

```
```

```
Hotel Profile
Restaurant Profile
Room Types
Rooms
Rates
Inventory
Booking Settings
POS Settings
Menu
Restaurant Settings
Staff
Business Roles
Business Payments
Business Notifications
Store Design
Own Integrations
```

### Staff

```
```

```
ONLY ASSIGNED OPERATIONS
```

---

## Aur sabse important: sirf menu hide nahi karenge

Har software ke liye 5-layer check hoga:

```
```

```
1. Sidebar
   ↓
2. Route Guard
   ↓
3. Page authorization
   ↓
4. API/RPC authorization
   ↓
5. Supabase RLS
```

Example:

```
```

```
Business Admin
       ↓
/super-admin/marketplace-settings
       ↓
❌ Route denied

Direct API
       ↓
❌ Authorization denied

Supabase
       ↓
❌ RLS denied
```

Aur:

```
```

```
Super Admin
       ↓
/super-admin/marketplace-settings
       ↓
✅
```

---

## Current audit ka consolidated result

| Software               | Super Admin scope   | Business Admin scope | Current issue     |
| ---------------------- | ------------------- | -------------------- | ----------------- |
| Hotel Booking          | All hotels          | Own hotel            | 🔴 RLS            |
| Hotel Marketplace      | All marketplace     | Own store            | 🔴 Data model     |
| Booking Engine         | Global              | Own hotel            | 🟠 Separation     |
| Hotel Management       | All properties      | Own property         | 🔴 Scope          |
| PMS                    | All properties      | Own property         | 🔴 Scope          |
| Restaurant Reservation | All restaurants     | Own restaurant       | 🟠 Workflow       |
| POS                    | All POS             | Own POS              | 🔴 Data ownership |
| Food Delivery          | All delivery        | Own delivery         | 🔴 Workflow       |
| Restaurant Marketplace | All restaurants     | Own store            | 🔴 Menu bridge    |
| Platform Store Control | Platform only       | ❌                    | 🟠 Readiness      |
| OTA Manager            | All channels        | Own channels         | 🔴 Runtime        |
| Hotel Setup            | Platform visibility | Own settings         | 🟠 Scope          |
| Restaurant Setup       | Platform visibility | Own settings         | 🟢 Foundation     |

Ye separation **har software/module par same standard se apply hona chahiye**. Current audit mein jo modules Super Admin scope ya duplicate data source ki wajah se problematic mile hain, unko sirf UI change karke complete nahi maana jayega. 

**Next implementation baseline:** `Super Admin = platform/all-tenant control`, `Business Admin = own-tenant control`, `Staff = assigned operations`; aur Super Admin-only settings Business Admin ke sidebar, routes, APIs aur RLS — chaaro jagah inaccessible rahengi.