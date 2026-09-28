'use client';
import {useParams} from 'next/navigation';
import {useEffect,useMemo,useState} from 'react';
import {supabase} from '../../../lib/supabase';

export default function Reservation(){
  const {id}=useParams();
  const [r,setR]=useState(null),[tables,setTables]=useState([]),[f,setF]=useState({name:'',phone:'',email:'',date:'',time:'19:30',party:2,duration:90,table:''}),[msg,setMsg]=useState(''),[loading,setLoading]=useState(false);
  useEffect(()=>{if(id)supabase.rpc('anaira_marketplace_business',{p_restaurant_id:id}).then(({data})=>setR(data?.[0]||null))},[id]);
  const loadAvailability=async()=>{if(!id||!f.date||!f.time)return;const {data,error}=await supabase.rpc('anaira_restaurant_reservation_availability',{p_restaurant_id:id,p_date:f.date,p_time:f.time,p_party_size:Number(f.party),p_duration_minutes:Number(f.duration)});if(error)setMsg(error.message);else{setTables(data||[]);if(f.table&&!data?.some(x=>x.table_id===f.table))setF(x=>({...x,table:''}))}};
  useEffect(()=>{loadAvailability()},[id,f.date,f.time,f.party,f.duration]);
  const available=useMemo(()=>tables.filter(x=>x.available),[tables]);
  async function reserve(){
    setLoading(true);setMsg('');
    const key=globalThis.crypto?.randomUUID?.()||`${Date.now()}-${Math.random()}`;
    const {data,error}=await supabase.rpc('anaira_create_restaurant_reservation_v2',{p_restaurant_id:id,p_guest_name:f.name,p_guest_phone:f.phone||null,p_guest_email:f.email||null,p_date:f.date,p_time:f.time,p_party_size:Number(f.party),p_duration_minutes:Number(f.duration),p_source:'anaira_marketplace',p_table_id:f.table||null,p_idempotency_key:key,p_special_request:null});
    setLoading(false);setMsg(error?error.message:`Reservation ${data?.reservation_code||''} confirmed.`);if(!error)loadAvailability();
  }
  return <main className="public-shell"><div className="eyebrow">ANAIRA RESTAURANT RESERVATION</div><h1>{r?.name||'Restaurant'}</h1><p>{r?.cuisine||''} · {r?.address||''}</p><section className="section form-grid">
    <input placeholder="Name" value={f.name} onChange={e=>setF({...f,name:e.target.value})}/><input placeholder="Phone" value={f.phone} onChange={e=>setF({...f,phone:e.target.value})}/><input placeholder="Email" value={f.email} onChange={e=>setF({...f,email:e.target.value})}/>
    <input type="date" value={f.date} onChange={e=>setF({...f,date:e.target.value})}/><input type="time" value={f.time} onChange={e=>setF({...f,time:e.target.value})}/><input type="number" min="1" value={f.party} onChange={e=>setF({...f,party:e.target.value})}/>
    <select value={f.duration} onChange={e=>setF({...f,duration:Number(e.target.value)})}><option value="60">60 minutes</option><option value="90">90 minutes</option><option value="120">120 minutes</option><option value="150">150 minutes</option></select>
    <select value={f.table} onChange={e=>setF({...f,table:e.target.value})}><option value="">Auto-assign available table</option>{available.map(t=><option key={t.table_id} value={t.table_id}>{t.table_number} · {t.capacity} seats{t.section?` · ${t.section}`:''}</option>)}</select>
    <button className="btn primary" disabled={loading||!f.name||!f.date||!f.time||available.length===0} onClick={reserve}>{loading?'Confirming…':'Reserve Table'}</button>
    {f.date&&f.time&&<div className="notice">{available.length?`${available.length} suitable table(s) available.`:'No suitable table is available for this time. Please choose another time.'}</div>}{msg&&<div className="notice">{msg}</div>}
  </section><a className="btn" href="/marketplace">← Back</a></main>
}
