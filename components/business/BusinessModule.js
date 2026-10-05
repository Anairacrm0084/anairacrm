'use client';
import {Suspense,useEffect,useMemo,useState} from 'react';
import {useSearchParams} from 'next/navigation';
import {supabase} from '../../lib/supabase';
import {businessConfig,businessModules} from '../../app/businessTypeConfig';
import {getDomainSchema} from './BusinessDomainSchemas';
import {workflowStatus} from './domainStore';

const FALLBACK={
 name:['Name','text'],description:['Description','textarea'],image_url:['Image URL','url'],photo_url:['Photo URL','url'],gallery:['Gallery URLs (comma separated)','textarea'],price:['Price','number'],amount:['Amount','number'],status:['Status','text'],notes:['Notes','textarea'],date:['Date','date'],start_date:['Start Date','date'],end_date:['End Date','date'],customer_name:['Customer','text'],phone:['Phone','tel'],email:['Email','email'],quantity:['Quantity','number']
};
const LABELS={image_url:'Image',photo_url:'Photo',gallery:'Gallery',duration_minutes:'Duration (min)',buffer_minutes:'Buffer (min)',commission_percent:'Commission %',tax_percent:'Tax %',online_booking:'Online Booking',price:'Price',sale_price:'Sale Price',stock_qty:'Stock Qty',reorder_level:'Reorder Level'};
function pretty(k){return LABELS[k]||k.replaceAll('_',' ').replace(/\b\w/g,x=>x.toUpperCase())}
function fieldSpec(f){
 if(typeof f==='string') return {key:f,label:pretty(f),type:(FALLBACK[f]?.[1]||'text')};
 return {key:f.key,label:f.label||pretty(f.key),type:f.type||'text',...f};
}
function initial(fields){return Object.fromEntries(fields.map(f=>[f.key,f.default??(f.type==='boolean'?true:'')]));}
function Input({f,value,onChange}){
 if(f.type==='boolean') return <label className="domain-check"><input type="checkbox" checked={!!value} onChange={e=>onChange(e.target.checked)}/>{f.label}</label>;
 if(f.type==='textarea'||f.type==='gallery') return <label>{f.label}<textarea value={value??''} onChange={e=>onChange(e.target.value)} rows={f.type==='gallery'?3:4}/></label>;
 return <label>{f.label}<input type={['number','date','url','email','tel'].includes(f.type)?f.type:'text'} value={value??''} onChange={e=>onChange(f.type==='number'?e.target.value:e.target.value)} /></label>;
}
function BusinessModuleInner({type,moduleKey}){
 const c=businessConfig(type), search=useSearchParams(), businessId=search.get('business')||search.get('id');
 const schema=useMemo(()=>getDomainSchema(type),[type]);
 const label=businessModules(type).find(x=>x.key===moduleKey)?.label||moduleKey;
 const raw=moduleKey==='catalog'||moduleKey==='services'||moduleKey==='products'||moduleKey==='primary' ? schema.fields : (schema.secondary?.[moduleKey]||[]);
 const fields=useMemo(()=>raw.map(fieldSpec),[raw]);
 const table=domainTable(type), statuses=workflowStatus(moduleKey);
 const [rows,setRows]=useState([]),[form,setForm]=useState(()=>initial(fields)),[edit,setEdit]=useState(null),[busy,setBusy]=useState(false),[msg,setMsg]=useState(''),[err,setErr]=useState('');
 async function load(){if(!businessId)return;const token=(await supabase.auth.getSession()).data.session?.access_token;const q=await fetch(`/api/business/domain?type=${encodeURIComponent(type)}&module=${encodeURIComponent(moduleKey)}&business=${encodeURIComponent(businessId)}`,{headers:token?{Authorization:`Bearer ${token}`}:{}});const d=await q.json();if(!q.ok)setErr(d.error||'Unable to load records');else setRows(d.rows||[])}
 useEffect(()=>{setForm(initial(fields));load()},[businessId,moduleKey]);
 async function save(e){e.preventDefault();if(!businessId)return;setBusy(true);setErr('');const token=(await supabase.auth.getSession()).data.session?.access_token;const title=String(form.name||form.title||form.reference||form.code||form.customer_name||label);const q=await fetch('/api/business/domain',{method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:JSON.stringify({type,module:moduleKey,business:businessId,id:edit||undefined,title,data:form,status:String(form.status||'active'),image_url:form.image_url||form.photo_url||null,gallery:form.gallery?String(form.gallery).split(',').map(x=>x.trim()).filter(Boolean):[]})});const d=await q.json();setBusy(false);if(!q.ok)setErr(d.error||'Save failed');else{setMsg(edit?'Updated.':'Created.');setEdit(null);setForm(initial(fields));load()}}
 async function remove(id){if(!confirm('Delete this record?'))return;const token=(await supabase.auth.getSession()).data.session?.access_token;const q=await fetch(`/api/business/domain?type=${encodeURIComponent(type)}&module=${encodeURIComponent(moduleKey)}&business=${encodeURIComponent(businessId)}&id=${encodeURIComponent(id)}`,{method:'DELETE',headers:token?{Authorization:`Bearer ${token}`}:{}});const d=await q.json();if(!q.ok)setErr(d.error||'Delete failed');else load()}
 async function transition(row,next){const token=(await supabase.auth.getSession()).data.session?.access_token;const q=await fetch('/api/business/domain',{method:'PATCH',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:JSON.stringify({type,module:moduleKey,business:businessId,id:row.id,status:next})});const d=await q.json();if(!q.ok)setErr(d.error||'Transition failed');else load()}
 const statusField=fields.find(f=>f.key==='status');
 return <main className="domain-engine-page"><div className="domain-engine-shell"><header className="domain-engine-head"><div><div className="eyebrow">ANAIRA BUSINESS OS · {c.name.toUpperCase()}</div><h1>{c.icon} {label}</h1><p><b>{type}</b> domain engine · {moduleKey} · tenant-isolated data workspace.</p></div><div className="domain-engine-badge">{table}</div></header>
 {err&&<div className="notice error">{err}</div>}{msg&&<div className="notice success">✓ {msg}</div>}
 <section className="domain-engine-grid"><form className="card admin-form" onSubmit={save}><h2>{edit?'Edit':'Create'} {label}</h2><div className="domain-form-grid">{fields.map(f=><Input key={f.key} f={f} value={form[f.key]} onChange={v=>setForm(x=>({...x,[f.key]:v}))}/>)}</div>{statusField&&<div className="domain-status-row"><b>Workflow status</b>{statuses.map(s=><button type="button" key={s} className={form.status===s?'active':''} onClick={()=>setForm(x=>({...x,status:s}))}>{s}</button>)}</div>}<div className="domain-actions"><button className="btn primary" disabled={busy}>{busy?'Saving…':edit?'Update':'Create'}</button>{edit&&<button type="button" className="btn" onClick={()=>{setEdit(null);setForm(initial(fields))}}>Cancel</button>}</div></form>
 <div className="card"><div className="domain-list-head"><div><h2>{label} Records</h2><p>{rows.length} records in this business domain.</p></div></div>{rows.length===0?<p>No records yet. Create the first {label.toLowerCase()}.</p>:<div className="domain-records">{rows.map(r=><article key={r.id}><div className="domain-record-main">{(r.data?.image_url||r.data?.photo_url)&&<img src={r.data.image_url||r.data.photo_url} alt=""/>}<div><h3>{r.title}</h3><span className="domain-status">{r.status}</span><p>{Object.entries(r.data||{}).filter(([k,v])=>v!==''&&v!=null&&k!=='image_url'&&k!=='photo_url').slice(0,5).map(([k,v])=>`${pretty(k)}: ${Array.isArray(v)?v.join(', '):String(v)}`).join(' · ')}</p></div></div><div className="domain-record-actions"><button className="btn" onClick={()=>{setEdit(r.id);setForm(r.data||{})}}>Edit</button>{statuses.filter(s=>s!==r.status).slice(0,2).map(s=><button className="btn" key={s} onClick={()=>transition(r,s)}>{s}</button>)}<button className="btn danger" onClick={()=>remove(r.id)}>Delete</button></div></article>)}</div>}</div></section></div></main>
}


export default function BusinessModule(props){
  return <Suspense fallback={<main className="domain-engine-page"><div className="domain-engine-shell"><div className="card">Loading business module…</div></div></main>}><BusinessModuleInner {...props}/></Suspense>;
}
