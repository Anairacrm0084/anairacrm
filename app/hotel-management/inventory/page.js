'use client';
import {useEffect,useMemo,useState} from 'react';
import {Section,Pill} from '../../components';
import {useTenantProperty,SetupHeader,SetupShell,SetupNav,ensureSelected,hospitalityMeta} from '../setup-components';
import {supabase} from '../../../lib/supabase';

function indiaToday(){return new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Kolkata',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date())}
function addDays(value,n){const d=new Date(`${value}T12:00:00+05:30`);d.setDate(d.getDate()+n);return new Intl.DateTimeFormat('en-CA',{timeZone:'Asia/Kolkata'}).format(d)}
function fmt(d){return new Date(`${d}T00:00:00+05:30`).toLocaleDateString('en-IN',{timeZone:'Asia/Kolkata',day:'2-digit',month:'short',year:'numeric'})}
function dayKey(d){return new Date(`${d}T12:00:00+05:30`).toLocaleDateString('en-US',{weekday:'short',timeZone:'Asia/Kolkata'})}
function shortDay(d){return new Date(`${d}T12:00:00+05:30`).toLocaleDateString('en-IN',{weekday:'short',timeZone:'Asia/Kolkata'})}

const palette={ink:'#17392d',muted:'#6b756f',gold:'#c69a3b',goldSoft:'#fbf3df',line:'#e8dfcf',cream:'#fbf8f1',white:'#fff',green:'#0b5b3b',red:'#b5443f'};
const card={background:'#fff',border:`1px solid ${palette.line}`,borderRadius:16,boxShadow:'0 8px 24px rgba(24,55,43,.055)'};
const labelStyle={display:'block',fontSize:10,fontWeight:900,letterSpacing:.5,color:palette.muted,textTransform:'uppercase',marginBottom:6};
const controlStyle={height:40,border:`1px solid ${palette.line}`,borderRadius:10,padding:'0 12px',background:'#fff',color:palette.ink,fontWeight:700,outline:'none'};

function StatusDot({tone='green'}){return <span style={{width:7,height:7,borderRadius:99,background:tone==='red'?palette.red:tone==='gold'?palette.gold:'#2c9a68',display:'inline-block'}}/>}
function MiniStat({label,value,sub,tone='green'}){return <div style={{...card,padding:'14px 16px',minWidth:150,flex:1}}><div style={{display:'flex',alignItems:'center',gap:7,fontSize:10,fontWeight:900,letterSpacing:.8,color:palette.muted,textTransform:'uppercase'}}><StatusDot tone={tone}/>{label}</div><div style={{fontSize:27,fontWeight:950,lineHeight:1.05,color:palette.ink,marginTop:8}}>{value}</div><div style={{fontSize:11,color:palette.muted,marginTop:5}}>{sub}</div></div>}

export default function Inventory(){
 const ctx=useTenantProperty();
 const [rid,setRid]=useState(null),[busy,setBusy]=useState(false),[data,setData]=useState({room_types:[],inventory:[],reservations:[]}),[start,setStart]=useState(indiaToday()),[days,setDays]=useState(14),[loading,setLoading]=useState(false),[msg,setMsg]=useState(''),[roomFilter,setRoomFilter]=useState('all'),[selectedDays,setSelectedDays]=useState({Mon:true,Tue:true,Wed:true,Thu:true,Fri:true,Sat:true,Sun:true}),[roomBlock,setRoomBlock]=useState(null);
 const id=ensureSelected(ctx,rid); const m=hospitalityMeta(ctx.hospitalityType); const end=addDays(start,Number(days)-1);
 async function load(){
  if(!id)return;
  setLoading(true);setMsg('');
  const [{data:d,error},{data:typeRows,typeError}]=await Promise.all([
   supabase.rpc('anaira_inventory_dashboard',{p_restaurant_id:id,p_start:start,p_end:addDays(start,Number(days))}),
   supabase.from('hms_room_types').select('id,hospitality_type').eq('restaurant_id',id).eq('hospitality_type',ctx.hospitalityType||'hotel')
  ]);
  if(error||typeError){setMsg(error?.message||typeError?.message||'Unable to load inventory.');setLoading(false);return}
  const allowed=new Set((typeRows||[]).map(x=>String(x.id))); const scoped=d||{room_types:[],inventory:[],reservations:[]};
  setData({...scoped,room_types:(scoped.room_types||[]).filter(x=>allowed.has(String(x.id))),inventory:(scoped.inventory||[]).filter(x=>allowed.has(String(x.room_type_id))),reservations:(scoped.reservations||[]).filter(x=>allowed.has(String(x.room_type_id)))});
  setLoading(false);
 }
 useEffect(()=>{load()},[id,ctx.hospitalityType,start,days]);
 const byType=useMemo(()=>{const out={};for(const r of data.inventory||[])(out[r.room_type_id]??=[]).push(r);return out},[data.inventory]);
 const visibleInventory=useMemo(()=>Object.values(byType).flat().filter(x=>selectedDays[dayKey(x.stay_date)]),[byType,selectedDays]);
 const stats=useMemo(()=>{
  const total=data.room_types.reduce((n,r)=>n+(r.rooms||[]).length,0);
  const available=data.inventory.reduce((n,x)=>n+Number(x.available_rooms||0),0);
  const blocked=data.inventory.reduce((n,x)=>n+Number(x.blocked_rooms||0),0);
  const restricted=data.inventory.filter(x=>x.stop_sell||x.close_on_arrival||x.close_on_departure).length;
  return {total,available,blocked,restricted};
 },[data]);
 async function saveControls(rt,x,patch){
  setBusy(true);setMsg('');
  const z=await supabase.rpc('anaira_set_inventory_controls',{p_restaurant_id:id,p_room_type_id:rt.id,p_stay_date:x.stay_date,p_stop_sell:patch.stop_sell??!!x.stop_sell,p_close_on_arrival:patch.close_on_arrival??!!x.close_on_arrival,p_close_on_departure:patch.close_on_departure??!!x.close_on_departure,p_cutoff_hours:patch.cutoff_hours!==undefined?patch.cutoff_hours:(x.cutoff_hours??null)});
  setBusy(false);if(z.error)setMsg(z.error.message);else load();
 }
 async function transitionHousekeeping(room,action){
  setBusy(true);setMsg('');const {error}=await supabase.rpc('anaira_room_housekeeping_transition',{p_restaurant_id:id,p_room_id:room.id,p_action:action});setBusy(false);if(error)setMsg(error.message);else await load();
 }
 return <SetupShell active="/hotel-management" title={`Smart ${m.label} Inventory`} subtitle={`Automatic ${m.unit.toLowerCase()} inventory from your physical units and confirmed reservations.`} ctx={ctx}>
  <SetupHeader title={`Smart ${m.label} Inventory`} subtitle={`${m.units} are created once in ${m.label} Management → ${m.units}. Daily inventory is generated automatically.`} ctx={ctx} rid={rid} setRid={setRid}/>
  {id?<>
   <div style={{display:'flex',gap:10,flexWrap:'wrap',margin:'14px 0'}}>
    <MiniStat label="Physical Units" value={stats.total} sub={`Across ${data.room_types.length} ${m.unitType.toLowerCase()} types`}/>
    <MiniStat label="Available" value={stats.available} sub="Within selected inventory window"/>
    <MiniStat label="Blocked" value={stats.blocked} sub="Inventory already unavailable" tone={stats.blocked?'gold':'green'}/>
    <MiniStat label="Restrictions" value={stats.restricted} sub="Stop Sell / arrival / departure" tone={stats.restricted?'gold':'green'}/>
   </div>

   <Section title="Inventory Control" meta="Live inventory · India Standard Time (Asia/Kolkata)">
    <div style={{...card,padding:14,background:'linear-gradient(135deg,#fffdf8,#fbf7ee)',boxShadow:'none'}}>
     <div style={{display:'flex',justifyContent:'space-between',gap:14,alignItems:'flex-end',flexWrap:'wrap'}}>
      <div style={{display:'flex',gap:10,alignItems:'flex-end',flexWrap:'wrap'}}>
       <label><span style={labelStyle}>From</span><input style={controlStyle} type="date" value={start} onChange={e=>setStart(e.target.value)}/></label>
       <label><span style={labelStyle}>View Window</span><select style={controlStyle} value={days} onChange={e=>setDays(Number(e.target.value))}><option value="7">7 days</option><option value="14">14 days</option><option value="30">30 days</option><option value="60">60 days</option></select></label>
       <button className="btn primary" style={{height:40,borderRadius:10}} onClick={load}>{loading?'Refreshing…':'↻ Refresh Live Inventory'}</button>
      </div>
      <div style={{fontSize:11,color:palette.muted,textAlign:'right'}}>Window: <b style={{color:palette.ink}}>{fmt(start)}</b> — <b style={{color:palette.ink}}>{fmt(end)}</b><br/>Inventory timezone: Asia/Kolkata</div>
     </div>
     {msg&&<div style={{marginTop:12,padding:'10px 12px',borderRadius:10,background:'#fff1ef',border:'1px solid #f0c9c5',color:'#9e3e39',fontSize:12,fontWeight:700}}>⚠ {msg}</div>}
     <div style={{marginTop:12,fontSize:12,color:palette.muted,lineHeight:1.6}}>Availability is calculated from <b style={{color:palette.ink}}>physical units + reservations + room blocks</b>. Checkout returns the unit to inventory; housekeeping remains a separate operational status.</div>
    </div>
   </Section>

   <Section title={`${m.unitType} Inventory`} meta={`${data.room_types.length} ${m.unitType.toLowerCase()} types · ${days} days`}>
    <div style={{display:'flex',justifyContent:'space-between',gap:14,alignItems:'center',flexWrap:'wrap',marginBottom:14}}>
     <div style={{display:'flex',gap:12,alignItems:'center',flexWrap:'wrap'}}>
      <label><span style={labelStyle}>{m.unitType}</span><select style={controlStyle} value={roomFilter} onChange={e=>setRoomFilter(e.target.value)}><option value="all">All {m.unitType}s</option>{data.room_types.map(rt=><option key={rt.id} value={rt.id}>{rt.name}</option>)}</select></label>
      <div><div style={labelStyle}>Display Days</div><div style={{display:'flex',gap:5,flexWrap:'wrap'}}>{Object.keys(selectedDays).map(d=><label key={d} style={{display:'flex',alignItems:'center',gap:4,padding:'7px 9px',border:`1px solid ${selectedDays[d]?'#d9c18b':palette.line}`,borderRadius:9,background:selectedDays[d]?palette.goldSoft:'#fff',fontSize:11,fontWeight:800}}><input type="checkbox" checked={selectedDays[d]} onChange={e=>setSelectedDays(x=>({...x,[d]:e.target.checked}))}/> {d}</label>)}</div></div>
     </div>
     <div style={{display:'flex',gap:7}}><button className="btn" onClick={()=>setSelectedDays({Mon:true,Tue:true,Wed:true,Thu:true,Fri:true,Sat:true,Sun:true})}>Select All</button><button className="btn" onClick={()=>setSelectedDays({Mon:false,Tue:false,Wed:false,Thu:false,Fri:false,Sat:false,Sun:false})}>Clear</button></div>
    </div>
    <div style={{fontSize:11,color:palette.muted,marginBottom:12,padding:'9px 12px',borderRadius:9,background:'#faf8f3',border:`1px solid ${palette.line}`}}>Daily cards retain the Anaira inventory layout. Smart Flow controls are embedded per date so you can manage selling restrictions without changing the underlying room data.</div>
    {(data.room_types||[]).filter(rt=>roomFilter==='all'||String(rt.id)===String(roomFilter)).map(rt=>{
     const inv=(byType[rt.id]||[]).filter(x=>selectedDays[dayKey(x.stay_date)]); const rooms=rt.rooms||[];
     return <div key={rt.id} style={{...card,overflow:'hidden',marginBottom:16}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:14,padding:'16px 18px',background:'linear-gradient(135deg,#fbf8f1,#fffdf9)',borderBottom:`1px solid ${palette.line}`}}>
       <div><div style={{fontSize:19,fontWeight:950,color:palette.ink}}>{rt.name}</div><div style={{fontSize:11,color:palette.muted,marginTop:3}}>{rt.code||'No code'} · {rooms.length} physical {m.units.toLowerCase()}</div></div>
       <div style={{display:'flex',gap:6,flexWrap:'wrap',justifyContent:'flex-end'}}>{rooms.map(r=><span key={r.id} style={{border:`1px solid ${palette.line}`,borderRadius:999,padding:'6px 9px',fontSize:10,fontWeight:850,background:'#fff',color:palette.ink}}>{m.unit} {r.room_number} · {r.floor||'—'}</span>)}</div>
      </div>
      <div style={{padding:14,display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(235px,1fr))',gap:11}}>
       {inv.map(x=>{const av=Number(x.available_rooms||0);const total=Number(x.total_rooms||0);const sold=Number(x.sold_rooms||0);const blocked=Number(x.blocked_rooms||0);const restricted=x.stop_sell||x.close_on_arrival||x.close_on_departure;return <div key={x.stay_date} style={{border:`1px solid ${restricted?'#ead8ae':palette.line}`,borderRadius:14,padding:13,background:restricted?'#fffdf7':'#fff',boxShadow:restricted?'0 5px 18px rgba(198,154,59,.08)':'0 2px 8px rgba(24,55,43,.025)'}}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:8}}><div><div style={{fontSize:10,fontWeight:950,letterSpacing:.8,color:palette.muted,textTransform:'uppercase'}}>{shortDay(x.stay_date)}</div><div style={{fontSize:13,fontWeight:900,color:palette.ink,marginTop:2}}>{fmt(x.stay_date)}</div></div><Pill tone={x.stop_sell?'red':av>0?'success':'red'}>{x.stop_sell?'Stop Sell':av>0?'Available':'Sold Out'}</Pill></div>
        <div style={{display:'flex',alignItems:'baseline',gap:7,marginTop:12}}><span style={{fontSize:31,fontWeight:950,lineHeight:1,color:palette.ink}}>{av}</span><span style={{fontSize:10,color:palette.muted}}>available of {total}</span></div>
        <div style={{display:'flex',gap:6,flexWrap:'wrap',marginTop:8}}><Pill tone="gold">{sold} booked</Pill>{blocked>0&&<Pill tone="red">{blocked} blocked</Pill>}{restricted&&<Pill tone="gold">Restricted</Pill>}</div>
        <div style={{marginTop:12,paddingTop:11,borderTop:`1px solid ${palette.line}`}}>
         <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:8}}><div style={{fontSize:10,fontWeight:950,letterSpacing:.7,color:palette.muted,textTransform:'uppercase'}}>Daily Controls</div><span style={{fontSize:9,color:palette.muted}}>Per date</span></div>
         <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:7,fontSize:10}}>
          <label style={{display:'flex',alignItems:'center',gap:5,padding:'7px 8px',borderRadius:8,background:x.stop_sell?'#fff0ee':'#faf9f6',border:`1px solid ${x.stop_sell?'#efc8c4':palette.line}`,fontWeight:800}}><input type="checkbox" disabled={busy} checked={!!x.stop_sell} onChange={e=>saveControls(rt,x,{stop_sell:e.target.checked})}/> Stop Sell</label>
          <label style={{display:'flex',alignItems:'center',gap:5,padding:'7px 8px',borderRadius:8,background:x.close_on_arrival?'#fff8e9':'#faf9f6',border:`1px solid ${x.close_on_arrival?'#ead8ae':palette.line}`,fontWeight:800}}><input type="checkbox" disabled={busy} checked={!!x.close_on_arrival} onChange={e=>saveControls(rt,x,{close_on_arrival:e.target.checked})}/> Close Arrival</label>
          <label style={{display:'flex',alignItems:'center',gap:5,padding:'7px 8px',borderRadius:8,background:x.close_on_departure?'#fff8e9':'#faf9f6',border:`1px solid ${x.close_on_departure?'#ead8ae':palette.line}`,fontWeight:800}}><input type="checkbox" disabled={busy} checked={!!x.close_on_departure} onChange={e=>saveControls(rt,x,{close_on_departure:e.target.checked})}/> Close Departure</label>
          <label style={{display:'flex',alignItems:'center',gap:4,padding:'6px 8px',borderRadius:8,background:'#faf9f6',border:`1px solid ${palette.line}`,fontWeight:800}}>Cut-off <input disabled={busy} style={{width:50,height:25,border:`1px solid ${palette.line}`,borderRadius:6,padding:'0 5px'}} type="number" min="0" value={x.cutoff_hours??''} placeholder="hrs" onChange={e=>setData(d=>({...d,inventory:d.inventory.map(q=>q.stay_date===x.stay_date&&q.room_type_id===x.room_type_id?{...q,cutoff_hours:e.target.value===''?null:Number(e.target.value)}:q)}))} onBlur={e=>saveControls(rt,x,{cutoff_hours:e.target.value===''?null:Number(e.target.value)})}/></label>
         </div>
        </div>
       </div>})}
      </div>
     </div>;
    })}
    {!data.room_types?.length&&<div className="notice">No room types found. Add Room Types and Individual Rooms first.</div>}
   </Section>

   <Section title="Physical Room Status" meta={`Live for ${fmt(start)} · each physical unit is tracked independently`}>
    <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fill,minmax(285px,1fr))',gap:12}}>
     {(data.room_types||[]).flatMap(rt=>(rt.rooms||[]).map(r=>({...r,type:rt.name}))).map(r=>{
      const status=r.effective_status||r.status; const hk=r.effective_housekeeping_status||r.housekeeping_status; const roomBlocked=status==='blocked'||r.booking_enabled===false; const unavailable=['reserved','occupied','dirty','cleaning','maintenance','out_of_order','blocked'].includes(status)||!['clean','inspected'].includes(hk)||roomBlocked;
      return <div key={r.id} style={{...card,padding:15,background:'linear-gradient(145deg,#fff,#fcfaf5)'}}>
       <div style={{display:'flex',justifyContent:'space-between',gap:8}}><div><div style={{fontSize:18,fontWeight:950,color:palette.ink}}>{m.unit} {r.room_number}</div><div style={{fontSize:11,color:palette.muted,marginTop:3}}>{r.type} · Floor {r.floor||'—'}{r.building?` · ${r.building}`:''}</div></div><Pill tone={unavailable?'red':'success'}>{unavailable?'Unavailable':'Available'}</Pill></div>
       <div style={{marginTop:11,display:'flex',gap:6,flexWrap:'wrap'}}><Pill tone={status==='available'?'success':status==='maintenance'||status==='out_of_order'||status==='dirty'||status==='blocked'?'red':'gold'}>{status}</Pill><Pill tone={hk==='clean'||hk==='inspected'?'success':'gold'}>{hk}</Pill>{roomBlocked&&<Pill tone="gold">Booking Blocked</Pill>}</div>
       {r.booking_block_reason&&<div style={{marginTop:8,padding:'8px 9px',borderRadius:8,background:'#fff8e9',fontSize:10,color:'#7b622a'}}><b>Reason:</b> {r.booking_block_reason}</div>}
       {r.reservation_code&&<div style={{fontSize:11,marginTop:8,color:palette.muted}}>Booking <b style={{color:palette.ink}}>{r.reservation_code}</b>{r.guest_name?` · ${r.guest_name}`:''}</div>}
       <div style={{display:'flex',gap:6,marginTop:11,flexWrap:'wrap'}}>{['dirty','cleaning','clean','inspected'].map(s=><button key={s} className="btn" disabled={busy} onClick={()=>transitionHousekeeping(r,s)}>{s[0].toUpperCase()+s.slice(1)}</button>)}<button className="btn primary" disabled={busy} onClick={()=>setRoomBlock({room:r,from:start,to:end,reason:r.booking_block_reason||'',blocked:!roomBlocked})}>{roomBlocked?'Unblock for Booking':'Block for Booking'}</button></div>
      </div>
     })}
    </div>
   </Section>

   <Section title="Live Reservation Impact" meta="Confirmed and checked-in stays affecting this inventory window">
    <div style={{...card,overflow:'hidden'}}><div style={{overflowX:'auto'}}><table style={{width:'100%',borderCollapse:'collapse',fontSize:12}}><thead><tr style={{background:'#faf8f3'}}>{['Booking','Guest',m.unitType,m.unit,'Check-in','Check-out','Status'].map(h=><th key={h} style={{textAlign:'left',padding:'12px 11px',borderBottom:`1px solid ${palette.line}`,fontSize:10,textTransform:'uppercase',letterSpacing:.5,color:palette.muted}}>{h}</th>)}</tr></thead><tbody>{(data.reservations||[]).map(r=><tr key={r.id}>{[r.reservation_code,r.guest_name||'—',data.room_types?.find(x=>x.id===r.room_type_id)?.name||'—',r.room_number||'Unassigned',fmt(r.check_in),fmt(r.check_out),r.status].map((v,i)=><td key={i} style={{padding:'11px',borderBottom:`1px solid ${palette.line}`,fontWeight:i===0?800:500,color:palette.ink}}>{i===6?<Pill tone={String(v).toLowerCase().includes('cancel')?'red':'success'}>{v}</Pill>:v}</td>)}</tr>)}{!data.reservations?.length&&<tr><td colSpan="7" style={{padding:24,textAlign:'center',color:palette.muted}}>No confirmed reservations affect this date range.</td></tr>}</tbody></table></div></div>
   </Section>

   {roomBlock&&<div style={{position:'fixed',inset:0,background:'rgba(10,35,25,.62)',backdropFilter:'blur(7px)',zIndex:50,display:'grid',placeItems:'center',padding:20}}><div style={{width:'min(580px,100%)',background:'#fffdf9',border:`1px solid ${palette.line}`,borderRadius:20,boxShadow:'0 30px 100px rgba(0,0,0,.3)',overflow:'hidden'}}>
    <div style={{padding:'20px 22px',background:'linear-gradient(135deg,#123e2f,#0a5a3b)',color:'#fff'}}><div style={{fontSize:10,fontWeight:900,letterSpacing:2,color:'#e3bf69'}}>ANAIRA · ROOM AVAILABILITY</div><h2 style={{margin:'6px 0 2px',fontSize:24}}>{roomBlock.blocked?'Block':'Unblock'} {m.unit} {roomBlock.room.room_number}</h2><div style={{fontSize:11,opacity:.78}}>{roomBlock.room.type||m.unitType} · booking availability control</div></div>
    <div style={{padding:22}}><div style={{padding:12,borderRadius:11,background:roomBlock.blocked?'#fff8e9':'#eef8f2',border:`1px solid ${roomBlock.blocked?'#ead8ae':'#cbe8d7'}`,fontSize:12,color:palette.ink,lineHeight:1.55}}>{roomBlock.blocked?'Only this physical unit will be removed from sellable inventory. Other units in the same room type remain bookable.':'This physical unit will return to sellable inventory for the selected dates.'}</div>
     <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginTop:16}}><label><span style={labelStyle}>From</span><input style={{...controlStyle,width:'100%'}} type="date" value={roomBlock.from} onChange={e=>setRoomBlock(x=>({...x,from:e.target.value}))}/></label><label><span style={labelStyle}>To</span><input style={{...controlStyle,width:'100%'}} type="date" value={roomBlock.to} onChange={e=>setRoomBlock(x=>({...x,to:e.target.value}))}/></label></div>
     <label style={{display:'block',marginTop:13}}><span style={labelStyle}>Reason</span><input style={{...controlStyle,width:'100%'}} disabled={!roomBlock.blocked} value={roomBlock.reason} onChange={e=>setRoomBlock(x=>({...x,reason:e.target.value}))} placeholder="Maintenance / owner block / renovation…"/></label>
     <div style={{display:'flex',justifyContent:'flex-end',gap:8,marginTop:20}}><button className="btn" onClick={()=>setRoomBlock(null)}>Cancel</button><button className="btn primary" disabled={busy} onClick={async()=>{setBusy(true);const q=await supabase.rpc('anaira_set_room_booking_block',{p_restaurant_id:id,p_room_id:roomBlock.room.id,p_from:roomBlock.from,p_to:roomBlock.to,p_blocked:roomBlock.blocked,p_reason:roomBlock.blocked?(roomBlock.reason||null):null});setBusy(false);if(q.error)setMsg(q.error.message);else{setMsg(`${m.unit} ${roomBlock.room.room_number} ${roomBlock.blocked?'blocked for':'released from'} booking.`);setRoomBlock(null);await load()}}}>{busy?'Saving…':roomBlock.blocked?'Block Room':'Unblock Room'}</button></div>
    </div>
   </div></div>}
   <SetupNav hospitalityType={ctx.hospitalityType}/>
  </>:<div className="notice">Select a property first.</div>}
 </SetupShell>
}
