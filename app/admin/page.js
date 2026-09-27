"use client";
import {useEffect,useState} from 'react';
import {AppShell,Header,Kpi,Section,Table,Pill} from '../components';
import {supabase} from '../../lib/supabase';

export default function Admin(){
 const [loading,setLoading]=useState(true),[properties,setProperties]=useState([]),[plugins,setPlugins]=useState([]),[seo,setSeo]=useState({sites:0,verified:0,issues:0,failures:0}),[error,setError]=useState(''),[saving,setSaving]=useState(false);
 const [form,setForm]=useState({name:'',slug:'',email:'',phone:'',address:''});
 const [assign,setAssign]=useState({email:'',password:'',propertyId:'',role:'admin',name:''});
 async function load(){
  const [rs,ps,ss,si,sa]=await Promise.all([
   supabase.from('restaurants').select('id,name,slug,status,phone,email,created_at').order('created_at',{ascending:false}),
   supabase.from('restaurant_plugins').select('restaurant_id,plugin_code,enabled,updated_at').order('updated_at',{ascending:false}),
   supabase.from('crm_seo_sites').select('id,verification_status').eq('archived',false),
   supabase.from('crm_seo_issues').select('id,status,severity'),
   supabase.from('crm_seo_automation_runs').select('id,status').eq('status','failed')
  ]);
  if(rs.error)setError(rs.error.message);else setProperties(rs.data||[]);if(ps.error)setError(ps.error.message);else setPlugins(ps.data||[]);setSeo({sites:ss.data?.length||0,verified:(ss.data||[]).filter(x=>x.verification_status==='verified').length,issues:(si.data||[]).filter(x=>x.status==='open').length,failures:sa.data?.length||0});
 }
 useEffect(()=>{(async()=>{if(!supabase){setError('Supabase is not configured.');setLoading(false);return}const {data:{session}}=await supabase.auth.getSession();if(!session){location.href='/login';return}const {data:p,error:pe}=await supabase.from('anaira_my_profile').select('is_super_admin,role').eq('id',session.user.id).maybeSingle();if(pe||!p||(!p.is_super_admin&&p.role!=='super_admin')){location.href='/';return}await load();setLoading(false)})()},[]);
 async function createProperty(e){e.preventDefault();setSaving(true);setError('');const {error:e1}=await supabase.rpc('anaira_create_property',{p_name:form.name,p_slug:form.slug,p_email:form.email||null,p_phone:form.phone||null,p_address:form.address||null});if(e1)setError(e1.message);else{setForm({name:'',slug:'',email:'',phone:'',address:''});await load()}setSaving(false)}
 async function assignUser(e){e.preventDefault();setSaving(true);setError('');
  if(!assign.email.trim()||!assign.password||!assign.propertyId){setError('Email, password and property are required.');setSaving(false);return}
  if(assign.password.length<8){setError('Password must be at least 8 characters.');setSaving(false);return}
  const {data,error:e1}=await supabase.functions.invoke('anaira-create-business-user',{body:{email:assign.email.trim(),password:assign.password,restaurant_id:assign.propertyId,role:assign.role,full_name:assign.name||null}});
  if(e1)setError(e1.message||'Unable to create login user.');else if(data?.error)setError(data.detail?`${data.error}: ${data.detail}`:data.error);else setAssign({email:'',password:'',propertyId:assign.propertyId,role:assign.role,name:''});setSaving(false)
 }

 if(loading)return <AppShell><div className="notice">Loading Anaira Super Admin…</div></AppShell>;
 if(error&&properties.length===0)return <AppShell><div className="notice error">{error}</div></AppShell>;
 const enabled=plugins.filter(x=>x.enabled).length,active=properties.filter(x=>x.status==='active').length;
 return <AppShell active="/admin"><Header eyebrow="ANAIRA PLATFORM ADMIN" title="Super Admin Command Center" subtitle="You are the platform owner. Manage every hotel, restaurant, user, plugin and integration from this control plane." actions={<><span className="superadmin-badge">● SUPER ADMIN</span><a className="btn" href="/plugins">Plugin Control Center</a></>}/>
  <div className="grid kpis"><Kpi label="Properties" value={properties.length} delta="All tenants"/><Kpi label="Active Properties" value={active} delta="Operational"/><Kpi label="Enabled Plugins" value={enabled} delta="Across tenants"/><Kpi label="Platform" value="LIVE" delta="Supabase"/><Kpi label="SEO Sites" value={seo.sites} delta={`${seo.verified} verified`}/><Kpi label="SEO Open Issues" value={seo.issues} delta="Live"/><Kpi label="SEO Job Failures" value={seo.failures} delta="Automation"/></div>
  {error&&<div className="notice error">{error}</div>}
  <div className="grid two">
   <Section title="Create Hotel / Restaurant" meta="Super Admin only"><form className="admin-form" onSubmit={createProperty}><label>Business name<input required value={form.name} onChange={e=>setForm({...form,name:e.target.value})}/></label><label>Slug<input required value={form.slug} onChange={e=>setForm({...form,slug:e.target.value})}/></label><label>Email<input type="email" value={form.email} onChange={e=>setForm({...form,email:e.target.value})}/></label><label>Phone<input value={form.phone} onChange={e=>setForm({...form,phone:e.target.value})}/></label><label className="full">Address<input value={form.address} onChange={e=>setForm({...form,address:e.target.value})}/></label><button className="btn primary full" disabled={saving}>{saving?'Creating…':'Create Property'}</button></form></Section>
   <Section title="Create Business Login" meta="No UUID required"><form className="admin-form" onSubmit={assignUser}><label>Email / Login ID<input required type="email" value={assign.email} onChange={e=>setAssign({...assign,email:e.target.value})} placeholder="admin@hotel.com"/></label><label>Password<input required type="password" minLength={8} autoComplete="new-password" value={assign.password} onChange={e=>setAssign({...assign,password:e.target.value})} placeholder="Minimum 8 characters"/></label><label>Property<select required value={assign.propertyId} onChange={e=>setAssign({...assign,propertyId:e.target.value})}><option value="">Select property</option>{properties.map(p=><option key={p.id} value={p.id}>{p.name}</option>)}</select></label><label>Role<select value={assign.role} onChange={e=>setAssign({...assign,role:e.target.value})}><option value="admin">Business Admin</option><option value="manager">Manager</option><option value="staff">Staff</option></select></label><label>Name<input value={assign.name} onChange={e=>setAssign({...assign,name:e.target.value})} placeholder="Business Admin"/></label><div className="notice full">Ye invitation nahi hai. Super Admin yahin se direct login account create karega. Supabase Auth UUID automatically generate karega; user email + password se login kar sakta hai.</div><button className="btn primary full" disabled={saving}>{saving?'Creating login...':'Create Login User'}</button></form></Section>
  </div>
  <Section title="Property / Tenant Management" meta="Hotels & restaurants"><Table columns={['Property','Slug','Status','Contact','Plugins','Open']} rows={properties.map(r=>[r.name||'Unnamed',r.slug||'—',<Pill key={r.id} tone={r.status==='active'?'success':'muted'}>{r.status||'—'}</Pill>,r.phone||r.email||'—',plugins.filter(p=>p.restaurant_id===r.id&&p.enabled).length,<a className="btn" href={'/admin/property/'+r.id}>Manage</a>])}/>{!properties.length&&<div className="notice">No hotel or restaurant tenants have been created yet.</div>}</Section>
  <div className="grid two"><Section title="Super Admin Identity" meta="One platform owner"><div className="notice"><b>Only one Super Admin.</b><br/>Your Super Admin user is created by Supabase Auth. Its UUID is generated automatically and is never entered manually. Business Admins, Managers and Staff are created directly with a Login ID + password. Supabase generates their Auth UUID automatically.</div></Section><Section title="What you control" meta="Platform owner"><ul><li>Hotels/restaurants and their business admins</li><li>CRM, Booking, PMS, Reservation, POS, Delivery, Store and OTA activation</li><li>Platform integrations, audit and sync health</li><li>Tenant-level configuration and access boundaries</li></ul></Section><Section title="Tenant isolation" meta="Security boundary"><div className="notice">Super Admin is platform-level. Every hotel/restaurant user gets a <b>restaurant_id</b>. Their dashboard and data stay inside that tenant.</div></Section></div>
 </AppShell>
}
