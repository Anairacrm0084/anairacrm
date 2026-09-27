'use client';
import {useEffect,useState} from 'react';
import {useParams} from 'next/navigation';
import {supabase} from '../../../lib/supabase';

export default function HotelBooking(){
 const {id}=useParams(); const [hotel,setHotel]=useState(null),[rooms,setRooms]=useState([]),[f,setF]=useState({in:'',out:'',adults:2,children:0,room:'' ,name:'',phone:'',email:''}),[msg,setMsg]=useState(''),[busy,setBusy]=useState(false);
 useEffect(()=>{if(id)supabase.rpc('anaira_marketplace_business',{p_restaurant_id:id}).then(({data})=>setHotel(data?.[0]||null))},[id]);
 async function search(){setMsg('');const {data,error}=await supabase.rpc('anaira_public_room_availability_by_id',{p_restaurant_id:id,p_check_in:f.in,p_check_out:f.out,p_adults:+f.adults,p_children:+f.children});if(error)setMsg(error.message);else setRooms(data||[])}
 async function book(){setBusy(true);const {data,error}=await supabase.rpc('anaira_create_public_booking_by_id',{p_restaurant_id:id,p_guest_name:f.name,p_guest_phone:f.phone,p_guest_email:f.email,p_check_in:f.in,p_check_out:f.out,p_room_type_id:f.room,p_adults:+f.adults,p_children:+f.children,p_source:'anaira_marketplace'});setBusy(false);setMsg(error?error.message:`Booking ${data?.[0]?.booking_code||''} created. Payment gateway can be attached to this booking.`)}
 return <main className="public-shell"><header><div className="eyebrow">ANAIRA HOTEL BOOKING</div><h1>{hotel?.name||'Hotel'}</h1><p>{hotel?.cuisine||'Hospitality'} · {hotel?.address||''}</p></header>
 <section className="section"><h2>Search Rooms</h2><div className="form-grid"><input type="date" value={f.in} onChange={e=>setF({...f,in:e.target.value})}/><input type="date" value={f.out} onChange={e=>setF({...f,out:e.target.value})}/><input type="number" min="1" value={f.adults} onChange={e=>setF({...f,adults:e.target.value})}/><input type="number" min="0" value={f.children} onChange={e=>setF({...f,children:e.target.value})}/><button className="btn primary" onClick={search}>Check Availability</button></div>
 {rooms.map(r=><article className="card" key={r.room_type_id}><b>{r.name}</b><p>₹{Number(r.base_rate||0).toLocaleString('en-IN')} · {r.available_rooms} available · up to {r.max_occupancy} guests</p><button className="btn" onClick={()=>setF({...f,room:r.room_type_id})}>{f.room===r.room_type_id?'Selected':'Select Room'}</button></article>)}</section>
 <section className="section"><h2>Guest Details</h2><div className="form-grid"><input placeholder="Full name" value={f.name} onChange={e=>setF({...f,name:e.target.value})}/><input placeholder="Phone" value={f.phone} onChange={e=>setF({...f,phone:e.target.value})}/><input placeholder="Email" value={f.email} onChange={e=>setF({...f,email:e.target.value})}/><button className="btn primary" disabled={!f.room||busy} onClick={book}>{busy?'Booking…':'Confirm Booking'}</button></div>{msg&&<div className="notice">{msg}</div>}</section>
 <a className="btn" href="/marketplace">← Back to Marketplace</a></main>
}