'use client'
import Link from 'next/link'
import { Hotel, Utensils, Users, ShieldCheck, Store, LayoutDashboard, CalendarDays, ShoppingBag } from 'lucide-react'

const links = [
  ['/', 'Anaira Home', LayoutDashboard],
  ['/anaira/marketplace', 'Marketplace', Store],
  ['/anaira/hotels', 'Hotel Booking', Hotel],
  ['/anaira/food', 'Food Marketplace', Utensils],
  ['/anaira/bookings', 'My Bookings', CalendarDays],
  ['/anaira/orders', 'My Orders', ShoppingBag],
  ['/anaira/customer', 'Customer 360', Users],
  ['/anaira/business-admin', 'Business Admin', ShieldCheck],
  ['/anaira/super-admin', 'Super Admin', ShieldCheck],
]

export default function AnairaShell({children, title='Anaira'}) {
  return <div className="anaira-shell">
    <header className="anaira-topbar">
      <div className="anaira-brand"><span className="anaira-logo">A</span><div><b>ANAIRA</b><small>Hospitality • Food • Commerce</small></div></div>
      <nav>{links.slice(1,7).map(([href,label,Icon]) => <Link key={href} href={href}><Icon size={16}/>{label}</Link>)}</nav>
      <Link className="anaira-admin-btn" href="/anaira/business-admin"><ShieldCheck size={16}/> Admin</Link>
    </header>
    <main className="anaira-main">
      <div className="anaira-page-title"><div><span>ANAIRA PLATFORM</span><h1>{title}</h1></div></div>
      {children}
    </main>
    <style jsx global>{`
      .anaira-shell{min-height:100vh;background:#07110e;color:#eef8f3;font-family:Inter,system-ui,sans-serif}.anaira-topbar{position:sticky;top:0;z-index:20;height:70px;display:flex;align-items:center;gap:24px;padding:0 28px;background:rgba(5,15,12,.92);backdrop-filter:blur(16px);border-bottom:1px solid rgba(255,255,255,.08)}.anaira-brand{display:flex;align-items:center;gap:10px;min-width:240px}.anaira-logo{width:38px;height:38px;border-radius:12px;display:grid;place-items:center;background:#c9a34b;color:#07110e;font-weight:900}.anaira-brand small{display:block;color:#8fa59c;font-size:10px;margin-top:2px}.anaira-topbar nav{display:flex;gap:5px;flex:1;overflow:auto}.anaira-topbar nav a,.anaira-admin-btn{display:flex;align-items:center;gap:7px;color:#cbd8d2;text-decoration:none;font-size:12px;padding:9px 10px;border-radius:9px;white-space:nowrap}.anaira-topbar nav a:hover,.anaira-admin-btn:hover{background:rgba(201,163,75,.12);color:#e9c76a}.anaira-admin-btn{border:1px solid rgba(201,163,75,.35);color:#e9c76a}.anaira-main{max-width:1450px;margin:auto;padding:30px}.anaira-page-title{margin-bottom:24px}.anaira-page-title span{font-size:10px;letter-spacing:2px;color:#c9a34b}.anaira-page-title h1{font-size:30px;margin:5px 0 0}.anaira-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px}.anaira-card{background:#0d1b16;border:1px solid rgba(255,255,255,.08);border-radius:16px;padding:20px}.anaira-card h3{margin:10px 0 6px}.anaira-card p{color:#91a79e;font-size:13px;line-height:1.6}.anaira-card a{color:#e9c76a;text-decoration:none}.anaira-stat{font-size:28px;font-weight:800;color:#e9c76a}.anaira-btn{display:inline-flex;align-items:center;gap:8px;background:#c9a34b;color:#07110e;border:0;border-radius:10px;padding:11px 15px;font-weight:800;text-decoration:none}.anaira-muted{color:#91a79e}.anaira-table{width:100%;border-collapse:collapse}.anaira-table th,.anaira-table td{text-align:left;padding:12px;border-bottom:1px solid rgba(255,255,255,.07);font-size:13px}.anaira-badge{display:inline-block;padding:4px 8px;border-radius:999px;background:rgba(67,183,121,.12);color:#75d6a1;font-size:11px}.anaira-search{width:100%;padding:13px;border-radius:11px;background:#09150f;border:1px solid rgba(255,255,255,.1);color:#fff}.anaira-hero{background:linear-gradient(135deg,#0d2118,#122c20);border:1px solid rgba(201,163,75,.25);border-radius:22px;padding:34px;margin-bottom:20px}.anaira-hero h2{font-size:32px;margin:0 0 8px}.anaira-hero p{max-width:720px;color:#a8b9b1;line-height:1.7}.anaira-kpis{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin:20px 0}.anaira-kpi{padding:18px;background:#0b1813;border:1px solid rgba(255,255,255,.07);border-radius:14px}.anaira-kpi small{color:#80958c}.anaira-section{margin-top:28px}.anaira-section h2{font-size:20px;margin-bottom:14px}@media(max-width:900px){.anaira-topbar nav{display:none}.anaira-brand{min-width:auto}.anaira-main{padding:18px}.anaira-kpis{grid-template-columns:repeat(2,1fr)}}
    `}</style>
  </div>
}
