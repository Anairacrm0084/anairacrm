'use client';
import Link from 'next/link';
import {Hotel,Utensils,Users,CalendarDays,ShoppingBag,Store,ArrowRight,ShieldCheck} from 'lucide-react';
import AnairaShell from '../../../components/anaira/AnairaShell';

const items=[
 {href:'/anaira/marketplace',label:'Marketplace',desc:'ANAIRA platform marketplace hub for hotels, restaurants and commerce.',icon:Store},
 {href:'/anaira/hotels',label:'Hotel Booking',desc:'Discover hotels, live availability, rooms and direct booking.',icon:Hotel},
 {href:'/anaira/food',label:'Food Marketplace',desc:'Browse connected restaurants and live food ordering experiences.',icon:Utensils},
 {href:'/anaira/bookings',label:'My Bookings',desc:'View hotel booking history, stays and reservation details.',icon:CalendarDays},
 {href:'/anaira/orders',label:'My Orders',desc:'View restaurant marketplace orders and order history.',icon:ShoppingBag},
 {href:'/anaira/customer',label:'Customer 360',desc:'Your ANAIRA customer identity, stays, orders and relationship history.',icon:Users}
];

export default function AnairaPlatform(){
 return <AnairaShell title="ANAIRA Platform">
  <section className="anaira-platform-page">
   <div className="anaira-platform-hero"><div><span>ANAIRA CUSTOMER PLATFORM</span><h1>Everything ANAIRA, in one place.</h1><p>The public-facing navigation is now a dedicated platform workspace. Hotels, food, bookings, orders and Customer 360 remain connected through the ANAIRA integration layer.</p></div><ShieldCheck size={44}/></div>
   <div className="anaira-platform-grid">{items.map(({href,label,desc,icon:Icon})=><Link href={href} className="anaira-platform-card" key={href}><div className="anaira-platform-icon"><Icon size={24}/></div><div><small>ANAIRA</small><h2>{label}</h2><p>{desc}</p></div><ArrowRight size={18}/></Link>)}</div>
  </section>
 </AnairaShell>
}
