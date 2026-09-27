
'use client';
import {useEffect,useMemo,useState} from 'react';
import {AppShell,Header,Section,Pill} from '../components';
import {supabase} from '../../lib/supabase';

const tabs=['Overview','Inbox','Pending Approval','Published','Negative Reviews','Recovery','Review Requests','Sources','Automation','Templates','SLA','Analytics','Settings'];
const labelize=x=>String(x||'').replace(/_/g,' ').replace(/\b\w/g,m=>m.toUpperCase());

export default function Reviews(){
 const [session,setSession]=useState(undefined),[tenantId,setTenantId]=useState(''),[reviews,setReviews]=useState([]),[sources,setSources]=useState([]),[jobs,setJobs]=useState([]),[stats,setStats]=useState(null),[tab,setTab]=useState('Overview'),[busy,setBusy]=useState(''),[msg,setMsg]=useState(''),[error,setError]=useState('');
 const [settings,setSettings]=useState({});
 const load=async()=>{
   if(!supabase||!session)return; setError('');
   const {data:p}=await supabase.from('anaira_my_profile').select('restaurant_id,is_super_admin').eq('id',session.user.id).maybeSingle();
   const tid=p?.restaurant_id||''; if(!tid)return setError('No CRM property is assigned to this account.'); setTenantId(tid);
   const [r,s,j,a,ps]=await Promise.all([
     supabase.from('crm_reviews').select('*').eq('tenant_id',tid).order('reviewed_at',{ascending:false}).limit(1000),
     supabase.from('crm_review_sources').select('*').eq('tenant_id',tid).order('created_at',{ascending:false}),
     supabase.from('crm_review_request_jobs').select('*').eq('tenant_id',tid).order('created_at',{ascending:false}).limit(500),
     fetch(`/api/reviews/analytics?tenantId=${tid}`).then(x=>x.json()),
     supabase.from('plugin_settings').select('config,custom_settings').eq('restaurant_id',tid).eq('plugin_code','ai-review-system').maybeSingle()
   ]);
   setReviews(r.data||[]);setSources(s.data||[]);setJobs(j.data||[]);setStats(a);setSettings({...((ps.data||{}).config?.settings||{}),...((ps.data||{}).custom_settings||{})});
 };
 useEffect(()=>{if(!supabase){setSession(null);return}supabase.auth.getSession().then(({data})=>setSession(data.session||null));},[]);
 useEffect(()=>{load();},[session]);
 const call=async(path,body={})=>{setBusy(path);setMsg('');setError('');try{const r=await fetch(path,{method:'POST',headers:{'content-type':'application/json',authorization:session?`Bearer ${session.access_token}`:''},body:JSON.stringify(body)});const j=await r.json();if(!r.ok||j.ok===false)throw new Error(j.error||'Request failed');setMsg(j.message||'Completed successfully');await load();return j}catch(e){setError(e.message);return null}finally{setBusy('')}};
 const pending=reviews.filter(r=>r.reply_status==='pending_approval'),negative=reviews.filter(r=>r.sentiment==='negative'||Number(r.rating)<=2),published=reviews.filter(r=>r.reply_status==='published');
 const connected=sources.some(x=>x.source==='google'&&x.api_enabled&&x.active);
 const startGoogle=async()=>{if(!tenantId||!session)return;setBusy('google');setError('');try{const r=await fetch('/api/reviews/source/oauth',{method:'POST',headers:{'content-type':'application/json',authorization:`Bearer ${session.access_token}`},body:JSON.stringify({tenantId})});const j=await r.json();if(!r.ok||!j.ok)throw new Error(j.error||'Google OAuth start failed');window.location.href=j.url}catch(e){setError(e.message);setBusy('')}};
 const sync=()=>call('/api/reviews/sync',{tenantId});
 const discover=()=>call('/api/reviews/source/discover',{tenantId});
 const process=()=>call('/api/reviews/process',{tenantId});
 const editReply=async(r)=>{const reply=window.prompt('Edit AI reply before approval',r.reply_text||'');if(reply===null)return;await call('/api/reviews/approve',{tenantId,reviewId:r.id,approved:true,reply})};
 const publish=async(r)=>{await call('/api/reviews/publish',{tenantId,reviewId:r.id})};
 const recovery=async(r)=>{await call('/api/reviews/recovery',{tenantId,reviewId:r.id,dueHours:settings.default_recovery_hours||24})};
 const visible=useMemo(()=>{
   if(tab==='Pending Approval')return pending;if(tab==='Published')return published;if(tab==='Negative Reviews')return negative;if(tab==='Inbox')return reviews;return reviews.slice(0,100);
 },[tab,reviews,pending,published,negative]);
 if(session===undefined)return <AppShell><div className="notice">Connecting to CRM…</div></AppShell>;
 if(!session)return <AppShell><div className="auth-card"><h1>Sign in required</h1><a className="btn primary" href="/login">Open CRM Login</a></div></AppShell>;
 return <AppShell active="/ai-reviews">
  <Header eyebrow="ANAIRA AI REVIEW AUTOMATION" title="Reputation Command Center" subtitle="Google Business Profile ingestion, AI classification, human approval, reply publishing, recovery, SLA, review-request automation and live analytics." actions={<><button className="btn primary" onClick={startGoogle}>Connect Google</button><a className="btn" href="/plugins/ai-review-system/settings">Plugin Settings</a></>}/>
  {(msg||error)&&<div className={error?'notice error':'notice'}>{error||msg}</div>}
  <div className="tabs" style={{display:'flex',gap:7,flexWrap:'wrap',marginBottom:16}}>{tabs.map(t=><button className={'btn '+(tab===t?'primary':'')} key={t} onClick={()=>setTab(t)}>{t}</button>)}</div>
  <div className="grid kpis">
   <div className="kpi"><small>Total Reviews</small><b>{stats?.total??reviews.length}</b><span>Live</span></div>
   <div className="kpi"><small>Average Rating</small><b>{stats?.avgRating??'—'}</b><span>out of 5</span></div>
   <div className="kpi"><small>Pending Approval</small><b>{pending.length}</b><span>AI replies</span></div>
   <div className="kpi"><small>Negative</small><b>{negative.length}</b><span>Recovery candidates</span></div>
  </div>
  {tab==='Overview'&&<>
   <Section title="Live Integration Health" meta="Real providers; no fake connection state"><div className="mini-grid">
    <div className="mini"><span>Google Business Profile</span><b>{connected?'Connected':'Not connected'}</b><small>OAuth + account/location discovery</small></div>
    <div className="mini"><span>AI Classification</span><b>{settings.ai_classification===false?'Disabled':'Enabled / provider-gated'}</b><small>Requires OPENAI_API_KEY on deployment</small></div>
    <div className="mini"><span>Reply Publishing</span><b>{settings.auto_publish&&settings.human_approval===false?'Auto publish':'Human approval'}</b><small>Google reply API</small></div>
    <div className="mini"><span>Automation</span><b>Scheduled</b><small>Sync / AI / request / SLA workers</small></div>
   </div></Section>
   <Section title="One-click Operations" meta="Run the actual backend workflow"><div style={{display:'flex',gap:8,flexWrap:'wrap'}}><button className="btn primary" onClick={discover} disabled={!!busy}>{busy==='/api/reviews/source/discover'?'Discovering…':'Discover Google Locations'}</button><button className="btn" onClick={sync} disabled={!!busy}>{busy==='/api/reviews/sync'?'Syncing…':'Sync Google Reviews Now'}</button><button className="btn" onClick={process} disabled={!!busy}>{busy==='/api/reviews/process'?'AI Processing…':'Run AI Review Engine'}</button><button className="btn" onClick={load}>Refresh Dashboard</button></div></Section>
  </>}
  {['Inbox','Pending Approval','Published','Negative Reviews'].includes(tab)&&<Section title="Review Inbox" meta={`${visible.length} reviews`}><div style={{display:'flex',gap:8,flexWrap:'wrap',marginBottom:12}}><button className="btn" onClick={sync}>Sync</button><button className="btn" onClick={process}>Run AI Engine</button></div><table className="data-table"><thead><tr><th>Source</th><th>Rating</th><th>Sentiment</th><th>Customer Review</th><th>AI Reply</th><th>Status / Actions</th></tr></thead><tbody>{visible.map(r=><tr key={r.id}><td>{r.source}</td><td>{r.rating||'—'}</td><td><Pill tone={r.sentiment==='negative'?'danger':r.sentiment==='positive'?'success':'muted'}>{r.sentiment||'pending'}</Pill></td><td><b>{r.author_name||'Guest'}</b><div>{(r.review_text||'').slice(0,220)}</div></td><td>{(r.reply_text||'').slice(0,220)}</td><td style={{minWidth:220}}><div style={{display:'flex',gap:5,flexWrap:'wrap'}}>{r.reply_status==='pending_approval'&&<><button className="btn" onClick={()=>editReply(r)}>Approve / Edit</button><button className="btn primary" onClick={()=>publish({...r,reply_status:'approved'})} disabled>Publish after approval</button></>}{r.reply_status==='approved'&&<button className="btn primary" onClick={()=>publish(r)}>Publish Google Reply</button>}{(r.sentiment==='negative'||Number(r.rating)<=2)&&<button className="btn" onClick={()=>recovery(r)}>Open Recovery</button>}{r.reply_status==='published'&&<Pill tone="success">Published</Pill>}</div></td></tr>)}</tbody></table></Section>}
  {tab==='Recovery'&&<Section title="Service Recovery Queue" meta="Negative reviews become owned recovery cases"><table className="data-table"><thead><tr><th>Review</th><th>Priority</th><th>Action</th></tr></thead><tbody>{negative.map(r=><tr key={r.id}><td>{(r.review_text||'').slice(0,260)}</td><td>{Number(r.rating)<=2?'Critical':'High'}</td><td><button className="btn" onClick={()=>recovery(r)}>Create / Re-open Case</button></td></tr>)}</tbody></table></Section>}
  {tab==='Review Requests'&&<Section title="Automated Review Request Queue" meta={`${jobs.length} jobs`}><div className="notice">Jobs are generated from hotel stays / restaurant visits, require verified communication consent, then are delivered through configured WhatsApp, SMS or Email providers with retry + dead-letter handling.</div><table className="data-table"><thead><tr><th>Reference</th><th>Channel</th><th>Due</th><th>Status</th><th>Attempts</th><th>Error</th></tr></thead><tbody>{jobs.map(j=><tr key={j.id}><td>{j.reference_type}:{j.reference_id}</td><td>{j.channel}</td><td>{j.due_at?new Date(j.due_at).toLocaleString():'—'}</td><td>{j.status}</td><td>{j.attempts||0}</td><td>{j.last_error||'—'}</td></tr>)}</tbody></table></Section>}
  {tab==='Sources'&&<Section title="Google Business Profile Locations" meta="Connect once, then discover every managed location"><div style={{display:'flex',gap:8,marginBottom:12}}><button className="btn primary" onClick={startGoogle}>Connect Google Account</button><button className="btn" onClick={discover}>Discover Locations</button><button className="btn" onClick={sync}>Sync All Locations</button></div><table className="data-table"><thead><tr><th>Location</th><th>Google Location ID</th><th>Account</th><th>Active</th><th>Last Sync</th></tr></thead><tbody>{sources.map(s=><tr key={s.id}><td>{s.settings?.title||s.location_id}</td><td>{s.location_id}</td><td>{s.settings?.account_id||'—'}</td><td>{s.active?'Yes':'No'}</td><td>{s.created_at?new Date(s.created_at).toLocaleString():'—'}</td></tr>)}</tbody></table><div className="notice" style={{marginTop:12}}>After OAuth, click <b>Discover Locations</b>. Anaira reads the Google accounts you administer, then imports their locations into the CRM source registry. Reviews are then synced hourly and can also be synced manually.</div></Section>}
  {tab==='Automation'&&<Section title="Automation Engine" meta="Scheduled backend workers"><div className="mini-grid"><div className="mini"><b>Review Sync</b><span>Hourly</span><small>Google Business Profile → crm_reviews</small></div><div className="mini"><b>AI Review Engine</b><span>Every 10 minutes</span><small>new review → AI → approval/recovery/optional publish</small></div><div className="mini"><b>Review Request Automation</b><span>Hourly</span><small>eligible stay/visit → consent-checked job</small></div><div className="mini"><b>Delivery Worker</b><span>Every 10 minutes</span><small>WhatsApp/SMS/Email with retry + dead letter</small></div></div></Section>}
  {tab==='Templates'&&<Section title="Review Templates" meta="Stored in crm_review_templates"><div className="notice">Templates are tenant-scoped database records. Create them from the AI Review plugin settings / template manager when you need provider-specific content.</div></Section>}
  {tab==='SLA'&&<Section title="Recovery SLA" meta="Automatic escalation"><div className="grid kpis"><div className="kpi"><small>Open Recovery</small><b>{stats?.recovery?.open??0}</b></div><div className="kpi"><small>Resolved</small><b>{stats?.recovery?.resolved??0}</b></div><div className="kpi"><small>Recovery Rate</small><b>{stats?.recovery?.rate??0}%</b></div><div className="kpi"><small>Overdue Escalations</small><b>{stats?.recovery?.overdue??0}</b></div></div></Section>}
  {tab==='Analytics'&&<Section title="Reputation Analytics" meta="Computed from live CRM review data"><div className="grid kpis"><div className="kpi"><small>Response Rate</small><b>{stats?.responseRate??0}%</b></div><div className="kpi"><small>Avg Response Time</small><b>{stats?.avgResponseHours??'—'}h</b></div><div className="kpi"><small>Positive</small><b>{stats?.positive??0}</b></div><div className="kpi"><small>Negative</small><b>{stats?.negative??0}</b></div></div><Section title="Source Performance"><table className="data-table"><thead><tr><th>Source</th><th>Reviews</th><th>Avg Rating</th><th>Negative %</th></tr></thead><tbody>{Object.entries(stats?.bySource||{}).map(([k,v])=><tr key={k}><td>{k}</td><td>{v.total}</td><td>{v.avgRating}</td><td>{v.total?Number(v.negative/v.total*100).toFixed(1):0}%</td></tr>)}</tbody></table></Section><Section title="30-day Trend"><table className="data-table"><thead><tr><th>Date</th><th>Reviews</th><th>Avg Rating</th><th>Positive</th><th>Negative</th></tr></thead><tbody>{(stats?.dailyTrend||[]).map(x=><tr key={x.date}><td>{x.date}</td><td>{x.total}</td><td>{x.avgRating}</td><td>{x.positive}</td><td>{x.negative}</td></tr>)}</tbody></table></Section></Section>}
  {tab==='Settings'&&<Section title="Effective AI Review Settings" meta="Loaded from plugin_settings"><div className="mini-grid">{Object.entries(settings).map(([k,v])=><div className="mini" key={k}><span>{labelize(k)}</span><b>{typeof v==='boolean'?(v?'Enabled':'Disabled'):String(v)}</b></div>)}</div><div className="notice" style={{marginTop:12}}>Important production credentials stay server-side. Google requires OAuth 2.0 with the <code>business.manage</code> scope; OpenAI / WhatsApp / Twilio / Resend credentials are also server-side environment variables.</div></Section>}
 </AppShell>
}
