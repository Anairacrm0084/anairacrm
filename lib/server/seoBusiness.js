export const SEO_BUSINESS_VERTICALS = [
  ['hotel','Hotel / Resort'],['restaurant','Restaurant'],['cafe','Cafe / Bakery'],['bar','Bar / Lounge'],
  ['salon','Salon / Beauty'],['barber_shop','Barber Shop'],['spa','Spa / Wellness'],
  ['clinic','Clinic / Hospital'],['dentist','Dentist'],['doctor','Doctor / Medical Professional'],['pharmacy','Pharmacy'],
  ['gym','Gym / Fitness'],['yoga','Yoga / Wellness'],['retail','Retail Store'],['grocery','Grocery / Supermarket'],
  ['fashion','Fashion / Apparel'],['jewellery','Jewellery'],['electronics','Electronics / Mobile'],['automotive','Automotive / Garage'],
  ['real_estate','Real Estate'],['travel_agency','Travel Agency / Tour Operator'],['education','Education / Coaching'],
  ['legal','Legal Services'],['accounting','Accounting / CA / Tax'],['it_services','IT / Software / Digital Agency'],
  ['professional_services','Professional Services'],['repair','Repair / Maintenance'],['cleaning','Cleaning Services'],
  ['pet_vet','Pet / Veterinary'],['photography','Photography'],['events','Events / Entertainment'],['coworking','Coworking'],
  ['logistics','Logistics / Delivery'],['construction','Construction / Home Services'],['local_service','Local Service'],
  ['ecommerce','E-commerce'],['saas','SaaS / Online Product'],['creator','Creator / Personal Brand'],['nonprofit','Non-profit / Organization'],
  ['education_institution','School / College / Institute'],['other','Other Business']
];
export const SEO_PLATFORM_TYPES = [
  ['custom','Custom Website'],['nextjs','Next.js'],['wordpress','WordPress'],['woocommerce','WooCommerce'],
  ['shopify','Shopify'],['wix','Wix'],['webflow','Webflow'],['squarespace','Squarespace'],['magento','Magento'],
  ['prestashop','PrestaShop'],['html','Static HTML'],['mobile_app','Mobile App / App Store Landing'],['marketplace','Marketplace / Multi-vendor'],['other','Other Platform']
];
export const SEO_GOALS = ['local_discovery','organic_leads','ecommerce_sales','bookings','appointments','calls','directions','brand_visibility','ai_visibility','content_authority','app_discovery'];
export const SEO_ENTITY_TYPES = ['Organization','LocalBusiness','Product','Service','Person','Article','BlogPosting','Event','Course','FAQPage','WebSite','WebPage','BreadcrumbList','SoftwareApplication'];
export function verticalLabel(v){return SEO_BUSINESS_VERTICALS.find(x=>x[0]===v)?.[1]||v||'Other Business'}
export function platformLabel(v){return SEO_PLATFORM_TYPES.find(x=>x[0]===v)?.[1]||v||'Custom Website'}
export function seoProfileDefaults(){return {business_vertical:'other',platform_type:'custom',goals:['organic_leads','brand_visibility'],service_area:{type:'local',radius_km:25,cities:[],countries:['IN']},primary_entities:['Organization','WebSite','WebPage'],local_seo_enabled:true,geo_visibility_enabled:true,ai_visibility_enabled:true,competitor_intelligence_enabled:true};}
