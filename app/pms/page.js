'use client';

import { useEffect, useMemo, useState } from 'react';
import { AppShell, Header, Section, Table, Pill } from '../components';
import { supabase } from '../../lib/supabase';

const actions = [
  ['confirm','Confirm'],['check_in','Check-in'],['room_move','Room Move'],['checkout','Check-out'],['no_show','No-show'],['cancel','Cancel']
];

export default function PMSPage(){
  const [session,setSession]=useState(null),[restaurantId,setRestaurantId]=useState(null),[rooms,setRooms]=useState([]),[reservations,setReservations]=useState([]),[busy,setBusy]=useState(''),[error,setError]=useState('');
  const load=async(rid)=>{
    if(!rid)return;
    const [rq,rs]=await Promise.all([
      supabase.from('hms_rooms').select('id,room_number,floor,status,housekeeping_status,room_type_id').eq('restaurant_id',rid).order('room_number'),
      supabase.from('hms_reservations').select('id,reservation_code,guest_id,room_id,check_in,check_out,status,adults,children,total_amount').eq('restaurant_id',rid).order('check_in',{ascending:true}).limit(100)
    ]);
    if(rq.error)setError(rq.error.message); if(rs.error)setError(rs.error.message);
    setRooms(rq.data||[]);setReservations(rs.data||[]);
  };
  useEffect(()=>{(async()=>{const {data}=await supabase.auth.getSession();if(!data.session){location.href='/login';return;}setSession(data.session);const p=await supabase.from('anaira_my_profile').select('restaurant_id').eq('id',data.session.user.id).maybeSingle();setRestaurantId(p.data?.restaurant_id||null);if(p.data?.restaurant_id)load(p.data.restaurant_id);})()},[]);
  const today=new Date().toISOString().slice(0,10);
  const arrivals=useMemo(()=>reservations.filter(x=>x.check_in===today&&['confirmed','pending'].includes(x.status)),[reservations]);
  const inhouse=useMemo(()=>reservations.filter(x=>['checked_in','in_house'].includes(x.status)),[reservations]);
  const departures=useMemo(()=>reservations.filter(x=>x.check_out===today&&['checked_in','in_house'].includes(x.status)),[reservations]);
  async function transition(r,action){
    setBusy(r.id+action);setError('');
    let roomId=r.room_id;
    if(action==='check_in'||action==='room_move'){
      roomId=prompt(action==='check_in'?'Room ID for check-in':'Target room ID',roomId||'')||null;
      if(!roomId){setBusy('');return;}
    }
    const {data,error:e}=await supabase.rpc('anaira_phase13_pms_transition',{p_restaurant_id:restaurantId,p_reservation_id:r.id,p_action:action,p_room_id:roomId,p_notes:null});
    if(e)setError(e.message);else if(data?.ok)await load(restaurantId);else setError('PMS transition was not accepted.');
    setBusy('');
  }
  if(!session)return <AppShell><div className="notice">Connecting to PMS…</div></AppShell>;
  return <AppShell active="/pms"><Header eyebrow="HOTEL PMS" title="Anaira Hotel PMS" subtitle="Front desk, room assignment, stay lifecycle and housekeeping handoff. Booking Engine and CRM remain optional integrations." actions={<button className="btn" onClick={()=>load(restaurantId)}>Refresh</button>}/>
    {error&&<div className="notice error">{error}</div>}
    <div className="grid kpis"><div className="kpi"><span>Arrivals</span><b>{arrivals.length}</b><small>Today</small></div><div className="kpi"><span>In-House</span><b>{inhouse.length}</b><small>Current</small></div><div className="kpi"><span>Departures</span><b>{departures.length}</b><small>Today</small></div><div className="kpi"><span>Rooms</span><b>{rooms.length}</b><small>Property</small></div></div>
    <Section title="Front Desk — Reservations" meta="Live HMS data"><Table columns={['Code','Check-in','Check-out','Status','Room','Total','Actions']} rows={reservations.map(r=>[r.reservation_code,r.check_in,r.check_out,<Pill>{r.status}</Pill>,r.room_id||'Unassigned',String(r.total_amount??0),<div style={{display:'flex',gap:6,flexWrap:'wrap'}}>{actions.map(([a,l])=><button key={a} className="btn" disabled={!!busy} onClick={()=>transition(r,a)}>{busy===r.id+a?'…':l}</button>)}</div>])}/></Section>
    <Section title="Room Status" meta="Live HMS rooms"><Table columns={['Room','Floor','Status','Housekeeping']} rows={rooms.map(r=>[r.room_number,r.floor||'—',<Pill>{r.status}</Pill>,<Pill>{r.housekeeping_status||'—'}</Pill>])}/></Section>
  </AppShell>;
}
