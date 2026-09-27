'use client';
import {useState} from 'react';
import Link from 'next/link';
import {Search, MapPin, Hotel, CalendarDays} from 'lucide-react';
import {supabase} from '../../../lib/supabase';
import AnairaShell from '../../../components/anaira/AnairaShell';

export default function Hotels(){
 const [q,setQ]=useState(''),[inDate,setInDate]=useState(''),[outDate,setOutDate]=useState(''),[adults,setAdults]=useState(2),[children,setChildren]=useState(0),[rows,setRows]=useState([]),[loading,setLoading]=useState(false),[msg,setMsg]=useState('');
 async function search(){
  if(!inDate||!outDate){setMsg('Select check-in and check-out dates.');return}
  if(outDate<=inDate){setMsg('Check-out must be after check-in.');return}
  setLoading(true);setMsg('');
  const {data,error}=await supabase.rpc('anaira_marketplace_hotel_search',{p_check_in:inDate,p_check_out:outDate,p_adults:Number(adults),p_children:Number(children),p_destination:q||null});
  setLoading(false);
  if(error){setRows([]);setMsg(error.message);return}
  setRows(data||[]);
  if(!(data||[]).length)setMsg('No published hotels with available room inventory were found for these dates.');
 }
 return <AnairaShell title="ANAIRA Hotels">
  <div className="anaira-card" style={{marginBottom:20}}><div style={{display:'grid',gridTemplateColumns:'2fr 1fr 1fr 1fr 1fr auto',gap:10,alignItems:'end'}}>
   <label>Destination<input className="anaira-search" value={q} onChange={e=>setQ(e.target.value)} placeholder="Kullu, Manali..."/></label>
   <label>Check-in<input className="anaira-search" type="date" value={inDate} onChange={e=>setInDate(e.target.value)}/></label>
   <label>Check-out<input className="anaira-search" type="date" value={outDate} onChange={e=>setOutDate(e.target.value)}/></label>
   <label>Adults<input className="anaira-search" type="number" min="1" value={adults} onChange={e=>setAdults(e.target.value)}/></label>
   <label>Children<input className="anaira-search" type="number" min="0" value={children} onChange={e=>setChildren(e.target.value)}/></label>
   <button className="anaira-btn" onClick={search} disabled={loading}><Search size={16}/>{loading?'Searching…':'Search'}</button>
  </div></div>
  {msg&&<div className="anaira-card" style={{marginBottom:18}}>{msg}</div>}
  {!rows.length&&!loading?<div className="anaira-card"><h2>Search live hotel inventory</h2><p className="anaira-muted">Results come from published ANAIRA hotel memberships and date-scoped inventory. No sample hotel cards are used.</p></div>:null}
  {loading?<p>Searching live hotel inventory…</p>:<div className="anaira-grid">{rows.map(x=><div className="anaira-card" key={x.restaurant_id}>
    <div className="anaira-muted"><MapPin size={14}/> {x.city||x.address}</div>
    {(x.listing_override?.cover_url||x.cover_image)&&<img src={x.listing_override?.cover_url||x.cover_image} alt="" style={{width:'100%',height:150,objectFit:'cover',borderRadius:12,marginTop:10}}/>}
    <h3>{x.listing_override?.title||x.hotel_name}</h3><p>{x.listing_override?.tagline||''}</p>
    <p><Hotel size={14}/> {x.available_room_types||0} room type(s) currently available</p>
    <p><CalendarDays size={14}/> {inDate} → {outDate}</p>
    <Link className="anaira-btn" href={`/book/${x.restaurant_id}?check_in=${inDate}&check_out=${outDate}&adults=${adults}&children=${children}`}>Select hotel & rooms →</Link>
  </div>)}</div>}
 </AnairaShell>
}
