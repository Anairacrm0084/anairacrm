'use client';
import AnairaShell from '@/components/anaira/AnairaShell';
import Link from 'next/link';
export default function HotelStore(){return <AnairaShell title="ANAIRA Hotel Store"><div className="anaira-hero"><h2>ANAIRA Hotels — Unified Hotel Store</h2><p>All approved hotels appear in one marketplace. Select a hotel to open its own customer-facing booking store.</p><div style={{display:'flex',gap:10,flexWrap:'wrap',marginTop:16}}><Link className="anaira-btn" href="/anaira/hotels">Open Hotel Marketplace →</Link><Link className="anaira-btn" href="/super-admin/stores">Super Admin Store Control →</Link><Link className="anaira-btn" href="/store-builder?kind=hotel">Hotel Store Builder →</Link></div></div></AnairaShell>}
