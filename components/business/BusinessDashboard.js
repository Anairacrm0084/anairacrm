
'use client';
import {Suspense,useEffect,useState} from 'react';
import {useSearchParams} from 'next/navigation';
import {supabase} from '../../lib/supabase';
import {businessConfig,businessModules} from '../../app/businessTypeConfig';
function BusinessDashboardInner({type}){const c=businessConfig(type),s=useSearchParams(),id=s.get('business')||s.get('id');const [counts,setCounts]=useState({}),[biz,setBiz]=useState(null);useEffect(()=>{(async()=>{if(!id)return;const [{data:b},{data:r}]=await Promise.all([supabase.from('restaurants').select('name,business_type,city,state').eq('id',id).maybeSingle(),supabase.from('anaira_business_records').select('module_key').eq('business_id',id)]);setBiz(b);const x={};(r||[]).forEach(v=>x[v.module_key]=(x[v.module_key]||0)+1);setCounts(x)})()},[id]);return <main style={{padding:'36px 20px',background:'#f6f5ef',minHeight:'100vh'}}><div style={{maxWidth:1180,margin:'auto'}}><div className="eyebrow">ANAIRA • {c.name.toUpperCase()} DASHBOARD</div><h1>{c.icon} {biz?.name||c.name}</h1><p>{biz?.city?[biz.city,biz.state].filter(Boolean).join(', '):'Business operations dashboard'}</p><div className="grid two">{businessModules(type).filter(m=>m.key!=='landing').map(m=><a className="card" key={m.key} href={`/business/${type}/${m.key}?business=${id}`}><div className="eyebrow">{m.key.toUpperCase()}</div><h2>{m.label}</h2><strong style={{fontSize:32}}>{counts[m.key]||0}</strong><p>Open {m.label}</p></a>)}</div><a className="card" style={{display:'block',marginTop:18}} href={`/business/${type}/landing?business=${id}`}><h2>↗ Front Landing Page</h2><p>Preview the customer-facing {c.name} landing page.</p></a></div></main>}


export default function BusinessDashboard(props){ return <Suspense fallback={<main className="domain-engine-page"><div className="card">Loading…</div></main>}><BusinessDashboardInner {...props}/></Suspense>; }
