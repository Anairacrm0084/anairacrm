export const pluginRegistry = {
  "plugins": {
    "crm": {
      "key": "crm",
      "name": "Anaira CRM",
      "route": "/crm",
      "category": "Customer",
      "description": "Customer 360, guest history, loyalty, campaigns and relationship intelligence.",
      "owner": "crm",
      "dataTable": "crm_customers",
      "fields": [
        "full_name",
        "customer_type",
        "total_hotel_revenue",
        "total_restaurant_revenue",
        "total_stays",
        "updated_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "duplicate_detection",
          "label": "Duplicate Detection",
          "type": "boolean",
          "default": true
        },
        {
          "key": "customer_timeline",
          "label": "Customer Timeline",
          "type": "boolean",
          "default": true
        },
        {
          "key": "auto_tagging",
          "label": "Automatic Customer Tags",
          "type": "boolean",
          "default": true
        },
        {
          "key": "lead_scoring",
          "label": "Lead Scoring",
          "type": "boolean",
          "default": true
        },
        {
          "key": "ltv_refresh_hours",
          "label": "LTV Refresh Hours",
          "type": "number",
          "default": 24
        }
      ],
      "permissions": [
        "crm.view",
        "crm.manage",
        "crm.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "crm.changed"
        ],
        "subscribes": []
      }
    },
    "hotel-booking": {
      "key": "hotel-booking",
      "name": "Anaira Booking Engine",
      "route": "/booking-engine",
      "category": "Hotel",
      "description": "Direct booking, availability, rate plans, add-ons, payments and confirmations.",
      "owner": "hotel-booking",
      "dataTable": "anaira_hotel_booking_admin_records",
      "fields": [
        "id","tenant_id","hms_reservation_id","customer_id","state","amount","currency","created_at","updated_at",
        "reservation_code","booking_reference","reservation_status","guest_name","guest_phone","guest_email",
        "room_type_name","room_number","rate_plan_name","rate_plan_code","check_in","check_out","adults","children",
        "nightly_rate","total_amount","deposit_amount","paid_amount","balance_amount","payment_status","payment_method",
        "payment_reference","payment_proof_url","payment_submission_status","payment_submission_reference",
        "payment_submission_proof_url","payment_submitted_at","payment_verified_at","booking_source"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "direct_booking",
          "label": "Direct Booking",
          "type": "boolean",
          "default": true
        },
        {
          "key": "payment_required",
          "label": "Payment Required",
          "type": "boolean",
          "default": true
        },
        {
          "key": "confirmation_required",
          "label": "Booking Confirmation Required",
          "type": "boolean",
          "default": true
        },
        {
          "key": "cancellation_window_hours",
          "label": "Cancellation Window Hours",
          "type": "number",
          "default": 24
        },
        {
          "key": "inventory_hold_minutes",
          "label": "Inventory Hold Minutes",
          "type": "number",
          "default": 15
        },
        {
          "key": "prearrival_automation",
          "label": "Pre-arrival Automation",
          "type": "boolean",
          "default": true
        },
        {
          "key": "tax_enabled",
          "label": "Tax Calculation",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "hotel-booking.view",
        "hotel-booking.manage",
        "hotel-booking.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "hotel-booking.changed"
        ],
        "subscribes": []
      }
    },
    "hotel-management-suite": {
      "key": "hotel-management-suite",
      "name": "Anaira Hotel Management System",
      "route": "/hotel-management",
      "category": "Hotel",
      "description": "Front desk, rooms, reservations, stays, housekeeping, rates, inventory and folios.",
      "owner": "hotel-management-suite",
      "dataTable": "hms_rooms",
      "fields": [
        "room_number",
        "room_type_id",
        "status",
        "housekeeping_status",
        "updated_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "front_desk",
          "label": "Front Desk",
          "type": "boolean",
          "default": true
        },
        {
          "key": "housekeeping",
          "label": "Housekeeping",
          "type": "boolean",
          "default": true
        },
        {
          "key": "folios",
          "label": "Folios",
          "type": "boolean",
          "default": true
        },
        {
          "key": "inventory",
          "label": "Inventory",
          "type": "boolean",
          "default": true
        },
        {
          "key": "night_audit",
          "label": "Night Audit",
          "type": "boolean",
          "default": true
        },
        {
          "key": "maintenance",
          "label": "Maintenance",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "hotel-management-suite.view",
        "hotel-management-suite.manage",
        "hotel-management-suite.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "hotel-management-suite.changed"
        ],
        "subscribes": []
      }
    },
    "hotel-pms": {
      "key": "hotel-pms",
      "name": "Hotel PMS",
      "route": "/pms",
      "category": "Hotel",
      "description": "Reservations, room inventory, front desk and housekeeping.",
      "owner": "hotel-pms",
      "dataTable": "hms_rooms",
      "fields": [
        "room_number",
        "room_type_id",
        "status",
        "housekeeping_status",
        "updated_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "front_desk",
          "label": "Front Desk",
          "type": "boolean",
          "default": true
        },
        {
          "key": "housekeeping",
          "label": "Housekeeping",
          "type": "boolean",
          "default": true
        },
        {
          "key": "auto_room_status",
          "label": "Automatic Room Status",
          "type": "boolean",
          "default": true
        },
        {
          "key": "overbooking_guard",
          "label": "Overbooking Guard",
          "type": "boolean",
          "default": true
        },
        {
          "key": "folio_management",
          "label": "Folio Management",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "hotel-pms.view",
        "hotel-pms.manage",
        "hotel-pms.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "hotel-pms.changed"
        ],
        "subscribes": []
      }
    },
    "restaurant-reservation": {
      "key": "restaurant-reservation",
      "name": "Restaurant Reservation",
      "route": "/reservation",
      "category": "Restaurant",
      "description": "Table inventory, reservations and waitlist.",
      "owner": "restaurant-reservation",
      "dataTable": "restaurant_reservations",
      "fields": [
        "guest_name",
        "reservation_date",
        "reservation_time",
        "party_size",
        "status"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "online_reservations",
          "label": "Online Reservations",
          "type": "boolean",
          "default": true
        },
        {
          "key": "waitlist",
          "label": "Waitlist",
          "type": "boolean",
          "default": true
        },
        {
          "key": "auto_assignment",
          "label": "Automatic Table Assignment",
          "type": "boolean",
          "default": false
        },
        {
          "key": "default_slot_minutes",
          "label": "Default Slot Minutes",
          "type": "number",
          "default": 30
        },
        {
          "key": "no_show_policy",
          "label": "No-show Policy",
          "type": "text",
          "default": "manager_review"
        }
      ],
      "permissions": [
        "restaurant-reservation.view",
        "restaurant-reservation.manage",
        "restaurant-reservation.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "restaurant-reservation.changed"
        ],
        "subscribes": []
      }
    },
    "food-delivery": {
      "key": "food-delivery",
      "name": "Food Delivery Marketplace",
      "route": "/delivery",
      "category": "Commerce",
      "description": "Customer ordering and delivery operations.",
      "owner": "food-delivery",
      "dataTable": "delivery_orders",
      "fields": [
        "order_code",
        "restaurant_id",
        "customer_name",
        "status",
        "total_amount"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "online_orders",
          "label": "Online Orders",
          "type": "boolean",
          "default": true
        },
        {
          "key": "cod",
          "label": "Cash On Delivery",
          "type": "boolean",
          "default": true
        },
        {
          "key": "auto_accept",
          "label": "Auto Accept Orders",
          "type": "boolean",
          "default": false
        },
        {
          "key": "delivery_radius_km",
          "label": "Delivery Radius KM",
          "type": "number",
          "default": 10
        },
        {
          "key": "minimum_order",
          "label": "Minimum Order",
          "type": "number",
          "default": 0
        },
        {
          "key": "dispatch_mode",
          "label": "Dispatch Mode",
          "type": "text",
          "default": "manual"
        }
      ],
      "permissions": [
        "food-delivery.view",
        "food-delivery.manage",
        "food-delivery.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "food-delivery.changed"
        ],
        "subscribes": []
      }
    },
    "restaurant-store": {
      "key": "restaurant-store",
      "name": "Restaurant Store Builder",
      "route": "/restaurant-stores",
      "category": "Commerce",
      "description": "Branded restaurant storefronts.",
      "owner": "restaurant-store",
      "dataTable": "restaurant_storefronts",
      "fields": [
        "restaurant_id",
        "slug",
        "store_name",
        "status",
        "published"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "published",
          "label": "Store Published",
          "type": "boolean",
          "default": false
        },
        {
          "key": "online_ordering",
          "label": "Online Ordering",
          "type": "boolean",
          "default": true
        },
        {
          "key": "custom_domain",
          "label": "Custom Domain",
          "type": "boolean",
          "default": false
        },
        {
          "key": "show_reviews",
          "label": "Show Reviews",
          "type": "boolean",
          "default": true
        },
        {
          "key": "tax_enabled",
          "label": "Tax Calculation",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "restaurant-store.view",
        "restaurant-store.manage",
        "restaurant-store.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "restaurant-store.changed"
        ],
        "subscribes": []
      }
    },
    "anaira-pos": {
      "key": "anaira-pos",
      "name": "Anaira POS",
      "route": "/pos",
      "category": "Operations",
      "description": "Restaurant billing, KOT, KDS, menu and payments.",
      "owner": "anaira-pos",
      "dataTable": "anaira_marketplace_orders",
      "fields": [
        "order_code",
        "order_type",
        "status",
        "total",
        "pos_order_id"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "kot_enabled",
          "label": "KOT Bridge",
          "type": "boolean",
          "default": true
        },
        {
          "key": "kds_enabled",
          "label": "KDS Bridge",
          "type": "boolean",
          "default": true
        },
        {
          "key": "thermal_printing",
          "label": "Thermal Printing Bridge",
          "type": "boolean",
          "default": true
        },
        {
          "key": "customer_sync",
          "label": "Customer Sync",
          "type": "boolean",
          "default": true
        },
        {
          "key": "delivery_sync",
          "label": "Delivery Sync",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "anaira-pos.view",
        "anaira-pos.manage",
        "anaira-pos.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "anaira-pos.changed"
        ],
        "subscribes": []
      }
    },
    "channel-manager": {
      "key": "channel-manager",
      "name": "Channel / OTA Manager",
      "route": "/channel-manager",
      "category": "Distribution",
      "description": "OTA inventory, rates and reservations.",
      "owner": "channel-manager",
      "dataTable": "ota_channels",
      "fields": [
        "name",
        "provider",
        "status",
        "last_sync_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "rate_sync",
          "label": "Rate Sync",
          "type": "boolean",
          "default": true
        },
        {
          "key": "inventory_sync",
          "label": "Inventory Sync",
          "type": "boolean",
          "default": true
        },
        {
          "key": "reservation_sync",
          "label": "Reservation Sync",
          "type": "boolean",
          "default": true
        },
        {
          "key": "parity_alerts",
          "label": "Parity Alerts",
          "type": "boolean",
          "default": true
        },
        {
          "key": "sync_interval_minutes",
          "label": "Sync Interval Minutes",
          "type": "number",
          "default": 15
        },
        {
          "key": "conflict_strategy",
          "label": "Conflict Strategy",
          "type": "text",
          "default": "latest_valid"
        }
      ],
      "permissions": [
        "channel-manager.view",
        "channel-manager.manage",
        "channel-manager.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "channel-manager.changed"
        ],
        "subscribes": []
      }
    },
    "marketplace": {
      "key": "marketplace",
      "name": "Anaira Marketplace",
      "route": "/marketplace",
      "category": "Commerce",
      "description": "First-party marketplace orchestration for hotel and restaurant discovery, booking and ordering surfaces.",
      "owner": "marketplace",
      "dataTable": "anaira_platform_stores",
      "fields": ["store_type","store_name","enabled","published","settings","updated_at"],
      "settingsSchema": [
        {"key":"hotel_marketplace_enabled","label":"Hotel Marketplace Enabled","type":"boolean","default":true},
        {"key":"restaurant_marketplace_enabled","label":"Restaurant Marketplace Enabled","type":"boolean","default":true},
        {"key":"booking_engine_bridge","label":"Booking Engine Bridge","type":"boolean","default":true},
        {"key":"restaurant_pos_bridge","label":"Restaurant POS Bridge","type":"boolean","default":true},
        {"key":"customer_event_bridge","label":"Customer / CRM Event Bridge","type":"boolean","default":true}
      ],
      "permissions": ["marketplace.view","marketplace.manage","marketplace.configure"],
      "dependencies": ["hotel-booking","anaira-pos","restaurant-store","food-delivery","restaurant-reservation"],
      "events": {"publishes":["marketplace.changed"],"subscribes":["hotel-booking.changed","anaira-pos.changed"]}
    },
    "seo-system": {
      "key": "seo-system",
      "name": "Anaira SEO System",
      "route": "/seo",
      "category": "CRM / Marketing",
      "description": "Technical SEO, crawler, keywords, rankings, integrations, AI content and analytics.",
      "owner": "seo-system",
      "dataTable": "crm_seo_sites",
      "fields": [
        "domain",
        "created_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sitemap_enabled",
          "label": "Sitemap",
          "type": "boolean",
          "default": true
        },
        {
          "key": "robots_enabled",
          "label": "Robots",
          "type": "boolean",
          "default": true
        },
        {
          "key": "respect_robots",
          "label": "Respect Robots",
          "type": "boolean",
          "default": true
        },
        {
          "key": "scheduled_crawl",
          "label": "Scheduled Crawl",
          "type": "boolean",
          "default": true
        },
        {
          "key": "crawl_max_pages",
          "label": "Max Crawl Pages",
          "type": "number",
          "default": 500
        },
        {
          "key": "browser_rendering",
          "label": "Browser Rendering",
          "type": "boolean",
          "default": false
        },
        {
          "key": "gsc_enabled",
          "label": "Search Console",
          "type": "boolean",
          "default": false
        },
        {
          "key": "ga4_enabled",
          "label": "GA4",
          "type": "boolean",
          "default": false
        },
        {
          "key": "rank_tracking_enabled",
          "label": "Rank Tracking",
          "type": "boolean",
          "default": true
        },
        {
          "key": "ai_content_enabled",
          "label": "AI Content",
          "type": "boolean",
          "default": true
        },
        {
          "key": "internal_links_enabled",
          "label": "Internal Links",
          "type": "boolean",
          "default": true
        },
        {
          "key": "schema_enabled",
          "label": "Schema",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "seo-system.view",
        "seo-system.manage",
        "seo-system.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "seo-system.changed"
        ],
        "subscribes": []
      }
    },
    "ai-review-system": {
      "key": "ai-review-system",
      "name": "Anaira AI Review Automation",
      "route": "/ai-reviews",
      "category": "CRM / Reputation",
      "description": "Review ingestion, AI replies, requests, recovery and reputation analytics.",
      "owner": "ai-review-system",
      "dataTable": "crm_reviews",
      "fields": [
        "source",
        "author_name",
        "rating",
        "sentiment",
        "status",
        "reviewed_at"
      ],
      "settingsSchema": [
        {
          "key": "business_vertical",
          "label": "Business Vertical",
          "type": "select",
          "default": "other",
          "options": [
            "hotel", "restaurant", "cafe", "bakery", "bar", "catering", "salon", "barber", "spa",
            "clinic", "dentist", "doctor", "hospital", "pharmacy", "gym", "yoga", "retail", "grocery",
            "fashion", "jewellery", "electronics", "furniture", "automotive", "auto_service", "real_estate",
            "travel", "education", "coaching", "legal", "accounting", "agency", "professional_services",
            "contractor", "home_services", "pet_services", "photography", "events", "entertainment", "coworking",
            "repair", "cleaning", "logistics", "other"
          ]
        },
        {
          "key": "review_request_label",
          "label": "Review Request Label",
          "type": "text",
          "default": "Customer Review Request"
        },
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "google_sync",
          "label": "Google Review Sync",
          "type": "boolean",
          "default": true
        },
        {
          "key": "review_requests",
          "label": "Review Requests",
          "type": "boolean",
          "default": true
        },
        {
          "key": "ai_classification",
          "label": "AI Classification",
          "type": "boolean",
          "default": true
        },
        {
          "key": "ai_reply_drafts",
          "label": "AI Reply Drafts",
          "type": "boolean",
          "default": true
        },
        {
          "key": "human_approval",
          "label": "Human Approval",
          "type": "boolean",
          "default": true
        },
        {
          "key": "auto_publish",
          "label": "Auto Publish",
          "type": "boolean",
          "default": false
        },
        {
          "key": "service_recovery",
          "label": "Service Recovery",
          "type": "boolean",
          "default": true
        },
        {
          "key": "sla_enabled",
          "label": "SLA",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_enabled",
          "label": "WhatsApp",
          "type": "boolean",
          "default": true
        },
        {
          "key": "sms_enabled",
          "label": "SMS",
          "type": "boolean",
          "default": true
        },
        {
          "key": "email_enabled",
          "label": "Email",
          "type": "boolean",
          "default": true
        },
        {
          "key": "request_delay_hours",
          "label": "Request Delay Hours",
          "type": "number",
          "default": 24
        }
      ],
      "permissions": [
        "ai-review-system.view",
        "ai-review-system.manage",
        "ai-review-system.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "ai-review-system.changed"
        ],
        "subscribes": []
      }
    },
    "customer_360": {
      "key": "customer_360",
      "name": "Customer 360",
      "route": "/customer-360",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Customer 360",
      "owner": "customer_360",
      "dataTable": "crm_customers",
      "fields": [
        "full_name",
        "customer_type",
        "total_hotel_revenue",
        "total_restaurant_revenue",
        "total_stays",
        "updated_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "unified_timeline",
          "label": "Unified Timeline",
          "type": "boolean",
          "default": true
        },
        {
          "key": "hotel_history",
          "label": "Hotel History",
          "type": "boolean",
          "default": true
        },
        {
          "key": "restaurant_history",
          "label": "Restaurant History",
          "type": "boolean",
          "default": true
        },
        {
          "key": "communication_history",
          "label": "Communication History",
          "type": "boolean",
          "default": true
        },
        {
          "key": "profile_enrichment",
          "label": "Profile Enrichment",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "customer_360.view",
        "customer_360.manage",
        "customer_360.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "customer_360.changed"
        ],
        "subscribes": []
      }
    },
    "customer_intelligence": {
      "key": "customer_intelligence",
      "name": "Customer Intelligence",
      "route": "/customer-intelligence",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Customer Intelligence",
      "owner": "customer_intelligence",
      "dataTable": "crm_customer_insights",
      "fields": [
        "customer_id",
        "insight_type",
        "insight_value",
        "confidence",
        "created_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "preference_learning",
          "label": "Preference Learning",
          "type": "boolean",
          "default": true
        },
        {
          "key": "affinity_scoring",
          "label": "Affinity Scoring",
          "type": "boolean",
          "default": true
        },
        {
          "key": "behavior_scoring",
          "label": "Behavior Scoring",
          "type": "boolean",
          "default": true
        },
        {
          "key": "insight_refresh_hours",
          "label": "Insight Refresh Hours",
          "type": "number",
          "default": 24
        }
      ],
      "permissions": [
        "customer_intelligence.view",
        "customer_intelligence.manage",
        "customer_intelligence.configure"
      ],
      "dependencies": [
        "crm"
      ],
      "events": {
        "publishes": [
          "customer_intelligence.changed"
        ],
        "subscribes": []
      }
    },
    "hotel_guest_crm": {
      "key": "hotel_guest_crm",
      "name": "Hotel Guest CRM",
      "route": "/hotel-guest-crm",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Hotel Guest CRM",
      "owner": "hotel_guest_crm",
      "dataTable": "crm_guest_stays",
      "fields": [
        "customer_id",
        "room_number",
        "booking_status",
        "check_in_date",
        "check_out_date",
        "total_amount"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "prearrival",
          "label": "Pre-arrival",
          "type": "boolean",
          "default": true
        },
        {
          "key": "stay_lifecycle",
          "label": "Stay Lifecycle",
          "type": "boolean",
          "default": true
        },
        {
          "key": "guest_requests",
          "label": "Guest Requests",
          "type": "boolean",
          "default": true
        },
        {
          "key": "upsell_offers",
          "label": "Guest Upsells",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "hotel_guest_crm.view",
        "hotel_guest_crm.manage",
        "hotel_guest_crm.configure"
      ],
      "dependencies": [
        "hotel-booking",
        "hotel-pms"
      ],
      "events": {
        "publishes": [
          "hotel_guest_crm.changed"
        ],
        "subscribes": []
      }
    },
    "restaurant_crm": {
      "key": "restaurant_crm",
      "name": "Restaurant CRM",
      "route": "/restaurant-crm",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Restaurant CRM",
      "owner": "restaurant_crm",
      "dataTable": "crm_restaurant_customer_metrics",
      "fields": [
        "customer_id",
        "total_visits",
        "lifetime_spend",
        "average_bill",
        "last_visit_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "visit_metrics",
          "label": "Visit Metrics",
          "type": "boolean",
          "default": true
        },
        {
          "key": "food_preferences",
          "label": "Food Preferences",
          "type": "boolean",
          "default": true
        },
        {
          "key": "auto_tags",
          "label": "Auto Tags",
          "type": "boolean",
          "default": true
        },
        {
          "key": "restaurant_ltv",
          "label": "Restaurant LTV",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "restaurant_crm.view",
        "restaurant_crm.manage",
        "restaurant_crm.configure"
      ],
      "dependencies": [
        "crm"
      ],
      "events": {
        "publishes": [
          "restaurant_crm.changed"
        ],
        "subscribes": []
      }
    },
    "customer_ltv": {
      "key": "customer_ltv",
      "name": "Customer Lifetime Value",
      "route": "/customer-ltv",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Customer Lifetime Value",
      "owner": "customer_ltv",
      "dataTable": "crm_customer_value_snapshots",
      "fields": [
        "customer_id",
        "snapshot_date",
        "total_revenue",
        "calculated_ltv",
        "visit_count"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "hotel_revenue",
          "label": "Hotel Revenue",
          "type": "boolean",
          "default": true
        },
        {
          "key": "restaurant_revenue",
          "label": "Restaurant Revenue",
          "type": "boolean",
          "default": true
        },
        {
          "key": "event_revenue",
          "label": "Event Revenue",
          "type": "boolean",
          "default": true
        },
        {
          "key": "ancillary_revenue",
          "label": "Ancillary Revenue",
          "type": "boolean",
          "default": true
        },
        {
          "key": "refresh_frequency_hours",
          "label": "Refresh Frequency Hours",
          "type": "number",
          "default": 24
        }
      ],
      "permissions": [
        "customer_ltv.view",
        "customer_ltv.manage",
        "customer_ltv.configure"
      ],
      "dependencies": [
        "crm"
      ],
      "events": {
        "publishes": [
          "customer_ltv.changed"
        ],
        "subscribes": []
      }
    },
    "lead_management": {
      "key": "lead_management",
      "name": "Lead Management",
      "route": "/lead-management",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Lead Management",
      "owner": "lead_management",
      "dataTable": "crm_leads",
      "fields": [
        "lead_type",
        "source",
        "stage",
        "estimated_value",
        "next_follow_up"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "pipeline_enabled",
          "label": "Pipeline",
          "type": "boolean",
          "default": true
        },
        {
          "key": "lead_scoring",
          "label": "Lead Scoring",
          "type": "boolean",
          "default": true
        },
        {
          "key": "source_tracking",
          "label": "Source Tracking",
          "type": "boolean",
          "default": true
        },
        {
          "key": "auto_assignment",
          "label": "Auto Assignment",
          "type": "boolean",
          "default": false
        }
      ],
      "permissions": [
        "lead_management.view",
        "lead_management.manage",
        "lead_management.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "lead_management.changed"
        ],
        "subscribes": []
      }
    },
    "followups": {
      "key": "followups",
      "name": "Follow-up Management",
      "route": "/followups",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Follow-up Management",
      "owner": "followups",
      "dataTable": "crm_followup_events",
      "fields": [
        "customer_id",
        "sequence_id",
        "event_type",
        "status",
        "scheduled_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "task_reminders",
          "label": "Task Reminders",
          "type": "boolean",
          "default": true
        },
        {
          "key": "sequence_automation",
          "label": "Sequence Automation",
          "type": "boolean",
          "default": true
        },
        {
          "key": "owner_required",
          "label": "Owner Required",
          "type": "boolean",
          "default": true
        },
        {
          "key": "reminder_hours_before",
          "label": "Reminder Hours Before",
          "type": "number",
          "default": 2
        }
      ],
      "permissions": [
        "followups.view",
        "followups.manage",
        "followups.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "followups.changed"
        ],
        "subscribes": []
      }
    },
    "corporate_crm": {
      "key": "corporate_crm",
      "name": "Corporate CRM",
      "route": "/corporate-crm",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Corporate CRM",
      "owner": "corporate_crm",
      "dataTable": "crm_corporate_accounts",
      "fields": [
        "company_name",
        "contact_name",
        "payment_terms",
        "credit_limit",
        "active"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "contracts",
          "label": "Contracts",
          "type": "boolean",
          "default": true
        },
        {
          "key": "negotiated_rates",
          "label": "Negotiated Rates",
          "type": "boolean",
          "default": true
        },
        {
          "key": "credit_control",
          "label": "Credit Control",
          "type": "boolean",
          "default": true
        },
        {
          "key": "account_reviews",
          "label": "Account Reviews",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "corporate_crm.view",
        "corporate_crm.manage",
        "corporate_crm.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "corporate_crm.changed"
        ],
        "subscribes": []
      }
    },
    "partner_crm": {
      "key": "partner_crm",
      "name": "Partner CRM",
      "route": "/partner-crm",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Partner CRM",
      "owner": "partner_crm",
      "dataTable": "crm_partners",
      "fields": [
        "name",
        "partner_type",
        "phone",
        "email",
        "commission_percent",
        "active"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "commission_tracking",
          "label": "Commission Tracking",
          "type": "boolean",
          "default": true
        },
        {
          "key": "partner_bookings",
          "label": "Partner Bookings",
          "type": "boolean",
          "default": true
        },
        {
          "key": "settlement_tracking",
          "label": "Settlement Tracking",
          "type": "boolean",
          "default": true
        },
        {
          "key": "partner_scoring",
          "label": "Partner Scoring",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "partner_crm.view",
        "partner_crm.manage",
        "partner_crm.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "partner_crm.changed"
        ],
        "subscribes": []
      }
    },
    "loyalty": {
      "key": "loyalty",
      "name": "Loyalty CRM",
      "route": "/loyalty",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Loyalty CRM",
      "owner": "loyalty",
      "dataTable": "crm_loyalty_accounts",
      "fields": [
        "customer_id",
        "tier",
        "points_balance",
        "lifetime_points",
        "created_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "earn_rules",
          "label": "Earn Rules",
          "type": "boolean",
          "default": true
        },
        {
          "key": "redeem_rules",
          "label": "Redeem Rules",
          "type": "boolean",
          "default": true
        },
        {
          "key": "tier_rules",
          "label": "Tier Rules",
          "type": "boolean",
          "default": true
        },
        {
          "key": "referrals",
          "label": "Referrals",
          "type": "boolean",
          "default": true
        },
        {
          "key": "reverse_transactions",
          "label": "Transaction Reversal",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "loyalty.view",
        "loyalty.manage",
        "loyalty.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "loyalty.changed"
        ],
        "subscribes": []
      }
    },
    "offers_coupons": {
      "key": "offers_coupons",
      "name": "Offers & Coupons",
      "route": "/offers-coupons",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Offers & Coupons",
      "owner": "offers_coupons",
      "dataTable": "crm_coupon_definitions",
      "fields": [
        "code",
        "name",
        "discount_type",
        "discount_value",
        "active",
        "starts_at",
        "ends_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "eligibility_rules",
          "label": "Eligibility Rules",
          "type": "boolean",
          "default": true
        },
        {
          "key": "redemption_limits",
          "label": "Redemption Limits",
          "type": "boolean",
          "default": true
        },
        {
          "key": "expiry_enforcement",
          "label": "Expiry Enforcement",
          "type": "boolean",
          "default": true
        },
        {
          "key": "customer_attribution",
          "label": "Customer Attribution",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "offers_coupons.view",
        "offers_coupons.manage",
        "offers_coupons.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "offers_coupons.changed"
        ],
        "subscribes": []
      }
    },
    "marketing_automation": {
      "key": "marketing_automation",
      "name": "Marketing Automation",
      "route": "/marketing-automation",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Marketing Automation",
      "owner": "marketing_automation",
      "dataTable": "crm_campaigns",
      "fields": [
        "name",
        "channel",
        "status",
        "scheduled_at",
        "created_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "trigger_engine",
          "label": "Trigger Engine",
          "type": "boolean",
          "default": true
        },
        {
          "key": "journeys",
          "label": "Journeys",
          "type": "boolean",
          "default": true
        },
        {
          "key": "campaign_scheduling",
          "label": "Campaign Scheduling",
          "type": "boolean",
          "default": true
        },
        {
          "key": "attribution",
          "label": "Revenue Attribution",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "marketing_automation.view",
        "marketing_automation.manage",
        "marketing_automation.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "marketing_automation.changed"
        ],
        "subscribes": []
      }
    },
    "whatsapp_crm": {
      "key": "whatsapp_crm",
      "name": "WhatsApp CRM",
      "route": "/whatsapp-crm",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: WhatsApp CRM",
      "owner": "whatsapp_crm",
      "dataTable": "crm_message_log",
      "fields": [
        "customer_id",
        "channel",
        "direction",
        "status",
        "sent_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "template_management",
          "label": "Template Management",
          "type": "boolean",
          "default": true
        },
        {
          "key": "inbound_logging",
          "label": "Inbound Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "outbound_logging",
          "label": "Outbound Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "delivery_status",
          "label": "Delivery Status",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "whatsapp_crm.view",
        "whatsapp_crm.manage",
        "whatsapp_crm.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "whatsapp_crm.changed"
        ],
        "subscribes": []
      }
    },
    "reputation": {
      "key": "reputation",
      "name": "Review & Reputation",
      "route": "/reputation",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Review & Reputation",
      "owner": "reputation",
      "dataTable": "crm_reviews",
      "fields": [
        "source",
        "author_name",
        "rating",
        "review_text",
        "sentiment",
        "reply_status"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "multi_source",
          "label": "Multi-source Reviews",
          "type": "boolean",
          "default": true
        },
        {
          "key": "sentiment",
          "label": "Sentiment Analysis",
          "type": "boolean",
          "default": true
        },
        {
          "key": "response_workflow",
          "label": "Response Workflow",
          "type": "boolean",
          "default": true
        },
        {
          "key": "review_requests",
          "label": "Review Requests",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "reputation.view",
        "reputation.manage",
        "reputation.configure"
      ],
      "dependencies": [
        "ai-review-system"
      ],
      "events": {
        "publishes": [
          "reputation.changed"
        ],
        "subscribes": []
      }
    },
    "guest_relations": {
      "key": "guest_relations",
      "name": "Guest Relations",
      "route": "/guest-relations",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Guest Relations",
      "owner": "guest_relations",
      "dataTable": "crm_complaints",
      "fields": [
        "customer_id",
        "title",
        "priority",
        "status",
        "opened_at",
        "resolved_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "complaints",
          "label": "Complaints",
          "type": "boolean",
          "default": true
        },
        {
          "key": "service_recovery",
          "label": "Service Recovery",
          "type": "boolean",
          "default": true
        },
        {
          "key": "sla",
          "label": "SLA",
          "type": "boolean",
          "default": true
        },
        {
          "key": "manager_escalation",
          "label": "Manager Escalation",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "guest_relations.view",
        "guest_relations.manage",
        "guest_relations.configure"
      ],
      "dependencies": [
        "crm"
      ],
      "events": {
        "publishes": [
          "guest_relations.changed"
        ],
        "subscribes": []
      }
    },
    "segmentation": {
      "key": "segmentation",
      "name": "Customer Segmentation",
      "route": "/segmentation",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Customer Segmentation",
      "owner": "segmentation",
      "dataTable": "crm_segments",
      "fields": [
        "name",
        "active",
        "definition",
        "created_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "dynamic_segments",
          "label": "Dynamic Segments",
          "type": "boolean",
          "default": true
        },
        {
          "key": "auto_membership",
          "label": "Auto Membership",
          "type": "boolean",
          "default": true
        },
        {
          "key": "segment_refresh_hours",
          "label": "Refresh Hours",
          "type": "number",
          "default": 6
        },
        {
          "key": "engagement_filters",
          "label": "Engagement Filters",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "segmentation.view",
        "segmentation.manage",
        "segmentation.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "segmentation.changed"
        ],
        "subscribes": []
      }
    },
    "churn": {
      "key": "churn",
      "name": "Churn / At-Risk",
      "route": "/churn",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Churn / At-Risk",
      "owner": "churn",
      "dataTable": "crm_churn_scores",
      "fields": [
        "customer_id",
        "score",
        "risk_level",
        "calculated_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "score_enabled",
          "label": "Churn Score",
          "type": "boolean",
          "default": true
        },
        {
          "key": "risk_threshold",
          "label": "Risk Threshold",
          "type": "number",
          "default": 70
        },
        {
          "key": "retention_actions",
          "label": "Retention Actions",
          "type": "boolean",
          "default": true
        },
        {
          "key": "recompute_hours",
          "label": "Recompute Hours",
          "type": "number",
          "default": 24
        }
      ],
      "permissions": [
        "churn.view",
        "churn.manage",
        "churn.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "churn.changed"
        ],
        "subscribes": []
      }
    },
    "vip": {
      "key": "vip",
      "name": "VIP Management",
      "route": "/vip",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: VIP Management",
      "owner": "vip",
      "dataTable": "crm_vip_profiles",
      "fields": [
        "customer_id",
        "vip_level",
        "dedicated_manager",
        "created_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "vip_levels",
          "label": "VIP Levels",
          "type": "boolean",
          "default": true
        },
        {
          "key": "amenity_tracking",
          "label": "Amenity Tracking",
          "type": "boolean",
          "default": true
        },
        {
          "key": "dedicated_manager",
          "label": "Dedicated Manager",
          "type": "boolean",
          "default": true
        },
        {
          "key": "vip_history",
          "label": "VIP History",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "vip.view",
        "vip.manage",
        "vip.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "vip.changed"
        ],
        "subscribes": []
      }
    },
    "revenue_management": {
      "key": "revenue_management",
      "name": "Revenue Management",
      "route": "/revenue-management",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Revenue Management",
      "owner": "revenue_management",
      "dataTable": "crm_revenue_rate_recommendations",
      "fields": [
        "room_type_id",
        "stay_date",
        "recommended_rate",
        "confidence",
        "status"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "occupancy_signal",
          "label": "Occupancy Signal",
          "type": "boolean",
          "default": true
        },
        {
          "key": "booking_pace",
          "label": "Booking Pace",
          "type": "boolean",
          "default": true
        },
        {
          "key": "competitor_signal",
          "label": "Competitor Signal",
          "type": "boolean",
          "default": true
        },
        {
          "key": "approval_required",
          "label": "Rate Approval Required",
          "type": "boolean",
          "default": true
        },
        {
          "key": "min_rate_guard",
          "label": "Minimum Rate Guard",
          "type": "number",
          "default": 0
        }
      ],
      "permissions": [
        "revenue_management.view",
        "revenue_management.manage",
        "revenue_management.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "revenue_management.changed"
        ],
        "subscribes": []
      }
    },
    "upselling": {
      "key": "upselling",
      "name": "Upselling Engine",
      "route": "/upselling",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Upselling Engine",
      "owner": "upselling",
      "dataTable": "crm_upsell_offers",
      "fields": [
        "name",
        "offer_type",
        "product_reference",
        "price",
        "active"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "prearrival_offers",
          "label": "Pre-arrival Offers",
          "type": "boolean",
          "default": true
        },
        {
          "key": "in_stay_offers",
          "label": "In-stay Offers",
          "type": "boolean",
          "default": true
        },
        {
          "key": "ancillary_catalog",
          "label": "Ancillary Catalog",
          "type": "boolean",
          "default": true
        },
        {
          "key": "approval_required",
          "label": "Approval Required",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "upselling.view",
        "upselling.manage",
        "upselling.configure"
      ],
      "dependencies": [
        "hotel-booking"
      ],
      "events": {
        "publishes": [
          "upselling.changed"
        ],
        "subscribes": []
      }
    },
    "cross_selling": {
      "key": "cross_selling",
      "name": "Cross-Selling Engine",
      "route": "/cross-selling",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Cross-Selling Engine",
      "owner": "cross_selling",
      "dataTable": "crm_cross_sell_rules",
      "fields": [
        "source_context",
        "target_product",
        "eligibility",
        "active"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "hotel_to_restaurant",
          "label": "Hotel → Restaurant",
          "type": "boolean",
          "default": true
        },
        {
          "key": "restaurant_to_hotel",
          "label": "Restaurant → Hotel",
          "type": "boolean",
          "default": true
        },
        {
          "key": "activity_cross_sell",
          "label": "Activity Cross-sell",
          "type": "boolean",
          "default": true
        },
        {
          "key": "customer_eligibility",
          "label": "Eligibility Engine",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "cross_selling.view",
        "cross_selling.manage",
        "cross_selling.configure"
      ],
      "dependencies": [
        "customer_360"
      ],
      "events": {
        "publishes": [
          "cross_selling.changed"
        ],
        "subscribes": []
      }
    },
    "event_crm": {
      "key": "event_crm",
      "name": "Event CRM",
      "route": "/event-crm",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Event CRM",
      "owner": "event_crm",
      "dataTable": "crm_events",
      "fields": [
        "name",
        "event_type",
        "venue",
        "event_date",
        "expected_guests",
        "stage",
        "estimated_value"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "lead_pipeline",
          "label": "Event Lead Pipeline",
          "type": "boolean",
          "default": true
        },
        {
          "key": "quotes",
          "label": "Event Quotes",
          "type": "boolean",
          "default": true
        },
        {
          "key": "followups",
          "label": "Event Follow-ups",
          "type": "boolean",
          "default": true
        },
        {
          "key": "deposit_tracking",
          "label": "Deposit Tracking",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "event_crm.view",
        "event_crm.manage",
        "event_crm.configure"
      ],
      "dependencies": [],
      "events": {
        "publishes": [
          "event_crm.changed"
        ],
        "subscribes": []
      }
    },
    "omnichannel_timeline": {
      "key": "omnichannel_timeline",
      "name": "Omnichannel Timeline",
      "route": "/omnichannel-timeline",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Omnichannel Timeline",
      "owner": "omnichannel_timeline",
      "dataTable": "crm_timeline_events",
      "fields": [
        "customer_id",
        "event_type",
        "channel",
        "title",
        "occurred_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "hotel_events",
          "label": "Hotel Events",
          "type": "boolean",
          "default": true
        },
        {
          "key": "restaurant_events",
          "label": "Restaurant Events",
          "type": "boolean",
          "default": true
        },
        {
          "key": "messages",
          "label": "Messages",
          "type": "boolean",
          "default": true
        },
        {
          "key": "reviews",
          "label": "Reviews",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "omnichannel_timeline.view",
        "omnichannel_timeline.manage",
        "omnichannel_timeline.configure"
      ],
      "dependencies": [
        "crm"
      ],
      "events": {
        "publishes": [
          "omnichannel_timeline.changed"
        ],
        "subscribes": []
      }
    },
    "consent_privacy": {
      "key": "consent_privacy",
      "name": "Consent & Privacy",
      "route": "/consent-privacy",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Consent & Privacy",
      "owner": "consent_privacy",
      "dataTable": "crm_consents",
      "fields": [
        "customer_id",
        "channel",
        "purpose",
        "status",
        "captured_at",
        "source"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "marketing_consent",
          "label": "Marketing Consent",
          "type": "boolean",
          "default": true
        },
        {
          "key": "channel_preferences",
          "label": "Channel Preferences",
          "type": "boolean",
          "default": true
        },
        {
          "key": "data_requests",
          "label": "Data Requests",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_trail",
          "label": "Consent Audit Trail",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "consent_privacy.view",
        "consent_privacy.manage",
        "consent_privacy.configure"
      ],
      "dependencies": [
        "crm"
      ],
      "events": {
        "publishes": [
          "consent_privacy.changed"
        ],
        "subscribes": []
      }
    },
    "relationship_manager": {
      "key": "relationship_manager",
      "name": "Relationship Manager",
      "route": "/relationship-manager",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Relationship Manager",
      "owner": "relationship_manager",
      "dataTable": "crm_relationship_assignments",
      "fields": [
        "customer_id",
        "staff_id",
        "assignment_type",
        "active",
        "assigned_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "portfolio_assignment",
          "label": "Portfolio Assignment",
          "type": "boolean",
          "default": true
        },
        {
          "key": "ownership_required",
          "label": "Ownership Required",
          "type": "boolean",
          "default": true
        },
        {
          "key": "workload_limits",
          "label": "Workload Limits",
          "type": "boolean",
          "default": false
        },
        {
          "key": "reassignment_audit",
          "label": "Reassignment Audit",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "relationship_manager.view",
        "relationship_manager.manage",
        "relationship_manager.configure"
      ],
      "dependencies": [
        "crm"
      ],
      "events": {
        "publishes": [
          "relationship_manager.changed"
        ],
        "subscribes": []
      }
    },
    "advanced_analytics": {
      "key": "advanced_analytics",
      "name": "Advanced CRM Analytics",
      "route": "/advanced-analytics",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Advanced CRM Analytics",
      "owner": "advanced_analytics",
      "dataTable": "crm_analytics_daily",
      "fields": [
        "tenant_id",
        "metric_date",
        "hotel_revenue",
        "restaurant_revenue",
        "ltv"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "retention",
          "label": "Retention Analytics",
          "type": "boolean",
          "default": true
        },
        {
          "key": "ltv",
          "label": "LTV Analytics",
          "type": "boolean",
          "default": true
        },
        {
          "key": "campaign_roi",
          "label": "Campaign ROI",
          "type": "boolean",
          "default": true
        },
        {
          "key": "guest_analytics",
          "label": "Guest Analytics",
          "type": "boolean",
          "default": true
        },
        {
          "key": "cohort_analysis",
          "label": "Cohort Analysis",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "advanced_analytics.view",
        "advanced_analytics.manage",
        "advanced_analytics.configure"
      ],
      "dependencies": [
        "crm"
      ],
      "events": {
        "publishes": [
          "advanced_analytics.changed"
        ],
        "subscribes": []
      }
    },
    "ai_crm": {
      "key": "ai_crm",
      "name": "AI CRM",
      "route": "/ai-crm",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: AI CRM",
      "owner": "ai_crm",
      "dataTable": "crm_ai_insights",
      "fields": [
        "customer_id",
        "insight_type",
        "summary",
        "recommendation",
        "confidence",
        "created_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "summaries",
          "label": "Customer Summaries",
          "type": "boolean",
          "default": true
        },
        {
          "key": "next_best_action",
          "label": "Next Best Action",
          "type": "boolean",
          "default": true
        },
        {
          "key": "ai_insights",
          "label": "AI Insights",
          "type": "boolean",
          "default": true
        },
        {
          "key": "human_approval",
          "label": "Human Approval",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "ai_crm.view",
        "ai_crm.manage",
        "ai_crm.configure"
      ],
      "dependencies": [
        "crm"
      ],
      "events": {
        "publishes": [
          "ai_crm.changed"
        ],
        "subscribes": []
      }
    },
    "revenue_forecasting": {
      "key": "revenue_forecasting",
      "name": "Revenue Forecasting",
      "route": "/revenue-forecasting",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Revenue Forecasting",
      "owner": "revenue_forecasting",
      "dataTable": "crm_revenue_forecasts",
      "fields": [
        "forecast_date",
        "horizon_days",
        "occupancy_forecast",
        "adr_forecast",
        "revpar_forecast",
        "demand_index",
        "confidence"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "occupancy_forecast",
          "label": "Occupancy Forecast",
          "type": "boolean",
          "default": true
        },
        {
          "key": "adr_forecast",
          "label": "ADR Forecast",
          "type": "boolean",
          "default": true
        },
        {
          "key": "revpar_forecast",
          "label": "RevPAR Forecast",
          "type": "boolean",
          "default": true
        },
        {
          "key": "demand_forecast",
          "label": "Demand Forecast",
          "type": "boolean",
          "default": true
        },
        {
          "key": "approval_required",
          "label": "Forecast Approval",
          "type": "boolean",
          "default": true
        }
      ],
      "permissions": [
        "revenue_forecasting.view",
        "revenue_forecasting.manage",
        "revenue_forecasting.configure"
      ],
      "dependencies": [
        "revenue_management"
      ],
      "events": {
        "publishes": [
          "revenue_forecasting.changed"
        ],
        "subscribes": []
      }
    },
    "competitor_intelligence": {
      "key": "competitor_intelligence",
      "name": "Competitor Rate Intelligence",
      "route": "/competitor-intelligence",
      "category": "CRM Platform",
      "description": "Enterprise CRM module: Competitor Rate Intelligence",
      "owner": "competitor_intelligence",
      "dataTable": "crm_competitor_rates",
      "fields": [
        "competitor_name",
        "room_type_label",
        "stay_date",
        "rate",
        "currency",
        "source",
        "captured_at"
      ],
      "settingsSchema": [
        {
          "key": "notifications_enabled",
          "label": "Notifications Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "audit_logging",
          "label": "Audit Logging",
          "type": "boolean",
          "default": true
        },
        {
          "key": "automation_enabled",
          "label": "Automation Enabled",
          "type": "boolean",
          "default": true
        },
        {
          "key": "retry_attempts",
          "label": "Retry Attempts",
          "type": "number",
          "default": 3,
          "min": 0,
          "max": 10
        },
        {
          "key": "manager_access",
          "label": "Manager Access",
          "type": "boolean",
          "default": true
        },
        {
          "key": "staff_access",
          "label": "Staff Access",
          "type": "boolean",
          "default": false
        },
        {
          "key": "email_notifications",
          "label": "Email Notifications",
          "type": "boolean",
          "default": true
        },
        {
          "key": "whatsapp_notifications",
          "label": "WhatsApp Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "sms_notifications",
          "label": "SMS Notifications",
          "type": "boolean",
          "default": false
        },
        {
          "key": "live_collection",
          "label": "Live Collection",
          "type": "boolean",
          "default": true
        },
        {
          "key": "rate_parity",
          "label": "Rate Parity",
          "type": "boolean",
          "default": true
        },
        {
          "key": "competitor_alerts",
          "label": "Competitor Alerts",
          "type": "boolean",
          "default": true
        },
        {
          "key": "collection_interval_hours",
          "label": "Collection Interval Hours",
          "type": "number",
          "default": 6
        }
      ],
      "permissions": [
        "competitor_intelligence.view",
        "competitor_intelligence.manage",
        "competitor_intelligence.configure"
      ],
      "dependencies": [
        "seo-system"
      ],
      "events": {
        "publishes": [
          "competitor_intelligence.changed"
        ],
        "subscribes": []
      }
    }
  }
};
