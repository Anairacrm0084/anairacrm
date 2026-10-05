import {NextResponse} from 'next/server';
import {supabaseAdmin} from '../../../../lib/supabaseAdmin';

const BUSINESS_ID=process.env.ANAIRA_GRAPHICS_BUSINESS_ID||'737d5047-39f0-480b-8279-c7b1262f9e6c';
const BUSINESS_NAME='Anaira Graphics & Digital Solution';
const BUSINESS_EMAIL='anairagraphicsdigitalsolution@gmail.com';
const BUCKET='anaira-business-assets';
const MAX_IMAGE_BYTES=10*1024*1024;
const SERVICE_CATS=['Graphics & Digital Design','Digital Printing','Web Design & Development','SEO & Local SEO','Social Media Marketing','Software & App Development','Signage & Display'];
const PORTFOLIO_GROUPS=['Websites & Web Projects','Anaira Products & SaaS','Client Software & Platforms','Design & Branding','Print & Signage','Other'];
const DEFAULT_SITE_SETTINGS={
  businessName:'Anaira Graphics & Digital Solution',businessShort:'Anaira Graphics',
  phone:'097365 80084',phoneHref:'tel:+919736500084',whatsapp:'https://wa.me/919736500084',
  address:'Opp. Sood Petrol Pump, Akhara, Kullu, Himachal Pradesh 175101, India',
  navServices:'Services',navWork:'Our Work',navProcess:'Process',navContact:'Contact',navCta:'Call Now',
  eyebrow:'KULLU · HIMACHAL PRADESH',heroTitle:'Design. Brand. Build. Grow.',heroDescription:'Graphic design, digital printing, websites, SEO, social media and custom software — one creative technology partner for your business.',heroPrimary:'Start a Project →',heroSecondary:'WhatsApp Us',trust1:'Branding',trust2:'Print',trust3:'Web',trust4:'SEO',trust5:'Software',artChip1:'WEB + SEO',artChip2:'SOFTWARE',artChip3:'PRINT',
  proofTitle:'From idea to execution.',proofText:'Creative work, digital products and business technology under one roof.',proofLink:'Explore our work →',
  focusKicker:'THE ANAiRA DIFFERENCE',focusTitle:'Not just a service. A complete business experience.',focusText:'We bring design, technology and production together so your brand looks premium everywhere — online, on paper and in the real world.',focusPill1:'Design',focusPill2:'Technology',focusPill3:'Production',focusPill4:'Brand Growth',focusCtaTitle:'SEE OUR WORK',focusCtaText:'Watch how we create brands',
  webImage:'/anaira-graphics/showcase/web.jpg',softwareImage:'/anaira-graphics/showcase/software.jpg',designImage:'/anaira-graphics/showcase/design.jpg',printImage:'/anaira-graphics/showcase/printing.jpg',
  webChip1:'Business\nWebsites',webChip2:'Travel & Booking\nWebsites',webChip3:'E-commerce\nStores',webChip4:'Landing\nPages',
  softwareChip1:'CRM\nSystems',softwareChip2:'POS\nSystems',softwareChip3:'Hotel PMS\n& Booking',softwareChip4:'Custom\nSoftware',
  designChip1:'Logo\nDesign',designChip2:'Brand\nIdentity',designChip3:'Social Media\nCreatives',designChip4:'Posters &\nBrochures',
  printChip1:'Flex &\nBanners',printChip2:'Acrylic &\nGlow Signs',printChip3:'LED\nDisplay',printChip4:'T-Shirt &\nCarry Bags',
  statsProjects:'500+',statsProjectsLabel:'Projects Delivered',statsClients:'100+',statsClientsLabel:'Happy Clients',statsYears:'10+',statsYearsLabel:'Years of Experience',statsComplete:'Complete',statsCompleteText:'Design + Technology + Production',
  webKicker:'WEBSITE DESIGN & DEVELOPMENT',webTitle:'Websites people enjoy using.',webText:'Premium business websites, landing pages, booking experiences and custom digital platforms built for speed, clarity and conversion.',webAction:'Explore Web Work',webViewAll:'View All Projects',
  softwareKicker:'SOFTWARE & APP DEVELOPMENT',softwareTitle:'Technology built around your business.',softwareText:'CRM, POS, booking, hospitality, automation, SaaS and custom applications — not templates, real workflows.',softwareAction:'Explore Software',softwareViewAll:'View All Solutions',
  designKicker:'GRAPHIC DESIGN & BRANDING',designTitle:'Visual identity that gets remembered.',designText:'Logos, brand systems, social creatives, posters, brochures, packaging and campaign artwork with a strong visual direction.',designAction:'Explore Design',designViewAll:'View All Designs',
  printKicker:'DIGITAL PRINTING & SIGNAGE',printTitle:'Take your brand into the real world.',printText:'Flex, banners, hoardings, acrylic, glow signs, neon, LED, carry bags and T-shirt printing — production-ready.',printAction:'Explore Printing',printViewAll:'View All Printing',
  servicesKicker:'WHAT WE DO',servicesTitle:'Every service. Presented with purpose.',servicesText:'Browse the categories below. Start with the essentials, expand when you want the full range, or open every service in a premium category view.',
  portfolioKicker:'SELECTED WORK',portfolioTitle:'Websites. Software. Real delivery.',portfolioText:"We don't just show services. This is where Anaira's actual web projects, products and client software are presented separately.",
  webProjectsLabel:'Web Projects',anairaProductsLabel:'Anaira Products & SaaS',clientSoftwareLabel:'Client Software',servicesCountLabel:'Services',websitesCategoryTitle:'🌐 Websites & Web Projects',anairaProductsCategoryTitle:'💻 Anaira Products & SaaS',clientSoftwareCategoryTitle:'🏢 Client Software & Platforms',moreWorkCategoryTitle:'🎨 More Work',projectCountLabel:'projects',systemCountLabel:'systems',
  whyKicker:'WHY ANAiRA',whyTitle:'Creative thinking. Technical execution.',why1Title:'Design that represents you.',why1Text:'Brand identity, campaigns, print and digital design built around your business—not templates.',why2Title:'Technology that works.',why2Text:'Websites, POS, CRM, booking systems, SaaS and custom business software.',why3Title:'One team. One vision.',why3Text:'Design, development, SEO, marketing and production connected in one workflow.',
  processKicker:'OUR PROCESS',processTitle:'Simple process. Serious output.',process1Title:'Understand',process1Text:'Business, audience, goals and exact requirement.',process2Title:'Design',process2Text:'A clear visual or digital concept before production.',process3Title:'Build',process3Text:'Production-ready print, web or software delivery.',process4Title:'Grow',process4Text:'SEO, marketing, analytics and CRM for measurable growth.',
  marqueeLabel:'A GLIMPSE OF THE WORK · SCROLL',
  ctaKicker:'READY TO BUILD?',ctaTitle:"Have an idea? Let's make it real.",ctaText:'Tell us what you need—design, printing, website, SEO, marketing or software.',ctaButton:'Start a Project →',
  contactKicker:'GET IN TOUCH',contactTitle:"Let's create something useful.",contactText:"Tell Anaira Graphics what you're building. We'll help you choose the right creative, digital or technology solution.",contactButton:'Send Enquiry →',
  contactPhoneLabel:'PHONE',contactWhatsappLabel:'WHATSAPP',contactWhatsappText:'Chat with Anaira Graphics',contactLocationLabel:'LOCATION',
  formNamePlaceholder:'Your name',formPhonePlaceholder:'Your phone number',formEmailPlaceholder:'you@example.com',formServiceLabel:'What do you need?',formServicePlaceholder:'Select a service',formMessageLabel:'Tell us about your requirement',formMessagePlaceholder:'Logo, website, printing, SEO, software… tell us what you need.',formSubmit:'Send Enquiry →',formSending:'Sending…',formSuccess:'✓ Enquiry received. Our team will contact you shortly.',
  allServicesLabel:'ALL SERVICES',relatedServicesLabel:'related services',closeLabel:'Close',enquireLabel:'Enquire →',addToCartLabel:'Add to cart',viewDemoLabel:'View Demo ↗',serviceCountLabel:'services',showLessLabel:'Show Less ↑',showMoreLabel:'Show More +',viewAllLabel:'View All ↗',demoLabel:'Demo ↗',showingLabel:'Showing 3 of',useLabel:'use',showMorePlainLabel:'Show More',orLabel:'or',viewAllPlainLabel:'View All',
  cartTitle:'SERVICE CART',checkoutTitle:'Checkout',selectedServicesTitle:'Your selected services',cartEmptyText:'Your cart is empty. Add a service from the service catalogue.',estimatedTotalLabel:'Estimated total',customQuoteLabel:'Custom quote',continueCheckoutLabel:'Continue to checkout →',deliveryNotesLabel:'Requirement / delivery notes',backLabel:'Back',submittingLabel:'Submitting…',placeOrderLabel:'Place Order Request →',
  websiteProjectTypeLabel:'WEBSITE / WEB',softwareProjectTypeLabel:'SOFTWARE / SAAS',nameLabel:'Name',phoneLabel:'Phone',emailLabel:'Email',qtyLabel:'Quantity',orderRequestSuccessPrefix:'Order request',receivedText:'received. We will contact you shortly.',
  footerTagline:'Design · Brand · Build · Grow',footerCopyright:'© Anaira Graphics & Digital Solution. All rights reserved.'
};

