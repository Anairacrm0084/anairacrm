'use client';
import { useEffect, useMemo, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import { supabase } from '../lib/supabase';

const PLUGIN_BY_ROUTE = {
  '/customer-360':'crm','/stays':'crm','/restaurant':'crm','/leads':'crm','/corporate':'crm','/partners':'crm',
  '/loyalty':'crm','/marketing':'crm','/campaigns':'crm','/guest-relations':'crm','/complaints':'crm','/revenue':'crm',
  '/analytics':'crm','/events':'crm','/ai':'crm','/segmentation':'crm','/vip':'crm','/timeline':'crm','/upselling':'crm',
  '/forecasting':'crm','/competitors':'crm','/ota':'crm','/workflows':'crm','/intelligence':'crm','/guest-requests':'crm',
  '/quotes':'crm','/partner-bookings':'crm','/reviews':'crm','/booking':'hotel-booking','/booking-engine':'hotel-booking','/hotel-management':'hotel-management-suite','/hotel-management/setup':'hotel-management-suite','/hotel-management/room-types':'hotel-management-suite','/hotel-management/rooms':'hotel-management-suite','/hotel-management/rates':'hotel-management-suite','/hotel-management/inventory':'hotel-management-suite','/pms':'hotel-pms','/reservation':'restaurant-reservation',
  '/delivery':'food-delivery','/store':'restaurant-store','/restaurant-stores':'restaurant-store','/channel-manager':'channel-manager','/pos':'anaira-pos','/housekeeping':'hotel-pms','/seo':'seo-system','/plugins/seo-system/settings':'seo-system','/ai-reviews':'ai-review-system'
};
const PERMISSION_BY_ROUTE = {
  '/customer-360':'customer.view','/stays':'customer.view','/restaurant':'customer.view','/leads':'lead.view','/corporate':'corporate.view','/partners':'corporate.view',
  '/loyalty':'loyalty.view','/marketing':'segment.view','/campaigns':'campaign.view','/guest-relations':'review.view','/complaints':'complaint.view','/revenue':'report.revenue',
  '/analytics':'report.view','/events':'corporate.view','/ai':'report.view','/segmentation':'segment.view','/vip':'customer.view','/timeline':'timeline.view','/upselling':'customer.view',
  '/forecasting':'report.revenue','/competitors':'report.revenue','/ota':'report.view','/workflows':'task.view','/intelligence':'customer.view','/guest-requests':'guest_request.view',
  '/quotes':'corporate.view','/partner-bookings':'corporate.view','/reviews':'review.view','/booking':'booking.view','/hotel-store':'booking.view','/hotel-management':'hms.room.view','/pms':'pms.room.view','/reservation':'reservation.view',
  '/delivery':'delivery.order.view','/store':'store.view','/channel-manager':'ota.sync.view','/pos':'pos.order.view','/housekeeping':'housekeeping.task.view','/my-work':'task.view','/team-tasks':'task.view',
  '/import-export':'customer.export','/activity':'staff.activity','/store-builder':'store.view','/plugins/seo-system/settings':'seo-system.configure'
};
const SUPER_ONLY_ROUTES = ['/super-admin','/anaira/super-admin','/admin','/properties','/business-admins','/audit','/platform-settings','/system'];
const ADMIN_ONLY_ROUTES = ['/store-builder','/users','/roles','/hotel-management/setup','/hotel-management/room-types','/hotel-management/rooms','/hotel-management/rates','/hotel-management/inventory','/restaurant-setup'];
const BUSINESS_SETTINGS_ROUTE='/business-settings';

const SUPER_GROUPS = [
  {title:'COMMAND CENTER',items:[['▦','Dashboard','/admin'],['▦','Properties / Tenants','/properties'],['♙','Business Admins','/business-admins'],['♙','Users & Staff','/users'],['◆','Roles & Profiles','/roles'],['◇','Plugin Control Center','/plugins'],['⚙','Global Integrations','/super-admin/integrations'],['◆','SEO System','/seo'],['★','AI Review Automation','/ai-reviews'],['◫','Audit Logs','/audit'],['⚙','Platform Settings','/platform-settings'],['⚙','Marketplace Settings','/super-admin/marketplace-settings'],['▣','Global Booking Engine','/super-admin/booking-engine']]},
  {title:'CRM PLATFORM',items:[['◉','Customer 360','/customer-360'],['⌂','Hotel Guest CRM','/stays'],['♨','Restaurant CRM','/restaurant'],['◆','Leads & Sales','/leads'],['▣','Corporate CRM','/corporate'],['♢','Partners','/partners'],['↔','Timeline / Interactions','/timeline'],['★','Guest Relations','/guest-relations'],['⚠','Complaints / Service Recovery','/complaints'],['★','Loyalty','/loyalty'],['◇','Segmentation','/segmentation'],['✦','VIP Management','/vip'],['◈','Offers & Coupons','/marketing'],['✉','Campaigns','/campaigns'],['◌','WhatsApp CRM','/integrations'],['⚙','Workflows / Automation','/workflows'],['✦','Events & Upselling','/events']]},
  {title:'BUSINESS INTELLIGENCE',items:[['▤','Analytics','/analytics'],['₹','Revenue Management','/revenue'],['◈','Forecasting','/forecasting'],['◈','Competitor Intelligence','/competitors'],['⇄','OTA / Channel Performance','/ota'],['✧','AI Insights','/ai'],['✧','Decision Intelligence','/intelligence']]},
  {title:'OPERATIONS',items:[['⌂','Hotel Booking','/booking'],['🏨','Hotel Marketplace','/anaira/hotels'],['▣','Booking Engine Control','/booking-engine'],['▦','Anaira Hotel Management','/hotel-management'],['▤','Hotel PMS','/pms'],['◫','Restaurant Reservation','/reservation'],['▣','Anaira POS','/pos'],['◉','Food Delivery','/delivery'],['◇','Restaurant Marketplace','/store'],['◆','Platform Store Control','/super-admin/stores'],['⇄','Channel / OTA Manager','/channel-manager'],['⚙','Hotel Setup','/hotel-management/setup'],['♨','Restaurant Setup','/restaurant-setup']]},
];

const BUSINESS_GROUPS = [
  {title:'COMMAND CENTER',items:[['▦','Dashboard','/'],['◌','My Tasks / Work Queue','/my-work']]},
  {title:'CRM',items:[['◉','Customer 360','/customer-360','customer.view','crm'],['⌂','Hotel Guest CRM','/stays','customer.view','crm'],['♨','Restaurant CRM','/restaurant','customer.view','crm'],['↔','Timeline / Interactions','/timeline','timeline.view','crm'],['◆','Leads & Sales','/leads','lead.view','crm'],['▣','Corporate CRM','/corporate','corporate.view','crm'],['♢','Partners','/partners','corporate.view','crm'],['▤','Quotes','/quotes','corporate.view','crm'],['▤','Partner Bookings','/partner-bookings','corporate.view','crm'],['★','Guest Relations','/guest-relations','review.view','crm'],['⚠','Complaints','/complaints','complaint.view','crm'],['✦','Service Recovery','/complaints','complaint.resolve','crm'],['★','VIP','/vip','customer.view','crm'],['★','Loyalty','/loyalty','loyalty.view','crm'],['◇','Segments','/segmentation','segment.view','crm'],['◈','Offers & Coupons','/marketing','segment.view','crm'],['✉','Campaigns','/campaigns','campaign.view','crm'],['◌','WhatsApp CRM','/integrations','crm.view','crm'],['⚙','Workflows / Automation','/workflows','task.view','crm'],['◆','SEO System','/seo','report.view','seo-system'],['★','AI Review Automation','/ai-reviews','review.view','ai-review-system'],['✦','Events / Upselling','/events','corporate.view','crm']]},
  {title:'INTELLIGENCE',items:[['▤','Analytics','/analytics','report.view','crm'],['₹','Revenue Management','/revenue','report.revenue','crm'],['◈','Forecasting','/forecasting','report.revenue','crm'],['◈','Competitor Intelligence','/competitors','report.revenue','crm'],['⇄','OTA / Channel Performance','/ota','report.view','crm'],['✧','AI Insights','/ai','report.view','crm'],['✧','Decision Intelligence','/intelligence','customer.view','crm']]},
  {title:'HOTEL MANAGEMENT',items:[['▦','Hotel Dashboard','/hotel-management','hms.room.view','hotel-management-suite'],['⌂','Hotel Profile','/hotel-management/setup','business.settings','hotel-management-suite'],['▣','Room Types','/hotel-management/room-types','hms.room.view','hotel-management-suite'],['▣','Rooms','/hotel-management/rooms','hms.room.view','hotel-management-suite'],['▦','Room Inventory','/hotel-management/inventory','hms.room.view','hotel-management-suite'],['₹','Rate Plans','/hotel-management/rates','booking.view','hotel-management-suite'],['⌂','Reservations','/booking','booking.view','hotel-booking'],['▤','PMS / Front Desk','/pms','pms.room.view','hotel-pms'],['⌂','Housekeeping','/housekeeping','housekeeping.task.view','hotel-pms']]},
  {title:'OPERATIONS',items:[['⌂','Hotel Booking Engine','/booking','booking.view','hotel-booking'],['🏨','My Hotel Store','/store-builder?kind=hotel','booking.view','hotel-booking'],['▣','Booking Engine Control','/booking-engine','booking.view','hotel-booking'],['◫','Restaurant Reservation','/reservation','reservation.view','restaurant-reservation'],['▣','Anaira POS','/pos','pos.order.view','anaira-pos'],['◉','Food Delivery','/delivery','delivery.order.view','food-delivery'],['◇','My Restaurant Store','/store-builder?kind=restaurant','store.view','restaurant-store'],['⇄','Channel / OTA','/channel-manager','ota.sync.view','channel-manager']]},
  {title:'MANAGEMENT',items:[['♙','Staff','/users','staff.view'],['◆','Roles & Profiles','/roles','staff.manage'],['⚙','Business Settings','/business-settings','business.settings'],['⚙','Integrations','/integrations','business.settings'],['⇄','Import / Export','/import-export','customer.export'],['♨','Restaurant Setup','/restaurant-setup','business.settings'],['◫','Activity Log','/activity','staff.activity']]},
];

const ROLE_GROUPS = {
  manager:[
    {title:'COMMAND CENTER',items:[['▦','Dashboard','/'],['◌','My Work','/my-work','task.view'],['☑','Team Tasks','/team-tasks','task.view']]},
    {title:'OPERATIONS',items:[['⌂','Bookings','/booking','booking.view','hotel-booking'],['▣','Booking Engine Control','/booking-engine','booking.view','hotel-booking'],['▦','Hotel Management','/hotel-management','hms.room.view','hotel-management-suite'],['▤','PMS','/pms','pms.room.view','hotel-pms'],['◫','Restaurant Reservations','/reservation','reservation.view','restaurant-reservation'],['▣','POS','/pos','pos.order.view','anaira-pos'],['◉','Delivery','/delivery','delivery.order.view','food-delivery'],['⌂','Housekeeping','/housekeeping','housekeeping.task.view','hotel-pms']]},
    {title:'CRM',items:[['◉','Customer 360','/customer-360','customer.view','crm'],['★','Guest Relations','/guest-relations','review.view','crm'],['◌','Guest Requests','/guest-requests','guest_request.view','crm'],['⚠','Complaints','/complaints','complaint.view','crm'],['✦','Service Recovery','/complaints','complaint.resolve','crm']]},
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
  marketing_executive:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'MARKETING',items:[['◇','Segments','/segmentation','segment.view','crm'],['✉','Campaigns','/campaigns','campaign.view','crm'],['◌','WhatsApp CRM','/integrations','crm.view','crm'],['★','Reviews','/guest-relations','review.view','crm']]}],
  crm_executive:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/'],['◌','My Work','/my-work','task.view']]},{title:'CRM',items:[['◉','Customer 360','/customer-360','customer.view','crm'],['↔','Timeline','/timeline','timeline.view','crm'],['◆','Leads','/leads','lead.view','crm'],['⚠','Complaints','/complaints','complaint.view','crm'],['★','Loyalty','/loyalty','loyalty.view','crm'],['◇','Segments','/segmentation','segment.view','crm'],['◌','Guest Requests','/guest-requests','guest_request.view','crm']]}],
  accountant:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'FINANCE',items:[['₹','Revenue Reports','/revenue','report.revenue','crm'],['▤','Reports','/analytics','report.financial','crm'],['▣','POS Payments','/pos','pos.payment.collect','anaira-pos'],['↩','Refunds','/pos','pos.payment.refund','anaira-pos']]}],
  read_only:[{title:'COMMAND CENTER',items:[['▦','Dashboard','/']]},{title:'VIEW',items:[['◉','Customer 360','/customer-360','customer.view','crm'],['⌂','Bookings','/booking','booking.view','hotel-booking'],['▣','Booking Engine Control','/booking-engine','booking.view','hotel-booking'],['▦','Hotel Management','/hotel-management','hms.room.view','hotel-management-suite'],['▤','PMS','/pms','pms.room.view','hotel-pms'],['▣','POS','/pos','pos.order.view','anaira-pos'],['▤','Reports','/analytics','report.view','crm']]}]
};

