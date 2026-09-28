'use client';
import {useEffect,useMemo,useState} from 'react';
import Link from 'next/link';

const stores=[
 {type:'hotel',name:'ANAIRA Hotels',path:'/anaira/hotels',settings:'/super-admin/hotel-marketplace-settings',label:'Hotel Marketplace',desc:'Hotels only • live room availability • direct booking'},
 {type:'restaurant',name:'ANAIRA Restaurants',path:'/store',settings:'/super-admin/marketplace-settings',label:'Restaurant Marketplace',desc:'Restaurants only • live menu • ordering / pickup / dine-in'}
];
export default function GlobalStoreQR(){
 const [origin,setOrigin]=useState('');
 useEffect(()=>setOrigin(process.env.NEXT_PUBLIC_SITE_URL||window.location.origin),[]);
 return <section className="global-store-qr-section">
  <div className="global-store-qr-head"><div><span>ANAIRA CUSTOMER STORES</span><h2>Global Store QR & Public Links</h2><p>One QR for each platform-owned marketplace. These links open the complete public stores, not individual hotel or restaurant records.</p></div></div>
  <div className="global-store-qr-grid">{stores.map(s=>{const link=`${origin}${s.path}`;const qr=`https://api.qrserver.com/v1/create-qr-code/?size=500x500&margin=12&data=${encodeURIComponent(link)}`;return <article className="global-store-qr-card" key={s.type}><img src={qr} alt={`${s.name} QR`}/><div><small>{s.label}</small><h3>{s.name}</h3><p>{s.desc}</p><div className="global-store-qr-actions"><a className="btn primary" href={qr} target="_blank" rel="noreferrer">Open / Save QR ↗</a><Link className="btn" href={s.path} target="_blank">Preview Store ↗</Link><Link className="btn" href={s.settings}>Settings</Link></div><code>{s.path}</code></div></article>})}</div>
 </section>;
}
