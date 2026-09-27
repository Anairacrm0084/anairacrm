'use client';
import {useEffect,useState} from 'react';
import {supabase} from '../../lib/supabase';

export default function Marketplace(){
 const [mode,setMode]=useState('all'),[city,setCity]=useState(''),[items,setItems]=useState([]),[loading,setLoading]=useState(true),[error,setError]=useState('');
 async function load(){
  setLoading(true); setError('');
  const {data,error}=await supabase.rpc('anaira_marketplace_businesses',{p_city:city||null,p_mode:mode});
  if(error)setError(error.message); else setItems(data||[]);
  setLoading(false);
 }
 useEffect(()=>{load()},[mode]);
 return <main className="public-shell"><header><div className="eyebrow">ANAIRA MARKETPLACE</div><h1>Hotels + Food, One Customer Account</h1><p>Book rooms from connected hotels and order food from connected restaurants.</p></header>
  <div className="section" style={{display:'flex',gap:10,flexWrap:'wrap'}}>
   <input value={city} onChange={e=>setCity(e.target.value)} placeholder="Search city / destination" />
   <button className={mode==='all'?'btn primary':'btn'} onClick={()=>setMode('all')}>All</button>
   <button className={mode==='hotel'?'btn primary':'btn'} onClick={()=>setMode('hotel')}>Hotels</button>
   <button className={mode==='food'?'btn primary':'btn'} onClick={()=>setMode('food')}>Food</button>
   <button className="btn" onClick={load}>Search</button>
  </div>
  {error&&<div className="notice error">{error}</div>}
  <section className="section"><div className="section-head"><h2>Connected Businesses</h2><span>{loading?'Loading…':`${items.length} marketplace listings`}</span></div>
   <div className="grid cards">
    {items.map(x=><article className="card" key={x.restaurant_id}>
      <div className="eyebrow">{x.listing_type?.replace('_',' & ').toUpperCase()}</div>
      <h3>{x.name}</h3><p>{x.cuisine||'Hospitality'} · {x.address||x.city||'India'}</p>
      <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
       {x.hotel_booking_enabled&&<a className="btn primary" href={`/hotel/${x.restaurant_id}`}>Book Hotel</a>}
       {x.food_ordering_enabled&&<a className="btn primary" href={`/restaurant/${x.restaurant_id}`}>Order Food</a>}
       {x.restaurant_reservation_enabled&&<a className="btn" href={`/restaurant-reservation/${x.restaurant_id}`}>Reserve Table</a>}
      </div>
    </article>)}
   </div>
   {!loading&&!items.length&&<div className="notice">No approved marketplace businesses found.</div>}
  </section></main>
}