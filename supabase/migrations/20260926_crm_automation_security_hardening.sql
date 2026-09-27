-- Phase 37: CRM workflow UI/runtime + security hardening
-- Webhook events are application-ingestion data. Tenant users may inspect their own tenant rows;
-- rows without tenant_id remain service-role/application-owned.
create policy "tenant_access" on public.crm_review_webhook_events
  as permissive for all to authenticated
  using (tenant_id is null or anaira_tenant_access(tenant_id))
  with check (tenant_id is null or anaira_tenant_access(tenant_id));

-- Remove anonymous execution from internal/admin/runtime functions. Public booking,
-- availability, marketplace and store discovery functions remain intentionally public.
revoke execute on function public.anaira_audit_plugin_settings() from anon;
revoke execute on function public.anaira_classify_review_ai(uuid) from anon;
revoke execute on function public.anaira_enqueue_delivery_order_to_pos() from anon;
revoke execute on function public.anaira_feedback_route_action(uuid,uuid,uuid,numeric) from anon;
revoke execute on function public.anaira_generate_hotel_rate_recommendation(uuid,uuid,date) from anon;
revoke execute on function public.anaira_phase13_hotel_inventory_expire_holds() from anon;
revoke execute on function public.anaira_phase13_hotel_inventory_hold(uuid,uuid,date,date,integer,text,uuid,integer) from anon;
revoke execute on function public.anaira_phase13_hotel_inventory_hold_release(uuid,uuid,text) from anon;
revoke execute on function public.anaira_phase13_pms_transition(uuid,uuid,text,uuid,text) from anon;
revoke execute on function public.anaira_queue_prearrival_jobs(timestamptz) from anon;
revoke execute on function public.anaira_queue_review_request(uuid,uuid,uuid,text,text,text,timestamptz) from anon;
revoke execute on function public.anaira_refresh_global_customer_links(uuid,uuid) from anon;
revoke execute on function public.anaira_resolve_crm_customer(uuid,text,text,text) from anon;
revoke execute on function public.anaira_seo_audit_page(uuid) from anon;
revoke execute on function public.anaira_settle_hms_folio(uuid,uuid,numeric,text,text,text) from anon;
revoke execute on function public.anaira_start_hotel_booking_transaction(uuid,text,text,text,date,date,uuid,uuid,integer,integer,text,jsonb,text,text) from anon;
