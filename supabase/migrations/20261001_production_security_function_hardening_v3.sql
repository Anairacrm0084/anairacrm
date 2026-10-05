-- Production security hardening: sensitive SECURITY DEFINER RPCs must not be callable by anon.
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure::text AS signature
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public'
      AND p.prosecdef=true
      AND p.proname IN (
        'anaira_close_crm_bill','anaira_confirm_hotel_booking_payment',
        'anaira_distribution_channel_guard','anaira_distribution_connection_guard',
        'anaira_distribution_mark_verified','anaira_mark_payment_verified',
        'anaira_set_daily_rate','anaira_set_inventory_controls','anaira_set_plugin',
        'anaira_set_profile_permission','anaira_set_room_booking_block',
        'anaira_set_user_permission','anaira_set_user_role','anaira_settle_hms_folio',
        'anaira_user_has_permission','anaira_verify_hotel_payment','anaira_submit_hotel_payment'
      )
  LOOP
    EXECUTE 'REVOKE EXECUTE ON FUNCTION ' || r.signature || ' FROM anon';
  END LOOP;
END $$;
