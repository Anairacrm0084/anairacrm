export const CRM_BUSINESS_VERTICALS = [
  ['hotel','Hotel / Resort'],['restaurant','Restaurant / Dining'],['cafe','Cafe / Coffee Shop'],['bakery','Bakery / Patisserie'],
  ['bar','Bar / Lounge'],['salon','Salon / Beauty'],['barber','Barber Shop'],['spa','Spa / Wellness'],
  ['clinic','Clinic / Healthcare'],['hospital','Hospital'],['dentist','Dental / Dentist'],['doctor','Doctor / Medical Professional'],
  ['pharmacy','Pharmacy'],['gym','Gym / Fitness'],['yoga','Yoga / Wellness'],['retail','Retail Store'],['grocery','Grocery / Supermarket'],
  ['fashion','Fashion / Apparel'],['jewellery','Jewellery'],['electronics','Electronics / Mobile'],['automotive','Automotive / Garage'],
  ['real_estate','Real Estate'],['travel','Travel Agency / Tour Operator'],['education','Education / Coaching'],
  ['legal','Legal / Law Firm'],['accounting','Accounting / CA / Tax'],['agency','Agency / Professional Services'],['it_services','IT / Software / Digital'],
  ['repair','Repair / Maintenance'],['cleaning','Cleaning Services'],['pet','Pet / Veterinary'],['photography','Photography'],
  ['events','Events / Entertainment'],['coworking','Coworking'],['logistics','Logistics / Transport'],['construction','Construction / Home Services'],
  ['ecommerce','E-commerce'],['saas','SaaS / Subscription'],['creator','Creator / Personal Brand'],['nonprofit','Non-profit'],['other','Other Business']
];

export const CRM_INTERACTION_TYPES = [
  'lead','inquiry','appointment','booking','purchase','service_completed','consultation','visit','stay','order',
  'delivery','project_completed','subscription','support_ticket','complaint','feedback','review','payment','refund','communication'
];

export const CRM_VERTICAL_LABELS = Object.fromEntries(CRM_BUSINESS_VERTICALS);

export const CRM_DEFAULT_MODEL = {
  customer_label: 'Customer',
  transaction_label: 'Transaction',
  service_label: 'Service',
  interaction_label: 'Interaction',
  lifecycle: ['lead','prospect','customer','active','repeat','at_risk','loyal','inactive'],
  metrics: ['lifetime_value','total_revenue','interaction_count','last_interaction_at','satisfaction_score','review_count'],
  modules: ['customer_360','leads','sales_pipeline','tasks','communications','consent','segments','loyalty','feedback','reputation','automation','analytics','ai','integrations']
};

export function normalizeCrmVertical(value) {
  const key = String(value || 'other').trim().toLowerCase().replace(/\s+/g,'_');
  return CRM_VERTICAL_LABELS[key] ? key : 'other';
}

export function buildCrmContext({ vertical='other', businessName='', metadata={} }={}) {
  const v = normalizeCrmVertical(vertical);
  const labels = {
    customer: v === 'clinic' || v === 'hospital' || v === 'dentist' || v === 'doctor' ? 'Client / Patient' : 'Customer',
    transaction: v === 'hotel' ? 'Booking / Stay' : v === 'restaurant' || v === 'cafe' || v === 'bakery' ? 'Order / Visit' : 'Transaction',
    service: v === 'barber' || v === 'salon' || v === 'spa' ? 'Appointment / Service' : v === 'professional' || v === 'legal' || v === 'accounting' ? 'Matter / Engagement' : 'Service',
    interaction: 'Interaction'
  };
  return { vertical:v, vertical_label:CRM_VERTICAL_LABELS[v], business_name:businessName, labels, ...CRM_DEFAULT_MODEL, metadata };
}
