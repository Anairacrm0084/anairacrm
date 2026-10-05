export const BUSINESS_TYPES = [
  ['hotel_resort','🏨','Hotel / Resort','hospitality'],['restaurant_cafe','🍽️','Restaurant / Cafe','food'],['salon','💇','Salon','beauty'],['barber_shop','💈','Barber Shop','beauty'],['spa_wellness','💆','Spa','wellness'],['clinic_hospital','🏥','Clinic / Hospital','healthcare'],['dentist_doctor','🦷','Dentist / Doctor','healthcare'],['pharmacy','💊','Pharmacy','healthcare'],['gym_yoga','🏋️','Gym / Yoga','fitness'],['retail_grocery','🛍️','Retail / Grocery','retail'],['fashion','👗','Fashion','retail'],['jewellery','💎','Jewellery','retail'],['electronics_mobile','📱','Electronics / Mobile','retail'],['automotive','🚗','Automotive','automotive'],['real_estate','🏠','Real Estate','professional'],['travel','✈️','Travel','travel'],['education_coaching','🎓','Education / Coaching','education'],['legal','⚖️','Legal','professional'],['ca_accounting_tax','📊','CA / Accounting / Tax','professional'],['it_agency','💻','IT / Agency','technology'],['repair_maintenance','🔧','Repair / Maintenance','services'],['cleaning','🧹','Cleaning','services'],['veterinary','🐕','Veterinary','healthcare'],['photography','📸','Photography','creative'],['events','🎉','Events','events'],['coworking','🏢','Coworking','workspace'],['logistics','🚚','Logistics','logistics'],['construction_home_services','🏗️','Construction / Home Services','services'],['ecommerce','🛒','E-commerce','commerce'],['saas_subscription','☁️','SaaS / Subscription','technology'],['creator_personal_brand','👤','Creator / Personal Brand','creator'],['non_profit','🤝','Non-profit','organization'],['other','•','Other','general']
];

