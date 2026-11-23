'use client';
import { useEffect, useMemo, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { supabase } from '../lib/supabase';

const PLUGIN_BY_ROUTE = {
  '/customer-360':'crm','/stays':'crm','/hotel-guest-crm':'hotel_guest_crm','/restaurant':'crm','/leads':'crm','/corporate':'crm','/partners':'crm',
  '/loyalty':'crm','/marketing':'crm','/campaigns':'crm','/guest-relations':'crm','/complaints':'crm','/revenue':'crm',
  '/analytics':'crm','/events':'crm','/ai':'crm','/segmentation':'crm','/vip':'crm','/timeline':'crm','/upselling':'crm',
  '/forecasting':'crm','/competitors':'crm','/ota':'crm','/workflows':'crm','/intelligence':'crm','/guest-requests':'crm',
  '/quotes':'crm','/partner-bookings':'crm','/reviews':'crm','/offers-coupons':'crm','/service-recovery':'crm','/service-tickets':'crm','/restaurant-crm':'crm','/customer-intelligence':'crm','/customer-ltv':'crm','/followups':'crm','/churn':'crm','/cross-selling':'crm','/reputation':'crm','/booking':'hotel-booking','/booking-engine':'hotel-booking','/hotel-management':'hotel-management-suite','/hotel-management/setup':'hotel-management-suite','/booking-engine/camping':'hotel-booking','/booking-engine/stays':'hotel-booking','/hotel-management/room-types':'hotel-management-suite','/hotel-management/rooms':'hotel-management-suite','/hotel-management/rates':'hotel-management-suite','/hotel-management/inventory':'hotel-management-suite','/hotel-management/rate-calendar':'hotel-management-suite','/pms':'hotel-pms','/reservation':'restaurant-reservation',
  '/delivery':'food-delivery','/store':'restaurant-store','/restaurant-stores':'restaurant-store','/channel-manager':'channel-manager','/pos':'anaira-pos','/housekeeping':'hotel-pms','/seo':'seo-system','/plugins/seo-system/settings':'seo-system','/ai-reviews':'ai-review-system'
};
const PERMISSION_BY_ROUTE = {
  '/customer-360':'customer.view','/stays':'customer.view','/hotel-guest-crm':'hotel_guest_crm.view','/restaurant':'customer.view','/leads':'lead.view','/corporate':'corporate.view','/partners':'corporate.view',
  '/loyalty':'loyalty.view','/marketing':'segment.view','/campaigns':'campaign.view','/guest-relations':'review.view','/complaints':'complaint.view','/revenue':'report.revenue',
  '/analytics':'report.view','/events':'corporate.view','/ai':'report.view','/segmentation':'segment.view','/vip':'customer.view','/timeline':'timeline.view','/upselling':'customer.view',
  '/forecasting':'report.revenue','/competitors':'report.revenue','/ota':'report.view','/workflows':'task.view','/intelligence':'customer.view','/guest-requests':'guest_request.view',
  '/quotes':'corporate.view','/partner-bookings':'corporate.view','/reviews':'review.view','/offers-coupons':'segment.view','/service-recovery':'complaint.resolve','/service-tickets':'staff.activity','/restaurant-crm':'customer.view','/customer-intelligence':'customer.view','/customer-ltv':'customer.view','/followups':'task.view','/churn':'customer.view','/cross-selling':'customer.view','/reputation':'review.view','/booking':'booking.view','/hotel-store':'booking.view','/hotel-management':'hms.room.view','/pms':'pms.room.view','/reservation':'reservation.view',
  '/delivery':'delivery.order.view','/store':'store.view','/channel-manager':'ota.sync.view','/pos':'pos.order.view','/housekeeping':'housekeeping.task.view','/my-work':'task.view','/team-tasks':'task.view',
  '/import-export':'customer.export','/activity':'staff.activity','/store-builder':'store.view','/plugins/seo-system/settings':'seo-system.configure'
};
const SUPER_ONLY_ROUTES = ['/super-admin','/anaira/super-admin','/admin','/properties','/business-admins','/audit','/platform-settings','/system','/super-admin/marketplace-settings','/super-admin/hotel-marketplace-settings','/super-admin/booking-engine','/super-admin/stores','/super-admin/anaira-store'];
const ADMIN_ONLY_ROUTES = ['/store-builder','/users','/roles','/restaurant-setup'];
const BUSINESS_SETTINGS_ROUTE='/business-settings';

const SUPER_GROUPS = [
  {title:'COMMAND CENTER',items:[['▦','Dashboard','/admin'],['▦','Properties / Tenants','/properties'],['♙','Business Admins','/business-admins'],['♙','Users & Staff','/users'],['◆','Roles & Profiles','/roles'],['◇','Plugin Control Center','/plugins'],['⚙','Global Integrations','/super-admin/integrations'],['◆','SEO System','/seo'],['★','AI Review Automation','/ai-reviews'],['◫','Audit Logs','/audit'],['⚙','Platform Settings','/platform-settings'],['▣','Global Booking Engine','/super-admin/booking-engine'],['⌂','Hotel Profile / Setup','/hotel-management/setup'],['♨','Restaurant Profile / Setup','/restaurant-setup']]},
  {title:'ANAIRA STORES',items:[['◆','ANAIRA Store & QR','/super-admin/anaira-store'],['🏨','Hotel Marketplace Store','/anaira/hotels'],['⚙','Hotel Marketplace Settings','/super-admin/hotel-marketplace-settings'],['🍽','Restaurant Marketplace','/store'],['⚙','Restaurant Marketplace Settings','/super-admin/marketplace-settings']]},
  {title:'CRM PLATFORM',items:[['◉','Customer 360','/customer-360'],['⌂','Hotel Guest CRM','/hotel-guest-crm'],['♨','Restaurant CRM','/restaurant'],['◆','Leads & Sales','/leads'],['▣','Corporate CRM','/corporate'],['♢','Partners','/partners'],['↔','Timeline / Interactions','/timeline'],['★','Guest Relations','/guest-relations'],['⚠','Complaints / Service Recovery','/complaints'],['★','Loyalty','/loyalty'],['◇','Segmentation','/segmentation'],['✦','VIP Management','/vip'],['◈','Offers & Coupons','/marketing'],['✉','Campaigns','/campaigns'],['◌','WhatsApp CRM','/whatsapp-crm'],['⚙','Workflows / Automation','/workflows'],['✦','Events & Upselling','/events']]},
  {title:'BUSINESS INTELLIGENCE',items:[['▤','Analytics','/analytics'],['₹','Revenue Management','/revenue'],['◈','Forecasting','/forecasting'],['◈','Competitor Intelligence','/competitors'],['⇄','OTA / Channel Performance','/ota'],['✧','AI Insights','/ai'],['✧','Decision Intelligence','/intelligence']]},
  {title:'OPERATIONS',items:[['⌂','Hotel Booking','/booking'],['▣','Booking Engine Control','/booking-engine'],['▦','Anaira Hotel Management','/hotel-management'],['▤','Hotel PMS','/pms'],['◫','Restaurant Reservation','/reservation'],['▣','Anaira POS','/pos'],['◉','Food Delivery','/delivery'],['⇄','Channel / OTA Manager','/channel-manager'],['⚙','Hotel Setup','/hotel-management/setup'],['♨','Restaurant Setup','/restaurant-setup']]},
];

const HOSPITALITY_MANAGEMENT_GROUPS = {
  hotel: {title:'HOTEL MANAGEMENT', items:[]},
  camp: {title:'CAMPING MANAGEMENT', items:[]},
  homestay: {title:'HOMESTAY MANAGEMENT', items:[]},
  guest_house: {title:'GUEST HOUSE MANAGEMENT', items:[]},
  cottage: {title:'COTTAGE MANAGEMENT', items:[]}
};
const HOSPITALITY_PLUGIN={hotel:'hotel-management-suite',camp:'camping-management',homestay:'homestay-management',guest_house:'guest-house-management',cottage:'cottage-management'};

function normalizeHospitalityType(value){
  const raw=String(value||'').trim().toLowerCase().replace(/[\s-]+/g,'_');
  const aliases={camping:'camp',campground:'camp',tent:'camp',guesthouse:'guest_house',homestay_property:'homestay',holiday_cottage:'cottage'};
  const type=aliases[raw]||raw;
  return HOSPITALITY_PLUGIN[type]?type:null;
}
function readHospitalityTypes(raw, primary, businessType){
  let values=[];
  if(Array.isArray(raw)) values=raw;
  else if(typeof raw==='string'&&raw.trim()){
    try { const parsed=JSON.parse(raw); values=Array.isArray(parsed)?parsed:[parsed]; }
    catch { values=raw.split(',').map(x=>x.trim()).filter(Boolean); }
  }
  if(!values.length&&primary) values=[primary];
  if(!values.length&&businessType) values=[businessType];
  if(!values.length&&['hotel_resort','hotel_restaurant'].includes(String(businessType||'').trim().toLowerCase())) values=['hotel'];
  return [...new Set(values.map(normalizeHospitalityType).filter(Boolean))];
}
const HOSPITALITY_MENU_META={
 hotel:['Hotel','Hotel','Hotel'],camp:['Camping','Camp','Camping'],homestay:['Homestay','Accommodation','Homestay'],guest_house:['Guest House','Accommodation','Guest House'],cottage:['Cottage','Cottage','Cottage']
};

const BUSINESS_GROUPS = [
  {title:'COMMAND CENTER',items:[['▦','Dashboard','/'],['◌','My Tasks / Work Queue','/my-work']]},
  {title:'CRM',items:[['◉','Customer 360','/customer-360','customer.view','crm'],['⌂','Hotel Guest CRM','/hotel-guest-crm','customer.view','crm'],['♨','Restaurant CRM','/restaurant','customer.view','crm'],['↔','Timeline / Interactions','/timeline','timeline.view','crm'],['◆','Leads & Sales','/leads','lead.view','crm'],['▣','Corporate CRM','/corporate','corporate.view','crm'],['♢','Partners','/partners','corporate.view','crm'],['▤','Quotes','/quotes','corporate.view','crm'],['▤','Partner Bookings','/partner-bookings','corporate.view','crm'],['★','Guest Relations','/guest-relations','review.view','crm'],['⚠','Complaints','/complaints','complaint.view','crm'],['✦','Service Recovery','/service-recovery','complaint.resolve','crm'],['★','VIP','/vip','customer.view','crm'],['★','Loyalty','/loyalty','loyalty.view','crm'],['◇','Segments','/segmentation','segment.view','crm'],['◈','Offers & Coupons','/offers-coupons','segment.view','crm'],['✉','Campaigns','/campaigns','campaign.view','crm'],['◌','WhatsApp CRM','/whatsapp-crm','crm.view','crm'],['⚙','Workflows / Automation','/workflows','task.view','crm'],['◆','SEO System','/seo','report.view','seo-system'],['★','AI Review Automation','/ai-reviews','review.view','ai-review-system'],['✦','Events / Upselling','/events','corporate.view','crm']]},
  {title:'INTELLIGENCE',items:[['▤','Analytics','/analytics','report.view','crm'],['₹','Revenue Management','/revenue','report.revenue','crm'],['◈','Forecasting','/forecasting','report.revenue','crm'],['◈','Competitor Intelligence','/competitors','report.revenue','crm'],['⇄','OTA / Channel Performance','/ota','report.view','crm'],['✧','AI Insights','/ai','report.view','crm'],['✧','Decision Intelligence','/intelligence','customer.view','crm']]},
  {title:'HOTEL MANAGEMENT',items:[['▦','Hotel Dashboard','/hotel-management','hms.room.view','hotel-management-suite'],['⌂','Hotel Profile','/hotel-management/setup','business.settings','hotel-management-suite'],['▣','Room Types','/hotel-management/room-types','hms.room.view','hotel-management-suite'],['▣','Rooms','/hotel-management/rooms','hms.room.view','hotel-management-suite'],['▦','Room Inventory','/hotel-management/inventory','hms.room.view','hotel-management-suite'],['₹','Rate Plans','/hotel-management/rates','booking.view','hotel-management-suite'],['⌂','Reservations','/booking','booking.view','hotel-booking'],['▤','PMS / Front Desk','/pms','pms.room.view','hotel-pms'],['⌂','Housekeeping','/housekeeping','housekeeping.task.view','hotel-pms']]},
  {title:'OPERATIONS',items:[['⌂','Hotel Booking Engine','/booking','booking.view','hotel-booking'],['🏨','My Hotel Store','/store-builder?kind=hotel','booking.view','hotel-booking'],['▣','Booking Engine Control','/booking-engine','booking.view','hotel-booking'],['◫','Restaurant Reservation','/reservation','reservation.view','restaurant-reservation'],['▣','Anaira POS','/pos','pos.order.view','anaira-pos'],['◉','Food Delivery','/delivery','delivery.order.view','food-delivery'],['◇','My Restaurant Store','/store-builder?kind=restaurant','store.view','restaurant-store'],['⇄','Channel / OTA','/channel-manager','ota.sync.view','channel-manager']]},
  {title:'MANAGEMENT',items:[['♙','Staff','/users','staff.view'],['◆','Roles & Profiles','/roles','staff.manage'],['⚙','Business Settings','/business-settings','business.settings'],['⚙','Integrations','/integrations','business.settings'],['⇄','Import / Export','/import-export','customer.export'],['♨','Restaurant Setup','/restaurant-setup','business.settings'],['◫','Activity Log','/activity','staff.activity']]},
];

const ROLE_GROUPS = {
  manager:[
    {title:'COMMAND CENTER',items:[['▦','Dashboard','/'],['◌','My Work','/my-work','task.view'],['☑','Team Tasks','/team-tasks','task.view']]},
    {title:'OPERATIONS',items:[['⌂','Bookings','/booking','booking.view','hotel-booking'],['▣','Booking Engine Control','/booking-engine','booking.view','hotel-booking'],['▦','Hotel Management','/hotel-management','hms.room.view','hotel-management-suite'],['▤','PMS','/pms','pms.room.view','hotel-pms'],['◫','Restaurant Reservations','/reservation','reservation.view','restaurant-reservation'],['▣','POS','/pos','pos.order.view','anaira-pos'],['◉','Delivery','/delivery','delivery.order.view','food-delivery'],['⌂','Housekeeping','/housekeeping','housekeeping.task.view','hotel-pms']]},
    {title:'CRM',items:[['◉','Customer 360','/customer-360','customer.view','crm'],['★','Guest Relations','/guest-relations','review.view','crm'],['◌','Guest Requests','/guest-requests','guest_request.view','crm'],['⚠','Complaints','/complaints','complaint.view','crm'],['✦','Service Recovery','/service-recovery','complaint.resolve','crm']]},
    {title:'SALES',items:[['◆','Leads','/leads','lead.view','crm'],['▣','Corporate Accounts','/corporate','corporate.view','crm'],['♢','Partners','/partners','corporate.view','crm']]},
    {title:'REPORTS',items:[['▤','Operational Reports','/analytics','report.view','crm'],['₹','Sales Reports','/leads','report.view','crm'],['★','Guest Reports','/customer-360','report.view','crm'],['₹','Revenue Reports','/revenue','report.revenue','crm']]},
    {title:'ACCOUNT',items:[['◉','My Profile','/profile'],['◆','My Permissions','/my-permissions']]}
  ],
  staff:[
    {title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},
    {title:'MY WORK',items:[['◌','Today’s Tasks','/my-work','task.view'],['⚠','Assigned Complaints','/complaints','complaint.view','crm'],['⌂','Guest Requests','/guest-requests','guest_request.view','crm']]},
    {title:'PROFILE WORKSPACE',items:[['▣','Open Workspace','/my-work','task.view']]}
  ]
};

const PROFILE_GROUPS = {
  front_desk:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'FRONT DESK',items:[['⌂','Arrivals','/booking','booking.view','hotel-booking'],['▦','Hotel Management','/hotel-management','hms.room.view','hotel-management-suite'],['✓','Check-in','/booking','booking.edit','hotel-booking'],['✓','Check-out','/booking','booking.edit','hotel-booking'],['▣','Bookings','/booking','booking.view','hotel-booking'],['◉','Guests','/customer-360','customer.view','crm'],['▤','Room Status','/pms','pms.room.status','hotel-pms'],['◌','Guest Requests','/guest-requests','guest_request.view','crm']]},{title:'SERVICE',items:[['⚠','Complaints','/complaints','complaint.view','crm'],['★','Reviews','/guest-relations','review.view','crm']]}],
  reservation_agent:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'RESERVATIONS',items:[['▣','Bookings','/booking','booking.view','hotel-booking'],['◫','Restaurant Reservations','/reservation','reservation.view','restaurant-reservation'],['◉','Guests','/customer-360','customer.view','crm'],['↔','Timeline','/timeline','timeline.view','crm']]},{title:'SALES',items:[['◆','Leads','/leads','lead.view','crm'],['☑','Follow-ups','/my-work','task.view','crm']]}],
  cashier:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'POS',items:[['▣','New Order','/pos','pos.order.create','anaira-pos'],['▣','Open Bills','/pos','pos.order.view','anaira-pos'],['₹','Payments','/pos','pos.payment.collect','anaira-pos'],['↩','Refunds','/pos','pos.payment.refund','anaira-pos'],['✓','Day Closing','/pos','pos.payment.close','anaira-pos']]},{title:'REPORTS',items:[['▤','Reports','/analytics','report.view','crm']]}],
  kitchen:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'KITCHEN',items:[['▣','KOT','/pos','pos.order.view','anaira-pos'],['▣','KDS','/pos','pos.order.view','anaira-pos'],['◉','Pending Orders','/pos','pos.order.view','anaira-pos'],['◉','Preparing','/pos','pos.order.edit','anaira-pos'],['✓','Completed','/pos','pos.order.view','anaira-pos']]}],
  housekeeping:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'HOUSEKEEPING',items:[['▤','Room Status','/pms','pms.room.status','hotel-pms'],['◌','Cleaning Queue','/housekeeping','housekeeping.task.view','hotel-pms'],['⚙','Maintenance Requests','/guest-requests','guest_request.view','crm'],['✓','Completed Rooms','/housekeeping','housekeeping.task.complete','hotel-pms']]}],
  restaurant_service:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'SERVICE',items:[['◫','Reservations','/reservation','reservation.view','restaurant-reservation'],['▣','New Order','/pos','pos.order.create','anaira-pos'],['◉','Orders','/pos','pos.order.view','anaira-pos'],['◌','Guest Requests','/guest-requests','guest_request.view','crm'],['⚠','Complaints','/complaints','complaint.view','crm']]}],
  sales_executive:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'SALES',items:[['◆','Leads','/leads','lead.view','crm'],['☑','Follow-ups','/my-work','task.view','crm'],['▤','Quotes','/quotes','corporate.view','crm'],['▣','Corporate Accounts','/corporate','corporate.view','crm'],['♢','Partners','/partners','corporate.view','crm']]}],
  marketing_executive:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'MARKETING',items:[['◇','Segments','/segmentation','segment.view','crm'],['✉','Campaigns','/campaigns','campaign.view','crm'],['◌','WhatsApp CRM','/whatsapp-crm','crm.view','crm'],['★','Reviews','/guest-relations','review.view','crm']]}],
  crm_executive:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/'],['◌','My Work','/my-work','task.view']]},{title:'CRM',items:[['◉','Customer 360','/customer-360','customer.view','crm'],['↔','Timeline','/timeline','timeline.view','crm'],['◆','Leads','/leads','lead.view','crm'],['⚠','Complaints','/complaints','complaint.view','crm'],['★','Loyalty','/loyalty','loyalty.view','crm'],['◇','Segments','/segmentation','segment.view','crm'],['◌','Guest Requests','/guest-requests','guest_request.view','crm']]}],
  accountant:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'FINANCE',items:[['₹','Revenue Reports','/revenue','report.revenue','crm'],['▤','Reports','/analytics','report.financial','crm'],['▣','POS Payments','/pos','pos.payment.collect','anaira-pos'],['↩','Refunds','/pos','pos.payment.refund','anaira-pos']]}],
  read_only:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'VIEW',items:[['◉','Customer 360','/customer-360','customer.view','crm'],['⌂','Bookings','/booking','booking.view','hotel-booking'],['▣','Booking Engine Control','/booking-engine','booking.view','hotel-booking'],['▦','Hotel Management','/hotel-management','hms.room.view','hotel-management-suite'],['▤','PMS','/pms','pms.room.view','hotel-pms'],['▣','POS','/pos','pos.order.view','anaira-pos'],['▤','Reports','/analytics','report.view','crm']]}]
};


