-- V16 typed business module engine: one physical table per business/module, tenant RLS, workflow audit
CREATE TABLE IF NOT EXISTS public.anaira_salon_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_services_business_idx ON public.anaira_salon_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_services;
CREATE POLICY tenant_select ON public.anaira_salon_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_services;
CREATE POLICY tenant_write ON public.anaira_salon_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_staff_business_idx ON public.anaira_salon_staff(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_staff ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_staff;
CREATE POLICY tenant_select ON public.anaira_salon_staff FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_staff;
CREATE POLICY tenant_write ON public.anaira_salon_staff FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_resources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_resources_business_idx ON public.anaira_salon_resources(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_resources ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_resources;
CREATE POLICY tenant_select ON public.anaira_salon_resources FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_resources;
CREATE POLICY tenant_write ON public.anaira_salon_resources FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_appointments_business_idx ON public.anaira_salon_appointments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_appointments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_appointments;
CREATE POLICY tenant_select ON public.anaira_salon_appointments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_appointments;
CREATE POLICY tenant_write ON public.anaira_salon_appointments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_walkins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_walkins_business_idx ON public.anaira_salon_walkins(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_walkins ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_walkins;
CREATE POLICY tenant_select ON public.anaira_salon_walkins FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_walkins;
CREATE POLICY tenant_write ON public.anaira_salon_walkins FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_waitlist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_waitlist_business_idx ON public.anaira_salon_waitlist(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_waitlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_waitlist;
CREATE POLICY tenant_select ON public.anaira_salon_waitlist FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_waitlist;
CREATE POLICY tenant_write ON public.anaira_salon_waitlist FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_customers_business_idx ON public.anaira_salon_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_customers;
CREATE POLICY tenant_select ON public.anaira_salon_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_customers;
CREATE POLICY tenant_write ON public.anaira_salon_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_inventory_business_idx ON public.anaira_salon_inventory(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_inventory;
CREATE POLICY tenant_select ON public.anaira_salon_inventory FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_inventory;
CREATE POLICY tenant_write ON public.anaira_salon_inventory FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_memberships_business_idx ON public.anaira_salon_memberships(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_memberships ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_memberships;
CREATE POLICY tenant_select ON public.anaira_salon_memberships FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_memberships;
CREATE POLICY tenant_write ON public.anaira_salon_memberships FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_packages_business_idx ON public.anaira_salon_packages(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_packages;
CREATE POLICY tenant_select ON public.anaira_salon_packages FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_packages;
CREATE POLICY tenant_write ON public.anaira_salon_packages FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_gift_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_gift_cards_business_idx ON public.anaira_salon_gift_cards(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_gift_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_gift_cards;
CREATE POLICY tenant_select ON public.anaira_salon_gift_cards FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_gift_cards;
CREATE POLICY tenant_write ON public.anaira_salon_gift_cards FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_loyalty (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_loyalty_business_idx ON public.anaira_salon_loyalty(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_loyalty ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_loyalty;
CREATE POLICY tenant_select ON public.anaira_salon_loyalty FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_loyalty;
CREATE POLICY tenant_write ON public.anaira_salon_loyalty FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_marketing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_marketing_business_idx ON public.anaira_salon_marketing(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_marketing ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_marketing;
CREATE POLICY tenant_select ON public.anaira_salon_marketing FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_marketing;
CREATE POLICY tenant_write ON public.anaira_salon_marketing FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_reviews_business_idx ON public.anaira_salon_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_reviews;
CREATE POLICY tenant_select ON public.anaira_salon_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_reviews;
CREATE POLICY tenant_write ON public.anaira_salon_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_online_booking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_online_booking_business_idx ON public.anaira_salon_online_booking(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_online_booking ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_online_booking;
CREATE POLICY tenant_select ON public.anaira_salon_online_booking FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_online_booking;
CREATE POLICY tenant_write ON public.anaira_salon_online_booking FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_payments_business_idx ON public.anaira_salon_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_payments;
CREATE POLICY tenant_select ON public.anaira_salon_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_payments;
CREATE POLICY tenant_write ON public.anaira_salon_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_invoices_business_idx ON public.anaira_salon_invoices(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_invoices;
CREATE POLICY tenant_select ON public.anaira_salon_invoices FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_invoices;
CREATE POLICY tenant_write ON public.anaira_salon_invoices FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_commissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_commissions_business_idx ON public.anaira_salon_commissions(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_commissions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_commissions;
CREATE POLICY tenant_select ON public.anaira_salon_commissions FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_commissions;
CREATE POLICY tenant_write ON public.anaira_salon_commissions FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_payroll (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_payroll_business_idx ON public.anaira_salon_payroll(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_payroll ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_payroll;
CREATE POLICY tenant_select ON public.anaira_salon_payroll FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_payroll;
CREATE POLICY tenant_write ON public.anaira_salon_payroll FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_salon_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_salon_reports_business_idx ON public.anaira_salon_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_salon_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_salon_reports;
CREATE POLICY tenant_select ON public.anaira_salon_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_salon_reports;
CREATE POLICY tenant_write ON public.anaira_salon_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_services_business_idx ON public.anaira_barber_shop_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_services;
CREATE POLICY tenant_select ON public.anaira_barber_shop_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_services;
CREATE POLICY tenant_write ON public.anaira_barber_shop_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_barbers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_barbers_business_idx ON public.anaira_barber_shop_barbers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_barbers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_barbers;
CREATE POLICY tenant_select ON public.anaira_barber_shop_barbers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_barbers;
CREATE POLICY tenant_write ON public.anaira_barber_shop_barbers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_chairs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_chairs_business_idx ON public.anaira_barber_shop_chairs(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_chairs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_chairs;
CREATE POLICY tenant_select ON public.anaira_barber_shop_chairs FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_chairs;
CREATE POLICY tenant_write ON public.anaira_barber_shop_chairs FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_appointments_business_idx ON public.anaira_barber_shop_appointments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_appointments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_appointments;
CREATE POLICY tenant_select ON public.anaira_barber_shop_appointments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_appointments;
CREATE POLICY tenant_write ON public.anaira_barber_shop_appointments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_walkins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_walkins_business_idx ON public.anaira_barber_shop_walkins(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_walkins ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_walkins;
CREATE POLICY tenant_select ON public.anaira_barber_shop_walkins FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_walkins;
CREATE POLICY tenant_write ON public.anaira_barber_shop_walkins FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_customers_business_idx ON public.anaira_barber_shop_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_customers;
CREATE POLICY tenant_select ON public.anaira_barber_shop_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_customers;
CREATE POLICY tenant_write ON public.anaira_barber_shop_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_products_business_idx ON public.anaira_barber_shop_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_products;
CREATE POLICY tenant_select ON public.anaira_barber_shop_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_products;
CREATE POLICY tenant_write ON public.anaira_barber_shop_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_inventory_business_idx ON public.anaira_barber_shop_inventory(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_inventory;
CREATE POLICY tenant_select ON public.anaira_barber_shop_inventory FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_inventory;
CREATE POLICY tenant_write ON public.anaira_barber_shop_inventory FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_memberships_business_idx ON public.anaira_barber_shop_memberships(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_memberships ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_memberships;
CREATE POLICY tenant_select ON public.anaira_barber_shop_memberships FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_memberships;
CREATE POLICY tenant_write ON public.anaira_barber_shop_memberships FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_packages_business_idx ON public.anaira_barber_shop_packages(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_packages;
CREATE POLICY tenant_select ON public.anaira_barber_shop_packages FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_packages;
CREATE POLICY tenant_write ON public.anaira_barber_shop_packages FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_gift_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_gift_cards_business_idx ON public.anaira_barber_shop_gift_cards(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_gift_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_gift_cards;
CREATE POLICY tenant_select ON public.anaira_barber_shop_gift_cards FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_gift_cards;
CREATE POLICY tenant_write ON public.anaira_barber_shop_gift_cards FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_loyalty (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_loyalty_business_idx ON public.anaira_barber_shop_loyalty(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_loyalty ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_loyalty;
CREATE POLICY tenant_select ON public.anaira_barber_shop_loyalty FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_loyalty;
CREATE POLICY tenant_write ON public.anaira_barber_shop_loyalty FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_offers_business_idx ON public.anaira_barber_shop_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_offers;
CREATE POLICY tenant_select ON public.anaira_barber_shop_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_offers;
CREATE POLICY tenant_write ON public.anaira_barber_shop_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_reviews_business_idx ON public.anaira_barber_shop_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_reviews;
CREATE POLICY tenant_select ON public.anaira_barber_shop_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_reviews;
CREATE POLICY tenant_write ON public.anaira_barber_shop_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_online_booking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_online_booking_business_idx ON public.anaira_barber_shop_online_booking(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_online_booking ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_online_booking;
CREATE POLICY tenant_select ON public.anaira_barber_shop_online_booking FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_online_booking;
CREATE POLICY tenant_write ON public.anaira_barber_shop_online_booking FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_payments_business_idx ON public.anaira_barber_shop_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_payments;
CREATE POLICY tenant_select ON public.anaira_barber_shop_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_payments;
CREATE POLICY tenant_write ON public.anaira_barber_shop_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_barber_shop_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_barber_shop_reports_business_idx ON public.anaira_barber_shop_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_barber_shop_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_barber_shop_reports;
CREATE POLICY tenant_select ON public.anaira_barber_shop_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_barber_shop_reports;
CREATE POLICY tenant_write ON public.anaira_barber_shop_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_treatments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_treatments_business_idx ON public.anaira_spa_wellness_treatments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_treatments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_treatments;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_treatments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_treatments;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_treatments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_therapists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_therapists_business_idx ON public.anaira_spa_wellness_therapists(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_therapists ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_therapists;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_therapists FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_therapists;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_therapists FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_rooms_business_idx ON public.anaira_spa_wellness_rooms(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_rooms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_rooms;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_rooms FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_rooms;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_rooms FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_beds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_beds_business_idx ON public.anaira_spa_wellness_beds(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_beds ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_beds;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_beds FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_beds;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_beds FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_appointments_business_idx ON public.anaira_spa_wellness_appointments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_appointments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_appointments;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_appointments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_appointments;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_appointments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_customers_business_idx ON public.anaira_spa_wellness_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_customers;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_customers;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_packages_business_idx ON public.anaira_spa_wellness_packages(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_packages;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_packages FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_packages;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_packages FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_memberships_business_idx ON public.anaira_spa_wellness_memberships(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_memberships ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_memberships;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_memberships FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_memberships;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_memberships FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_products_business_idx ON public.anaira_spa_wellness_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_products;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_products;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_inventory_business_idx ON public.anaira_spa_wellness_inventory(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_inventory;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_inventory FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_inventory;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_inventory FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_payments_business_idx ON public.anaira_spa_wellness_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_payments;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_payments;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_gift_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_gift_cards_business_idx ON public.anaira_spa_wellness_gift_cards(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_gift_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_gift_cards;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_gift_cards FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_gift_cards;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_gift_cards FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_loyalty (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_loyalty_business_idx ON public.anaira_spa_wellness_loyalty(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_loyalty ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_loyalty;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_loyalty FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_loyalty;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_loyalty FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_offers_business_idx ON public.anaira_spa_wellness_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_offers;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_offers;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_reviews_business_idx ON public.anaira_spa_wellness_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_reviews;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_reviews;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_online_booking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_online_booking_business_idx ON public.anaira_spa_wellness_online_booking(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_online_booking ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_online_booking;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_online_booking FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_online_booking;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_online_booking FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_spa_wellness_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_spa_wellness_reports_business_idx ON public.anaira_spa_wellness_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_spa_wellness_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_spa_wellness_reports;
CREATE POLICY tenant_select ON public.anaira_spa_wellness_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_spa_wellness_reports;
CREATE POLICY tenant_write ON public.anaira_spa_wellness_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_departments_business_idx ON public.anaira_clinic_hospital_departments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_departments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_departments;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_departments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_departments;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_departments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_doctors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_doctors_business_idx ON public.anaira_clinic_hospital_doctors(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_doctors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_doctors;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_doctors FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_doctors;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_doctors FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_services_business_idx ON public.anaira_clinic_hospital_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_services;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_services;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_appointments_business_idx ON public.anaira_clinic_hospital_appointments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_appointments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_appointments;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_appointments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_appointments;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_appointments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_patients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_patients_business_idx ON public.anaira_clinic_hospital_patients(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_patients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_patients;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_patients FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_patients;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_patients FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_medical_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_medical_records_business_idx ON public.anaira_clinic_hospital_medical_records(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_medical_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_medical_records;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_medical_records FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_medical_records;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_medical_records FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_prescriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_prescriptions_business_idx ON public.anaira_clinic_hospital_prescriptions(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_prescriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_prescriptions;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_prescriptions FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_prescriptions;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_prescriptions FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_lab (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_lab_business_idx ON public.anaira_clinic_hospital_lab(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_lab ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_lab;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_lab FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_lab;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_lab FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_rooms_business_idx ON public.anaira_clinic_hospital_rooms(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_rooms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_rooms;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_rooms FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_rooms;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_rooms FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_billing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_billing_business_idx ON public.anaira_clinic_hospital_billing(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_billing ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_billing;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_billing FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_billing;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_billing FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_payments_business_idx ON public.anaira_clinic_hospital_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_payments;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_payments;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_insurance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_insurance_business_idx ON public.anaira_clinic_hospital_insurance(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_insurance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_insurance;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_insurance FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_insurance;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_insurance FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_pharmacy (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_pharmacy_business_idx ON public.anaira_clinic_hospital_pharmacy(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_pharmacy ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_pharmacy;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_pharmacy FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_pharmacy;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_pharmacy FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_staff_business_idx ON public.anaira_clinic_hospital_staff(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_staff ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_staff;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_staff FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_staff;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_staff FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_reviews_business_idx ON public.anaira_clinic_hospital_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_reviews;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_reviews;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_reports_business_idx ON public.anaira_clinic_hospital_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_reports;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_reports;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_clinic_hospital_online_booking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_clinic_hospital_online_booking_business_idx ON public.anaira_clinic_hospital_online_booking(business_id,status,created_at DESC);
ALTER TABLE public.anaira_clinic_hospital_online_booking ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_clinic_hospital_online_booking;
CREATE POLICY tenant_select ON public.anaira_clinic_hospital_online_booking FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_clinic_hospital_online_booking;
CREATE POLICY tenant_write ON public.anaira_clinic_hospital_online_booking FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_doctors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_doctors_business_idx ON public.anaira_dentist_doctor_doctors(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_doctors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_doctors;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_doctors FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_doctors;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_doctors FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_specializations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_specializations_business_idx ON public.anaira_dentist_doctor_specializations(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_specializations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_specializations;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_specializations FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_specializations;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_specializations FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_treatments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_treatments_business_idx ON public.anaira_dentist_doctor_treatments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_treatments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_treatments;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_treatments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_treatments;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_treatments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_services_business_idx ON public.anaira_dentist_doctor_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_services;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_services;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_patients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_patients_business_idx ON public.anaira_dentist_doctor_patients(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_patients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_patients;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_patients FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_patients;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_patients FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_appointments_business_idx ON public.anaira_dentist_doctor_appointments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_appointments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_appointments;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_appointments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_appointments;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_appointments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_dental_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_dental_records_business_idx ON public.anaira_dentist_doctor_dental_records(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_dental_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_dental_records;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_dental_records FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_dental_records;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_dental_records FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_prescriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_prescriptions_business_idx ON public.anaira_dentist_doctor_prescriptions(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_prescriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_prescriptions;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_prescriptions FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_prescriptions;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_prescriptions FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_billing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_billing_business_idx ON public.anaira_dentist_doctor_billing(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_billing ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_billing;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_billing FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_billing;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_billing FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_payments_business_idx ON public.anaira_dentist_doctor_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_payments;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_payments;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_followups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_followups_business_idx ON public.anaira_dentist_doctor_followups(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_followups ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_followups;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_followups FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_followups;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_followups FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_reviews_business_idx ON public.anaira_dentist_doctor_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_reviews;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_reviews;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_online_booking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_online_booking_business_idx ON public.anaira_dentist_doctor_online_booking(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_online_booking ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_online_booking;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_online_booking FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_online_booking;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_online_booking FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_dentist_doctor_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_dentist_doctor_reports_business_idx ON public.anaira_dentist_doctor_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_dentist_doctor_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_dentist_doctor_reports;
CREATE POLICY tenant_select ON public.anaira_dentist_doctor_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_dentist_doctor_reports;
CREATE POLICY tenant_write ON public.anaira_dentist_doctor_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_products_business_idx ON public.anaira_pharmacy_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_products;
CREATE POLICY tenant_select ON public.anaira_pharmacy_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_products;
CREATE POLICY tenant_write ON public.anaira_pharmacy_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_categories_business_idx ON public.anaira_pharmacy_categories(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_categories;
CREATE POLICY tenant_select ON public.anaira_pharmacy_categories FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_categories;
CREATE POLICY tenant_write ON public.anaira_pharmacy_categories FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_brands (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_brands_business_idx ON public.anaira_pharmacy_brands(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_brands ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_brands;
CREATE POLICY tenant_select ON public.anaira_pharmacy_brands FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_brands;
CREATE POLICY tenant_write ON public.anaira_pharmacy_brands FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_inventory_business_idx ON public.anaira_pharmacy_inventory(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_inventory;
CREATE POLICY tenant_select ON public.anaira_pharmacy_inventory FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_inventory;
CREATE POLICY tenant_write ON public.anaira_pharmacy_inventory FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_batches_business_idx ON public.anaira_pharmacy_batches(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_batches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_batches;
CREATE POLICY tenant_select ON public.anaira_pharmacy_batches FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_batches;
CREATE POLICY tenant_write ON public.anaira_pharmacy_batches FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_expiry (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_expiry_business_idx ON public.anaira_pharmacy_expiry(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_expiry ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_expiry;
CREATE POLICY tenant_select ON public.anaira_pharmacy_expiry FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_expiry;
CREATE POLICY tenant_write ON public.anaira_pharmacy_expiry FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_suppliers_business_idx ON public.anaira_pharmacy_suppliers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_suppliers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_suppliers;
CREATE POLICY tenant_select ON public.anaira_pharmacy_suppliers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_suppliers;
CREATE POLICY tenant_write ON public.anaira_pharmacy_suppliers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_purchases_business_idx ON public.anaira_pharmacy_purchases(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_purchases ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_purchases;
CREATE POLICY tenant_select ON public.anaira_pharmacy_purchases FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_purchases;
CREATE POLICY tenant_write ON public.anaira_pharmacy_purchases FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_sales_business_idx ON public.anaira_pharmacy_sales(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_sales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_sales;
CREATE POLICY tenant_select ON public.anaira_pharmacy_sales FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_sales;
CREATE POLICY tenant_write ON public.anaira_pharmacy_sales FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_pos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_pos_business_idx ON public.anaira_pharmacy_pos(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_pos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_pos;
CREATE POLICY tenant_select ON public.anaira_pharmacy_pos FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_pos;
CREATE POLICY tenant_write ON public.anaira_pharmacy_pos FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_customers_business_idx ON public.anaira_pharmacy_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_customers;
CREATE POLICY tenant_select ON public.anaira_pharmacy_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_customers;
CREATE POLICY tenant_write ON public.anaira_pharmacy_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_prescriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_prescriptions_business_idx ON public.anaira_pharmacy_prescriptions(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_prescriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_prescriptions;
CREATE POLICY tenant_select ON public.anaira_pharmacy_prescriptions FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_prescriptions;
CREATE POLICY tenant_write ON public.anaira_pharmacy_prescriptions FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_offers_business_idx ON public.anaira_pharmacy_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_offers;
CREATE POLICY tenant_select ON public.anaira_pharmacy_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_offers;
CREATE POLICY tenant_write ON public.anaira_pharmacy_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_loyalty (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_loyalty_business_idx ON public.anaira_pharmacy_loyalty(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_loyalty ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_loyalty;
CREATE POLICY tenant_select ON public.anaira_pharmacy_loyalty FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_loyalty;
CREATE POLICY tenant_write ON public.anaira_pharmacy_loyalty FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_delivery (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_delivery_business_idx ON public.anaira_pharmacy_delivery(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_delivery ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_delivery;
CREATE POLICY tenant_select ON public.anaira_pharmacy_delivery FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_delivery;
CREATE POLICY tenant_write ON public.anaira_pharmacy_delivery FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_payments_business_idx ON public.anaira_pharmacy_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_payments;
CREATE POLICY tenant_select ON public.anaira_pharmacy_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_payments;
CREATE POLICY tenant_write ON public.anaira_pharmacy_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_pharmacy_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_pharmacy_reports_business_idx ON public.anaira_pharmacy_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_pharmacy_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_pharmacy_reports;
CREATE POLICY tenant_select ON public.anaira_pharmacy_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_pharmacy_reports;
CREATE POLICY tenant_write ON public.anaira_pharmacy_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_classes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_classes_business_idx ON public.anaira_gym_yoga_classes(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_classes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_classes;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_classes FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_classes;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_classes FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_trainers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_trainers_business_idx ON public.anaira_gym_yoga_trainers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_trainers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_trainers;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_trainers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_trainers;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_trainers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_members_business_idx ON public.anaira_gym_yoga_members(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_members;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_members FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_members;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_members FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_memberships_business_idx ON public.anaira_gym_yoga_memberships(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_memberships ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_memberships;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_memberships FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_memberships;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_memberships FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_packages_business_idx ON public.anaira_gym_yoga_packages(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_packages;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_packages FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_packages;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_packages FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_schedules_business_idx ON public.anaira_gym_yoga_schedules(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_schedules;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_schedules FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_schedules;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_schedules FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_attendance_business_idx ON public.anaira_gym_yoga_attendance(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_attendance;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_attendance FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_attendance;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_attendance FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_payments_business_idx ON public.anaira_gym_yoga_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_payments;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_payments;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_pos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_pos_business_idx ON public.anaira_gym_yoga_pos(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_pos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_pos;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_pos FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_pos;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_pos FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_products_business_idx ON public.anaira_gym_yoga_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_products;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_products;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_offers_business_idx ON public.anaira_gym_yoga_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_offers;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_offers;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_loyalty (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_loyalty_business_idx ON public.anaira_gym_yoga_loyalty(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_loyalty ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_loyalty;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_loyalty FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_loyalty;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_loyalty FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_customers_business_idx ON public.anaira_gym_yoga_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_customers;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_customers;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_online_booking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_online_booking_business_idx ON public.anaira_gym_yoga_online_booking(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_online_booking ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_online_booking;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_online_booking FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_online_booking;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_online_booking FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_gym_yoga_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_gym_yoga_reports_business_idx ON public.anaira_gym_yoga_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_gym_yoga_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_gym_yoga_reports;
CREATE POLICY tenant_select ON public.anaira_gym_yoga_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_gym_yoga_reports;
CREATE POLICY tenant_write ON public.anaira_gym_yoga_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_categories_business_idx ON public.anaira_retail_grocery_categories(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_categories;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_categories FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_categories;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_categories FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_products_business_idx ON public.anaira_retail_grocery_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_products;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_products;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_brands (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_brands_business_idx ON public.anaira_retail_grocery_brands(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_brands ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_brands;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_brands FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_brands;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_brands FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_inventory_business_idx ON public.anaira_retail_grocery_inventory(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_inventory;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_inventory FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_inventory;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_inventory FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_suppliers_business_idx ON public.anaira_retail_grocery_suppliers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_suppliers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_suppliers;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_suppliers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_suppliers;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_suppliers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_purchases_business_idx ON public.anaira_retail_grocery_purchases(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_purchases ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_purchases;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_purchases FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_purchases;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_purchases FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_pos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_pos_business_idx ON public.anaira_retail_grocery_pos(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_pos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_pos;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_pos FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_pos;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_pos FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_customers_business_idx ON public.anaira_retail_grocery_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_customers;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_customers;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_offers_business_idx ON public.anaira_retail_grocery_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_offers;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_offers;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_coupons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_coupons_business_idx ON public.anaira_retail_grocery_coupons(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_coupons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_coupons;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_coupons FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_coupons;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_coupons FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_loyalty (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_loyalty_business_idx ON public.anaira_retail_grocery_loyalty(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_loyalty ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_loyalty;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_loyalty FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_loyalty;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_loyalty FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_delivery (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_delivery_business_idx ON public.anaira_retail_grocery_delivery(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_delivery ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_delivery;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_delivery FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_delivery;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_delivery FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_orders_business_idx ON public.anaira_retail_grocery_orders(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_orders;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_orders FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_orders;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_orders FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_reviews_business_idx ON public.anaira_retail_grocery_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_reviews;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_reviews;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_payments_business_idx ON public.anaira_retail_grocery_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_payments;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_payments;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_retail_grocery_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_retail_grocery_reports_business_idx ON public.anaira_retail_grocery_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_retail_grocery_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_retail_grocery_reports;
CREATE POLICY tenant_select ON public.anaira_retail_grocery_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_retail_grocery_reports;
CREATE POLICY tenant_write ON public.anaira_retail_grocery_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_collections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_collections_business_idx ON public.anaira_fashion_collections(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_collections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_collections;
CREATE POLICY tenant_select ON public.anaira_fashion_collections FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_collections;
CREATE POLICY tenant_write ON public.anaira_fashion_collections FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_products_business_idx ON public.anaira_fashion_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_products;
CREATE POLICY tenant_select ON public.anaira_fashion_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_products;
CREATE POLICY tenant_write ON public.anaira_fashion_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_categories_business_idx ON public.anaira_fashion_categories(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_categories;
CREATE POLICY tenant_select ON public.anaira_fashion_categories FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_categories;
CREATE POLICY tenant_write ON public.anaira_fashion_categories FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_sizes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_sizes_business_idx ON public.anaira_fashion_sizes(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_sizes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_sizes;
CREATE POLICY tenant_select ON public.anaira_fashion_sizes FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_sizes;
CREATE POLICY tenant_write ON public.anaira_fashion_sizes FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_colors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_colors_business_idx ON public.anaira_fashion_colors(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_colors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_colors;
CREATE POLICY tenant_select ON public.anaira_fashion_colors FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_colors;
CREATE POLICY tenant_write ON public.anaira_fashion_colors FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_variants_business_idx ON public.anaira_fashion_variants(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_variants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_variants;
CREATE POLICY tenant_select ON public.anaira_fashion_variants FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_variants;
CREATE POLICY tenant_write ON public.anaira_fashion_variants FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_inventory_business_idx ON public.anaira_fashion_inventory(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_inventory;
CREATE POLICY tenant_select ON public.anaira_fashion_inventory FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_inventory;
CREATE POLICY tenant_write ON public.anaira_fashion_inventory FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_orders_business_idx ON public.anaira_fashion_orders(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_orders;
CREATE POLICY tenant_select ON public.anaira_fashion_orders FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_orders;
CREATE POLICY tenant_write ON public.anaira_fashion_orders FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_pos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_pos_business_idx ON public.anaira_fashion_pos(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_pos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_pos;
CREATE POLICY tenant_select ON public.anaira_fashion_pos FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_pos;
CREATE POLICY tenant_write ON public.anaira_fashion_pos FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_customers_business_idx ON public.anaira_fashion_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_customers;
CREATE POLICY tenant_select ON public.anaira_fashion_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_customers;
CREATE POLICY tenant_write ON public.anaira_fashion_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_offers_business_idx ON public.anaira_fashion_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_offers;
CREATE POLICY tenant_select ON public.anaira_fashion_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_offers;
CREATE POLICY tenant_write ON public.anaira_fashion_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_coupons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_coupons_business_idx ON public.anaira_fashion_coupons(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_coupons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_coupons;
CREATE POLICY tenant_select ON public.anaira_fashion_coupons FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_coupons;
CREATE POLICY tenant_write ON public.anaira_fashion_coupons FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_wishlist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_wishlist_business_idx ON public.anaira_fashion_wishlist(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_wishlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_wishlist;
CREATE POLICY tenant_select ON public.anaira_fashion_wishlist FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_wishlist;
CREATE POLICY tenant_write ON public.anaira_fashion_wishlist FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_reviews_business_idx ON public.anaira_fashion_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_reviews;
CREATE POLICY tenant_select ON public.anaira_fashion_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_reviews;
CREATE POLICY tenant_write ON public.anaira_fashion_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_payments_business_idx ON public.anaira_fashion_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_payments;
CREATE POLICY tenant_select ON public.anaira_fashion_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_payments;
CREATE POLICY tenant_write ON public.anaira_fashion_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_fashion_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_fashion_reports_business_idx ON public.anaira_fashion_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_fashion_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_fashion_reports;
CREATE POLICY tenant_select ON public.anaira_fashion_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_fashion_reports;
CREATE POLICY tenant_write ON public.anaira_fashion_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_collections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_collections_business_idx ON public.anaira_jewellery_collections(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_collections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_collections;
CREATE POLICY tenant_select ON public.anaira_jewellery_collections FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_collections;
CREATE POLICY tenant_write ON public.anaira_jewellery_collections FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_products_business_idx ON public.anaira_jewellery_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_products;
CREATE POLICY tenant_select ON public.anaira_jewellery_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_products;
CREATE POLICY tenant_write ON public.anaira_jewellery_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_categories_business_idx ON public.anaira_jewellery_categories(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_categories;
CREATE POLICY tenant_select ON public.anaira_jewellery_categories FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_categories;
CREATE POLICY tenant_write ON public.anaira_jewellery_categories FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_materials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_materials_business_idx ON public.anaira_jewellery_materials(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_materials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_materials;
CREATE POLICY tenant_select ON public.anaira_jewellery_materials FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_materials;
CREATE POLICY tenant_write ON public.anaira_jewellery_materials FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_purity (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_purity_business_idx ON public.anaira_jewellery_purity(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_purity ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_purity;
CREATE POLICY tenant_select ON public.anaira_jewellery_purity FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_purity;
CREATE POLICY tenant_write ON public.anaira_jewellery_purity FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_stones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_stones_business_idx ON public.anaira_jewellery_stones(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_stones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_stones;
CREATE POLICY tenant_select ON public.anaira_jewellery_stones FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_stones;
CREATE POLICY tenant_write ON public.anaira_jewellery_stones FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_certificates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_certificates_business_idx ON public.anaira_jewellery_certificates(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_certificates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_certificates;
CREATE POLICY tenant_select ON public.anaira_jewellery_certificates FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_certificates;
CREATE POLICY tenant_write ON public.anaira_jewellery_certificates FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_inventory_business_idx ON public.anaira_jewellery_inventory(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_inventory;
CREATE POLICY tenant_select ON public.anaira_jewellery_inventory FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_inventory;
CREATE POLICY tenant_write ON public.anaira_jewellery_inventory FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_pos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_pos_business_idx ON public.anaira_jewellery_pos(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_pos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_pos;
CREATE POLICY tenant_select ON public.anaira_jewellery_pos FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_pos;
CREATE POLICY tenant_write ON public.anaira_jewellery_pos FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_customers_business_idx ON public.anaira_jewellery_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_customers;
CREATE POLICY tenant_select ON public.anaira_jewellery_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_customers;
CREATE POLICY tenant_write ON public.anaira_jewellery_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_orders_business_idx ON public.anaira_jewellery_orders(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_orders;
CREATE POLICY tenant_select ON public.anaira_jewellery_orders FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_orders;
CREATE POLICY tenant_write ON public.anaira_jewellery_orders FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_wishlist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_wishlist_business_idx ON public.anaira_jewellery_wishlist(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_wishlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_wishlist;
CREATE POLICY tenant_select ON public.anaira_jewellery_wishlist FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_wishlist;
CREATE POLICY tenant_write ON public.anaira_jewellery_wishlist FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_offers_business_idx ON public.anaira_jewellery_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_offers;
CREATE POLICY tenant_select ON public.anaira_jewellery_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_offers;
CREATE POLICY tenant_write ON public.anaira_jewellery_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_reviews_business_idx ON public.anaira_jewellery_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_reviews;
CREATE POLICY tenant_select ON public.anaira_jewellery_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_reviews;
CREATE POLICY tenant_write ON public.anaira_jewellery_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_payments_business_idx ON public.anaira_jewellery_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_payments;
CREATE POLICY tenant_select ON public.anaira_jewellery_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_payments;
CREATE POLICY tenant_write ON public.anaira_jewellery_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_jewellery_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_jewellery_reports_business_idx ON public.anaira_jewellery_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_jewellery_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_jewellery_reports;
CREATE POLICY tenant_select ON public.anaira_jewellery_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_jewellery_reports;
CREATE POLICY tenant_write ON public.anaira_jewellery_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_products_business_idx ON public.anaira_electronics_mobile_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_products;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_products;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_brands (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_brands_business_idx ON public.anaira_electronics_mobile_brands(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_brands ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_brands;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_brands FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_brands;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_brands FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_models (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_models_business_idx ON public.anaira_electronics_mobile_models(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_models ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_models;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_models FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_models;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_models FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_variants_business_idx ON public.anaira_electronics_mobile_variants(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_variants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_variants;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_variants FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_variants;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_variants FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_imei_serials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_imei_serials_business_idx ON public.anaira_electronics_mobile_imei_serials(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_imei_serials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_imei_serials;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_imei_serials FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_imei_serials;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_imei_serials FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_warranty (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_warranty_business_idx ON public.anaira_electronics_mobile_warranty(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_warranty ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_warranty;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_warranty FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_warranty;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_warranty FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_inventory_business_idx ON public.anaira_electronics_mobile_inventory(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_inventory;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_inventory FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_inventory;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_inventory FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_purchases_business_idx ON public.anaira_electronics_mobile_purchases(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_purchases ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_purchases;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_purchases FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_purchases;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_purchases FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_suppliers_business_idx ON public.anaira_electronics_mobile_suppliers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_suppliers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_suppliers;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_suppliers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_suppliers;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_suppliers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_pos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_pos_business_idx ON public.anaira_electronics_mobile_pos(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_pos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_pos;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_pos FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_pos;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_pos FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_customers_business_idx ON public.anaira_electronics_mobile_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_customers;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_customers;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_repairs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_repairs_business_idx ON public.anaira_electronics_mobile_repairs(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_repairs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_repairs;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_repairs FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_repairs;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_repairs FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_offers_business_idx ON public.anaira_electronics_mobile_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_offers;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_offers;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_reviews_business_idx ON public.anaira_electronics_mobile_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_reviews;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_reviews;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_orders_business_idx ON public.anaira_electronics_mobile_orders(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_orders;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_orders FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_orders;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_orders FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_payments_business_idx ON public.anaira_electronics_mobile_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_payments;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_payments;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_electronics_mobile_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_electronics_mobile_reports_business_idx ON public.anaira_electronics_mobile_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_electronics_mobile_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_electronics_mobile_reports;
CREATE POLICY tenant_select ON public.anaira_electronics_mobile_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_electronics_mobile_reports;
CREATE POLICY tenant_write ON public.anaira_electronics_mobile_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_vehicles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_vehicles_business_idx ON public.anaira_automotive_vehicles(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_vehicles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_vehicles;
CREATE POLICY tenant_select ON public.anaira_automotive_vehicles FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_vehicles;
CREATE POLICY tenant_write ON public.anaira_automotive_vehicles FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_services_business_idx ON public.anaira_automotive_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_services;
CREATE POLICY tenant_select ON public.anaira_automotive_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_services;
CREATE POLICY tenant_write ON public.anaira_automotive_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_technicians (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_technicians_business_idx ON public.anaira_automotive_technicians(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_technicians ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_technicians;
CREATE POLICY tenant_select ON public.anaira_automotive_technicians FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_technicians;
CREATE POLICY tenant_write ON public.anaira_automotive_technicians FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_appointments_business_idx ON public.anaira_automotive_appointments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_appointments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_appointments;
CREATE POLICY tenant_select ON public.anaira_automotive_appointments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_appointments;
CREATE POLICY tenant_write ON public.anaira_automotive_appointments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_customers_business_idx ON public.anaira_automotive_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_customers;
CREATE POLICY tenant_select ON public.anaira_automotive_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_customers;
CREATE POLICY tenant_write ON public.anaira_automotive_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_vehicle_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_vehicle_records_business_idx ON public.anaira_automotive_vehicle_records(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_vehicle_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_vehicle_records;
CREATE POLICY tenant_select ON public.anaira_automotive_vehicle_records FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_vehicle_records;
CREATE POLICY tenant_write ON public.anaira_automotive_vehicle_records FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_parts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_parts_business_idx ON public.anaira_automotive_parts(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_parts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_parts;
CREATE POLICY tenant_select ON public.anaira_automotive_parts FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_parts;
CREATE POLICY tenant_write ON public.anaira_automotive_parts FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_inventory_business_idx ON public.anaira_automotive_inventory(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_inventory;
CREATE POLICY tenant_select ON public.anaira_automotive_inventory FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_inventory;
CREATE POLICY tenant_write ON public.anaira_automotive_inventory FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_job_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_job_cards_business_idx ON public.anaira_automotive_job_cards(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_job_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_job_cards;
CREATE POLICY tenant_select ON public.anaira_automotive_job_cards FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_job_cards;
CREATE POLICY tenant_write ON public.anaira_automotive_job_cards FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_estimates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_estimates_business_idx ON public.anaira_automotive_estimates(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_estimates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_estimates;
CREATE POLICY tenant_select ON public.anaira_automotive_estimates FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_estimates;
CREATE POLICY tenant_write ON public.anaira_automotive_estimates FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_invoices_business_idx ON public.anaira_automotive_invoices(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_invoices;
CREATE POLICY tenant_select ON public.anaira_automotive_invoices FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_invoices;
CREATE POLICY tenant_write ON public.anaira_automotive_invoices FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_payments_business_idx ON public.anaira_automotive_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_payments;
CREATE POLICY tenant_select ON public.anaira_automotive_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_payments;
CREATE POLICY tenant_write ON public.anaira_automotive_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_service_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_service_history_business_idx ON public.anaira_automotive_service_history(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_service_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_service_history;
CREATE POLICY tenant_select ON public.anaira_automotive_service_history FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_service_history;
CREATE POLICY tenant_write ON public.anaira_automotive_service_history FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_offers_business_idx ON public.anaira_automotive_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_offers;
CREATE POLICY tenant_select ON public.anaira_automotive_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_offers;
CREATE POLICY tenant_write ON public.anaira_automotive_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_reviews_business_idx ON public.anaira_automotive_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_reviews;
CREATE POLICY tenant_select ON public.anaira_automotive_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_reviews;
CREATE POLICY tenant_write ON public.anaira_automotive_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_automotive_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_automotive_reports_business_idx ON public.anaira_automotive_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_automotive_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_automotive_reports;
CREATE POLICY tenant_select ON public.anaira_automotive_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_automotive_reports;
CREATE POLICY tenant_write ON public.anaira_automotive_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_properties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_properties_business_idx ON public.anaira_real_estate_properties(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_properties ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_properties;
CREATE POLICY tenant_select ON public.anaira_real_estate_properties FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_properties;
CREATE POLICY tenant_write ON public.anaira_real_estate_properties FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_property_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_property_types_business_idx ON public.anaira_real_estate_property_types(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_property_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_property_types;
CREATE POLICY tenant_select ON public.anaira_real_estate_property_types FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_property_types;
CREATE POLICY tenant_write ON public.anaira_real_estate_property_types FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_locations_business_idx ON public.anaira_real_estate_locations(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_locations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_locations;
CREATE POLICY tenant_select ON public.anaira_real_estate_locations FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_locations;
CREATE POLICY tenant_write ON public.anaira_real_estate_locations FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_agents_business_idx ON public.anaira_real_estate_agents(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_agents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_agents;
CREATE POLICY tenant_select ON public.anaira_real_estate_agents FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_agents;
CREATE POLICY tenant_write ON public.anaira_real_estate_agents FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_leads_business_idx ON public.anaira_real_estate_leads(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_leads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_leads;
CREATE POLICY tenant_select ON public.anaira_real_estate_leads FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_leads;
CREATE POLICY tenant_write ON public.anaira_real_estate_leads FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_enquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_enquiries_business_idx ON public.anaira_real_estate_enquiries(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_enquiries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_enquiries;
CREATE POLICY tenant_select ON public.anaira_real_estate_enquiries FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_enquiries;
CREATE POLICY tenant_write ON public.anaira_real_estate_enquiries FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_viewings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_viewings_business_idx ON public.anaira_real_estate_viewings(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_viewings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_viewings;
CREATE POLICY tenant_select ON public.anaira_real_estate_viewings FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_viewings;
CREATE POLICY tenant_write ON public.anaira_real_estate_viewings FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_bookings_business_idx ON public.anaira_real_estate_bookings(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_bookings;
CREATE POLICY tenant_select ON public.anaira_real_estate_bookings FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_bookings;
CREATE POLICY tenant_write ON public.anaira_real_estate_bookings FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_listings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_listings_business_idx ON public.anaira_real_estate_listings(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_listings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_listings;
CREATE POLICY tenant_select ON public.anaira_real_estate_listings FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_listings;
CREATE POLICY tenant_write ON public.anaira_real_estate_listings FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_amenities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_amenities_business_idx ON public.anaira_real_estate_amenities(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_amenities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_amenities;
CREATE POLICY tenant_select ON public.anaira_real_estate_amenities FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_amenities;
CREATE POLICY tenant_write ON public.anaira_real_estate_amenities FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_documents_business_idx ON public.anaira_real_estate_documents(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_documents;
CREATE POLICY tenant_select ON public.anaira_real_estate_documents FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_documents;
CREATE POLICY tenant_write ON public.anaira_real_estate_documents FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_offers_business_idx ON public.anaira_real_estate_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_offers;
CREATE POLICY tenant_select ON public.anaira_real_estate_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_offers;
CREATE POLICY tenant_write ON public.anaira_real_estate_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_customers_business_idx ON public.anaira_real_estate_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_customers;
CREATE POLICY tenant_select ON public.anaira_real_estate_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_customers;
CREATE POLICY tenant_write ON public.anaira_real_estate_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_real_estate_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_real_estate_reports_business_idx ON public.anaira_real_estate_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_real_estate_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_real_estate_reports;
CREATE POLICY tenant_select ON public.anaira_real_estate_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_real_estate_reports;
CREATE POLICY tenant_write ON public.anaira_real_estate_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_destinations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_destinations_business_idx ON public.anaira_travel_destinations(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_destinations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_destinations;
CREATE POLICY tenant_select ON public.anaira_travel_destinations FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_destinations;
CREATE POLICY tenant_write ON public.anaira_travel_destinations FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_tours (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_tours_business_idx ON public.anaira_travel_tours(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_tours ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_tours;
CREATE POLICY tenant_select ON public.anaira_travel_tours FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_tours;
CREATE POLICY tenant_write ON public.anaira_travel_tours FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_packages_business_idx ON public.anaira_travel_packages(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_packages;
CREATE POLICY tenant_select ON public.anaira_travel_packages FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_packages;
CREATE POLICY tenant_write ON public.anaira_travel_packages FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_hotels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_hotels_business_idx ON public.anaira_travel_hotels(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_hotels ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_hotels;
CREATE POLICY tenant_select ON public.anaira_travel_hotels FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_hotels;
CREATE POLICY tenant_write ON public.anaira_travel_hotels FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_activities_business_idx ON public.anaira_travel_activities(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_activities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_activities;
CREATE POLICY tenant_select ON public.anaira_travel_activities FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_activities;
CREATE POLICY tenant_write ON public.anaira_travel_activities FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_vehicles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_vehicles_business_idx ON public.anaira_travel_vehicles(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_vehicles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_vehicles;
CREATE POLICY tenant_select ON public.anaira_travel_vehicles FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_vehicles;
CREATE POLICY tenant_write ON public.anaira_travel_vehicles FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_agents_business_idx ON public.anaira_travel_agents(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_agents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_agents;
CREATE POLICY tenant_select ON public.anaira_travel_agents FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_agents;
CREATE POLICY tenant_write ON public.anaira_travel_agents FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_bookings_business_idx ON public.anaira_travel_bookings(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_bookings;
CREATE POLICY tenant_select ON public.anaira_travel_bookings FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_bookings;
CREATE POLICY tenant_write ON public.anaira_travel_bookings FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_customers_business_idx ON public.anaira_travel_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_customers;
CREATE POLICY tenant_select ON public.anaira_travel_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_customers;
CREATE POLICY tenant_write ON public.anaira_travel_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_payments_business_idx ON public.anaira_travel_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_payments;
CREATE POLICY tenant_select ON public.anaira_travel_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_payments;
CREATE POLICY tenant_write ON public.anaira_travel_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_offers_business_idx ON public.anaira_travel_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_offers;
CREATE POLICY tenant_select ON public.anaira_travel_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_offers;
CREATE POLICY tenant_write ON public.anaira_travel_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_reviews_business_idx ON public.anaira_travel_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_reviews;
CREATE POLICY tenant_select ON public.anaira_travel_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_reviews;
CREATE POLICY tenant_write ON public.anaira_travel_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_gallery (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_gallery_business_idx ON public.anaira_travel_gallery(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_gallery ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_gallery;
CREATE POLICY tenant_select ON public.anaira_travel_gallery FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_gallery;
CREATE POLICY tenant_write ON public.anaira_travel_gallery FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_travel_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_travel_reports_business_idx ON public.anaira_travel_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_travel_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_travel_reports;
CREATE POLICY tenant_select ON public.anaira_travel_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_travel_reports;
CREATE POLICY tenant_write ON public.anaira_travel_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_courses_business_idx ON public.anaira_education_coaching_courses(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_courses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_courses;
CREATE POLICY tenant_select ON public.anaira_education_coaching_courses FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_courses;
CREATE POLICY tenant_write ON public.anaira_education_coaching_courses FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_programs_business_idx ON public.anaira_education_coaching_programs(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_programs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_programs;
CREATE POLICY tenant_select ON public.anaira_education_coaching_programs FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_programs;
CREATE POLICY tenant_write ON public.anaira_education_coaching_programs FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_teachers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_teachers_business_idx ON public.anaira_education_coaching_teachers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_teachers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_teachers;
CREATE POLICY tenant_select ON public.anaira_education_coaching_teachers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_teachers;
CREATE POLICY tenant_write ON public.anaira_education_coaching_teachers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_students (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_students_business_idx ON public.anaira_education_coaching_students(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_students ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_students;
CREATE POLICY tenant_select ON public.anaira_education_coaching_students FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_students;
CREATE POLICY tenant_write ON public.anaira_education_coaching_students FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_batches_business_idx ON public.anaira_education_coaching_batches(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_batches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_batches;
CREATE POLICY tenant_select ON public.anaira_education_coaching_batches FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_batches;
CREATE POLICY tenant_write ON public.anaira_education_coaching_batches FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_class_schedule (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_class_schedule_business_idx ON public.anaira_education_coaching_class_schedule(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_class_schedule ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_class_schedule;
CREATE POLICY tenant_select ON public.anaira_education_coaching_class_schedule FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_class_schedule;
CREATE POLICY tenant_write ON public.anaira_education_coaching_class_schedule FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_admissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_admissions_business_idx ON public.anaira_education_coaching_admissions(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_admissions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_admissions;
CREATE POLICY tenant_select ON public.anaira_education_coaching_admissions FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_admissions;
CREATE POLICY tenant_write ON public.anaira_education_coaching_admissions FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_attendance_business_idx ON public.anaira_education_coaching_attendance(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_attendance;
CREATE POLICY tenant_select ON public.anaira_education_coaching_attendance FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_attendance;
CREATE POLICY tenant_write ON public.anaira_education_coaching_attendance FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_fees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_fees_business_idx ON public.anaira_education_coaching_fees(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_fees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_fees;
CREATE POLICY tenant_select ON public.anaira_education_coaching_fees FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_fees;
CREATE POLICY tenant_write ON public.anaira_education_coaching_fees FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_exams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_exams_business_idx ON public.anaira_education_coaching_exams(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_exams ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_exams;
CREATE POLICY tenant_select ON public.anaira_education_coaching_exams FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_exams;
CREATE POLICY tenant_write ON public.anaira_education_coaching_exams FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_certificates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_certificates_business_idx ON public.anaira_education_coaching_certificates(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_certificates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_certificates;
CREATE POLICY tenant_select ON public.anaira_education_coaching_certificates FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_certificates;
CREATE POLICY tenant_write ON public.anaira_education_coaching_certificates FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_events_business_idx ON public.anaira_education_coaching_events(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_events;
CREATE POLICY tenant_select ON public.anaira_education_coaching_events FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_events;
CREATE POLICY tenant_write ON public.anaira_education_coaching_events FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_offers_business_idx ON public.anaira_education_coaching_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_offers;
CREATE POLICY tenant_select ON public.anaira_education_coaching_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_offers;
CREATE POLICY tenant_write ON public.anaira_education_coaching_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_payments_business_idx ON public.anaira_education_coaching_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_payments;
CREATE POLICY tenant_select ON public.anaira_education_coaching_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_payments;
CREATE POLICY tenant_write ON public.anaira_education_coaching_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_education_coaching_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_education_coaching_reports_business_idx ON public.anaira_education_coaching_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_education_coaching_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_education_coaching_reports;
CREATE POLICY tenant_select ON public.anaira_education_coaching_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_education_coaching_reports;
CREATE POLICY tenant_write ON public.anaira_education_coaching_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_lawyers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_lawyers_business_idx ON public.anaira_legal_lawyers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_lawyers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_lawyers;
CREATE POLICY tenant_select ON public.anaira_legal_lawyers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_lawyers;
CREATE POLICY tenant_write ON public.anaira_legal_lawyers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_practice_areas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_practice_areas_business_idx ON public.anaira_legal_practice_areas(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_practice_areas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_practice_areas;
CREATE POLICY tenant_select ON public.anaira_legal_practice_areas FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_practice_areas;
CREATE POLICY tenant_write ON public.anaira_legal_practice_areas FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_services_business_idx ON public.anaira_legal_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_services;
CREATE POLICY tenant_select ON public.anaira_legal_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_services;
CREATE POLICY tenant_write ON public.anaira_legal_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_clients_business_idx ON public.anaira_legal_clients(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_clients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_clients;
CREATE POLICY tenant_select ON public.anaira_legal_clients FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_clients;
CREATE POLICY tenant_write ON public.anaira_legal_clients FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_leads_business_idx ON public.anaira_legal_leads(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_leads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_leads;
CREATE POLICY tenant_select ON public.anaira_legal_leads FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_leads;
CREATE POLICY tenant_write ON public.anaira_legal_leads FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_cases_business_idx ON public.anaira_legal_cases(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_cases ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_cases;
CREATE POLICY tenant_select ON public.anaira_legal_cases FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_cases;
CREATE POLICY tenant_write ON public.anaira_legal_cases FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_documents_business_idx ON public.anaira_legal_documents(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_documents;
CREATE POLICY tenant_select ON public.anaira_legal_documents FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_documents;
CREATE POLICY tenant_write ON public.anaira_legal_documents FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_appointments_business_idx ON public.anaira_legal_appointments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_appointments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_appointments;
CREATE POLICY tenant_select ON public.anaira_legal_appointments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_appointments;
CREATE POLICY tenant_write ON public.anaira_legal_appointments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_billing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_billing_business_idx ON public.anaira_legal_billing(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_billing ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_billing;
CREATE POLICY tenant_select ON public.anaira_legal_billing FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_billing;
CREATE POLICY tenant_write ON public.anaira_legal_billing FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_payments_business_idx ON public.anaira_legal_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_payments;
CREATE POLICY tenant_select ON public.anaira_legal_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_payments;
CREATE POLICY tenant_write ON public.anaira_legal_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_tasks_business_idx ON public.anaira_legal_tasks(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_tasks;
CREATE POLICY tenant_select ON public.anaira_legal_tasks FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_tasks;
CREATE POLICY tenant_write ON public.anaira_legal_tasks FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_testimonials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_testimonials_business_idx ON public.anaira_legal_testimonials(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_testimonials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_testimonials;
CREATE POLICY tenant_select ON public.anaira_legal_testimonials FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_testimonials;
CREATE POLICY tenant_write ON public.anaira_legal_testimonials FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_legal_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_legal_reports_business_idx ON public.anaira_legal_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_legal_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_legal_reports;
CREATE POLICY tenant_select ON public.anaira_legal_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_legal_reports;
CREATE POLICY tenant_write ON public.anaira_legal_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_services_business_idx ON public.anaira_ca_accounting_tax_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_services;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_services;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_team (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_team_business_idx ON public.anaira_ca_accounting_tax_team(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_team ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_team;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_team FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_team;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_team FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_clients_business_idx ON public.anaira_ca_accounting_tax_clients(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_clients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_clients;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_clients FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_clients;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_clients FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_leads_business_idx ON public.anaira_ca_accounting_tax_leads(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_leads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_leads;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_leads FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_leads;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_leads FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_assignments_business_idx ON public.anaira_ca_accounting_tax_assignments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_assignments;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_assignments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_assignments;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_assignments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_documents_business_idx ON public.anaira_ca_accounting_tax_documents(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_documents;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_documents FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_documents;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_documents FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_compliance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_compliance_business_idx ON public.anaira_ca_accounting_tax_compliance(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_compliance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_compliance;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_compliance FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_compliance;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_compliance FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_deadlines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_deadlines_business_idx ON public.anaira_ca_accounting_tax_deadlines(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_deadlines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_deadlines;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_deadlines FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_deadlines;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_deadlines FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_invoices_business_idx ON public.anaira_ca_accounting_tax_invoices(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_invoices;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_invoices FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_invoices;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_invoices FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_payments_business_idx ON public.anaira_ca_accounting_tax_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_payments;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_payments;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_tasks_business_idx ON public.anaira_ca_accounting_tax_tasks(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_tasks;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_tasks FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_tasks;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_tasks FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ca_accounting_tax_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ca_accounting_tax_reports_business_idx ON public.anaira_ca_accounting_tax_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ca_accounting_tax_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ca_accounting_tax_reports;
CREATE POLICY tenant_select ON public.anaira_ca_accounting_tax_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ca_accounting_tax_reports;
CREATE POLICY tenant_write ON public.anaira_ca_accounting_tax_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_services_business_idx ON public.anaira_it_agency_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_services;
CREATE POLICY tenant_select ON public.anaira_it_agency_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_services;
CREATE POLICY tenant_write ON public.anaira_it_agency_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_team (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_team_business_idx ON public.anaira_it_agency_team(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_team ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_team;
CREATE POLICY tenant_select ON public.anaira_it_agency_team FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_team;
CREATE POLICY tenant_write ON public.anaira_it_agency_team FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_projects_business_idx ON public.anaira_it_agency_projects(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_projects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_projects;
CREATE POLICY tenant_select ON public.anaira_it_agency_projects FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_projects;
CREATE POLICY tenant_write ON public.anaira_it_agency_projects FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_portfolio (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_portfolio_business_idx ON public.anaira_it_agency_portfolio(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_portfolio ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_portfolio;
CREATE POLICY tenant_select ON public.anaira_it_agency_portfolio FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_portfolio;
CREATE POLICY tenant_write ON public.anaira_it_agency_portfolio FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_clients_business_idx ON public.anaira_it_agency_clients(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_clients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_clients;
CREATE POLICY tenant_select ON public.anaira_it_agency_clients FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_clients;
CREATE POLICY tenant_write ON public.anaira_it_agency_clients FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_leads_business_idx ON public.anaira_it_agency_leads(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_leads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_leads;
CREATE POLICY tenant_select ON public.anaira_it_agency_leads FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_leads;
CREATE POLICY tenant_write ON public.anaira_it_agency_leads FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_proposals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_proposals_business_idx ON public.anaira_it_agency_proposals(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_proposals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_proposals;
CREATE POLICY tenant_select ON public.anaira_it_agency_proposals FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_proposals;
CREATE POLICY tenant_write ON public.anaira_it_agency_proposals FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_packages_business_idx ON public.anaira_it_agency_packages(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_packages;
CREATE POLICY tenant_select ON public.anaira_it_agency_packages FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_packages;
CREATE POLICY tenant_write ON public.anaira_it_agency_packages FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_pricing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_pricing_business_idx ON public.anaira_it_agency_pricing(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_pricing ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_pricing;
CREATE POLICY tenant_select ON public.anaira_it_agency_pricing FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_pricing;
CREATE POLICY tenant_write ON public.anaira_it_agency_pricing FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_tasks_business_idx ON public.anaira_it_agency_tasks(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_tasks;
CREATE POLICY tenant_select ON public.anaira_it_agency_tasks FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_tasks;
CREATE POLICY tenant_write ON public.anaira_it_agency_tasks FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_invoices_business_idx ON public.anaira_it_agency_invoices(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_invoices;
CREATE POLICY tenant_select ON public.anaira_it_agency_invoices FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_invoices;
CREATE POLICY tenant_write ON public.anaira_it_agency_invoices FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_payments_business_idx ON public.anaira_it_agency_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_payments;
CREATE POLICY tenant_select ON public.anaira_it_agency_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_payments;
CREATE POLICY tenant_write ON public.anaira_it_agency_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_testimonials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_testimonials_business_idx ON public.anaira_it_agency_testimonials(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_testimonials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_testimonials;
CREATE POLICY tenant_select ON public.anaira_it_agency_testimonials FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_testimonials;
CREATE POLICY tenant_write ON public.anaira_it_agency_testimonials FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_case_studies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_case_studies_business_idx ON public.anaira_it_agency_case_studies(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_case_studies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_case_studies;
CREATE POLICY tenant_select ON public.anaira_it_agency_case_studies FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_case_studies;
CREATE POLICY tenant_write ON public.anaira_it_agency_case_studies FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_it_agency_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_it_agency_reports_business_idx ON public.anaira_it_agency_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_it_agency_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_it_agency_reports;
CREATE POLICY tenant_select ON public.anaira_it_agency_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_it_agency_reports;
CREATE POLICY tenant_write ON public.anaira_it_agency_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_services_business_idx ON public.anaira_repair_maintenance_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_services;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_services;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_technicians (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_technicians_business_idx ON public.anaira_repair_maintenance_technicians(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_technicians ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_technicians;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_technicians FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_technicians;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_technicians FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_customers_business_idx ON public.anaira_repair_maintenance_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_customers;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_customers;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_assets_business_idx ON public.anaira_repair_maintenance_assets(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_assets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_assets;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_assets FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_assets;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_assets FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_jobs_business_idx ON public.anaira_repair_maintenance_jobs(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_jobs;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_jobs FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_jobs;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_jobs FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_job_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_job_cards_business_idx ON public.anaira_repair_maintenance_job_cards(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_job_cards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_job_cards;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_job_cards FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_job_cards;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_job_cards FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_appointments_business_idx ON public.anaira_repair_maintenance_appointments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_appointments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_appointments;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_appointments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_appointments;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_appointments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_parts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_parts_business_idx ON public.anaira_repair_maintenance_parts(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_parts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_parts;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_parts FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_parts;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_parts FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_inventory_business_idx ON public.anaira_repair_maintenance_inventory(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_inventory;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_inventory FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_inventory;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_inventory FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_estimates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_estimates_business_idx ON public.anaira_repair_maintenance_estimates(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_estimates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_estimates;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_estimates FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_estimates;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_estimates FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_invoices_business_idx ON public.anaira_repair_maintenance_invoices(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_invoices;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_invoices FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_invoices;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_invoices FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_payments_business_idx ON public.anaira_repair_maintenance_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_payments;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_payments;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_service_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_service_history_business_idx ON public.anaira_repair_maintenance_service_history(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_service_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_service_history;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_service_history FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_service_history;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_service_history FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_reviews_business_idx ON public.anaira_repair_maintenance_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_reviews;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_reviews;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_repair_maintenance_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_repair_maintenance_reports_business_idx ON public.anaira_repair_maintenance_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_repair_maintenance_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_repair_maintenance_reports;
CREATE POLICY tenant_select ON public.anaira_repair_maintenance_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_repair_maintenance_reports;
CREATE POLICY tenant_write ON public.anaira_repair_maintenance_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_services_business_idx ON public.anaira_cleaning_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_services;
CREATE POLICY tenant_select ON public.anaira_cleaning_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_services;
CREATE POLICY tenant_write ON public.anaira_cleaning_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_packages_business_idx ON public.anaira_cleaning_packages(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_packages;
CREATE POLICY tenant_select ON public.anaira_cleaning_packages FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_packages;
CREATE POLICY tenant_write ON public.anaira_cleaning_packages FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_staff_business_idx ON public.anaira_cleaning_staff(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_staff ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_staff;
CREATE POLICY tenant_select ON public.anaira_cleaning_staff FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_staff;
CREATE POLICY tenant_write ON public.anaira_cleaning_staff FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_service_areas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_service_areas_business_idx ON public.anaira_cleaning_service_areas(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_service_areas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_service_areas;
CREATE POLICY tenant_select ON public.anaira_cleaning_service_areas FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_service_areas;
CREATE POLICY tenant_write ON public.anaira_cleaning_service_areas FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_bookings_business_idx ON public.anaira_cleaning_bookings(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_bookings;
CREATE POLICY tenant_select ON public.anaira_cleaning_bookings FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_bookings;
CREATE POLICY tenant_write ON public.anaira_cleaning_bookings FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_customers_business_idx ON public.anaira_cleaning_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_customers;
CREATE POLICY tenant_select ON public.anaira_cleaning_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_customers;
CREATE POLICY tenant_write ON public.anaira_cleaning_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_recurring_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_recurring_jobs_business_idx ON public.anaira_cleaning_recurring_jobs(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_recurring_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_recurring_jobs;
CREATE POLICY tenant_select ON public.anaira_cleaning_recurring_jobs FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_recurring_jobs;
CREATE POLICY tenant_write ON public.anaira_cleaning_recurring_jobs FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_schedules_business_idx ON public.anaira_cleaning_schedules(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_schedules;
CREATE POLICY tenant_select ON public.anaira_cleaning_schedules FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_schedules;
CREATE POLICY tenant_write ON public.anaira_cleaning_schedules FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_pricing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_pricing_business_idx ON public.anaira_cleaning_pricing(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_pricing ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_pricing;
CREATE POLICY tenant_select ON public.anaira_cleaning_pricing FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_pricing;
CREATE POLICY tenant_write ON public.anaira_cleaning_pricing FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_addons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_addons_business_idx ON public.anaira_cleaning_addons(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_addons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_addons;
CREATE POLICY tenant_select ON public.anaira_cleaning_addons FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_addons;
CREATE POLICY tenant_write ON public.anaira_cleaning_addons FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_invoices_business_idx ON public.anaira_cleaning_invoices(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_invoices;
CREATE POLICY tenant_select ON public.anaira_cleaning_invoices FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_invoices;
CREATE POLICY tenant_write ON public.anaira_cleaning_invoices FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_payments_business_idx ON public.anaira_cleaning_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_payments;
CREATE POLICY tenant_select ON public.anaira_cleaning_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_payments;
CREATE POLICY tenant_write ON public.anaira_cleaning_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_reviews_business_idx ON public.anaira_cleaning_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_reviews;
CREATE POLICY tenant_select ON public.anaira_cleaning_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_reviews;
CREATE POLICY tenant_write ON public.anaira_cleaning_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_online_booking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_online_booking_business_idx ON public.anaira_cleaning_online_booking(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_online_booking ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_online_booking;
CREATE POLICY tenant_select ON public.anaira_cleaning_online_booking FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_online_booking;
CREATE POLICY tenant_write ON public.anaira_cleaning_online_booking FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_cleaning_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_cleaning_reports_business_idx ON public.anaira_cleaning_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_cleaning_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_cleaning_reports;
CREATE POLICY tenant_select ON public.anaira_cleaning_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_cleaning_reports;
CREATE POLICY tenant_write ON public.anaira_cleaning_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_veterinarians (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_veterinarians_business_idx ON public.anaira_veterinary_veterinarians(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_veterinarians ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_veterinarians;
CREATE POLICY tenant_select ON public.anaira_veterinary_veterinarians FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_veterinarians;
CREATE POLICY tenant_write ON public.anaira_veterinary_veterinarians FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_services_business_idx ON public.anaira_veterinary_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_services;
CREATE POLICY tenant_select ON public.anaira_veterinary_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_services;
CREATE POLICY tenant_write ON public.anaira_veterinary_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_pets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_pets_business_idx ON public.anaira_veterinary_pets(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_pets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_pets;
CREATE POLICY tenant_select ON public.anaira_veterinary_pets FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_pets;
CREATE POLICY tenant_write ON public.anaira_veterinary_pets FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_pet_owners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_pet_owners_business_idx ON public.anaira_veterinary_pet_owners(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_pet_owners ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_pet_owners;
CREATE POLICY tenant_select ON public.anaira_veterinary_pet_owners FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_pet_owners;
CREATE POLICY tenant_write ON public.anaira_veterinary_pet_owners FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_appointments_business_idx ON public.anaira_veterinary_appointments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_appointments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_appointments;
CREATE POLICY tenant_select ON public.anaira_veterinary_appointments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_appointments;
CREATE POLICY tenant_write ON public.anaira_veterinary_appointments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_medical_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_medical_records_business_idx ON public.anaira_veterinary_medical_records(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_medical_records ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_medical_records;
CREATE POLICY tenant_select ON public.anaira_veterinary_medical_records FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_medical_records;
CREATE POLICY tenant_write ON public.anaira_veterinary_medical_records FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_vaccinations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_vaccinations_business_idx ON public.anaira_veterinary_vaccinations(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_vaccinations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_vaccinations;
CREATE POLICY tenant_select ON public.anaira_veterinary_vaccinations FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_vaccinations;
CREATE POLICY tenant_write ON public.anaira_veterinary_vaccinations FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_prescriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_prescriptions_business_idx ON public.anaira_veterinary_prescriptions(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_prescriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_prescriptions;
CREATE POLICY tenant_select ON public.anaira_veterinary_prescriptions FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_prescriptions;
CREATE POLICY tenant_write ON public.anaira_veterinary_prescriptions FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_pharmacy (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_pharmacy_business_idx ON public.anaira_veterinary_pharmacy(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_pharmacy ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_pharmacy;
CREATE POLICY tenant_select ON public.anaira_veterinary_pharmacy FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_pharmacy;
CREATE POLICY tenant_write ON public.anaira_veterinary_pharmacy FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_billing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_billing_business_idx ON public.anaira_veterinary_billing(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_billing ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_billing;
CREATE POLICY tenant_select ON public.anaira_veterinary_billing FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_billing;
CREATE POLICY tenant_write ON public.anaira_veterinary_billing FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_payments_business_idx ON public.anaira_veterinary_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_payments;
CREATE POLICY tenant_select ON public.anaira_veterinary_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_payments;
CREATE POLICY tenant_write ON public.anaira_veterinary_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_followups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_followups_business_idx ON public.anaira_veterinary_followups(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_followups ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_followups;
CREATE POLICY tenant_select ON public.anaira_veterinary_followups FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_followups;
CREATE POLICY tenant_write ON public.anaira_veterinary_followups FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_reviews_business_idx ON public.anaira_veterinary_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_reviews;
CREATE POLICY tenant_select ON public.anaira_veterinary_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_reviews;
CREATE POLICY tenant_write ON public.anaira_veterinary_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_veterinary_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_veterinary_reports_business_idx ON public.anaira_veterinary_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_veterinary_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_veterinary_reports;
CREATE POLICY tenant_select ON public.anaira_veterinary_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_veterinary_reports;
CREATE POLICY tenant_write ON public.anaira_veterinary_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_services_business_idx ON public.anaira_photography_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_services;
CREATE POLICY tenant_select ON public.anaira_photography_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_services;
CREATE POLICY tenant_write ON public.anaira_photography_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_packages_business_idx ON public.anaira_photography_packages(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_packages;
CREATE POLICY tenant_select ON public.anaira_photography_packages FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_packages;
CREATE POLICY tenant_write ON public.anaira_photography_packages FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_portfolio (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_portfolio_business_idx ON public.anaira_photography_portfolio(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_portfolio ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_portfolio;
CREATE POLICY tenant_select ON public.anaira_photography_portfolio FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_portfolio;
CREATE POLICY tenant_write ON public.anaira_photography_portfolio FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_albums (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_albums_business_idx ON public.anaira_photography_albums(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_albums ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_albums;
CREATE POLICY tenant_select ON public.anaira_photography_albums FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_albums;
CREATE POLICY tenant_write ON public.anaira_photography_albums FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_photographers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_photographers_business_idx ON public.anaira_photography_photographers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_photographers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_photographers;
CREATE POLICY tenant_select ON public.anaira_photography_photographers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_photographers;
CREATE POLICY tenant_write ON public.anaira_photography_photographers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_availability (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_availability_business_idx ON public.anaira_photography_availability(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_availability ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_availability;
CREATE POLICY tenant_select ON public.anaira_photography_availability FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_availability;
CREATE POLICY tenant_write ON public.anaira_photography_availability FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_bookings_business_idx ON public.anaira_photography_bookings(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_bookings;
CREATE POLICY tenant_select ON public.anaira_photography_bookings FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_bookings;
CREATE POLICY tenant_write ON public.anaira_photography_bookings FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_clients_business_idx ON public.anaira_photography_clients(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_clients ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_clients;
CREATE POLICY tenant_select ON public.anaira_photography_clients FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_clients;
CREATE POLICY tenant_write ON public.anaira_photography_clients FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_contracts_business_idx ON public.anaira_photography_contracts(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_contracts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_contracts;
CREATE POLICY tenant_select ON public.anaira_photography_contracts FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_contracts;
CREATE POLICY tenant_write ON public.anaira_photography_contracts FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_invoices_business_idx ON public.anaira_photography_invoices(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_invoices;
CREATE POLICY tenant_select ON public.anaira_photography_invoices FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_invoices;
CREATE POLICY tenant_write ON public.anaira_photography_invoices FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_payments_business_idx ON public.anaira_photography_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_payments;
CREATE POLICY tenant_select ON public.anaira_photography_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_payments;
CREATE POLICY tenant_write ON public.anaira_photography_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_gallery (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_gallery_business_idx ON public.anaira_photography_gallery(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_gallery ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_gallery;
CREATE POLICY tenant_select ON public.anaira_photography_gallery FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_gallery;
CREATE POLICY tenant_write ON public.anaira_photography_gallery FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_testimonials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_testimonials_business_idx ON public.anaira_photography_testimonials(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_testimonials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_testimonials;
CREATE POLICY tenant_select ON public.anaira_photography_testimonials FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_testimonials;
CREATE POLICY tenant_write ON public.anaira_photography_testimonials FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_photography_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_photography_reports_business_idx ON public.anaira_photography_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_photography_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_photography_reports;
CREATE POLICY tenant_select ON public.anaira_photography_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_photography_reports;
CREATE POLICY tenant_write ON public.anaira_photography_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_event_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_event_types_business_idx ON public.anaira_events_event_types(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_event_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_event_types;
CREATE POLICY tenant_select ON public.anaira_events_event_types FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_event_types;
CREATE POLICY tenant_write ON public.anaira_events_event_types FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_packages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_packages_business_idx ON public.anaira_events_packages(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_packages;
CREATE POLICY tenant_select ON public.anaira_events_packages FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_packages;
CREATE POLICY tenant_write ON public.anaira_events_packages FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_venues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_venues_business_idx ON public.anaira_events_venues(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_venues ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_venues;
CREATE POLICY tenant_select ON public.anaira_events_venues FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_venues;
CREATE POLICY tenant_write ON public.anaira_events_venues FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_services_business_idx ON public.anaira_events_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_services;
CREATE POLICY tenant_select ON public.anaira_events_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_services;
CREATE POLICY tenant_write ON public.anaira_events_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_vendors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_vendors_business_idx ON public.anaira_events_vendors(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_vendors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_vendors;
CREATE POLICY tenant_select ON public.anaira_events_vendors FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_vendors;
CREATE POLICY tenant_write ON public.anaira_events_vendors FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_team (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_team_business_idx ON public.anaira_events_team(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_team ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_team;
CREATE POLICY tenant_select ON public.anaira_events_team FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_team;
CREATE POLICY tenant_write ON public.anaira_events_team FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_bookings_business_idx ON public.anaira_events_bookings(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_bookings;
CREATE POLICY tenant_select ON public.anaira_events_bookings FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_bookings;
CREATE POLICY tenant_write ON public.anaira_events_bookings FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_customers_business_idx ON public.anaira_events_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_customers;
CREATE POLICY tenant_select ON public.anaira_events_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_customers;
CREATE POLICY tenant_write ON public.anaira_events_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_guests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_guests_business_idx ON public.anaira_events_guests(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_guests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_guests;
CREATE POLICY tenant_select ON public.anaira_events_guests FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_guests;
CREATE POLICY tenant_write ON public.anaira_events_guests FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_tickets_business_idx ON public.anaira_events_tickets(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_tickets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_tickets;
CREATE POLICY tenant_select ON public.anaira_events_tickets FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_tickets;
CREATE POLICY tenant_write ON public.anaira_events_tickets FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_payments_business_idx ON public.anaira_events_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_payments;
CREATE POLICY tenant_select ON public.anaira_events_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_payments;
CREATE POLICY tenant_write ON public.anaira_events_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_gallery (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_gallery_business_idx ON public.anaira_events_gallery(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_gallery ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_gallery;
CREATE POLICY tenant_select ON public.anaira_events_gallery FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_gallery;
CREATE POLICY tenant_write ON public.anaira_events_gallery FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_offers_business_idx ON public.anaira_events_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_offers;
CREATE POLICY tenant_select ON public.anaira_events_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_offers;
CREATE POLICY tenant_write ON public.anaira_events_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_events_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_events_reports_business_idx ON public.anaira_events_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_events_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_events_reports;
CREATE POLICY tenant_select ON public.anaira_events_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_events_reports;
CREATE POLICY tenant_write ON public.anaira_events_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_locations_business_idx ON public.anaira_coworking_locations(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_locations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_locations;
CREATE POLICY tenant_select ON public.anaira_coworking_locations FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_locations;
CREATE POLICY tenant_write ON public.anaira_coworking_locations FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_rooms_business_idx ON public.anaira_coworking_rooms(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_rooms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_rooms;
CREATE POLICY tenant_select ON public.anaira_coworking_rooms FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_rooms;
CREATE POLICY tenant_write ON public.anaira_coworking_rooms FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_desks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_desks_business_idx ON public.anaira_coworking_desks(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_desks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_desks;
CREATE POLICY tenant_select ON public.anaira_coworking_desks FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_desks;
CREATE POLICY tenant_write ON public.anaira_coworking_desks FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_meeting_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_meeting_rooms_business_idx ON public.anaira_coworking_meeting_rooms(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_meeting_rooms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_meeting_rooms;
CREATE POLICY tenant_select ON public.anaira_coworking_meeting_rooms FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_meeting_rooms;
CREATE POLICY tenant_write ON public.anaira_coworking_meeting_rooms FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_memberships_business_idx ON public.anaira_coworking_memberships(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_memberships ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_memberships;
CREATE POLICY tenant_select ON public.anaira_coworking_memberships FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_memberships;
CREATE POLICY tenant_write ON public.anaira_coworking_memberships FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_plans_business_idx ON public.anaira_coworking_plans(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_plans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_plans;
CREATE POLICY tenant_select ON public.anaira_coworking_plans FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_plans;
CREATE POLICY tenant_write ON public.anaira_coworking_plans FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_bookings_business_idx ON public.anaira_coworking_bookings(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_bookings;
CREATE POLICY tenant_select ON public.anaira_coworking_bookings FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_bookings;
CREATE POLICY tenant_write ON public.anaira_coworking_bookings FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_members_business_idx ON public.anaira_coworking_members(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_members;
CREATE POLICY tenant_select ON public.anaira_coworking_members FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_members;
CREATE POLICY tenant_write ON public.anaira_coworking_members FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_visitors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_visitors_business_idx ON public.anaira_coworking_visitors(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_visitors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_visitors;
CREATE POLICY tenant_select ON public.anaira_coworking_visitors FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_visitors;
CREATE POLICY tenant_write ON public.anaira_coworking_visitors FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_amenities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_amenities_business_idx ON public.anaira_coworking_amenities(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_amenities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_amenities;
CREATE POLICY tenant_select ON public.anaira_coworking_amenities FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_amenities;
CREATE POLICY tenant_write ON public.anaira_coworking_amenities FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_payments_business_idx ON public.anaira_coworking_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_payments;
CREATE POLICY tenant_select ON public.anaira_coworking_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_payments;
CREATE POLICY tenant_write ON public.anaira_coworking_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_invoices_business_idx ON public.anaira_coworking_invoices(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_invoices;
CREATE POLICY tenant_select ON public.anaira_coworking_invoices FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_invoices;
CREATE POLICY tenant_write ON public.anaira_coworking_invoices FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_access (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_access_business_idx ON public.anaira_coworking_access(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_access ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_access;
CREATE POLICY tenant_select ON public.anaira_coworking_access FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_access;
CREATE POLICY tenant_write ON public.anaira_coworking_access FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_coworking_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_coworking_reports_business_idx ON public.anaira_coworking_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_coworking_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_coworking_reports;
CREATE POLICY tenant_select ON public.anaira_coworking_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_coworking_reports;
CREATE POLICY tenant_write ON public.anaira_coworking_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_services_business_idx ON public.anaira_logistics_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_services;
CREATE POLICY tenant_select ON public.anaira_logistics_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_services;
CREATE POLICY tenant_write ON public.anaira_logistics_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_vehicles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_vehicles_business_idx ON public.anaira_logistics_vehicles(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_vehicles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_vehicles;
CREATE POLICY tenant_select ON public.anaira_logistics_vehicles FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_vehicles;
CREATE POLICY tenant_write ON public.anaira_logistics_vehicles FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_drivers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_drivers_business_idx ON public.anaira_logistics_drivers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_drivers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_drivers;
CREATE POLICY tenant_select ON public.anaira_logistics_drivers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_drivers;
CREATE POLICY tenant_write ON public.anaira_logistics_drivers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_customers_business_idx ON public.anaira_logistics_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_customers;
CREATE POLICY tenant_select ON public.anaira_logistics_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_customers;
CREATE POLICY tenant_write ON public.anaira_logistics_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_shipments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_shipments_business_idx ON public.anaira_logistics_shipments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_shipments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_shipments;
CREATE POLICY tenant_select ON public.anaira_logistics_shipments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_shipments;
CREATE POLICY tenant_write ON public.anaira_logistics_shipments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_orders_business_idx ON public.anaira_logistics_orders(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_orders;
CREATE POLICY tenant_select ON public.anaira_logistics_orders FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_orders;
CREATE POLICY tenant_write ON public.anaira_logistics_orders FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_tracking (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_tracking_business_idx ON public.anaira_logistics_tracking(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_tracking ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_tracking;
CREATE POLICY tenant_select ON public.anaira_logistics_tracking FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_tracking;
CREATE POLICY tenant_write ON public.anaira_logistics_tracking FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_routes_business_idx ON public.anaira_logistics_routes(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_routes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_routes;
CREATE POLICY tenant_select ON public.anaira_logistics_routes FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_routes;
CREATE POLICY tenant_write ON public.anaira_logistics_routes FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_warehouses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_warehouses_business_idx ON public.anaira_logistics_warehouses(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_warehouses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_warehouses;
CREATE POLICY tenant_select ON public.anaira_logistics_warehouses FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_warehouses;
CREATE POLICY tenant_write ON public.anaira_logistics_warehouses FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_rates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_rates_business_idx ON public.anaira_logistics_rates(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_rates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_rates;
CREATE POLICY tenant_select ON public.anaira_logistics_rates FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_rates;
CREATE POLICY tenant_write ON public.anaira_logistics_rates FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_invoices_business_idx ON public.anaira_logistics_invoices(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_invoices;
CREATE POLICY tenant_select ON public.anaira_logistics_invoices FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_invoices;
CREATE POLICY tenant_write ON public.anaira_logistics_invoices FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_payments_business_idx ON public.anaira_logistics_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_payments;
CREATE POLICY tenant_select ON public.anaira_logistics_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_payments;
CREATE POLICY tenant_write ON public.anaira_logistics_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_documents_business_idx ON public.anaira_logistics_documents(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_documents;
CREATE POLICY tenant_select ON public.anaira_logistics_documents FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_documents;
CREATE POLICY tenant_write ON public.anaira_logistics_documents FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_logistics_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_logistics_reports_business_idx ON public.anaira_logistics_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_logistics_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_logistics_reports;
CREATE POLICY tenant_select ON public.anaira_logistics_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_logistics_reports;
CREATE POLICY tenant_write ON public.anaira_logistics_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_services_business_idx ON public.anaira_construction_home_services_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_services;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_services;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_projects_business_idx ON public.anaira_construction_home_services_projects(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_projects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_projects;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_projects FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_projects;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_projects FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_team (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_team_business_idx ON public.anaira_construction_home_services_team(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_team ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_team;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_team FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_team;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_team FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_workers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_workers_business_idx ON public.anaira_construction_home_services_workers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_workers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_workers;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_workers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_workers;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_workers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_materials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_materials_business_idx ON public.anaira_construction_home_services_materials(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_materials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_materials;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_materials FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_materials;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_materials FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_suppliers_business_idx ON public.anaira_construction_home_services_suppliers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_suppliers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_suppliers;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_suppliers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_suppliers;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_suppliers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_estimates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_estimates_business_idx ON public.anaira_construction_home_services_estimates(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_estimates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_estimates;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_estimates FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_estimates;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_estimates FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_jobs_business_idx ON public.anaira_construction_home_services_jobs(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_jobs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_jobs;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_jobs FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_jobs;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_jobs FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_schedules_business_idx ON public.anaira_construction_home_services_schedules(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_schedules;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_schedules FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_schedules;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_schedules FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_customers_business_idx ON public.anaira_construction_home_services_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_customers;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_customers;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_invoices_business_idx ON public.anaira_construction_home_services_invoices(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_invoices;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_invoices FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_invoices;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_invoices FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_payments_business_idx ON public.anaira_construction_home_services_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_payments;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_payments;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_gallery (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_gallery_business_idx ON public.anaira_construction_home_services_gallery(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_gallery ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_gallery;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_gallery FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_gallery;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_gallery FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_before_after (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_before_afte_business_idx ON public.anaira_construction_home_services_before_after(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_before_after ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_before_after;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_before_after FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_before_after;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_before_after FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_reviews_business_idx ON public.anaira_construction_home_services_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_reviews;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_reviews;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_construction_home_services_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_construction_home_services_reports_business_idx ON public.anaira_construction_home_services_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_construction_home_services_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_construction_home_services_reports;
CREATE POLICY tenant_select ON public.anaira_construction_home_services_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_construction_home_services_reports;
CREATE POLICY tenant_write ON public.anaira_construction_home_services_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_categories_business_idx ON public.anaira_ecommerce_categories(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_categories;
CREATE POLICY tenant_select ON public.anaira_ecommerce_categories FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_categories;
CREATE POLICY tenant_write ON public.anaira_ecommerce_categories FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_products_business_idx ON public.anaira_ecommerce_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_products;
CREATE POLICY tenant_select ON public.anaira_ecommerce_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_products;
CREATE POLICY tenant_write ON public.anaira_ecommerce_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_variants_business_idx ON public.anaira_ecommerce_variants(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_variants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_variants;
CREATE POLICY tenant_select ON public.anaira_ecommerce_variants FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_variants;
CREATE POLICY tenant_write ON public.anaira_ecommerce_variants FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_images_business_idx ON public.anaira_ecommerce_images(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_images ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_images;
CREATE POLICY tenant_select ON public.anaira_ecommerce_images FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_images;
CREATE POLICY tenant_write ON public.anaira_ecommerce_images FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_inventory_business_idx ON public.anaira_ecommerce_inventory(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_inventory ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_inventory;
CREATE POLICY tenant_select ON public.anaira_ecommerce_inventory FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_inventory;
CREATE POLICY tenant_write ON public.anaira_ecommerce_inventory FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_orders_business_idx ON public.anaira_ecommerce_orders(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_orders;
CREATE POLICY tenant_select ON public.anaira_ecommerce_orders FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_orders;
CREATE POLICY tenant_write ON public.anaira_ecommerce_orders FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_customers_business_idx ON public.anaira_ecommerce_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_customers;
CREATE POLICY tenant_select ON public.anaira_ecommerce_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_customers;
CREATE POLICY tenant_write ON public.anaira_ecommerce_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_coupons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_coupons_business_idx ON public.anaira_ecommerce_coupons(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_coupons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_coupons;
CREATE POLICY tenant_select ON public.anaira_ecommerce_coupons FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_coupons;
CREATE POLICY tenant_write ON public.anaira_ecommerce_coupons FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_offers_business_idx ON public.anaira_ecommerce_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_offers;
CREATE POLICY tenant_select ON public.anaira_ecommerce_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_offers;
CREATE POLICY tenant_write ON public.anaira_ecommerce_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_wishlist (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_wishlist_business_idx ON public.anaira_ecommerce_wishlist(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_wishlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_wishlist;
CREATE POLICY tenant_select ON public.anaira_ecommerce_wishlist FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_wishlist;
CREATE POLICY tenant_write ON public.anaira_ecommerce_wishlist FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_cart (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_cart_business_idx ON public.anaira_ecommerce_cart(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_cart ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_cart;
CREATE POLICY tenant_select ON public.anaira_ecommerce_cart FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_cart;
CREATE POLICY tenant_write ON public.anaira_ecommerce_cart FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_payments_business_idx ON public.anaira_ecommerce_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_payments;
CREATE POLICY tenant_select ON public.anaira_ecommerce_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_payments;
CREATE POLICY tenant_write ON public.anaira_ecommerce_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_shipping (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_shipping_business_idx ON public.anaira_ecommerce_shipping(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_shipping ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_shipping;
CREATE POLICY tenant_select ON public.anaira_ecommerce_shipping FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_shipping;
CREATE POLICY tenant_write ON public.anaira_ecommerce_shipping FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_returns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_returns_business_idx ON public.anaira_ecommerce_returns(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_returns ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_returns;
CREATE POLICY tenant_select ON public.anaira_ecommerce_returns FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_returns;
CREATE POLICY tenant_write ON public.anaira_ecommerce_returns FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_reviews_business_idx ON public.anaira_ecommerce_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_reviews;
CREATE POLICY tenant_select ON public.anaira_ecommerce_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_reviews;
CREATE POLICY tenant_write ON public.anaira_ecommerce_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_ecommerce_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_ecommerce_analytics_business_idx ON public.anaira_ecommerce_analytics(business_id,status,created_at DESC);
ALTER TABLE public.anaira_ecommerce_analytics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_ecommerce_analytics;
CREATE POLICY tenant_select ON public.anaira_ecommerce_analytics FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_ecommerce_analytics;
CREATE POLICY tenant_write ON public.anaira_ecommerce_analytics FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_products_business_idx ON public.anaira_saas_subscription_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_products;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_products;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_plans_business_idx ON public.anaira_saas_subscription_plans(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_plans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_plans;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_plans FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_plans;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_plans FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_features (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_features_business_idx ON public.anaira_saas_subscription_features(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_features ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_features;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_features FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_features;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_features FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_pricing (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_pricing_business_idx ON public.anaira_saas_subscription_pricing(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_pricing ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_pricing;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_pricing FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_pricing;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_pricing FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_subscriptions_business_idx ON public.anaira_saas_subscription_subscriptions(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_subscriptions;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_subscriptions FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_subscriptions;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_subscriptions FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_customers_business_idx ON public.anaira_saas_subscription_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_customers;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_customers;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_trials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_trials_business_idx ON public.anaira_saas_subscription_trials(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_trials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_trials;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_trials FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_trials;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_trials FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_coupons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_coupons_business_idx ON public.anaira_saas_subscription_coupons(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_coupons ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_coupons;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_coupons FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_coupons;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_coupons FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_invoices_business_idx ON public.anaira_saas_subscription_invoices(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_invoices;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_invoices FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_invoices;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_invoices FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_payments_business_idx ON public.anaira_saas_subscription_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_payments;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_payments;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_usage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_usage_business_idx ON public.anaira_saas_subscription_usage(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_usage ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_usage;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_usage FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_usage;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_usage FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_support (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_support_business_idx ON public.anaira_saas_subscription_support(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_support ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_support;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_support FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_support;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_support FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_knowledge_base (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_knowledge_base_business_idx ON public.anaira_saas_subscription_knowledge_base(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_knowledge_base ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_knowledge_base;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_knowledge_base FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_knowledge_base;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_knowledge_base FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_testimonials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_testimonials_business_idx ON public.anaira_saas_subscription_testimonials(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_testimonials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_testimonials;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_testimonials FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_testimonials;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_testimonials FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_saas_subscription_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_saas_subscription_analytics_business_idx ON public.anaira_saas_subscription_analytics(business_id,status,created_at DESC);
ALTER TABLE public.anaira_saas_subscription_analytics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_saas_subscription_analytics;
CREATE POLICY tenant_select ON public.anaira_saas_subscription_analytics FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_saas_subscription_analytics;
CREATE POLICY tenant_write ON public.anaira_saas_subscription_analytics FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_content (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_content_business_idx ON public.anaira_creator_personal_brand_content(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_content ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_content;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_content FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_content;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_content FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_services_business_idx ON public.anaira_creator_personal_brand_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_services;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_services;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_courses_business_idx ON public.anaira_creator_personal_brand_courses(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_courses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_courses;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_courses FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_courses;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_courses FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_products_business_idx ON public.anaira_creator_personal_brand_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_products;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_products;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_digital_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_digital_product_business_idx ON public.anaira_creator_personal_brand_digital_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_digital_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_digital_products;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_digital_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_digital_products;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_digital_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_portfolio (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_portfolio_business_idx ON public.anaira_creator_personal_brand_portfolio(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_portfolio ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_portfolio;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_portfolio FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_portfolio;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_portfolio FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_bookings_business_idx ON public.anaira_creator_personal_brand_bookings(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_bookings;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_bookings FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_bookings;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_bookings FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_customers_business_idx ON public.anaira_creator_personal_brand_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_customers;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_customers;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_sponsors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_sponsors_business_idx ON public.anaira_creator_personal_brand_sponsors(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_sponsors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_sponsors;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_sponsors FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_sponsors;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_sponsors FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_testimonials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_testimonials_business_idx ON public.anaira_creator_personal_brand_testimonials(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_testimonials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_testimonials;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_testimonials FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_testimonials;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_testimonials FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_offers_business_idx ON public.anaira_creator_personal_brand_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_offers;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_offers;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_newsletter (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_newsletter_business_idx ON public.anaira_creator_personal_brand_newsletter(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_newsletter ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_newsletter;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_newsletter FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_newsletter;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_newsletter FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_gallery (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_gallery_business_idx ON public.anaira_creator_personal_brand_gallery(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_gallery ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_gallery;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_gallery FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_gallery;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_gallery FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_seo (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_seo_business_idx ON public.anaira_creator_personal_brand_seo(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_seo ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_seo;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_seo FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_seo;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_seo FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_creator_personal_brand_analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_creator_personal_brand_analytics_business_idx ON public.anaira_creator_personal_brand_analytics(business_id,status,created_at DESC);
ALTER TABLE public.anaira_creator_personal_brand_analytics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_creator_personal_brand_analytics;
CREATE POLICY tenant_select ON public.anaira_creator_personal_brand_analytics FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_creator_personal_brand_analytics;
CREATE POLICY tenant_write ON public.anaira_creator_personal_brand_analytics FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_causes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_causes_business_idx ON public.anaira_non_profit_causes(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_causes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_causes;
CREATE POLICY tenant_select ON public.anaira_non_profit_causes FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_causes;
CREATE POLICY tenant_write ON public.anaira_non_profit_causes FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_programs_business_idx ON public.anaira_non_profit_programs(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_programs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_programs;
CREATE POLICY tenant_select ON public.anaira_non_profit_programs FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_programs;
CREATE POLICY tenant_write ON public.anaira_non_profit_programs FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_projects_business_idx ON public.anaira_non_profit_projects(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_projects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_projects;
CREATE POLICY tenant_select ON public.anaira_non_profit_projects FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_projects;
CREATE POLICY tenant_write ON public.anaira_non_profit_projects FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_team (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_team_business_idx ON public.anaira_non_profit_team(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_team ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_team;
CREATE POLICY tenant_select ON public.anaira_non_profit_team FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_team;
CREATE POLICY tenant_write ON public.anaira_non_profit_team FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_volunteers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_volunteers_business_idx ON public.anaira_non_profit_volunteers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_volunteers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_volunteers;
CREATE POLICY tenant_select ON public.anaira_non_profit_volunteers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_volunteers;
CREATE POLICY tenant_write ON public.anaira_non_profit_volunteers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_donors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_donors_business_idx ON public.anaira_non_profit_donors(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_donors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_donors;
CREATE POLICY tenant_select ON public.anaira_non_profit_donors FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_donors;
CREATE POLICY tenant_write ON public.anaira_non_profit_donors FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_donations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_donations_business_idx ON public.anaira_non_profit_donations(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_donations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_donations;
CREATE POLICY tenant_select ON public.anaira_non_profit_donations FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_donations;
CREATE POLICY tenant_write ON public.anaira_non_profit_donations FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_campaigns_business_idx ON public.anaira_non_profit_campaigns(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_campaigns ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_campaigns;
CREATE POLICY tenant_select ON public.anaira_non_profit_campaigns FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_campaigns;
CREATE POLICY tenant_write ON public.anaira_non_profit_campaigns FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_events_business_idx ON public.anaira_non_profit_events(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_events;
CREATE POLICY tenant_select ON public.anaira_non_profit_events FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_events;
CREATE POLICY tenant_write ON public.anaira_non_profit_events FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_beneficiaries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_beneficiaries_business_idx ON public.anaira_non_profit_beneficiaries(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_beneficiaries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_beneficiaries;
CREATE POLICY tenant_select ON public.anaira_non_profit_beneficiaries FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_beneficiaries;
CREATE POLICY tenant_write ON public.anaira_non_profit_beneficiaries FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_gallery (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_gallery_business_idx ON public.anaira_non_profit_gallery(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_gallery ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_gallery;
CREATE POLICY tenant_select ON public.anaira_non_profit_gallery FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_gallery;
CREATE POLICY tenant_write ON public.anaira_non_profit_gallery FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_stories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_stories_business_idx ON public.anaira_non_profit_stories(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_stories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_stories;
CREATE POLICY tenant_select ON public.anaira_non_profit_stories FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_stories;
CREATE POLICY tenant_write ON public.anaira_non_profit_stories FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_testimonials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_testimonials_business_idx ON public.anaira_non_profit_testimonials(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_testimonials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_testimonials;
CREATE POLICY tenant_select ON public.anaira_non_profit_testimonials FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_testimonials;
CREATE POLICY tenant_write ON public.anaira_non_profit_testimonials FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_non_profit_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_non_profit_reports_business_idx ON public.anaira_non_profit_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_non_profit_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_non_profit_reports;
CREATE POLICY tenant_select ON public.anaira_non_profit_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_non_profit_reports;
CREATE POLICY tenant_write ON public.anaira_non_profit_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_services_business_idx ON public.anaira_other_services(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_services;
CREATE POLICY tenant_select ON public.anaira_other_services FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_services;
CREATE POLICY tenant_write ON public.anaira_other_services FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_products_business_idx ON public.anaira_other_products(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_products;
CREATE POLICY tenant_select ON public.anaira_other_products FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_products;
CREATE POLICY tenant_write ON public.anaira_other_products FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_categories_business_idx ON public.anaira_other_categories(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_categories;
CREATE POLICY tenant_select ON public.anaira_other_categories FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_categories;
CREATE POLICY tenant_write ON public.anaira_other_categories FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_team (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_team_business_idx ON public.anaira_other_team(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_team ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_team;
CREATE POLICY tenant_select ON public.anaira_other_team FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_team;
CREATE POLICY tenant_write ON public.anaira_other_team FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_customers_business_idx ON public.anaira_other_customers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_customers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_customers;
CREATE POLICY tenant_select ON public.anaira_other_customers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_customers;
CREATE POLICY tenant_write ON public.anaira_other_customers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_leads_business_idx ON public.anaira_other_leads(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_leads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_leads;
CREATE POLICY tenant_select ON public.anaira_other_leads FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_leads;
CREATE POLICY tenant_write ON public.anaira_other_leads FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_appointments_business_idx ON public.anaira_other_appointments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_appointments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_appointments;
CREATE POLICY tenant_select ON public.anaira_other_appointments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_appointments;
CREATE POLICY tenant_write ON public.anaira_other_appointments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_orders_business_idx ON public.anaira_other_orders(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_orders;
CREATE POLICY tenant_select ON public.anaira_other_orders FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_orders;
CREATE POLICY tenant_write ON public.anaira_other_orders FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_offers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_offers_business_idx ON public.anaira_other_offers(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_offers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_offers;
CREATE POLICY tenant_select ON public.anaira_other_offers FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_offers;
CREATE POLICY tenant_write ON public.anaira_other_offers FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_gallery (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_gallery_business_idx ON public.anaira_other_gallery(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_gallery ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_gallery;
CREATE POLICY tenant_select ON public.anaira_other_gallery FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_gallery;
CREATE POLICY tenant_write ON public.anaira_other_gallery FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_testimonials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_testimonials_business_idx ON public.anaira_other_testimonials(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_testimonials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_testimonials;
CREATE POLICY tenant_select ON public.anaira_other_testimonials FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_testimonials;
CREATE POLICY tenant_write ON public.anaira_other_testimonials FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_reviews_business_idx ON public.anaira_other_reviews(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_reviews;
CREATE POLICY tenant_select ON public.anaira_other_reviews FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_reviews;
CREATE POLICY tenant_write ON public.anaira_other_reviews FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_payments_business_idx ON public.anaira_other_payments(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_payments;
CREATE POLICY tenant_select ON public.anaira_other_payments FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_payments;
CREATE POLICY tenant_write ON public.anaira_other_payments FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_other_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active',
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  image_url text,
  gallery jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_other_reports_business_idx ON public.anaira_other_reports(business_id,status,created_at DESC);
ALTER TABLE public.anaira_other_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_select ON public.anaira_other_reports;
CREATE POLICY tenant_select ON public.anaira_other_reports FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
DROP POLICY IF EXISTS tenant_write ON public.anaira_other_reports;
CREATE POLICY tenant_write ON public.anaira_other_reports FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
CREATE TABLE IF NOT EXISTS public.anaira_business_domain_events_v16 (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), business_id uuid NOT NULL, business_type text NOT NULL,
 module_key text NOT NULL, entity_id uuid NOT NULL, event_type text NOT NULL,
 from_status text, to_status text, payload jsonb NOT NULL DEFAULT '{}'::jsonb,
 actor_id uuid REFERENCES auth.users(id), created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS anaira_domain_events_v16_idx ON public.anaira_business_domain_events_v16(business_id,module_key,created_at DESC);
ALTER TABLE public.anaira_business_domain_events_v16 ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_events_v16 ON public.anaira_business_domain_events_v16;
CREATE POLICY tenant_events_v16 ON public.anaira_business_domain_events_v16 FOR ALL TO authenticated USING (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id)) WITH CHECK (public.anaira_current_is_super_admin() OR public.anaira_tenant_access(business_id));