function normalizeGroups(groups){return groups.map(g=>({...g,items:g.items.map(x=>({icon:x[0],label:x[1],href:x[2],permission:x[3],plugin:x[4]}))}));}

export function AppShell({children, active}) {
  const pathname=usePathname(); const router=useRouter();
  const [ctx,setCtx]=useState({loading:true,session:null,role:null,profileKey:null,isSuperAdmin:false,restaurantId:null,plugins:{},permissions:{}});
  useEffect(()=>{let alive=true;(async()=>{
    if(!supabase){if(alive)setCtx(x=>({...x,loading:false}));return;}
    const {data:{session}}=await supabase.auth.getSession();
    if(!session){if(alive)setCtx({loading:false,session:null,role:null,profileKey:null,isSuperAdmin:false,restaurantId:null,plugins:{},permissions:{}});return;}
    const {data:p}=await supabase.from('anaira_my_profile').select('is_super_admin,role,restaurant_id,full_name').eq('id',session.user.id).maybeSingle();
    const superAdmin=p?.is_super_admin===true||p?.role==='super_admin';
    let plugins={},permissions={};
    if(!superAdmin&&p?.restaurant_id){
      const [{data:pl},{data:rp},{data:up},{data:prof}]=await Promise.all([
        supabase.from('restaurant_plugins').select('plugin_code,enabled').eq('restaurant_id',p.restaurant_id),
        supabase.from('anaira_role_permissions').select('permission_key').eq('role_key',p.role||'staff'),
        supabase.from('anaira_user_permissions').select('permission_key,allowed').eq('user_id',session.user.id).eq('restaurant_id',p.restaurant_id),
        supabase.from('anaira_user_profiles').select('profile_key').eq('user_id',session.user.id).eq('restaurant_id',p.restaurant_id).maybeSingle()
      ]);
      plugins=Object.fromEntries((pl||[]).map(x=>[x.plugin_code,x.enabled===true]));
      permissions=Object.fromEntries((rp||[]).map(x=>[x.permission_key,true]));
      if(prof?.profile_key){ const {data:pp}=await supabase.from('anaira_profile_permissions').select('permission_key').eq('profile_key',prof.profile_key); (pp||[]).forEach(x=>{permissions[x.permission_key]=true}); }
      (up||[]).forEach(x=>{permissions[x.permission_key]=x.allowed===true});
      var profileKey=prof?.profile_key||null;
    }
    if(alive)setCtx({loading:false,session,role:p?.role||'staff',profileKey:typeof profileKey==='undefined'?null:profileKey,isSuperAdmin:superAdmin,restaurantId:p?.restaurant_id||null,plugins,permissions,fullName:p?.full_name||''});
  })();return()=>{alive=false}},[]);

  const groups=useMemo(()=>{
    if(ctx.isSuperAdmin)return normalizeGroups(SUPER_GROUPS);
    if(ctx.role==='admin'||ctx.profileKey==='business_admin')return normalizeGroups(BUSINESS_GROUPS);
    if(ctx.role==='staff' && ctx.profileKey && PROFILE_GROUPS[ctx.profileKey]) return normalizeGroups(PROFILE_GROUPS[ctx.profileKey]);
    return normalizeGroups(ROLE_GROUPS[ctx.role]||ROLE_GROUPS.staff);
  },[ctx.isSuperAdmin,ctx.role,ctx.profileKey]);

  const visibleGroups=groups.map(g=>({...g,items:g.items.filter(item=>{
    if(!item.permission && !item.plugin)return true;
    if(ctx.isSuperAdmin)return true;
    if(item.plugin && ctx.plugins[item.plugin]!==true)return false;
    if(item.permission && ctx.permissions[item.permission]!==true && ctx.role!=='admin' && ctx.profileKey!=='business_admin')return false;
    return true;
  })})).filter(g=>g.items.length);

  useEffect(()=>{
    if(ctx.loading)return;
    if(!ctx.session){ if(pathname!=='/login') router.replace('/login'); return; }
    if(pathname==='/admin' || pathname.startsWith('/admin/')){if(!ctx.isSuperAdmin)router.replace('/');return;}
    if(pathname==='/plugins' && !ctx.isSuperAdmin && ctx.role!=='admin' && ctx.profileKey!=='business_admin'){router.replace('/');return;}
    if(SUPER_ONLY_ROUTES.some(r=>pathname===r||pathname.startsWith(r+'/')) && !ctx.isSuperAdmin){router.replace('/');return;}
    if(ADMIN_ONLY_ROUTES.some(r=>pathname===r||pathname.startsWith(r+'/')) && !ctx.isSuperAdmin && ctx.role!=='admin' && ctx.profileKey!=='business_admin'){router.replace('/');return;}
    if(pathname===BUSINESS_SETTINGS_ROUTE && !ctx.isSuperAdmin && ctx.role!=='admin' && ctx.profileKey!=='business_admin'){router.replace('/');return;}
    if(ctx.isSuperAdmin)return;
    const plugin=PLUGIN_BY_ROUTE[pathname];
    if(plugin && ctx.plugins[plugin]!==true){router.replace('/');return;}
    if(ctx.role!=='admin' && ctx.profileKey!=='business_admin'){
      const required=PERMISSION_BY_ROUTE[pathname];
      if(required && ctx.permissions[required]!==true)router.replace('/');
    }
  },[ctx.loading,ctx.session,ctx.isSuperAdmin,ctx.role,ctx.profileKey,ctx.plugins,ctx.permissions,pathname,router]);

  const portalLabel=ctx.isSuperAdmin?'SUPER ADMIN':(ctx.role==='admin'||ctx.profileKey==='business_admin')?'BUSINESS PORTAL':ctx.role==='manager'?'MANAGER PORTAL':'STAFF PORTAL';
  const [mobileNavOpen,setMobileNavOpen]=useState(false);
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
    <button type="button" className="mobile-nav-toggle" aria-label={mobileNavOpen?'Close navigation':'Open navigation'} aria-expanded={mobileNavOpen} onClick={()=>setMobileNavOpen(v=>!v)}>
      <span></span><span></span><span></span>
    </button>
    {mobileNavOpen&&<button type="button" className="mobile-nav-backdrop" aria-label="Close navigation" onClick={()=>setMobileNavOpen(false)}/>}
    <aside className={'sidebar'+(mobileNavOpen?' is-open':'')}>
      <div className="brand"><img src="/assets/anaira-logo.webp" alt="Anaira"/><div><b>ANAIRA</b><span>HOTEL & RESTAURANT CRM</span></div></div>
      <div className="portal-badge">{portalLabel}{ctx.restaurantId&&!ctx.isSuperAdmin?' • '+ctx.restaurantId.slice(0,8):''}</div>
      <nav className="nav">{visibleGroups.map((group,gi)=><div className="nav-group" key={group.title}><div className="navtitle">{group.title}</div>{group.items.map(item=><a key={`${item.href}-${item.label}`} href={item.href} className={active===item.href||pathname===item.href?'active':''} onClick={()=>setMobileNavOpen(false)}><i>{item.icon}</i><span>{item.label}</span></a>)}</div>)}</nav>
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