async function business(){
 const s=supabaseAdmin();
 const byId=await s.from('restaurants').select('id,name,email,business_type').eq('id',BUSINESS_ID).maybeSingle();
 if(byId.error)throw byId.error;if(byId.data)return [s,byId.data];
 const byIdentity=await s.from('restaurants').select('id,name,email,business_type').eq('name',BUSINESS_NAME).eq('email',BUSINESS_EMAIL).limit(1).maybeSingle();
 if(byIdentity.error)throw byIdentity.error;if(!byIdentity.data)throw new Error('Anaira Graphics business tenant not found');return [s,byIdentity.data];
}
async function auth(req,businessId){
 const token=(req.headers.get('authorization')||'').replace(/^Bearer\s+/i,'');if(!token)return false;
 const s=supabaseAdmin();const {data:u}=await s.auth.getUser(token);if(!u?.user)return false;
 const {data:p}=await s.from('profiles').select('restaurant_id,is_super_admin').eq('id',u.user.id).maybeSingle();
 if(p?.is_super_admin||p?.restaurant_id===businessId)return true;
 const {data:m}=await s.from('anaira_business_memberships').select('business_id').eq('business_id',businessId).eq('user_id',u.user.id).eq('status','active').maybeSingle();return Boolean(m?.business_id);
}
function storagePath(url){
 if(!url||typeof url!=='string')return null;
 const marker=`/storage/v1/object/public/${BUCKET}/`;
 const i=url.indexOf(marker);return i>=0?decodeURIComponent(url.slice(i+marker.length)):null;
}
async function removeUrls(s,urls){
 const paths=[...new Set((urls||[]).map(storagePath).filter(Boolean))];
 for(let i=0;i<paths.length;i+=1000){const part=paths.slice(i,i+1000);if(part.length){const r=await s.storage.from(BUCKET).remove(part);if(r.error)console.warn('Storage cleanup warning',r.error.message);}}
}

