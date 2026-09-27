'use client';
import {useEffect,useMemo,useState} from 'react';
import Link from 'next/link';
import {supabase} from '../lib/supabase';
import MarketplaceQR from '../components/anaira/MarketplaceQR';

const emptyCounts={hotel:0,restaurant:0};

export default function PlatformStoreControl(){
  const [stores,setStores]=useState([]);
  const [properties,setProperties]=useState([]);
  const [members,setMembers]=useState([]);
  const [type,setType]=useState('hotel');
  const [q,setQ]=useState('');
  const [loading,setLoading]=useState(true);
  const [busy,setBusy]=useState(false);
  const [msg,setMsg]=useState('');

  const current=useMemo(()=>stores.find(s=>s.store_type===type),[stores,type]);
  const propertyMap=useMemo(()=>Object.fromEntries(properties.map(p=>[p.id,p])),[properties]);
  const visibleMembers=useMemo(()=>members.filter(m=>{
    const p=propertyMap[m.restaurant_id];
    const text=`${p?.name||''} ${p?.city||''} ${p?.address||''}`.toLowerCase();
    return !q || text.includes(q.toLowerCase());
  }),[members,propertyMap,q]);

  async function load(nextType=type){
    setLoading(true); setMsg('');
    const {data:s,error:se}=await supabase.from('anaira_platform_stores').select('*').order('store_type');
    if(se){setMsg(se.message);setLoading(false);return;}
    const rows=s||[]; setStores(rows);
    const {data:p,error:pe}=await supabase.from('restaurants').select('id,name,status,city,address,logo,cover_image,cuisine,phone,website').order('name');
    if(pe){setMsg(pe.message);setLoading(false);return;}
    setProperties(p||[]);
    const store=rows.find(x=>x.store_type===nextType);
    if(store){
      const {data:m,error:me}=await supabase.from('anaira_store_memberships').select('*').eq('store_id',store.id).order('sort_order');
      if(me){setMsg(me.message);setMembers([]);} else setMembers(m||[]);
    } else setMembers([]);
    setLoading(false);
  }

  useEffect(()=>{load('hotel')},[]);
  useEffect(()=>{if(stores.length) load(type)},[type]);

  async function toggleStore(){
    if(!current)return;
    setBusy(true);
    const enabled=!current.enabled;
    const {error}=await supabase.from('anaira_platform_stores').update({enabled,updated_at:new Date().toISOString()}).eq('id',current.id);
    setMsg(error?.message||`${current.store_name} ${enabled?'enabled':'disabled'}`);
    setBusy(false);
    load(type);
  }

  async function toggleListing(m){
    const {error}=await supabase.from('anaira_store_memberships').update({enabled:!m.enabled}).eq('id',m.id);
    setMsg(error?.message||'Listing visibility updated');
    load(type);
  }

  const openUrl=(p)=>type==='hotel'?`/book/${p.id}`:`/store/${p.id}`;
  const listed=members.filter(m=>m.enabled).length;
  const activeBusinesses=properties.filter(p=>p.status==='active').length;

  return <div style={{display:'grid',gap:18}}>
    <div className="card" style={{overflow:'hidden'}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:16,flexWrap:'wrap'}}>
        <div>
          <div style={{fontSize:11,letterSpacing:1.5,fontWeight:800,color:'#8b6b27'}}>SUPER ADMIN • MARKETPLACE CONTROL</div>
          <h1 style={{margin:'5px 0 4px'}}>ANAIRA Platform Stores</h1>
          <p style={{margin:0,color:'#667'}}>Exactly two platform stores. Select one, manage its published businesses, and preview each business's own customer-facing store.</p>
        </div>
        <select className="compact-input" value={type} onChange={e=>{setQ('');setType(e.target.value)}} style={{minWidth:220,fontWeight:700}}>
          <option value="hotel">🏨 Hotel Store</option>
          <option value="restaurant">🍽 Restaurant Store</option>
        </select>
      </div>
      <div style={{display:'grid',gridTemplateColumns:'repeat(2,minmax(0,1fr))',gap:14,marginTop:18}}>
        {['hotel','restaurant'].map(t=>{const s=stores.find(x=>x.store_type===t);const selected=t===type;return <button key={t} onClick={()=>{setQ('');setType(t)}} style={{textAlign:'left',padding:20,borderRadius:18,border:`2px solid ${selected?'#c69b3c':'#e6e0d2'}`,background:selected?'#fff9ea':'#fff',cursor:'pointer',boxShadow:selected?'0 8px 26px #c69b3c22':'none'}}>
          <div style={{fontSize:12,fontWeight:800,color:'#777'}}>{t==='hotel'?'HOTEL MARKETPLACE':'RESTAURANT MARKETPLACE'}</div>
          <div style={{display:'flex',justifyContent:'space-between',gap:10,alignItems:'center'}}><h2 style={{margin:'6px 0'}}>{s?.store_name||`ANAIRA ${t==='hotel'?'Hotels':'Restaurants'}`}</h2><span style={{fontWeight:800,color:s?.enabled?'#147a4b':'#a33'}}>{s?.enabled?'● LIVE':'○ OFF'}</span></div>
          <p style={{margin:0,color:'#667'}}>{t==='hotel'?'All hotels → hotel profile → rooms → rates → booking':'All restaurants → restaurant store → menu → delivery / pickup / dine-in'}</p>
        </button>})}
      </div>
    </div>

    {current&&<div className="card">
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:12,flexWrap:'wrap'}}>
        <div><div style={{fontSize:12,fontWeight:800,color:'#8b6b27'}}>{type==='hotel'?'ANAIRA HOTELS':'ANAIRA RESTAURANTS'}</div><h2 style={{margin:'4px 0'}}>{current.store_name}</h2><div style={{fontSize:13,color:'#667'}}>One platform store · businesses have their own store pages inside it.</div></div>
        <div style={{display:'flex',gap:8,flexWrap:'wrap'}}><Link className="btn" href={type==='hotel'?'/anaira/hotels':'/anaira/food'} target="_blank">Open Public Marketplace ↗</Link><button className="btn primary" disabled={busy} onClick={toggleStore}>{busy?'Saving…':current.enabled?'Disable Store':'Enable Store'}</button></div>
      </div>
      <div style={{display:'grid',gridTemplateColumns:'repeat(3,minmax(0,1fr))',gap:10,marginTop:16}}>
        <div style={{padding:14,borderRadius:14,background:'#faf8f1'}}><small>ACTIVE BUSINESSES</small><h2 style={{margin:'4px 0'}}>{activeBusinesses}</h2></div>
        <div style={{padding:14,borderRadius:14,background:'#faf8f1'}}><small>LISTED IN THIS STORE</small><h2 style={{margin:'4px 0'}}>{listed}</h2></div>
        <div style={{padding:14,borderRadius:14,background:'#faf8f1'}}><small>STORE STATUS</small><h2 style={{margin:'4px 0'}}>{current.enabled?'Live':'Disabled'}</h2></div>
      </div>
    </div>}

    <div className="card">
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'end',gap:12,flexWrap:'wrap'}}>
        <div><h2 style={{margin:'0 0 4px'}}>{type==='hotel'?'Hotels in ANAIRA Hotels':'Restaurants in ANAIRA Restaurants'}</h2><p style={{margin:0,color:'#667'}}>Click a business to preview <b>its own store</b>. Super Admin only controls platform listing/visibility.</p></div>
        <input className="compact-input" value={q} onChange={e=>setQ(e.target.value)} placeholder={type==='hotel'?'Search hotel, city…':'Search restaurant, city…'} style={{minWidth:280}}/>
      </div>
      {loading?<div className="notice" style={{marginTop:16}}>Loading store…</div>:!visibleMembers.length?<div className="notice" style={{marginTop:16}}>No businesses are listed in this platform store yet.</div>:<div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(310px,1fr))',gap:16,marginTop:18}}>
        {visibleMembers.map(m=>{const p=propertyMap[m.restaurant_id];return <article key={m.id} style={{background:'#fff',border:'1px solid #e8e2d6',borderRadius:18,overflow:'hidden',boxShadow:'0 5px 18px #0000000b'}}>
          <div style={{height:155,background:p?.cover_image?`url(${p.cover_image}) center/cover`:'#0b3b2a',position:'relative'}}><div style={{position:'absolute',top:10,left:10,padding:'5px 9px',borderRadius:999,background:'#fff',fontSize:11,fontWeight:800}}>{m.enabled?'LISTED':'HIDDEN'}</div></div>
          <div style={{padding:16}}><div style={{fontSize:12,color:'#777'}}>{p?.city||p?.address||'—'}</div><h3 style={{margin:'5px 0'}}>{p?.name||m.restaurant_id}</h3><p style={{fontSize:13,color:'#667',minHeight:36,margin:'5px 0 12px'}}>{type==='hotel'?'Hotel profile • rooms • rates • availability':'Restaurant • menu • delivery • pickup • dine-in'}</p>
            <div style={{display:'flex',gap:8,flexWrap:'wrap'}}><Link className="btn primary" href={openUrl(p)} target="_blank">Open {type==='hotel'?'Hotel':'Restaurant'} Store ↗</Link><button className="btn" onClick={()=>toggleListing(m)}>{m.enabled?'Hide from Store':'List in Store'}</button></div>{type==='hotel'&&m.enabled&&<div style={{marginTop:12}}><MarketplaceQR restaurantId={m.restaurant_id} hotelName={p?.name||'Hotel'} compact/></div>}
          </div>
        </article>})}
      </div>}
      {msg&&<div className="notice" style={{marginTop:14}}>{msg}</div>}
    </div>
  </div>
}
