'use client';
import {useEffect,useMemo,useState} from 'react';
import {Section,Pill} from '../../components';
import {useTenantProperty,SetupHeader,SetupShell,SetupNav,ensureSelected,hospitalityMeta} from '../setup-components';
import {supabase} from '../../../lib/supabase';

function indiaToday(){return new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Kolkata',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date())}
function addDays(value,n){const d=new Date(`${value}T12:00:00+05:30`);d.setDate(d.getDate()+n);return new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Kolkata'}).format(d)}
function fmt(d){return new Date(`${d}T00:00:00+05:30`).toLocaleDateString('en-IN',{timeZone:'Asia/Kolkata',day:'2-digit',month:'short',year:'numeric'})}

export default function Inventory(){
 const ctx=useTenantProperty();
 const [rid,setRid]=useState(null),[busy,setBusy]=useState(false),[data,setData]=useState({room_types:[],inventory:[],reservations:[]}),[start,setStart]=useState(indiaToday()),[days,setDays]=useState(14),[loading,setLoading]=useState(false),[msg,setMsg]=useState('');
 const id=ensureSelected(ctx,rid); const m=hospitalityMeta(ctx.hospitalityType);
 const end=addDays(start,Number(days));
 async function load(){
  if(!id)return;
  setLoading(true);setMsg('');
  const [{data:d,error},{data:typeRows,typeError}]=await Promise.all([
    supabase.rpc('anaira_inventory_dashboard',{p_restaurant_id:id,p_start:start,p_end:end}),
    supabase.from('hms_room_types').select('id,hospitality_type').eq('restaurant_id',id).eq('hospitality_type',ctx.hospitalityType||'hotel')
  ]);
  if(error||typeError){setMsg(error?.message||typeError?.message||'Unable to load inventory.');setLoading(false);return}
  const allowed=new Set((typeRows||[]).map(x=>String(x.id)));
  const scoped=d||{room_types:[],inventory:[],reservations:[]};
  setData({
    ...scoped,
    room_types:(scoped.room_types||[]).filter(x=>allowed.has(String(x.id))),
    inventory:(scoped.inventory||[]).filter(x=>allowed.has(String(x.room_type_id))),
    reservations:(scoped.reservations||[]).filter(x=>allowed.has(String(x.room_type_id)))
  });
  setLoading(false);
 }
 useEffect(()=>{load()},[id,ctx.hospitalityType,start,days]);
 const byType=useMemo(()=>{
  const m={};
  for(const r of data.inventory||[]){(m[r.room_type_id]??=[]).push(r)}
  return m;
 },[data.inventory]);
 const today=start;
 const todayIndia=indiaToday();
 return <SetupShell active="/hotel-management" title={`Smart ${m.label} Inventory`} subtitle={`Automatic ${m.unit.toLowerCase()} inventory from your physical units and confirmed reservations.`} ctx={ctx}>
  <SetupHeader title={`Smart ${m.label} Inventory`} subtitle={`${m.units} are created once in ${m.label} Management → ${m.units}. Daily inventory is generated automatically.`} ctx={ctx} rid={rid} setRid={setRid}/>
  {id?<>
   <Section title="Inventory Control" meta="No daily room entry required">
    <div className="filters" style={{display:'flex',gap:12,alignItems:'center',flexWrap:'wrap'}}>
     <label><span style={{display:'block',fontSize:11,fontWeight:700}}>From</span><input type="date" value={start} onChange={e=>setStart(e.target.value)}/></label>
     <label><span style={{display:'block',fontSize:11,fontWeight:700}}>View</span><select value={days} onChange={e=>setDays(Number(e.target.value))}><option value="7">7 days</option><option value="14">14 days</option><option value="30">30 days</option><option value="60">60 days</option></select></label>
     <button className="btn" onClick={load}>{loading?'Refreshing…':'Refresh Live Inventory'}</button>
     {msg&&<span className="notice">{msg}</span>}
    </div>
    <div style={{marginTop:12,fontSize:12,color:'#68706a'}}>Total inventory comes from <b>Physical Units</b>. Confirmed / checked-in reservations reduce availability only for the dates they overlap. When a booking ends, the room automatically becomes available for the next date unless blocked or under maintenance.</div>
   </Section>

   <Section title={`${m.unitType} Inventory`} meta={`${(data.room_types||[]).length} room types · ${days} days`}>
    <div style={{display:'grid',gap:16}}>
     {(data.room_types||[]).map(rt=>{
      const rooms=rt.rooms||[]; const inv=byType[rt.id]||[];
      return <div key={rt.id} className="card" style={{padding:16,borderRadius:14}}>
       <div style={{display:'flex',justifyContent:'space-between',gap:16,alignItems:'flex-start',flexWrap:'wrap'}}>
        <div><div style={{fontSize:18,fontWeight:800}}>{rt.name}</div><div style={{fontSize:11,opacity:.7}}>{rt.code||'No code'} · {rooms.length} physical unit{rooms.length===1?'':'s'}</div></div>
        <div style={{fontSize:12}}><b>Units:</b> {rooms.map(r=><span key={r.id} style={{display:'inline-block',marginLeft:6,padding:'4px 8px',borderRadius:999,border:'1px solid #ddd'}}>{r.room_number} · F{r.floor||'—'}</span>)}</div>
       </div>
       <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(170px,1fr))',gap:10,marginTop:14}}>
        {inv.map(x=>{const available=Number(x.available_rooms||0);const sold=Number(x.sold_rooms||0);const blocked=Number(x.blocked_rooms||0);return <div key={x.stay_date} style={{padding:12,border:'1px solid #e5e0d7',borderRadius:12,background:available>0?'#fff':'#faf6f4'}}>
          <div style={{fontSize:11,fontWeight:800}}>{fmt(x.stay_date)}</div>
          <div style={{fontSize:22,fontWeight:900,marginTop:4}}>{available}</div>
          <div style={{fontSize:10,opacity:.7}}>available of {x.total_rooms}</div>
          <div style={{display:'flex',gap:6,marginTop:8,flexWrap:'wrap'}}><Pill tone={available>0?'success':'red'}>{available>0?'Available':'Sold out'}</Pill>{sold>0&&<Pill tone="gold">{sold} booked</Pill>}{blocked>0&&<Pill tone="red">{blocked} blocked</Pill>}</div>
        </div>})}
       </div>
      </div>
     })}
     {!data.room_types?.length&&<div className="notice">No room types found. Add Room Types and Individual Rooms first.</div>}
    </div>
   </Section>

   <Section title="Physical Room Status" meta={`Live for ${fmt(start)} · India Standard Time (Asia/Kolkata) · each room exists once`}>
    <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(270px,1fr))',gap:12}}>
     {(data.room_types||[]).flatMap(rt=>(rt.rooms||[]).map(r=>({...r,type:rt.name}))).map(r=>{
       const status=r.effective_status||r.status; const hk=r.effective_housekeeping_status||r.housekeeping_status;
       const unavailable=['reserved','occupied','dirty','cleaning','maintenance','out_of_order','blocked'].includes(status)||!['clean','inspected'].includes(hk);
       return <div key={r.id} className="card" style={{padding:14,borderRadius:12}}>
        <div style={{display:'flex',justifyContent:'space-between',gap:8}}><div><div style={{fontSize:17,fontWeight:800}}>{m.unit} {r.room_number}</div><div style={{fontSize:11,opacity:.7}}>{r.type} · Floor {r.floor||'—'}{r.building?` · ${r.building}`:''}</div></div><Pill tone={unavailable?'red':'success'}>{unavailable?'Unavailable':'Available'}</Pill></div>
        <div style={{marginTop:10,display:'flex',gap:6,flexWrap:'wrap'}}><Pill tone={status==='available'?'success':status==='maintenance'||status==='out_of_order'||status==='dirty'?'red':'gold'}>{status}</Pill><Pill tone={hk==='clean'||hk==='inspected'?'success':'gold'}>{hk}</Pill></div>
        {r.reservation_code&&<div style={{fontSize:11,marginTop:8,opacity:.75}}>Booking {r.reservation_code}{r.guest_name?` · ${r.guest_name}`:''}</div>}
        <div style={{display:'flex',gap:6,marginTop:10,flexWrap:'wrap'}}>
         {['dirty','cleaning','clean','inspected'].map(s=><button key={s} className="btn" disabled={busy} onClick={async()=>{const {error}=await supabase.rpc('anaira_room_housekeeping_transition',{p_restaurant_id:id,p_room_id:r.id,p_action:s});if(error)setMsg(error.message);else await load()}}>{s[0].toUpperCase()+s.slice(1)}</button>)}
        </div>
       </div>})}
    </div>
   </Section>

   <Section title="Live Reservation Impact" meta="Confirmed and checked-in stays affecting this inventory window">
    <div style={{overflowX:'auto'}}><table style={{width:'100%',borderCollapse:'collapse',fontSize:12}}><thead><tr>{['Booking','Guest',m.unitType,m.unit,'Check-in','Check-out','Status'].map(h=><th key={h} style={{textAlign:'left',padding:10,borderBottom:'1px solid #ddd'}}>{h}</th>)}</tr></thead><tbody>{(data.reservations||[]).map(r=><tr key={r.id}>{[r.reservation_code,r.guest_name||'—',data.room_types?.find(x=>x.id===r.room_type_id)?.name||'—',r.room_number||'Unassigned',fmt(r.check_in),fmt(r.check_out),r.status].map((v,i)=><td key={i} style={{padding:10,borderBottom:'1px solid #eee'}}>{v}</td>)}</tr>)}{!data.reservations?.length&&<tr><td colSpan="7" style={{padding:18,textAlign:'center',opacity:.65}}>No confirmed reservations affect this date range.</td></tr>}</tbody></table></div>
   </Section>
   <SetupNav hospitalityType={ctx.hospitalityType}/>
  </>:<div className="notice">Select a property first.</div>}
 </SetupShell>
}