export async function GET(req){
 try{const [s,b]=await business();const adminMode=new URL(req.url).searchParams.get('admin')==='1';if(adminMode&&!await auth(req,b.id))return NextResponse.json({error:'Anaira Graphics settings access denied'},{status:403});
  let q=s.from('anaira_it_agency_portfolio').select('*').eq('business_id',b.id).order('sort_order').order('created_at');if(!adminMode)q=q.eq('status','active');const {data,error}=await q;if(error)throw error;
  const rows=data||[];
  const settingsRow=rows.find(x=>x.data?.kind==='site_settings');
  const settings=settingsRow?.data?.settings||{};
  const services=rows.filter(x=>x.data?.kind==='service').map(x=>({id:x.id,title:x.title,description:x.data?.description||'',category:x.data?.category||'Services',image_url:x.image_url||x.data?.image_url||null,alt_text:x.data?.alt_text||x.title,sort_order:x.sort_order,status:x.status,icon:x.data?.icon||'✦',buy_enabled:Boolean(x.data?.buy_enabled),price:Number(x.data?.price||0),currency:x.data?.currency||'INR',unit:x.data?.unit||'service',demo_url:x.data?.demo_url||''}));
  const portfolio=rows.filter(x=>x.data?.kind==='portfolio').map(x=>({id:x.id,title:x.title,description:x.data?.description||'',type:x.data?.type||'website',tag:x.data?.tag||'',live_url:x.data?.live_url||'',portfolio_group:x.data?.portfolio_group||'Websites & Web Projects',image_url:x.image_url||null,alt_text:x.data?.alt_text||x.title,gallery:Array.isArray(x.gallery)?x.gallery:[],sort_order:x.sort_order,status:x.status}));
  return NextResponse.json({ok:true,business:b,services,portfolio,settings,needsSeed:!settingsRow,categories:SERVICE_CATS,portfolioGroups:PORTFOLIO_GROUPS});
 }catch(e){return NextResponse.json({ok:false,error:e.message},{status:500});}
}