const SPECIAL={
 salon:{unit:'Service',plural:'Services',booking:'Appointments',staff:'Stylists / Staff',primary:'Salon Services',settings:['Salon profile','Services & pricing','Stylists / staff','Working hours','Appointments','Packages & memberships','Customer CRM','Offers & loyalty']},
 barber_shop:{unit:'Service',plural:'Services',booking:'Appointments',staff:'Barbers',primary:'Barber Services',settings:['Barber shop profile','Services & pricing','Barbers / staff','Working hours','Appointments','Packages','Customer CRM','Offers & loyalty']},
 spa_wellness:{unit:'Treatment',plural:'Treatments',booking:'Appointments',staff:'Therapists',primary:'Spa Treatments',settings:['Spa profile','Treatments & pricing','Therapists','Working hours','Appointments','Packages & memberships','Customer CRM','Offers & loyalty']},
 clinic_hospital:{unit:'Service',plural:'Services',booking:'Appointments',staff:'Doctors / Staff',primary:'Clinical Services',settings:['Clinic profile','Departments','Doctors & staff','Services','Appointments','Patients','Billing & insurance','Reports']},
 dentist_doctor:{unit:'Service',plural:'Services',booking:'Appointments',staff:'Doctors / Staff',primary:'Medical Services',settings:['Practice profile','Doctors','Services','Appointments','Patients','Prescriptions / notes','Billing','Reports']},
 pharmacy:{unit:'Product',plural:'Products',booking:'Orders',staff:'Staff',primary:'Pharmacy Products',settings:['Pharmacy profile','Products','Stock & batches','Suppliers','Sales','Customers','Billing & tax','Reports']},
 gym_yoga:{unit:'Class',plural:'Classes',booking:'Bookings',staff:'Trainers',primary:'Fitness Programs',settings:['Gym profile','Plans & memberships','Classes','Trainers','Schedules','Member CRM','Attendance','Payments']},
 retail_grocery:{unit:'Product',plural:'Products',booking:'Orders',staff:'Staff',primary:'Retail Catalog',settings:['Store profile','Products','Categories','Inventory','Suppliers','Orders','Customers','POS & billing']},
 fashion:{unit:'Product',plural:'Products',booking:'Orders',staff:'Staff',primary:'Fashion Catalog',settings:['Brand profile','Collections','Products & variants','Inventory','Orders','Customers','Offers','Storefront']},
 jewellery:{unit:'Product',plural:'Products',booking:'Orders',staff:'Sales Staff',primary:'Jewellery Catalog',settings:['Jewellery profile','Collections','Products','Inventory','Certificates','Sales','Customers','Storefront']},
 electronics_mobile:{unit:'Product',plural:'Products',booking:'Orders',staff:'Sales Staff',primary:'Electronics Catalog',settings:['Store profile','Products & IMEI','Inventory','Suppliers','Sales','Repairs','Customers','POS']},
 automotive:{unit:'Service',plural:'Services',booking:'Appointments',staff:'Technicians',primary:'Automotive Services',settings:['Workshop profile','Services','Vehicles','Customers','Technicians','Appointments','Job cards','Invoices']},
 real_estate:{unit:'Listing',plural:'Listings',booking:'Enquiries',staff:'Agents',primary:'Property Listings',settings:['Agency profile','Listings','Agents','Leads','Site visits','Deals','Documents','Reports']},
 travel:{unit:'Package',plural:'Packages',booking:'Bookings',staff:'Agents',primary:'Travel Packages',settings:['Travel profile','Packages','Destinations','Agents','Enquiries','Bookings','Suppliers','Payments']},
 education_coaching:{unit:'Course',plural:'Courses',booking:'Admissions',staff:'Teachers',primary:'Courses & Programs',settings:['Institute profile','Courses','Batches','Teachers','Students','Admissions','Fees','Attendance']},
 legal:{unit:'Matter',plural:'Matters',booking:'Consultations',staff:'Lawyers',primary:'Legal Matters',settings:['Firm profile','Practice areas','Lawyers','Clients','Matters','Appointments','Documents','Billing']},
 ca_accounting_tax:{unit:'Engagement',plural:'Engagements',booking:'Appointments',staff:'Professionals',primary:'Client Services',settings:['Firm profile','Services','Professionals','Clients','Engagements','Tasks','Documents','Billing']},
 it_agency:{unit:'Project',plural:'Projects',booking:'Enquiries',staff:'Team',primary:'Projects & Services',settings:['Agency profile','Services','Projects','Team','Leads','Tasks','Clients','Invoices']},
 repair_maintenance:{unit:'Service',plural:'Services',booking:'Jobs',staff:'Technicians',primary:'Repair Services',settings:['Business profile','Services','Technicians','Job intake','Jobs','Customers','Parts / inventory','Invoices']},
 cleaning:{unit:'Service',plural:'Services',booking:'Bookings',staff:'Cleaners',primary:'Cleaning Services',settings:['Business profile','Services','Staff','Service areas','Bookings','Customers','Schedules','Invoices']},
 veterinary:{unit:'Service',plural:'Services',booking:'Appointments',staff:'Vets / Staff',primary:'Veterinary Services',settings:['Clinic profile','Vets','Services','Appointments','Pet patients','Owners','Vaccinations','Billing']},
 photography:{unit:'Package',plural:'Packages',booking:'Bookings',staff:'Photographers',primary:'Photography Packages',settings:['Studio profile','Packages','Photographers','Portfolio','Enquiries','Bookings','Customers','Invoices']},
 events:{unit:'Event',plural:'Events',booking:'Bookings',staff:'Team',primary:'Events',settings:['Event company profile','Event types','Events','Venues','Clients','Bookings','Vendors','Invoices']},
 coworking:{unit:'Space',plural:'Spaces',booking:'Bookings',staff:'Community Team',primary:'Workspace Inventory',settings:['Workspace profile','Spaces','Memberships','Meeting rooms','Members','Bookings','Access','Billing']},
 logistics:{unit:'Shipment',plural:'Shipments',booking:'Orders',staff:'Drivers / Staff',primary:'Logistics Operations',settings:['Company profile','Services','Vehicles','Drivers','Shipments','Customers','Tracking','Billing']},
 construction_home_services:{unit:'Service',plural:'Services',booking:'Projects',staff:'Workers / Team',primary:'Home Services',settings:['Business profile','Services','Team','Leads','Projects','Site visits','Materials','Invoices']},
 ecommerce:{unit:'Product',plural:'Products',booking:'Orders',staff:'Team',primary:'E-commerce Catalog',settings:['Store profile','Products','Categories','Inventory','Orders','Customers','Coupons','Storefront']},
 saas_subscription:{unit:'Plan',plural:'Plans',booking:'Subscriptions',staff:'Team',primary:'Subscription Catalog',settings:['Company profile','Plans','Features','Customers','Subscriptions','Invoices','Usage','Analytics']},
 creator_personal_brand:{unit:'Offering',plural:'Offerings',booking:'Enquiries',staff:'Team',primary:'Creator Offerings',settings:['Brand profile','Offerings','Content','Audience','Leads','Bookings','Campaigns','Analytics']},
 non_profit:{unit:'Program',plural:'Programs',booking:'Donations',staff:'Team',primary:'Programs & Fundraising',settings:['Organization profile','Programs','Donors','Campaigns','Volunteers','Donations','Grants','Reports']},
 other:{unit:'Item',plural:'Items',booking:'Enquiries',staff:'Team',primary:'Business Catalog',settings:['Business profile','Items / services','Team','Leads','Customers','Bookings','Payments','Reports']}
};



