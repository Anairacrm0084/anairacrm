-- P7 marketplace data repair: ensure connected Restaurant SaaS businesses are discoverable
-- in the Super Admin Restaurant Marketplace without duplicating POS master data.

DO $$
DECLARE
  restaurant_store uuid;
BEGIN
  SELECT id INTO restaurant_store
  FROM public.anaira_platform_stores
  WHERE store_type='restaurant'
  ORDER BY created_at NULLS LAST, id
  LIMIT 1;

  IF restaurant_store IS NULL THEN
    RAISE NOTICE 'Restaurant platform store is not provisioned; skipping membership backfill.';
    RETURN;
  END IF;

  INSERT INTO public.anaira_store_memberships
    (store_id, restaurant_id, enabled, sort_order, listing_override, catalog_source, manual_catalog_enabled, store_config, image_config, sync_status)
  SELECT
    restaurant_store, r.id, true, 0, '{}'::jsonb, 'restaurant_saas', false, '{}'::jsonb, '{}'::jsonb, 'configured'
  FROM public.restaurants r
  JOIN public.anaira_restaurant_connections c ON c.restaurant_id=r.id AND c.status='connected' AND c.enabled=true
  LEFT JOIN public.anaira_store_memberships m ON m.store_id=restaurant_store AND m.restaurant_id=r.id
  WHERE m.id IS NULL AND r.status='active';

  INSERT INTO public.anaira_marketplace_listings
    (restaurant_id, listing_type, marketplace_visible, food_ordering_enabled, restaurant_reservation_enabled, approval_status, display_name, city, cover_image)
  SELECT
    r.id, 'restaurant', true, true, true, 'approved', r.name, r.city, r.cover_image
  FROM public.restaurants r
  JOIN public.anaira_restaurant_connections c ON c.restaurant_id=r.id AND c.status='connected' AND c.enabled=true
  WHERE r.status='active'
  ON CONFLICT (restaurant_id) DO UPDATE
    SET food_ordering_enabled=true, restaurant_reservation_enabled=true, marketplace_visible=true, approval_status='approved', updated_at=now();
END $$;