export async function POST(req){
 try{const [s,b]=await business();if(!await auth(req,b.id))return NextResponse.json({error:'Anaira Graphics settings access denied'},{status:403});const ct=req.headers.get('content-type')||'';
  if(ct.includes('multipart/form-data')){const fd=await req.formData();const file=fd.get('file');if(!file||typeof file.arrayBuffer!=='function')return NextResponse.json({error:'Image file required'},{status:400});if(file.size>MAX_IMAGE_BYTES)return NextResponse.json({error:'Image must be 10MB or smaller'},{status:400});if(!String(file.type||'').startsWith('image/'))return NextResponse.json({error:'Only image files are allowed'},{status:400});const ext=(file.name||'image').split('.').pop().toLowerCase().replace(/[^a-z0-9]/g,'')||'jpg';const path=`anaira-graphics/${b.id}/${crypto.randomUUID()}.${ext}`;const buf=Buffer.from(await file.arrayBuffer());const up=await s.storage.from(BUCKET).upload(path,buf,{contentType:file.type||'image/jpeg',cacheControl:'31536000',upsert:false});if(up.error)throw up.error;const {data}=s.storage.from(BUCKET).getPublicUrl(path);return NextResponse.json({ok:true,url:data.publicUrl,path});}
  const body=await req.json();
  if(body.action==='seed'){
    const existing=await s.from('anaira_it_agency_portfolio').select('id').eq('business_id',b.id).eq('data->>kind','site_settings').maybeSingle();
    if(existing.error)throw existing.error;
    if(existing.data)return NextResponse.json({ok:true,message:'Already initialized'});
    const row={business_id:b.id,title:'Anaira Graphics Landing Settings',status:'active',data:{kind:'site_settings',settings:DEFAULT_SITE_SETTINGS},sort_order:1};
    const r=await s.from('anaira_it_agency_portfolio').insert(row).select('*').single();
    if(r.error)throw r.error;
    return NextResponse.json({ok:true,message:'Landing settings initialized',item:r.data});
   }
  if(body.action==='save_settings'){
   const incoming=body.settings&&typeof body.settings==='object'?body.settings:{};
   const settings={...DEFAULT_SITE_SETTINGS};
   Object.keys(DEFAULT_SITE_SETTINGS).forEach(k=>{if(typeof incoming[k]==='string')settings[k]=incoming[k].trim();});
   const old=await s.from('anaira_it_agency_portfolio').select('id').eq('business_id',b.id).eq('data->>kind','site_settings').maybeSingle();
   if(old.error)throw old.error;
   const payload={business_id:b.id,title:'Anaira Graphics Landing Settings',status:'active',data:{kind:'site_settings',settings},sort_order:1,updated_at:new Date().toISOString()};
   const r=old.data?await s.from('anaira_it_agency_portfolio').update(payload).eq('id',old.data.id).eq('business_id',b.id):await s.from('anaira_it_agency_portfolio').insert(payload);
   if(r.error)throw r.error;
   return NextResponse.json({ok:true,settings});
  }
  if(body.action==='save'){
   const kind=body.kind==='service'?'service':'portfolio';const title=String(body.title||'').trim();if(!title)return NextResponse.json({error:'Title is required'},{status:400});
   const nextGallery=Array.isArray(body.gallery)?body.gallery.filter(Boolean):[];const payload={business_id:b.id,title,status:body.status==='inactive'?'inactive':'active',data:kind==='service'?{kind,description:String(body.description||''),category:SERVICE_CATS.includes(body.category)?body.category:'Graphics & Digital Design',tag:String(body.tag||''),alt_text:String(body.alt_text||title),icon:String(body.icon||'✦'),buy_enabled:Boolean(body.buy_enabled),price:Math.max(0,Number(body.price||0)),currency:String(body.currency||'INR'),unit:String(body.unit||'service'),demo_url:String(body.demo_url||'')}:{kind,type:body.type==='software'?'software':'website',description:String(body.description||''),tag:String(body.tag||''),live_url:String(body.live_url||''),portfolio_group:PORTFOLIO_GROUPS.includes(body.portfolio_group)?body.portfolio_group:'Websites & Web Projects',alt_text:String(body.alt_text||title)},image_url:body.image_url||null,gallery:kind==='portfolio'?nextGallery:[],sort_order:Number(body.sort_order||0),updated_at:new Date().toISOString()};
   let old=null;if(body.id){const oldR=await s.from('anaira_it_agency_portfolio').select('*').eq('id',body.id).eq('business_id',b.id).maybeSingle();if(oldR.error)throw oldR.error;old=oldR.data;}
   let r;if(body.id)r=await s.from('anaira_it_agency_portfolio').update(payload).eq('id',body.id).eq('business_id',b.id).select('*').single();else r=await s.from('anaira_it_agency_portfolio').insert(payload).select('*').single();if(r.error)throw r.error;
   if(old){const oldUrls=[old.image_url,...(Array.isArray(old.gallery)?old.gallery:[])].filter(Boolean);const newUrls=[payload.image_url,...nextGallery].filter(Boolean);const removed=oldUrls.filter(u=>!newUrls.includes(u));if(removed.length)await removeUrls(s,removed);}
   return NextResponse.json({ok:true,item:r.data});
  }
  return NextResponse.json({error:'Unknown action'},{status:400});
 }catch(e){return NextResponse.json({ok:false,error:e?.message||'Unable to save content'},{status:400});}
}

export async function DELETE(req){
 try{const [s,b]=await business();if(!await auth(req,b.id))return NextResponse.json({error:'Anaira Graphics settings access denied'},{status:403});const id=new URL(req.url).searchParams.get('id');if(!id)return NextResponse.json({error:'id required'},{status:400});const oldR=await s.from('anaira_it_agency_portfolio').select('image_url,gallery').eq('id',id).eq('business_id',b.id).maybeSingle();if(oldR.error)throw oldR.error;if(!oldR.data)return NextResponse.json({error:'Item not found'},{status:404});const r=await s.from('anaira_it_agency_portfolio').delete().eq('id',id).eq('business_id',b.id);if(r.error)throw r.error;await removeUrls(s,[oldR.data.image_url,...(Array.isArray(oldR.data.gallery)?oldR.data.gallery:[])]);return NextResponse.json({ok:true});}catch(e){return NextResponse.json({ok:false,error:e?.message||'Unable to delete item'},{status:400});}
}