Object.entries(HOSPITALITY_MANAGEMENT_GROUPS).forEach(([type,g])=>{
 const [label,unit,short]=HOSPITALITY_MENU_META[type];
 g.items=[
  ['▦',`${label} Dashboard`,'/hotel-management','hms.room.view',HOSPITALITY_PLUGIN[type]],
  ['⌂',`${label} Profile`,'/hotel-management/setup','business.settings',HOSPITALITY_PLUGIN[type]],
  ['▣',type==='hotel'?'Room Types':`${unit} Types`,'/hotel-management/room-types','hms.room.view',HOSPITALITY_PLUGIN[type]],
  ['▣',type==='hotel'?'Rooms':`${unit}s`,'/hotel-management/rooms','hms.room.view',HOSPITALITY_PLUGIN[type]],
  ['▦',type==='hotel'?'Room Inventory':`${label} Inventory`,'/hotel-management/inventory','hms.room.view',HOSPITALITY_PLUGIN[type]],
  ['₹','Rate Plans','/hotel-management/rates','booking.view',HOSPITALITY_PLUGIN[type]],
  ['⌂','Reservations','/booking','booking.view','hotel-booking'],
  ['▤',`${label} PMS / Front Desk`,'/pms','pms.room.view',HOSPITALITY_PLUGIN[type]],
  ['⌂',`${label} Housekeeping`,'/housekeeping','housekeeping.task.view',HOSPITALITY_PLUGIN[type]]
 ];
});


