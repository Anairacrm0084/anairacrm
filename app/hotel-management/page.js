'use client';

import { useEffect, useMemo, useState } from 'react';
import { AppShell, Header, Section, Table, Pill } from '../components';
import { hospitalityMeta } from './setup-components';
import { supabase } from '../../lib/supabase';

const actions = [
  ['confirm','Confirm'],
  ['check_in','Check-in'],
  ['room_move','Room Move'],
  ['checkout','Check-out'],
  ['no_show','No-show'],
  ['cancel','Cancel']
];

const fmtMoney = (v) => `₹${Number(v || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

export default function PMSPage(){
  const [session,setSession]=useState(null),[restaurantId,setRestaurantId]=useState(null);
  const [rooms,setRooms]=useState([]),[reservations,setReservations]=useState([]),[guests,setGuests]=useState([]),[types,setTypes]=useState([]),[rates,setRates]=useState([]),[payments,setPayments]=useState([]);
  const [busy,setBusy]=useState(''),[error,setError]=useState(''),[hospitalityType,setHospitalityType]=useState('hotel');

  const load=async(rid,type=hospitalityType)=>{
    if(!rid)return;
    setError('');
    const [rq,rs,gq,tq,rpq,pq]=await Promise.all([
      supabase.from('hms_rooms').select('id,room_number,floor,status,housekeeping_status,room_type_id,hospitality_type').eq('restaurant_id',rid).eq('hospitality_type',type).order('room_number'),
      supabase.from('hms_reservations').select('id,reservation_code,guest_id,room_id,room_type_id,rate_plan_id,booking_reference,source,check_in,check_out,status,adults,children,rate,total_amount,deposit_amount,paid_amount,balance_amount,payment_status,payment_method,payment_reference,payment_proof_url,special_requests,created_at,hospitality_type').eq('restaurant_id',rid).eq('hospitality_type',type).order('check_in',{ascending:true}).limit(200),
      supabase.from('hms_guests').select('id,full_name,phone,email').eq('restaurant_id',rid),
      supabase.from('hms_room_types').select('id,name,code,hospitality_type').eq('restaurant_id',rid).eq('hospitality_type',type),
      supabase.from('hms_rate_plans').select('id,name,code,hospitality_type').eq('restaurant_id',rid).eq('hospitality_type',type),
      supabase.from('anaira_hotel_payment_submissions').select('id,reservation_id,method,note,receipt_path,status,created_at,updated_at').eq('tenant_id',rid).order('created_at',{ascending:false}).limit(200)
    ]);
    const bad=[rq,rs,gq,tq,rpq,pq].find(x=>x.error);
    if(bad)setError(bad.error.message);
    setRooms(rq.data||[]);setReservations(rs.data||[]);setGuests(gq.data||[]);setTypes(tq.data||[]);setRates(rpq.data||[]);setPayments(pq.data||[]);
  };

  useEffect(()=>{(async()=>{
    const {data}=await supabase.auth.getSession();
    if(!data.session){location.href='/login';return;}
    setSession(data.session);
    const p=await supabase.from('anaira_my_profile').select('restaurant_id').eq('id',data.session.user.id).maybeSingle();
    setRestaurantId(p.data?.restaurant_id||null);
    if(p.data?.restaurant_id){
      const t=await supabase.from('restaurants').select('hospitality_type,hospitality_types').eq('id',p.data.restaurant_id).maybeSingle();
      const types=Array.isArray(t.data?.hospitality_types)&&t.data.hospitality_types.length?t.data.hospitality_types:[t.data?.hospitality_type||'hotel'];
      const requested=typeof window!=='undefined'?new URLSearchParams(window.location.search).get('type'):'';
      setHospitalityType(types.includes(requested)?requested:types[0]);
      load(p.data.restaurant_id,types.includes(requested)?requested:types[0]);
    }
  })()},[]);

  const guestMap=useMemo(()=>Object.fromEntries(guests.map(x=>[x.id,x])),[guests]);
  const typeMap=useMemo(()=>Object.fromEntries(types.map(x=>[x.id,x])),[types]);
  const rateMap=useMemo(()=>Object.fromEntries(rates.map(x=>[x.id,x])),[rates]);
  const roomMap=useMemo(()=>Object.fromEntries(rooms.map(x=>[x.id,x])),[rooms]);
  const paymentMap=useMemo(()=>{
    const m={}; for(const p of payments){ if(!m[p.reservation_id])m[p.reservation_id]=p; } return m;
  },[payments]);

  const meta=hospitalityMeta(hospitalityType);
  const today=new Date().toISOString().slice(0,10);
  const arrivals=useMemo(()=>reservations.filter(x=>x.check_in===today&&['confirmed','inquiry','payment_pending'].includes(x.status)),[reservations]);
  const inhouse=useMemo(()=>reservations.filter(x=>['checked_in','in_house'].includes(x.status)),[reservations]);
  const departures=useMemo(()=>reservations.filter(x=>x.check_out===today&&['checked_in','in_house'].includes(x.status)),[reservations]);

  async function transition(r,action){
    setBusy(r.id+action);setError('');
    let roomId=r.room_id;
    if(action==='check_in'||action==='room_move'){
      roomId=prompt(action==='check_in'?'Room ID for check-in':'Target room ID',roomId||'')||null;
      if(!roomId){setBusy('');return;}
    }
    const {data,error:e}=await supabase.rpc('anaira_hms_reservation_transition',{p_restaurant_id:restaurantId,p_reservation_id:r.id,p_action:action,p_room_id:roomId,p_notes:null});
    if(e)setError(e.message);else if(data?.ok)await load(restaurantId);else setError('Reservation transition was not accepted.');
    setBusy('');
  }

  async function verifyPayment(r){
    const submission=paymentMap[r.id];
    if(!submission){setError('No payment submission found for this reservation.');return;}
    setBusy(r.id+'verify');setError('');
    const {data,error:e}=await supabase.rpc('anaira_verify_hotel_payment',{p_reservation_id:r.id,p_submission_id:submission.id});
    if(e)setError(e.message);else if(data?.ok)await load(restaurantId);else setError('Payment verification was not accepted.');
    setBusy('');
  }

  if(!session)return <AppShell><div className="notice">Connecting to PMS…</div></AppShell>;

  return <AppShell active="/hotel-management">
    <Header eyebrow={`${meta.label.toUpperCase()} OPERATIONS`} title={`Anaira ${meta.label} Management System`} subtitle={`Front desk, reservations, ${meta.unit.toLowerCase()} assignment, payment review and stay lifecycle.`} actions={<div style={{display:"flex",gap:6,flexWrap:"wrap"}}><a className="btn" href={`/hotel-management/room-rate-mapping?type=${hospitalityType}`}>Room / Rate Mapping</a><a className="btn" href={`/revenue-management?type=${hospitalityType}`}>Yield Management</a><a className="btn" href={`/hotel-management/booking-source?type=${hospitalityType}`}>Booking Source</a><button className="btn" onClick={()=>load(restaurantId)}>Refresh</button></div>}/>
    {error&&<div className="notice error">{error}</div>}
    <div className="grid kpis">
      <div className="kpi"><span>Arrivals</span><b>{arrivals.length}</b><small>Today</small></div>
      <div className="kpi"><span>In-House</span><b>{inhouse.length}</b><small>Current</small></div>
      <div className="kpi"><span>Departures</span><b>{departures.length}</b><small>Today</small></div>
      <div className="kpi"><span>Reservations</span><b>{reservations.length}</b><small>Live HMS</small></div>
    </div>

    <Section title="Reservations" meta={`Canonical HMS reservations — ${meta.label} Management master`}>
      <Table columns={['Code','Guest',`${meta.unit} / Type`,'Rate Plan','Stay','Status','Payment','Total','Actions']} rows={reservations.map(r=>{
        const g=guestMap[r.guest_id]; const room=roomMap[r.room_id]; const type=typeMap[r.room_type_id]; const rate=rateMap[r.rate_plan_id]; const ps=paymentMap[r.id];
        const paymentLabel=r.payment_status||'pending';
        return [
          r.reservation_code||r.booking_reference||'—',
          <div><b>{g?.full_name||'Guest'}</b><small style={{display:'block'}}>{g?.phone||g?.email||'—'}</small></div>,
          <div>{room?.room_number||'Unassigned'}<small style={{display:'block'}}>{type?.name||'—'}</small><small style={{display:'block',color:'#777'}}>Room ID: {r.room_id||'Not assigned'}</small></div>,
          <div>{rate?.name||'—'}<small style={{display:'block'}}>{rate?.code||''}</small><small style={{display:'block',color:'#777'}}>₹{Number(r.rate||0).toLocaleString('en-IN')}/night</small></div>,
          <div>{r.check_in} → {r.check_out}<small style={{display:'block'}}>{r.adults||0} adults · {r.children||0} children</small></div>,
          <Pill>{r.status}</Pill>,
          <div><Pill>{paymentLabel}</Pill><small style={{display:'block'}}>{r.payment_method||'—'}</small><small style={{display:'block'}}>Paid: {fmtMoney(r.paid_amount)} · Balance: {fmtMoney(r.balance_amount)}</small>{ps?.receipt_path&&<a href={ps.proof_url} target="_blank" rel="noreferrer" style={{fontSize:11}}>Receipt</a>}</div>,
          fmtMoney(r.total_amount),
          <div style={{display:'flex',gap:6,flexWrap:'wrap'}}>
            {r.payment_status==='submitted'&&<button className="btn" disabled={!!busy} onClick={()=>verifyPayment(r)}>{busy===r.id+'verify'?'…':'Verify Payment'}</button>}
            {actions.filter(([a])=>{
              if(a==='confirm') return ['inquiry','payment_pending'].includes(r.status);
              if(a==='check_in') return r.status==='confirmed';
              if(a==='room_move') return ['checked_in','in_house'].includes(r.status);
              if(a==='checkout') return ['checked_in','in_house'].includes(r.status);
              if(a==='no_show') return ['inquiry','payment_pending','confirmed'].includes(r.status);
              if(a==='cancel') return !['cancelled','checked_out'].includes(r.status);
              return true;
            }).map(([a,l])=><button key={a} className="btn" disabled={!!busy} onClick={()=>transition(r,a)}>{busy===r.id+a?'…':l}</button>)}
          </div>
        ];
      })}/>
    </Section>

    <Section title={`${meta.unit} Status`} meta={`Live HMS ${meta.units.toLowerCase()}`}><Table columns={[meta.unit,'Floor','Type','Status','Housekeeping']} rows={rooms.map(r=>[r.room_number,r.floor||'—',typeMap[r.room_type_id]?.name||'—',<Pill>{r.status}</Pill>,<Pill>{r.housekeeping_status||'—'}</Pill>])}/></Section>
  </AppShell>;
}
