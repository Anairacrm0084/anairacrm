'use client';
import {useEffect,useMemo,useState} from 'react';
import {AppShell,Header,Section,Table,Pill} from './components';
import {supabase} from '../lib/supabase';
import {pluginCatalog} from './pluginCatalog';

const label=k=>k.replace(/_/g,' ').replace(/\b\w/g,c=>c.toUpperCase());
const hidden=new Set(['id','restaurant_id','created_at','updated_at']);
const typeOf=k=>/(price|amount|total|fee|tax|capacity|party_size|guests|quantity|commission)/i.test(k)?'number':/(date|_at$)/i.test(k)?(k.endsWith('_at')?'datetime-local':'date'):'text';
const bool=k=>/^(active|published|verified|closed)$/i.test(k);
function Input({name,value,onChange}){if(bool(name))return <label className="check-field"><input type="checkbox" checked={!!value} onChange={e=>onChange(e.target.checked)}/><span>{label(name)}</span></label>;return <label><span>{label(name)}</span><input type={typeOf(name)} value={value??''} onChange={e=>onChange(e.target.value)}/></label>}

export default function OperationalPluginPage({pluginKey,title,subtitle,table,fields,headers,orderBy='created_at',secondTable=null,action}){
 const plugin=pluginCatalog.find(x=>x.key===pluginKey);const [session,setSession]=useState(undefined),[profile,setProfile]=useState(null),[rid,setRid]=useState(''),[properties,setProperties]=useState([]),[enabled,setEnabled]=useState(false),[rows,setRows]=useState([]),[editing,setEditing]=useState(null),[form,setForm]=useState({}),[error,setError]=useState(''),[busy,setBusy]=useState(false),[query,setQuery]=useState('');
 useEffect(()=>{(async()=>{if(!supabase){setSession(null);return}const {data}=await supabase.auth.getSession();setSession(data.session);if(!data.session)return;const {data:p}=await supabase.from('anaira_my_profile').select('restaurant_id,is_super_admin,role').eq('id',data.session.user.id).maybeSingle();setProfile(p||{});if(p?.is_super_admin){const {data:rs}=await supabase.from('restaurants').select('id,name,status').order('name');setProperties(rs||[])}else setRid(p?.restaurant_id||'')})()},[]);
 useEffect(()=>{if(profile?.is_super_admin&&properties.length&&!rid)setRid(properties[0].id)},[profile,properties,rid]);
 useEffect(()=>{if(!rid||!plugin)return;(async()=>{const {data}=await supabase.from('restaurant_plugins').select('enabled').eq('restaurant_id',rid).eq('plugin_code',pluginKey).maybeSingle();setEnabled(data?.enabled===true)})()},[rid,pluginKey]);
 const load=async()=>{if(!rid||!enabled)return;let q=supabase.from(table).select('*').eq('restaurant_id',rid).order(orderBy,{ascending:false}).limit(200);const r=await q;if(r.error)setError(r.error.message);else setRows(r.data||[])};
 useEffect(()=>{load()},[rid,enabled,table,orderBy]);
 const shown=useMemo(()=>{const q=query.trim().toLowerCase();return q?rows.filter(r=>fields.some(f=>String(r[f]??'').toLowerCase().includes(q))):rows},[rows,query,fields]);
 const start=(r)=>{setEditing(r?.id||null);const x={};fields.forEach(f=>x[f]=r?.[f]??(bool(f)?false:''));setForm(x)};
 const save=async e=>{e.preventDefault();setBusy(true);setError('');const payload={};fields.forEach(f=>{let v=form[f];if(v==='')v=null;if(typeOf(f)==='number'&&v!==null)v=Number(v);payload[f]=v});let q=editing?supabase.from(table).update(payload).eq('id',editing).eq('restaurant_id',rid):supabase.from(table).insert({...payload,restaurant_id:rid});const r=await q;if(r.error)setError(r.error.message);else{setEditing(null);setForm({});await load()}setBusy(false)};
 const del=async r=>{if(!confirm(`Delete ${title} record?`))return;const q=await supabase.from(table).delete().eq('id',r.id).eq('restaurant_id',rid);if(q.error)setError(q.error.message);else load()};
 const doAction=async r=>{if(!action?.nextStatus)return;setBusy(true);const patch={status:action.nextStatus};const q=await supabase.from(table).update(patch).eq('id',r.id).eq('restaurant_id',rid);if(q.error)setError(q.error.message);else await load();setBusy(false)};
 if(session===undefined)return <div className="notice">Connecting…</div>;
 if(!session)return <AppShell><div className="auth-card"><h1>Sign in required</h1><a className="btn primary" href="/login">Open CRM Login</a></div></AppShell>;
 return <AppShell active={plugin?.route}><Header eyebrow={plugin?.category||'OPERATIONS'} title={title||plugin?.name} subtitle={subtitle||plugin?.description} actions={profile?.is_super_admin&&<select value={rid} onChange={e=>setRid(e.target.value)} style={{padding:10,borderRadius:10}}><option value="">Select property</option>{properties.map(p=><option key={p.id} value={p.id}>{p.name}</option>)}</select>}/>
 {!rid?<div className="notice">Select a property.</div>:!enabled?<div className="notice">This plugin is disabled for this property. Enable it from Plugin Control Center.</div>:<>
 <div className="live-bar"><span className="status-dot ok"/><b>LIVE OPERATIONAL DATA</b><span>{table}</span><span>{shown.length} records</span></div>{error&&<div className="notice error">{error}</div>}
 <Section title={editing?'Edit record':'Create record'} meta="Authenticated tenant-scoped CRUD"><form className="card admin-form" onSubmit={save}>{fields.map(f=><Input key={f} name={f} value={form[f]} onChange={v=>setForm({...form,[f]:v})}/>)}<div className="full"><button className="btn primary" disabled={busy}>{busy?'Saving…':editing?'Update':'Create'}</button>{editing&&<button type="button" className="btn" onClick={()=>{setEditing(null);setForm({})}}>Cancel</button>}</div></form></Section>
 <Section title={title||table} meta={`${shown.length} live records`}><div className="filters"><input placeholder="Search live records" value={query} onChange={e=>setQuery(e.target.value)}/><button className="btn" onClick={load}>Refresh</button></div>{!shown.length?<div className="notice">No records yet.</div>:<Table columns={[...headers,'Actions']} rows={shown.map(r=>[...fields.map(f=>{const v=r[f];return v===null||v===undefined||v===''?'—':typeof v==='boolean'?<Pill tone={v?'success':'muted'}>{v?'Yes':'No'}</Pill>:typeof v==='object'?JSON.stringify(v):String(v).slice(0,100)}),<><button className="btn" onClick={()=>start(r)}>Edit</button> <button className="btn" onClick={()=>del(r)}>Delete</button>{action?.nextStatus&&r.status!==action.nextStatus&&<button className="btn primary" onClick={()=>doAction(r)}>{action.label}</button>}</>] )}/>}</Section>
 {secondTable&&<Section title={secondTable.title} meta={secondTable.table}><div className="notice">Use the dedicated operational records below. This table is read-only here to preserve its ownership boundary.</div></Section>}
 </>}</AppShell>
}
