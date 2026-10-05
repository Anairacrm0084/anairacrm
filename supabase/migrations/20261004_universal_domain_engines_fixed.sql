-- Anaira Universal Business Domain Engine Runtime (fixed live-compatible RLS)
DO $$
DECLARE t text;
BEGIN
 FOREACH t IN ARRAY ARRAY['salon','barber_shop','spa_wellness','clinic_hospital','dentist_doctor','pharmacy','gym_yoga','retail_grocery','fashion','jewellery','electronics_mobile','automotive','real_estate','travel','education_coaching','legal','ca_accounting_tax','it_agency','repair_maintenance','cleaning','veterinary','photography','events','coworking','logistics','construction_home_services','ecommerce','saas_subscription','creator_personal_brand','non_profit','other'] LOOP
   EXECUTE format('CREATE TABLE IF NOT EXISTS public.anaira_domain_%I (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), business_id uuid NOT NULL, business_type text NOT NULL, module_key text NOT NULL, title text NOT NULL, status text NOT NULL DEFAULT ''active'', data jsonb NOT NULL DEFAULT ''{}''::jsonb, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now())', t);
   EXECUTE format('CREATE INDEX IF NOT EXISTS ana_dom_%I_business_module_idx ON public.anaira_domain_%I (business_id,module_key,created_at DESC)', t,t);
   EXECUTE format('ALTER TABLE public.anaira_domain_%I ENABLE ROW LEVEL SECURITY', t);
   EXECUTE format('DROP POLICY IF EXISTS tenant_domain_select ON public.anaira_domain_%I',t);
   EXECUTE format('DROP POLICY IF EXISTS tenant_domain_write ON public.anaira_domain_%I',t);
   EXECUTE format('CREATE POLICY tenant_domain_select ON public.anaira_domain_%I FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id))',t);
   EXECUTE format('CREATE POLICY tenant_domain_write ON public.anaira_domain_%I FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id))',t);
 END LOOP;
END $$;

CREATE TABLE IF NOT EXISTS public.anaira_business_workflow_events (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), business_id uuid NOT NULL, business_type text NOT NULL,
 entity_table text NOT NULL, entity_id uuid NOT NULL, module_key text NOT NULL,
 from_status text, to_status text NOT NULL, payload jsonb NOT NULL DEFAULT '{}'::jsonb,
 actor_id uuid REFERENCES auth.users(id), created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_workflow_events_business_idx ON public.anaira_business_workflow_events(business_id,created_at DESC);
ALTER TABLE public.anaira_business_workflow_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS workflow_events_tenant ON public.anaira_business_workflow_events;
CREATE POLICY workflow_events_tenant ON public.anaira_business_workflow_events FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