const BUSINESS_TYPE_MENU = {
 salon:{title:'SALON',items:[['💇','Salon Dashboard','/business/salon','business.settings'],['⚙','Salon Setup','/business/salon/setup','business.settings'],['✂','Services & Pricing','/business/salon/setup','business.settings'],['♙','Stylists / Staff','/business/salon/setup','business.settings'],['◷','Working Hours','/business/salon/setup','business.settings'],['◉','Appointments','/business/salon/setup','business.settings'],['◇','Packages & Memberships','/business/salon/setup','business.settings'],['◈','Offers & Loyalty','/business/salon/setup','business.settings'],['↗','Front Landing Page','/business/salon','business.settings']]},
 barber_shop:{title:'BARBER SHOP',items:[['💈','Barber Dashboard','/business/barber_shop','business.settings'],['⚙','Barber Shop Setup','/business/barber_shop/setup','business.settings'],['✂','Services & Pricing','/business/barber_shop/setup','business.settings'],['♙','Barbers / Staff','/business/barber_shop/setup','business.settings'],['◷','Working Hours','/business/barber_shop/setup','business.settings'],['◉','Appointments','/business/barber_shop/setup','business.settings'],['◇','Packages','/business/barber_shop/setup','business.settings'],['◈','Offers & Loyalty','/business/barber_shop/setup','business.settings'],['↗','Front Landing Page','/business/barber_shop','business.settings']]},
 spa_wellness:{title:'SPA / WELLNESS',items:[['💆','Spa Dashboard','/business/spa_wellness','business.settings'],['⚙','Spa Setup','/business/spa_wellness/setup','business.settings'],['✦','Treatments & Pricing','/business/spa_wellness/setup','business.settings'],['♙','Therapists','/business/spa_wellness/setup','business.settings'],['◷','Working Hours','/business/spa_wellness/setup','business.settings'],['◉','Appointments','/business/spa_wellness/setup','business.settings'],['◇','Packages & Memberships','/business/spa_wellness/setup','business.settings'],['◈','Offers & Loyalty','/business/spa_wellness/setup','business.settings'],['↗','Front Landing Page','/business/spa_wellness','business.settings']]},
 clinic_hospital:{title:'CLINIC / HOSPITAL',items:[['🏥','Clinic Dashboard','/business/clinic_hospital','business.settings'],['⚙','Clinic Setup','/business/clinic_hospital/setup','business.settings'],['▣','Departments','/business/clinic_hospital/setup','business.settings'],['♙','Doctors & Staff','/business/clinic_hospital/setup','business.settings'],['✦','Services','/business/clinic_hospital/setup','business.settings'],['◉','Appointments','/business/clinic_hospital/setup','business.settings'],['◈','Patients','/business/clinic_hospital/setup','business.settings'],['↗','Front Landing Page','/business/clinic_hospital','business.settings']]},
 dentist_doctor:{title:'DENTIST / DOCTOR',items:[['🦷','Practice Dashboard','/business/dentist_doctor','business.settings'],['⚙','Practice Setup','/business/dentist_doctor/setup','business.settings'],['♙','Doctors','/business/dentist_doctor/setup','business.settings'],['✦','Services','/business/dentist_doctor/setup','business.settings'],['◉','Appointments','/business/dentist_doctor/setup','business.settings'],['◈','Patients','/business/dentist_doctor/setup','business.settings'],['↗','Front Landing Page','/business/dentist_doctor','business.settings']]},
 pharmacy:{title:'PHARMACY',items:[['💊','Pharmacy Dashboard','/business/pharmacy','business.settings'],['⚙','Pharmacy Setup','/business/pharmacy/setup','business.settings'],['▣','Products','/business/pharmacy/setup','business.settings'],['▤','Stock & Batches','/business/pharmacy/setup','business.settings'],['♙','Suppliers','/business/pharmacy/setup','business.settings'],['₹','Sales & Billing','/business/pharmacy/setup','business.settings'],['↗','Front Landing Page','/business/pharmacy','business.settings']]},
 gym_yoga:{title:'GYM / YOGA',items:[['🏋️','Fitness Dashboard','/business/gym_yoga','business.settings'],['⚙','Gym / Yoga Setup','/business/gym_yoga/setup','business.settings'],['◇','Plans & Memberships','/business/gym_yoga/setup','business.settings'],['▣','Classes','/business/gym_yoga/setup','business.settings'],['♙','Trainers','/business/gym_yoga/setup','business.settings'],['◷','Schedules','/business/gym_yoga/setup','business.settings'],['◉','Members','/business/gym_yoga/setup','business.settings'],['↗','Front Landing Page','/business/gym_yoga','business.settings']]}
};
function businessTypeMenuFallback(type){
 const map={retail_grocery:'Retail / Grocery',fashion:'Fashion',jewellery:'Jewellery',electronics_mobile:'Electronics / Mobile',automotive:'Automotive',real_estate:'Real Estate',travel:'Travel',education_coaching:'Education / Coaching',legal:'Legal',ca_accounting_tax:'CA / Accounting / Tax',it_agency:'IT / Agency',repair_maintenance:'Repair / Maintenance',cleaning:'Cleaning',veterinary:'Veterinary',photography:'Photography',events:'Events',coworking:'Coworking',logistics:'Logistics',construction_home_services:'Construction / Home Services',ecommerce:'E-commerce',saas_subscription:'SaaS / Subscription',creator_personal_brand:'Creator / Personal Brand',non_profit:'Non-profit',other:'Business'};
 const label=map[type]; if(!label)return null; return {title:label.toUpperCase(),items:[['▦',`${label} Dashboard`,`/business/${type}`,'business.settings'],['⚙',`${label} Setup`,`/business/${type}/setup`,'business.settings'],['▣','Catalog / Services',`/business/${type}/setup`,'business.settings'],['♙','Team / Staff',`/business/${type}/setup`,'business.settings'],['◉','Bookings / Enquiries',`/business/${type}/setup`,'business.settings'],['◈','Offers / Promotions',`/business/${type}/setup`,'business.settings'],['↗','Front Landing Page',`/business/${type}`,'business.settings']]};
}