const MODULES={
 salon:[['catalog','Services & Pricing'],['team','Stylists / Staff'],['schedule','Working Hours'],['appointments','Appointments'],['memberships','Packages & Memberships'],['offers','Offers & Loyalty'],['customers','Customers'],['landing','Front Landing Page']],
 barber_shop:[['catalog','Services & Pricing'],['team','Barbers / Staff'],['schedule','Working Hours'],['appointments','Appointments'],['memberships','Packages'],['offers','Offers & Loyalty'],['customers','Customers'],['landing','Front Landing Page']],
 spa_wellness:[['catalog','Treatments & Pricing'],['team','Therapists'],['schedule','Working Hours'],['appointments','Appointments'],['memberships','Packages & Memberships'],['offers','Offers & Loyalty'],['customers','Customers'],['landing','Front Landing Page']],
 clinic_hospital:[['departments','Departments'],['team','Doctors & Staff'],['catalog','Clinical Services'],['appointments','Appointments'],['patients','Patients'],['billing','Billing & Insurance'],['reports','Reports'],['landing','Front Landing Page']],
 dentist_doctor:[['team','Doctors'],['catalog','Medical Services'],['appointments','Appointments'],['patients','Patients'],['notes','Prescriptions / Notes'],['billing','Billing'],['reports','Reports'],['landing','Front Landing Page']],
 pharmacy:[['catalog','Products'],['inventory','Stock & Batches'],['suppliers','Suppliers'],['sales','Sales & Billing'],['customers','Customers'],['reports','Reports'],['landing','Front Landing Page']],
 gym_yoga:[['memberships','Plans & Memberships'],['catalog','Classes'],['team','Trainers'],['schedule','Schedules'],['customers','Members'],['attendance','Attendance'],['payments','Payments'],['landing','Front Landing Page']],
 retail_grocery:[['catalog','Products'],['categories','Categories'],['inventory','Inventory'],['suppliers','Suppliers'],['orders','Orders'],['customers','Customers'],['pos','POS & Billing'],['landing','Front Landing Page']],
 fashion:[['collections','Collections'],['catalog','Products & Variants'],['inventory','Inventory'],['orders','Orders'],['customers','Customers'],['offers','Offers'],['storefront','Storefront'],['landing','Front Landing Page']],
 jewellery:[['collections','Collections'],['catalog','Products'],['inventory','Inventory'],['certificates','Certificates'],['sales','Sales'],['customers','Customers'],['storefront','Storefront'],['landing','Front Landing Page']],
 electronics_mobile:[['catalog','Products & IMEI'],['inventory','Inventory'],['suppliers','Suppliers'],['sales','Sales'],['repairs','Repairs'],['customers','Customers'],['pos','POS'],['landing','Front Landing Page']],
 automotive:[['catalog','Services'],['vehicles','Vehicles'],['customers','Customers'],['team','Technicians'],['appointments','Appointments'],['jobs','Job Cards'],['billing','Invoices'],['landing','Front Landing Page']],
 real_estate:[['listings','Listings'],['team','Agents'],['leads','Leads'],['visits','Site Visits'],['deals','Deals'],['documents','Documents'],['reports','Reports'],['landing','Front Landing Page']],
 travel:[['catalog','Packages'],['destinations','Destinations'],['team','Agents'],['leads','Enquiries'],['bookings','Bookings'],['suppliers','Suppliers'],['payments','Payments'],['landing','Front Landing Page']],
 education_coaching:[['catalog','Courses'],['batches','Batches'],['team','Teachers'],['students','Students'],['admissions','Admissions'],['fees','Fees'],['attendance','Attendance'],['landing','Front Landing Page']],
 legal:[['practice','Practice Areas'],['team','Lawyers'],['customers','Clients'],['matters','Matters'],['appointments','Consultations'],['documents','Documents'],['billing','Billing'],['landing','Front Landing Page']],
 ca_accounting_tax:[['catalog','Services'],['team','Professionals'],['customers','Clients'],['engagements','Engagements'],['tasks','Tasks'],['documents','Documents'],['billing','Billing'],['landing','Front Landing Page']],
 it_agency:[['catalog','Services'],['projects','Projects'],['team','Team'],['leads','Leads'],['tasks','Tasks'],['customers','Clients'],['billing','Invoices'],['landing','Front Landing Page']],
 repair_maintenance:[['catalog','Services'],['team','Technicians'],['jobs','Job Intake / Jobs'],['customers','Customers'],['inventory','Parts / Inventory'],['billing','Invoices'],['reports','Reports'],['landing','Front Landing Page']],
 cleaning:[['catalog','Services'],['team','Staff'],['areas','Service Areas'],['bookings','Bookings'],['customers','Customers'],['schedule','Schedules'],['billing','Invoices'],['landing','Front Landing Page']],
 veterinary:[['team','Vets / Staff'],['catalog','Services'],['appointments','Appointments'],['patients','Pet Patients'],['customers','Owners'],['vaccinations','Vaccinations'],['billing','Billing'],['landing','Front Landing Page']],
 photography:[['catalog','Packages'],['team','Photographers'],['portfolio','Portfolio'],['leads','Enquiries'],['bookings','Bookings'],['customers','Customers'],['billing','Invoices'],['landing','Front Landing Page']],
 events:[['types','Event Types'],['events','Events'],['venues','Venues'],['customers','Clients'],['bookings','Bookings'],['vendors','Vendors'],['billing','Invoices'],['landing','Front Landing Page']],
 coworking:[['spaces','Spaces'],['memberships','Memberships'],['rooms','Meeting Rooms'],['customers','Members'],['bookings','Bookings'],['access','Access'],['billing','Billing'],['landing','Front Landing Page']],
 logistics:[['catalog','Services'],['vehicles','Vehicles'],['team','Drivers / Staff'],['shipments','Shipments'],['customers','Customers'],['tracking','Tracking'],['billing','Billing'],['landing','Front Landing Page']],
 construction_home_services:[['catalog','Services'],['team','Team'],['leads','Leads'],['projects','Projects'],['visits','Site Visits'],['inventory','Materials'],['billing','Invoices'],['landing','Front Landing Page']],
 ecommerce:[['catalog','Products'],['categories','Categories'],['inventory','Inventory'],['orders','Orders'],['customers','Customers'],['offers','Coupons'],['storefront','Storefront'],['landing','Front Landing Page']],
 saas_subscription:[['plans','Plans'],['features','Features'],['customers','Customers'],['subscriptions','Subscriptions'],['billing','Invoices'],['usage','Usage'],['reports','Analytics'],['landing','Front Landing Page']],
 creator_personal_brand:[['catalog','Offerings'],['content','Content'],['customers','Audience'],['leads','Leads'],['bookings','Bookings'],['campaigns','Campaigns'],['reports','Analytics'],['landing','Front Landing Page']],
 non_profit:[['programs','Programs'],['customers','Donors'],['campaigns','Campaigns'],['team','Volunteers'],['donations','Donations'],['grants','Grants'],['reports','Reports'],['landing','Front Landing Page']],
 other:[['catalog','Items / Services'],['team','Team'],['leads','Leads'],['customers','Customers'],['bookings','Bookings'],['payments','Payments'],['reports','Reports'],['landing','Front Landing Page']]
};

export function businessModules(type){
 const base=MODULES[type]||MODULES.other;
 return base.map(([key,label])=>({key,label}));
}

export function businessConfig(type){
 const found=BUSINESS_TYPES.find(x=>x[0]===type); const base={code:type,icon:found?.[1]||'•',name:found?.[2]||'Business',category:found?.[3]||'general'};
 if(type==='hotel_resort') return {...base,unit:'Room',plural:'Rooms',booking:'Reservations',staff:'Staff',primary:'Hotel Rooms',settings:['Hotel profile','Room types','Rooms','Rate plans','Inventory','Reservations','PMS / Front Desk','Housekeeping']};
 if(type==='restaurant_cafe') return {...base,unit:'Menu Item',plural:'Menu Items',booking:'Reservations / Orders',staff:'Restaurant Staff',primary:'Restaurant Menu',settings:['Restaurant profile','Menu & categories','Tables','Reservations','POS','Orders','Kitchen','Delivery / pickup']};
 return {...base,...SPECIAL[type]};
}

export function typeOptions(){return BUSINESS_TYPES.map(([code,icon,name])=>({code,icon,name}));}
