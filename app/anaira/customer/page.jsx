'use client';
import {useEffect,useState} from 'react';
import AnairaShell from '@/components/anaira/AnairaShell';
import {UserRound,Hotel,Utensils,Heart,MessageSquare,Search} from 'lucide-react';
import {supabase} from '../../../lib/supabase';

export default function Customer(){
 const [customers,setCustomers]=useState([]),[q,setQ]=useState(''),[selected,setSelected]=useState(null),[stats,setStats]=useState({stays:0,visits:0,points:0,ltv:0}),[error,setError]=useState('');
 useEffect(()=>{(async()=>{const {data,error}=await supabase.from('crm_customers').select('*').order('updated_at',{ascending:false}).limit(100);if(error)setError(error.message);else{setCustomers(data||[]);setSelected(data?.[0]||null)}})()},[]);
 useEffect(()=>{if(!selected)return;(async()=>{const [s,v,l]=await Promise.all([
  supabase.from('crm_guest_stays').select('id',{count:'exact',head:true}).eq('customer_id',selected.id),
  supabase.from('crm_restaurant_visits').select('id',{count:'exact',head:true}).eq('customer_id',selected.id),
  supabase.from('crm_loyalty_accounts').select('points_balance').eq('customer_id',selected.id).maybeSingle()
 ]);setStats({stays:s.count||0,visits:v.count||0,points:l.data?.points_balance||0,ltv:Number(selected.total_hotel_revenue||0)+Number(selected.total_restaurant_revenue||0)})})()},[selected]);
 const filtered=customers.filter(c=>!q||`${c.full_name} ${c.phone||''} ${c.email||''}`.toLowerCase().includes(q.toLowerCase()));
 return <AnairaShell title="Customer 360"><div className="anaira-card"><h2><UserRound size={20}/> Live Customer 360</h2><p className="anaira-muted">Real CRM customer identity with hotel, restaurant and loyalty data.</p><input className="anaira-search" placeholder="Search customer, phone or email" value={q} onChange={e=>setQ(e.target.value)}/>{error&&<p className="anaira-muted">{error}</p>}</div>
 <div className="anaira-grid" style={{marginTop:18}}>{filtered.map(c=><button key={c.id} className="anaira-card" style={{textAlign:'left',cursor:'pointer',border:selected?.id===c.id?'1px solid #c69b3c':undefined}} onClick={()=>setSelected(c)}><b>{c.full_name}</b><p className="anaira-muted">{c.phone||c.email||'No contact'}</p><small>{c.customer_type||'guest'} {c.vip?'• VIP':''}</small></button>)}</div>
 {selected&&<><div className="anaira-card" style={{marginTop:18}}><h2>{selected.full_name}</h2><p>{selected.phone||'—'} · {selected.email||'—'}</p><div className="anaira-kpis"><div className="anaira-kpi"><small>Hotel Stays</small><div className="anaira-stat">{stats.stays}</div></div><div className="anaira-kpi"><small>Restaurant Visits</small><div className="anaira-stat">{stats.visits}</div></div><div className="anaira-kpi"><small>Loyalty</small><div className="anaira-stat">{Number(stats.points).toLocaleString('en-IN')}</div></div><div className="anaira-kpi"><small>LTV</small><div className="anaira-stat">₹{stats.ltv.toLocaleString('en-IN')}</div></div></div></div>
 <div className="anaira-grid" style={{marginTop:18}}><div className="anaira-card"><h3><Hotel size={18}/> Hotel History</h3><p>Revenue ₹{Number(selected.total_hotel_revenue||0).toLocaleString('en-IN')} · {selected.total_stays||stats.stays} stays</p></div><div className="anaira-card"><h3><Utensils size={18}/> Restaurant History</h3><p>Revenue ₹{Number(selected.total_restaurant_revenue||0).toLocaleString('en-IN')} · {selected.total_restaurant_visits||stats.visits} visits</p></div><div className="anaira-card"><h3><Heart size={18}/> Loyalty</h3><p>Points {Number(stats.points).toLocaleString('en-IN')} · {selected.vip?'VIP customer':'Standard customer'}</p></div><div className="anaira-card"><h3><MessageSquare size={18}/> Service</h3><p>Customer profile is linked to CRM interactions, complaints and feedback tables.</p></div></div></>}</AnairaShell>
}