const TENANT_ADMIN_ROLES = new Set(['admin','business_admin','owner','business_owner','tenant_admin','property_admin','property_owner','hospitality_admin','hotel_admin','hotel_owner','homestay_admin','homestay_owner','homestay_manager','guest_house_admin','guest_house_owner','guest_house_manager','cottage_admin','cottage_owner','cottage_manager','camp_admin','camp_owner','camp_manager']);
function normalizeRoleKey(value){return String(value||'').trim().toLowerCase().replace(/[\s-]+/g,'_');}
function isTenantAdminContext(role,profileKey){return TENANT_ADMIN_ROLES.has(normalizeRoleKey(role))||TENANT_ADMIN_ROLES.has(normalizeRoleKey(profileKey));}
function hospitalityTypeForAdminRole(role,profileKey){
 const aliases={hotel_admin:'hotel',hotel_owner:'hotel',camp_admin:'camp',camping_admin:'camp',camp_owner:'camp',camp_manager:'camp',homestay_admin:'homestay',homestay_owner:'homestay',homestay_manager:'homestay',guest_house_admin:'guest_house',guesthouse_admin:'guest_house',guest_house_owner:'guest_house',guest_house_manager:'guest_house',cottage_admin:'cottage',cottage_owner:'cottage',cottage_manager:'cottage'};
 return aliases[normalizeRoleKey(role)]||aliases[normalizeRoleKey(profileKey)]||null;
}
function normalizeGroups(groups){return groups.map(g=>({...g,items:g.items.map(x=>({icon:x[0],label:x[1],href:x[2],permission:x[3],plugin:x[4]}))}));}

