BEGIN;
ALTER TABLE public.restaurants DROP CONSTRAINT IF EXISTS restaurants_hospitality_types_check;
ALTER TABLE public.restaurants ADD CONSTRAINT restaurants_hospitality_types_check CHECK ((hospitality_types <@ ARRAY['hotel'::text,'camp'::text,'homestay'::text,'guest_house'::text,'cottage'::text]) AND (cardinality(hospitality_types) >= 0));

CREATE TABLE IF NOT EXISTS public.anaira_business_type_profiles (
  code text PRIMARY KEY,
  icon text NOT NULL DEFAULT '•',
  name text NOT NULL,
  category text NOT NULL DEFAULT 'general',
  settings jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order integer NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.anaira_business_type_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "business type profiles authenticated read" ON public.anaira_business_type_profiles;
CREATE POLICY "business type profiles authenticated read" ON public.anaira_business_type_profiles FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "business type profiles super admin write" ON public.anaira_business_type_profiles;
CREATE POLICY "business type profiles super admin write" ON public.anaira_business_type_profiles FOR ALL TO authenticated USING (public.anaira_current_is_super_admin()) WITH CHECK (public.anaira_current_is_super_admin());

INSERT INTO public.anaira_business_type_profiles(code,icon,name,category,settings,sort_order)
VALUES
('hotel_resort','🏨','Hotel / Resort','hospitality','["Hotel profile", "Room types", "Rooms", "Rate plans", "Inventory", "Reservations", "PMS / Front Desk", "Housekeeping"]'::jsonb,10),
('restaurant_cafe','🍽️','Restaurant / Cafe','food','["Restaurant profile", "Menu & categories", "Tables", "Reservations", "POS", "Orders", "Kitchen", "Delivery / pickup"]'::jsonb,20),
('salon','💇','Salon','beauty','["Salon profile", "Services & pricing", "Stylists / staff", "Working hours", "Appointments", "Packages & memberships", "Customer CRM", "Offers & loyalty"]'::jsonb,30),
('barber_shop','💈','Barber Shop','beauty','["Barber shop profile", "Services & pricing", "Barbers / staff", "Working hours", "Appointments", "Packages", "Customer CRM", "Offers & loyalty"]'::jsonb,40),
('spa_wellness','💆','Spa','wellness','["Spa profile", "Treatments & pricing", "Therapists", "Working hours", "Appointments", "Packages & memberships", "Customer CRM", "Offers & loyalty"]'::jsonb,50),
('clinic_hospital','🏥','Clinic / Hospital','healthcare','["Clinic profile", "Departments", "Doctors & staff", "Services", "Appointments", "Patients", "Billing & insurance", "Reports"]'::jsonb,60),
('dentist_doctor','🦷','Dentist / Doctor','healthcare','["Practice profile", "Doctors", "Services", "Appointments", "Patients", "Prescriptions / notes", "Billing", "Reports"]'::jsonb,70),
('pharmacy','💊','Pharmacy','healthcare','["Pharmacy profile", "Products", "Stock & batches", "Suppliers", "Sales", "Customers", "Billing & tax", "Reports"]'::jsonb,80),
('gym_yoga','🏋️','Gym / Yoga','fitness','["Gym profile", "Plans & memberships", "Classes", "Trainers", "Schedules", "Member CRM", "Attendance", "Payments"]'::jsonb,90),
('retail_grocery','🛍️','Retail / Grocery','retail','["Store profile", "Products", "Categories", "Inventory", "Suppliers", "Orders", "Customers", "POS & billing"]'::jsonb,100),
('fashion','👗','Fashion','retail','["Brand profile", "Collections", "Products & variants", "Inventory", "Orders", "Customers", "Offers", "Storefront"]'::jsonb,110),
('jewellery','💎','Jewellery','retail','["Jewellery profile", "Collections", "Products", "Inventory", "Certificates", "Sales", "Customers", "Storefront"]'::jsonb,120),
('electronics_mobile','📱','Electronics / Mobile','retail','["Store profile", "Products & IMEI", "Inventory", "Suppliers", "Sales", "Repairs", "Customers", "POS"]'::jsonb,130),
('automotive','🚗','Automotive','automotive','["Workshop profile", "Services", "Vehicles", "Customers", "Technicians", "Appointments", "Job cards", "Invoices"]'::jsonb,140),
('real_estate','🏠','Real Estate','professional','["Agency profile", "Listings", "Agents", "Leads", "Site visits", "Deals", "Documents", "Reports"]'::jsonb,150),
('travel','✈️','Travel','travel','["Travel profile", "Packages", "Destinations", "Agents", "Enquiries", "Bookings", "Suppliers", "Payments"]'::jsonb,160),
('education_coaching','🎓','Education / Coaching','education','["Institute profile", "Courses", "Batches", "Teachers", "Students", "Admissions", "Fees", "Attendance"]'::jsonb,170),
('legal','⚖️','Legal','professional','["Firm profile", "Practice areas", "Lawyers", "Clients", "Matters", "Appointments", "Documents", "Billing"]'::jsonb,180),
('ca_accounting_tax','📊','CA / Accounting / Tax','professional','["Firm profile", "Services", "Professionals", "Clients", "Engagements", "Tasks", "Documents", "Billing"]'::jsonb,190),
('it_agency','💻','IT / Agency','technology','["Agency profile", "Services", "Projects", "Team", "Leads", "Tasks", "Clients", "Invoices"]'::jsonb,200),
('repair_maintenance','🔧','Repair / Maintenance','services','["Business profile", "Services", "Technicians", "Job intake", "Jobs", "Customers", "Parts / inventory", "Invoices"]'::jsonb,210),
('cleaning','🧹','Cleaning','services','["Business profile", "Services", "Staff", "Service areas", "Bookings", "Customers", "Schedules", "Invoices"]'::jsonb,220),
('veterinary','🐕','Veterinary','healthcare','["Clinic profile", "Vets", "Services", "Appointments", "Pet patients", "Owners", "Vaccinations", "Billing"]'::jsonb,230),
('photography','📸','Photography','creative','["Studio profile", "Packages", "Photographers", "Portfolio", "Enquiries", "Bookings", "Customers", "Invoices"]'::jsonb,240),
('events','🎉','Events','events','["Event company profile", "Event types", "Events", "Venues", "Clients", "Bookings", "Vendors", "Invoices"]'::jsonb,250),
('coworking','🏢','Coworking','workspace','["Workspace profile", "Spaces", "Memberships", "Meeting rooms", "Members", "Bookings", "Access", "Billing"]'::jsonb,260),
('logistics','🚚','Logistics','logistics','["Company profile", "Services", "Vehicles", "Drivers", "Shipments", "Customers", "Tracking", "Billing"]'::jsonb,270),
('construction_home_services','🏗️','Construction / Home Services','services','["Business profile", "Services", "Team", "Leads", "Projects", "Site visits", "Materials", "Invoices"]'::jsonb,280),
('ecommerce','🛒','E-commerce','commerce','["Store profile", "Products", "Categories", "Inventory", "Orders", "Customers", "Coupons", "Storefront"]'::jsonb,290),
('saas_subscription','☁️','SaaS / Subscription','technology','["Company profile", "Plans", "Features", "Customers", "Subscriptions", "Invoices", "Usage", "Analytics"]'::jsonb,300),
('creator_personal_brand','👤','Creator / Personal Brand','creator','["Brand profile", "Offerings", "Content", "Audience", "Leads", "Bookings", "Campaigns", "Analytics"]'::jsonb,310),
('non_profit','🤝','Non-profit','organization','["Organization profile", "Programs", "Donors", "Campaigns", "Volunteers", "Donations", "Grants", "Reports"]'::jsonb,320),
('other','•','Other','general','["Business profile", "Items / services", "Team", "Leads", "Customers", "Bookings", "Payments", "Reports"]'::jsonb,330)
ON CONFLICT (code) DO UPDATE SET icon=excluded.icon,name=excluded.name,category=excluded.category,settings=excluded.settings,sort_order=excluded.sort_order,updated_at=now();

CREATE TABLE IF NOT EXISTS public.anaira_business_workspaces (
  business_id uuid PRIMARY KEY REFERENCES public.restaurants(id) ON DELETE CASCADE,
  business_type text NOT NULL REFERENCES public.anaira_business_types(code),
  setup_status text NOT NULL DEFAULT 'draft' CHECK (setup_status IN ('draft','configured','published','suspended')),
  settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  landing_enabled boolean NOT NULL DEFAULT true,
  landing_settings jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.anaira_business_workspaces ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "business workspace tenant read" ON public.anaira_business_workspaces;
CREATE POLICY "business workspace tenant read" ON public.anaira_business_workspaces FOR SELECT TO authenticated USING (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=business_id AND m.status='active'));
DROP POLICY IF EXISTS "business workspace tenant write" ON public.anaira_business_workspaces;
CREATE POLICY "business workspace tenant write" ON public.anaira_business_workspaces FOR INSERT TO authenticated WITH CHECK (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=business_id AND m.status='active'));
DROP POLICY IF EXISTS "business workspace tenant update" ON public.anaira_business_workspaces;
CREATE POLICY "business workspace tenant update" ON public.anaira_business_workspaces FOR UPDATE TO authenticated USING (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=business_id AND m.status='active')) WITH CHECK (public.anaira_current_is_super_admin() OR EXISTS (SELECT 1 FROM public.anaira_business_memberships m WHERE m.user_id=auth.uid() AND m.business_id=business_id AND m.status='active'));

CREATE INDEX IF NOT EXISTS idx_anaira_business_workspaces_type ON public.anaira_business_workspaces(business_type);
CREATE INDEX IF NOT EXISTS idx_restaurants_business_type ON public.restaurants(business_type);

INSERT INTO public.anaira_business_workspaces(business_id,business_type,setup_status,settings)
SELECT r.id,r.business_type,'configured',jsonb_build_object('business_type',r.business_type,'name',r.name)
FROM public.restaurants r
WHERE r.business_type IS NOT NULL
ON CONFLICT (business_id) DO UPDATE SET business_type=excluded.business_type,updated_at=now();

COMMIT;