function hospitalityManagementItems(type){
  const m=hospitalityMetaForSidebar(type);
  const plugin=HOSPITALITY_PLUGIN[type]||'hotel-management-suite';
  const unitType={hotel:'Room',camp:'Camp / Tent',homestay:'Homestay Unit',guest_house:'Guest House Unit',cottage:'Cottage'}[type]||'Accommodation';
  const unit={hotel:'Room',camp:'Camp',homestay:'Unit',guest_house:'Unit',cottage:'Cottage'}[type]||'Unit';
  return [
    ['▦',`${m.label} Dashboard`,`/hotel-management?type=${type}`,'hms.room.view',plugin],
    ['✎',`Edit ${m.label} Property Profile`,`/hotel-management/setup?type=${type}`,'business.settings',plugin],
    ['▣',type==='hotel'?'Room Types':`${unitType} Types`,`/hotel-management/room-types?type=${type}`,'hms.room.view',plugin],
    ['▣',type==='hotel'?'Rooms':`${unit}s`,`/hotel-management/rooms?type=${type}`,'hms.room.view',plugin],
    ['▦',type==='hotel'?'Room Inventory':`${m.label} Inventory`,`/hotel-management/inventory?type=${type}`,'hms.room.view',plugin],
    ['₹','Rate Plans',`/hotel-management/rates?type=${type}`,'booking.view',plugin],
    ['₹','Daily Rate Calendar',`/hotel-management/rate-calendar?type=${type}`,'booking.view',plugin],
    ['⌂','Reservations',`/booking?type=${type}`,'booking.view',plugin],
    ['▤',`${m.label} PMS / Front Desk`,`/pms?type=${type}`,'pms.room.view',plugin],
    ['⌂',`${m.label} Housekeeping`,`/housekeeping?type=${type}`,'housekeeping.task.view',plugin]
  ];
}
function hospitalityRevenueItems(type){
  const m=hospitalityMetaForSidebar(type);
  const plugin=HOSPITALITY_PLUGIN[type]||'hotel-management-suite';
  return [
    ['↔','Room / Rate Mapping',`/hotel-management/room-rate-mapping?type=${type}`,'booking.view',plugin],
    ['▤','Booking Source',`/hotel-management/booking-source?type=${type}`,'booking.view',plugin],
    ['⇄','Channel / OTA Manager',`/channel-manager?type=${type}`,'ota.sync.view','channel-manager'],
    ['◇','Yield Management',`/revenue-management?type=${type}`,'report.revenue',plugin]
  ];
}
function hospitalityOperationItems(types){
  const out=[];
  for(const type of types){
    const m=hospitalityMetaForSidebar(type);
    const plugin=HOSPITALITY_PLUGIN[type]||'hotel-management-suite';
    out.push(
      ['⌂',`${m.label} Booking Engine`,`/booking?type=${type}`,'booking.view',plugin],
      ['🏨',`My ${m.label} Store`,'/store-builder?kind='+encodeURIComponent(type)+'&hospitality_type='+encodeURIComponent(type),'booking.view',plugin],
      ['▣',`${m.label} Booking Control`,`/booking-engine?type=${type}`,'booking.view',plugin]
    );
  }
  return out;
}
function hospitalityMetaForSidebar(type){
  return {
    hotel:{label:'Hotel'},
    camp:{label:'Camping'},
    homestay:{label:'Homestay'},
    guest_house:{label:'Guest House'},
    cottage:{label:'Cottage'}
  }[type]||{label:'Hospitality'};
}
function stripStaticHospitalityItems(group){
  const blocked=['/hotel-management','/hotel-management/setup','/hotel-management/room-types','/hotel-management/rooms','/hotel-management/rates','/hotel-management/inventory','/booking','/booking-engine','/pms','/housekeeping','/store-builder'];
  return {...group,items:group.items.filter(x=>!blocked.includes(String(x[2]||'').split('?')[0]))};
}

export function AppShell({children, active}) {
  const pathname=usePathname(); const router=useRouter();
  const [ctx,setCtx]=useState({loading:true,session:null,role:null,profileKey:null,isSuperAdmin:false,restaurantId:null,businessType:null,plugins:{},permissions:{},hospitalityType:null,hospitalityTypes:[]});
  useEffect(()=>{
    let alive=true;
    let requestId=0;
    const loadContext=async(session)=>{
      const current=++requestId;
      if(!session){
        if(alive)setCtx({loading:false,session:null,role:null,profileKey:null,isSuperAdmin:false,restaurantId:null,businessType:null,plugins:{},permissions:{},hospitalityType:null,hospitalityTypes:[]});
        return;
      }
      if(alive)setCtx(x=>({...x,loading:true,session}));
      let {data:p}=await supabase.from('anaira_my_profile').select('is_super_admin,role,restaurant_id,full_name').eq('id',session.user.id).maybeSingle();
      // Match Store Builder's canonical-profile fallback. The legacy view can
      // intermittently omit newer/custom tenant profiles and must not trigger
      // a false dashboard/login redirect.
      if(!p){
        const {data:canonical}=await supabase.from('profiles').select('is_super_admin,role,restaurant_id,full_name,status').eq('id',session.user.id).maybeSingle();
        p=canonical;
      }
      const superAdmin=p?.is_super_admin===true||String(p?.role||'').trim().toLowerCase()==='super_admin';
      let plugins={},permissions={},hospitalityType=null,hospitalityTypes=[],businessType=null,profileKey=null;
      if(!superAdmin&&p?.restaurant_id){
        const [{data:pl},{data:rp},{data:up},{data:prof},{data:biz}]=await Promise.all([
          supabase.from('restaurant_plugins').select('plugin_code,enabled').eq('restaurant_id',p.restaurant_id),
          supabase.from('anaira_role_permissions').select('permission_key').eq('role_key',p.role||'staff'),
          supabase.from('anaira_user_permissions').select('permission_key,allowed').eq('user_id',session.user.id).eq('restaurant_id',p.restaurant_id),
          supabase.from('anaira_user_profiles').select('profile_key').eq('user_id',session.user.id).eq('restaurant_id',p.restaurant_id).maybeSingle(),
          supabase.from('restaurants').select('business_type,hospitality_type,hospitality_types').eq('id',p.restaurant_id).maybeSingle()
        ]);
        profileKey=prof?.profile_key||null;
        const pluginsMap=Object.fromEntries((pl||[]).map(x=>[x.plugin_code,x.enabled===true]));
        businessType=String(biz?.business_type||'').trim().toLowerCase()||null;
        const configured=readHospitalityTypes(biz?.hospitality_types,biz?.hospitality_type,businessType);
        for(const t of configured){const key=HOSPITALITY_PLUGIN[t];if(key&&!Object.prototype.hasOwnProperty.call(pluginsMap,key))pluginsMap[key]=true;}
        if(configured.length){
          hospitalityTypes=configured.filter((t,i,a)=>HOSPITALITY_PLUGIN[t]&&a.indexOf(t)===i);
        }else{
          const [{data:hmsTypes},{data:campTypes}]=await Promise.all([
            supabase.from('hms_room_types').select('hospitality_type').eq('restaurant_id',p.restaurant_id).eq('active',true),
            supabase.from('camp_unit_types').select('id').eq('restaurant_id',p.restaurant_id).eq('active',true).limit(1)
          ]);
          for(const row of (hmsTypes||[])){const t=row?.hospitality_type;if(HOSPITALITY_PLUGIN[t]&&pluginsMap[HOSPITALITY_PLUGIN[t]]!==false&&!hospitalityTypes.includes(t))hospitalityTypes.push(t);}
          if((campTypes||[]).length&&pluginsMap['camping-management']!==false&&!hospitalityTypes.includes('camp'))hospitalityTypes.push('camp');
          if(!hospitalityTypes.length){for(const t of readHospitalityTypes([],biz?.hospitality_type,businessType)){if(HOSPITALITY_PLUGIN[t]&&pluginsMap[HOSPITALITY_PLUGIN[t]]!==false&&!hospitalityTypes.includes(t))hospitalityTypes.push(t);}}
        }
        hospitalityType=hospitalityTypes[0]||null;
        plugins=pluginsMap;
        permissions=Object.fromEntries((rp||[]).map(x=>[x.permission_key,true]));
        if(profileKey){const {data:pp}=await supabase.from('anaira_profile_permissions').select('permission_key').eq('profile_key',profileKey);(pp||[]).forEach(x=>{permissions[x.permission_key]=true;});}
        (up||[]).forEach(x=>{permissions[x.permission_key]=x.allowed===true;});
      }
      if(alive&&current===requestId)setCtx({loading:false,session,role:p?.role||'staff',profileKey,isSuperAdmin:superAdmin,restaurantId:p?.restaurant_id||null,businessType,plugins,permissions,hospitalityType,hospitalityTypes,fullName:p?.full_name||''});
    };
    if(!supabase){setCtx(x=>({...x,loading:false}));return()=>{alive=false;};}
    const {data:{subscription}}=supabase.auth.onAuthStateChange((_event,session)=>{void loadContext(session);});
    supabase.auth.getSession().then(({data})=>loadContext(data.session));
    return()=>{alive=false;subscription?.unsubscribe();};
  },[]);

  const groups=useMemo(()=>{
    if(ctx.isSuperAdmin)return normalizeGroups(SUPER_GROUPS);
    // The management context must follow the current hospitality route.
    // Previously the sidebar always preferred the property's first configured
    // type, so /hotel-management?type=camp could still render HOTEL MANAGEMENT.
    const urlType=typeof window!=='undefined'?new URLSearchParams(window.location.search).get('type'):'';
    const validUrlType=urlType&&HOSPITALITY_PLUGIN[urlType]?urlType:'';
    const configuredTypes=ctx.hospitalityTypes?.length?ctx.hospitalityTypes:[];
    const businessIsHotel=ctx.businessType==='hotel_resort'||ctx.businessType==='hotel_restaurant';
    const adminRoleType=hospitalityTypeForAdminRole(ctx.role,ctx.profileKey);
    const effectiveConfiguredTypes=configuredTypes.length?configuredTypes:(adminRoleType?[adminRoleType]:[]);
    const businessIsRestaurant=ctx.businessType==='restaurant_cafe'||ctx.businessType==='hotel_restaurant';
    // A configured hospitality profile is authoritative even when the tenant's
    // generic business_type is not hotel_resort (for example a homestay or cottage).
    // Keep the legacy hotel fallback only for older hotel tenants with no profile.
    const hasConfiguredHospitality=effectiveConfiguredTypes.length>0;
    const types=(businessIsHotel||hasConfiguredHospitality)
      ?(validUrlType && effectiveConfiguredTypes.includes(validUrlType)?[validUrlType]:hasConfiguredHospitality?effectiveConfiguredTypes:['hotel'])
      :[];
    const mgGroups=types.map(type=>({
      title:(HOSPITALITY_MANAGEMENT_GROUPS[type]||HOSPITALITY_MANAGEMENT_GROUPS.hotel).title,
      items:hospitalityManagementItems(type)
    }));
    const revenueGroups=types.map(type=>({
      title:`${hospitalityMetaForSidebar(type).label.toUpperCase()} REVENUE & DISTRIBUTION`,
      items:hospitalityRevenueItems(type)
    }));
    const dynamicOps={title:'HOSPITALITY OPERATIONS',items:hospitalityOperationItems(types)};
    const tenantAdmin=isTenantAdminContext(ctx.role,ctx.profileKey);
    if(tenantAdmin){
      const base=BUSINESS_GROUPS.filter(g=>g.title!=='HOTEL MANAGEMENT').map(stripStaticHospitalityItems);
      // Restaurant administration is a tenant-level capability and must remain
      // visible even when the property is configured primarily as hotel/camp/etc.
      // Do not let the hospitality-type sidebar replacement hide the restaurant
      // profile, menu/store, POS or reservation controls.
      const restaurantAdded=ctx.plugins['restaurant-management']===true || ctx.plugins['restaurant-core']===true || ctx.plugins['restaurant-store']===true || ctx.plugins['anaira-pos']===true || ctx.plugins['restaurant-reservation']===true || ctx.plugins['food-delivery']===true;
      const restaurantEnabled=restaurantAdded;
      const isAnairaGraphics = ctx.restaurantId === '737d5047-39f0-480b-8279-c7b1262f9e6c' && ctx.businessType === 'it_agency';
      const businessCfg = BUSINESS_TYPE_MENU[ctx.businessType] || businessTypeMenuFallback(ctx.businessType);

      // Anaira Graphics is a tenant-specific IT Agency implementation.
      // Do not show the generic IT / Agency catalog/setup/landing menu for this
      // tenant because those functions are already represented by the dedicated
      // Anaira Graphics CMS. Keep only the operational CRM/work items below.
      const businessGroup = (businessCfg && !isAnairaGraphics) ? {
        title: businessCfg.title.toUpperCase(),
        items: businessCfg.items.map(x=>[
          x[0],
          x[1],
          (x[2].startsWith('/business/') && ctx.restaurantId)
            ? `${x[2]}${x[2].includes('?')?'&':'?'}business=${ctx.restaurantId}`
            : x[2],
          x[3],
          x[4]
        ])
      } : null;

      const anaIraGraphicsGroup = isAnairaGraphics ? {title:'ANAIRA GRAPHICS',items:[
        ['🎨','Anaira Graphics Settings','/anaira-graphics/settings','business.settings'],
        ['🛠','Services & Projects','/anaira-graphics/settings?tab=services','business.settings'],
        ['▣','Portfolio / All Projects','/anaira-graphics/settings?tab=all','business.settings'],
        ['↗','Front Landing Page','/business/it_agency/landing?business=737d5047-39f0-480b-8279-c7b1262f9e6c','business.settings']
      ]} : null;

      const anaIraGraphicsOperationsGroup = isAnairaGraphics ? {title:'IT AGENCY OPERATIONS',items:[
        ['♙','Team / Staff','/business/it_agency/setup','business.settings'],
        ['◆','Leads','/leads','lead.view','crm'],
        ['✓','Tasks','/my-work','task.view'],
        ['◉','Clients','/customer-360','customer.view','crm'],
        ['₹','Invoices','/corporate','corporate.view','crm']
      ]} : null;
      const restaurantGroup=restaurantEnabled?{title:'RESTAURANT MANAGEMENT',items:[
        ['♨','Restaurant Setup','/restaurant-setup','business.settings','restaurant-store'],
        ['◇','My Restaurant Store','/store-builder?kind=restaurant','store.view','restaurant-store'],
        ['▣','Anaira POS / Menu','/pos','pos.order.view','anaira-pos'],
        ['◫','Restaurant Reservations','/reservation','reservation.view','restaurant-reservation'],
        ['◉','Food Delivery','/delivery','delivery.order.view','food-delivery']
      ]}:null;
      return normalizeGroups([
        ...mgGroups,
        ...revenueGroups,
        ...(anaIraGraphicsGroup?[anaIraGraphicsGroup]:[]),
        ...(anaIraGraphicsOperationsGroup?[anaIraGraphicsOperationsGroup]:[]),
        ...(businessGroup?[businessGroup]:[]),
        ...(restaurantGroup?[restaurantGroup]:[]),
        ...base,
        dynamicOps
      ]);
    }
    if(ctx.role==='staff' && ctx.profileKey && PROFILE_GROUPS[ctx.profileKey]){
      const base=PROFILE_GROUPS[ctx.profileKey].map(stripStaticHospitalityItems);
      const businessCfg = BUSINESS_TYPE_MENU[ctx.businessType] || businessTypeMenuFallback(ctx.businessType);
      const businessGroup = businessCfg ? {title: businessCfg.title, items: businessCfg.items.map(x=>[x[0],x[1],(x[2].startsWith('/business/') && ctx.restaurantId) ? `${x[2]}${x[2].includes('?')?'&':'?'}business=${ctx.restaurantId}` : x[2],x[3],x[4]])} : null;
      return normalizeGroups([...(businessGroup?[businessGroup]:[]),...mgGroups,...revenueGroups,...base,dynamicOps]);
    }
    const base=(ROLE_GROUPS[ctx.role]||ROLE_GROUPS.staff).map(stripStaticHospitalityItems);
    const businessCfg = BUSINESS_TYPE_MENU[ctx.businessType] || businessTypeMenuFallback(ctx.businessType);
    const businessGroup = businessCfg ? {title: businessCfg.title, items: businessCfg.items.map(x=>[x[0],x[1],(x[2].startsWith('/business/') && ctx.restaurantId) ? `${x[2]}${x[2].includes('?')?'&':'?'}business=${ctx.restaurantId}` : x[2],x[3],x[4]])} : null;
    return normalizeGroups([...(businessGroup?[businessGroup]:[]),...mgGroups,...revenueGroups,...base,dynamicOps]);
  },[pathname,ctx.isSuperAdmin,ctx.role,ctx.profileKey,ctx.businessType,ctx.plugins,ctx.hospitalityType,ctx.hospitalityTypes?.join('|')]);

  const visibleGroups=groups.map(g=>({...g,items:g.items.filter(item=>{
    if(!item.permission && !item.plugin)return true;
    if(ctx.isSuperAdmin)return true;
    const hospitalityPluginKeys=Object.values(HOSPITALITY_PLUGIN);
    const hospitalityItem=item.plugin && hospitalityPluginKeys.includes(item.plugin);
    const isTenantAdmin=isTenantAdminContext(ctx.role,ctx.profileKey);
    // Hospitality plugins are tenant-scoped. Their menu items must remain
    // visible for configured properties even when legacy plugin/permission
    // rows have not been backfilled for a custom Homestay Admin profile.
    if(item.plugin && ctx.plugins[item.plugin]!==true && !hospitalityItem) return false;
    if(item.permission && ctx.permissions[item.permission]!==true && !isTenantAdmin)return false;
    return true;
  })})).filter(g=>g.items.length);

  useEffect(()=>{
    if(ctx.loading)return;
    if(!ctx.session){ if(pathname!=='/login') router.replace('/login'); return; }
    if(pathname==='/admin' || pathname.startsWith('/admin/')){if(!ctx.isSuperAdmin)router.replace('/');return;}
    if(pathname==='/plugins' && !ctx.isSuperAdmin && ctx.role!=='admin' && ctx.profileKey!=='business_admin'){router.replace('/');return;}
    if(SUPER_ONLY_ROUTES.some(r=>pathname===r||pathname.startsWith(r+'/')) && !ctx.isSuperAdmin){router.replace('/');return;}
    const isTenantAdmin=isTenantAdminContext(ctx.role,ctx.profileKey);
    const routeParams=typeof window!=='undefined'?new URLSearchParams(window.location.search):new URLSearchParams();
    const requestedType=normalizeHospitalityType(routeParams.get('type')||routeParams.get('hospitality_type'));
    const roleHospitalityType=hospitalityTypeForAdminRole(ctx.role,ctx.profileKey);
    const effectiveHospitalityTypes=(ctx.hospitalityTypes||[]).length?ctx.hospitalityTypes:(roleHospitalityType?[roleHospitalityType]:[]);
    const configuredHospitality=!!requestedType&&effectiveHospitalityTypes.some(x=>normalizeHospitalityType(x)===requestedType);
    const typeScopedStore=pathname==='/store-builder' && (routeParams.get('kind')==='hotel' || !!routeParams.get('hospitality_type'));
    const isHospitalityRoute=pathname==='/hotel-management'||pathname.startsWith('/hotel-management/')||pathname==='/pms'||pathname==='/housekeeping'||pathname==='/booking'||pathname==='/booking-engine'||pathname==='/revenue-management'||typeScopedStore;
    // Property-scoped Homestay/Camp/Guest House/Cottage workspaces belong to
    // their tenant admins, including custom role keys such as homestay_admin.
    // Keep platform-only users/roles screens restricted.
    const adminOnlyRoute=ADMIN_ONLY_ROUTES.some(r=>pathname===r||pathname.startsWith(r+'/'));
    const tenantAdminAllowed=adminOnlyRoute && isTenantAdmin && (pathname!=='/store-builder' || configuredHospitality || typeScopedStore);
    if(adminOnlyRoute && !ctx.isSuperAdmin && !tenantAdminAllowed && ctx.role!=='admin' && ctx.role!=='business_admin' && ctx.profileKey!=='business_admin'){router.replace('/');return;}
    if(pathname===BUSINESS_SETTINGS_ROUTE && !ctx.isSuperAdmin && ctx.role!=='admin' && ctx.role!=='business_admin' && ctx.profileKey!=='business_admin'){router.replace('/');return;}
    if(ctx.isSuperAdmin)return;
    let plugin=PLUGIN_BY_ROUTE[pathname];
    const restaurantAdded=ctx.plugins['restaurant-management']===true || ctx.plugins['restaurant-core']===true || ctx.plugins['restaurant-store']===true || ctx.plugins['anaira-pos']===true || ctx.plugins['restaurant-reservation']===true || ctx.plugins['food-delivery']===true;
    const businessIsHotel=ctx.businessType==='hotel_resort'||ctx.businessType==='hotel_restaurant';
    const businessIsRestaurant=ctx.businessType==='restaurant_cafe'||ctx.businessType==='hotel_restaurant';
    const hasConfiguredHospitality=effectiveHospitalityTypes.length>0;
    const hotelRoute=pathname==='/hotel-management'||pathname.startsWith('/hotel-management/')||pathname==='/pms'||pathname==='/housekeeping';
    const restaurantRoute=pathname==='/restaurant-setup'||pathname.startsWith('/restaurant-setup/');
    if(hotelRoute && !businessIsHotel && !hasConfiguredHospitality) { router.replace('/'); return; }
    if(restaurantRoute && !restaurantAdded) { router.replace('/'); return; }
    if(pathname==='/restaurant-setup') plugin='restaurant-store';
    if(pathname==='/hotel-management'||pathname.startsWith('/hotel-management/')||pathname==='/booking-engine'||pathname==='/store-builder'){
      if(requestedType) plugin=HOSPITALITY_PLUGIN[requestedType]||plugin;
    }
    const hospitalityPath = pathname==='/hotel-management' || pathname.startsWith('/hotel-management/') || pathname==='/pms' || pathname==='/housekeeping' || pathname==='/booking' || pathname==='/booking-engine' || typeScopedStore;
    // Hotel Guest CRM is an enterprise CRM workspace. Older tenants may not
    // have a dedicated `hotel_guest_crm` row in restaurant_plugins because the
    // module was historically governed by the parent CRM plugin. In that case
    // the dedicated page must not bounce back to Dashboard when CRM itself is
    // enabled. An explicit hotel_guest_crm=false row still blocks access.
    const hotelGuestCrmRoute = pathname==='/hotel-guest-crm' || pathname.startsWith('/hotel-guest-crm/');
     if(hotelGuestCrmRoute) plugin='hotel_guest_crm';
    const hotelGuestCrmEnabled = ctx.plugins['hotel_guest_crm']===true ||
      (hotelGuestCrmRoute && !Object.prototype.hasOwnProperty.call(ctx.plugins,'hotel_guest_crm') && ctx.plugins['crm']===true);
    if(plugin && ctx.plugins[plugin]!==true && !(hospitalityPath && configuredHospitality)){
      if(!(hotelGuestCrmRoute && plugin==='hotel_guest_crm' && hotelGuestCrmEnabled)){router.replace('/');return;}
    }
    // Tenant-level hospitality admins own the configured property workspace.
    // Do not require legacy staff permission rows for their Homestay tabs.
    // Non-admin staff still pass the normal per-route permission check.
    if(!(isTenantAdmin && isHospitalityRoute)){
      const required=PERMISSION_BY_ROUTE[pathname];
      if(required && ctx.permissions[required]!==true)router.replace('/');
    }
  },[ctx.loading,ctx.session,ctx.isSuperAdmin,ctx.role,ctx.profileKey,ctx.plugins,ctx.permissions,ctx.businessType,ctx.hospitalityType,ctx.hospitalityTypes,ctx.restaurantId,pathname,router]);

  const portalLabel=ctx.isSuperAdmin?'SUPER ADMIN':(ctx.role==='admin'||ctx.profileKey==='business_admin')?'BUSINESS PORTAL':ctx.role==='manager'?'MANAGER PORTAL':'STAFF PORTAL';
  const [mobileNavOpen,setMobileNavOpen]=useState(false);
  const [openGroups,setOpenGroups]=useState(()=>({}));

  // Mobile uses the exact same `visibleGroups` source as desktop.
  // When the hamburger opens, expand every currently visible group so no
  // business-type menu item is hidden behind collapsed desktop-style sections.
  const toggleMobileNavigation=()=>{
    setMobileNavOpen(prev=>{
      const next=!prev;
      if(next && typeof window!=='undefined' && window.matchMedia('(max-width:760px)').matches){
        setOpenGroups(Object.fromEntries(visibleGroups.map(group=>[group.title,true])));
      }
      return next;
    });
  };
  useEffect(()=>{
    setOpenGroups(prev=>{
      const next={};
      visibleGroups.forEach(g=>{
        const containsActive=g.items.some(item=>item.href===pathname);
        next[g.title]=typeof prev[g.title]==='boolean'?prev[g.title]:containsActive;
      });
      return next;
    });
  },[visibleGroups.map(g=>g.title).join('|'),pathname]);
  useEffect(()=>{setMobileNavOpen(false)},[pathname]);
  useEffect(()=>{
    if(!mobileNavOpen) return;
    const onKey=(e)=>{if(e.key==='Escape') setMobileNavOpen(false)};
    document.addEventListener('keydown',onKey);
    const previous=document.body.style.overflow;
    document.body.style.overflow='hidden';
    return ()=>{document.removeEventListener('keydown',onKey);document.body.style.overflow=previous};
  },[mobileNavOpen]);
  return <div className="shell">
    <button type="button" className="mobile-nav-toggle" aria-label={mobileNavOpen?'Close navigation':'Open navigation'} aria-expanded={mobileNavOpen} onClick={toggleMobileNavigation}>
      <span></span><span></span><span></span>
    </button>
    {mobileNavOpen&&<button type="button" className="mobile-nav-backdrop" aria-label="Close navigation" onClick={()=>setMobileNavOpen(false)}/>}
    <aside className={'sidebar'+(mobileNavOpen?' is-open':'')}>
      <div className="brand"><img src="/assets/anaira-logo.webp" alt="Anaira"/><div><b>ANAIRA</b><span>HOTEL & RESTAURANT CRM</span></div></div>
      <div className="portal-badge">{portalLabel}{ctx.restaurantId&&!ctx.isSuperAdmin?' • '+ctx.restaurantId.slice(0,8):''}</div>
      <nav className="nav">{visibleGroups.map((group,gi)=>{const open=!!openGroups[group.title]; return <div className="nav-group" key={group.title}><button type="button" className={'navtitle navtitle-toggle'+(open?' is-open':'')} aria-expanded={open} onClick={()=>setOpenGroups(prev=>({...prev,[group.title]:!open}))}><span>{group.title}</span><b aria-hidden="true">{open?'⌃':'⌄'}</b></button><div className={'nav-submenu'+(open?' is-open':'')}>{group.items.map(item=><a key={`${item.href}-${item.label}`} href={item.href} className={active===item.href||pathname===item.href?'active':''} onClick={()=>setMobileNavOpen(false)}><i>{item.icon}</i><span>{item.label}</span></a>)}</div></div>})}</nav>
      <button className="logout-btn" onClick={async()=>{await supabase?.auth.signOut();location.href='/login'}}>Sign out</button>
    </aside>
    <main className="main">{children}</main>
  </div>
}
export function Header({eyebrow,title,subtitle,actions}) { return <header className="top"><div><div className="eyebrow">{eyebrow||'ANAIRA CRM'}</div><div className="title">{title}</div><div className="subtitle">{subtitle}</div></div><div className="actions">{actions||<a className="btn primary" href="/">Command Center</a>}</div></header> }
export function Kpi({label,value,delta,tone=''}) { return <div className="card"><div className="kpi-label">{label}</div><div className="kpi-value">{value}</div><div className={'delta '+tone}>{delta}</div></div> }
export function Section({title,meta,children,className=''}) { return <section className={'card section '+className}><div className="section-head"><h2>{title}</h2><span>{meta}</span></div>{children}</section> }
export function Pill({children,tone=''}) { return <span className={'pill '+tone}>{children}</span> }
export function Table({columns,rows}) { return <table className="table"><thead><tr>{columns.map(c=><th key={c}>{c}</th>)}</tr></thead><tbody>{rows.map((row,i)=><tr key={i}>{row.map((cell,j)=><td key={j}>{cell}</td>)}</tr>)}</tbody></table> }
export function Progress({label,value,display}) { return <div style={{margin:'9px 0'}}><div className="metric-row" style={{border:0,padding:'2px 0'}}><span>{label}</span><b>{display||value+'%'}</b></div><div style={{height:7,background:'#eee8d9',borderRadius:99,overflow:'hidden'}}><div style={{height:'100%',width:value+'%',background:'linear-gradient(90deg,#0d6d48,#e0af3e)',borderRadius:99}}/></div></div> }
export function Timeline({items}) { return <div className="timeline">{items.map((x,i)=><div className="timeline-item" key={i}><div className="timeline-dot">{x.icon||'•'}</div><div><b>{x.title}</b><div className="subtitle">{x.time}</div><p className="subtitle" style={{margin:'4px 0 0'}}>{x.text}</p></div></div>)}</div> }
export function ModuleCards({items}) { return <div className="module-grid">{items.map(([icon,title,text,href])=><a className="module-card" href={href||'#'} key={`${href||'#'}-${title}`}><div className="module-icon">{icon}</div><h3>{title}</h3><p>{text}</p></a>)}</div> }
export function Filters({children}) { return <div className="filters">{children||<><input placeholder="Search..."/><select defaultValue="all"><option value="all">All Status</option><option>Active</option><option>Pending</option><option>Closed</option></select><button className="btn">Filter</button></>}</div> }
