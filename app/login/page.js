"use client";
import {useEffect,useState} from "react";
import {supabase} from "../../lib/supabase";
import {redirect} from "next/navigation";

export default function Login(){
 const [email,setEmail]=useState(""); const [password,setPassword]=useState(""); const [showPassword,setShowPassword]=useState(false); const [busy,setBusy]=useState(false); const [error,setError]=useState("");
 useEffect(()=>{(async()=>{if(!supabase)return;const {data}=await supabase.auth.getSession();if(!data.session)return;const {data:p}=await supabase.from('anaira_my_profile').select('is_super_admin,role').eq('id',data.session.user.id).maybeSingle();window.location.href=(p?.is_super_admin||p?.role==='super_admin')?'/admin':'/'})()},[]);
 async function submit(e){e.preventDefault();setBusy(true);setError("");
  if(!supabase){setError("Supabase configuration is missing.");setBusy(false);return}
  const {data,error}=await supabase.auth.signInWithPassword({email:email.trim(),password});
  if(error){setError(error.message === "Invalid login credentials" ? "Invalid email or password. Make sure this account exists in the connected Anaira Supabase project and use the current Supabase Auth password." : error.message);setBusy(false);return}
  const {data:profile}=await supabase.from("anaira_my_profile").select("is_super_admin,role,restaurant_id").eq("id",data.user.id).maybeSingle();
  if(!profile){window.location.href='/business-onboarding';return}
  if(profile.is_super_admin || profile.role==="super_admin") window.location.href="/admin"; else window.location.href="/";
 }
 return <main className="login-page"><div className="login-shell"><div className="login-brand"><img src="/assets/anaira-logo.webp" alt="Anaira"/><span>ANAIRA</span></div><div className="eyebrow">ENTERPRISE HOSPITALITY PLATFORM</div><h1>Welcome back</h1><p className="login-sub">Sign in to Anaira CRM & Hospitality Command Center.</p><form onSubmit={submit}><label>Email<input type="email" autoComplete="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="you@company.com" required/></label><label>Password<div className="login-password-wrap"><input type={showPassword?"text":"password"} autoComplete="current-password" value={password} onChange={e=>setPassword(e.target.value)} placeholder="••••••••" required/><button type="button" className="login-password-toggle" onClick={()=>setShowPassword(v=>!v)} aria-label={showPassword?"Hide password":"Show password"} aria-pressed={showPassword} title={showPassword?"Hide password":"Show password"}>{showPassword?<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"/><circle cx="12" cy="12" r="2.5"/></svg>:<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 3l18 18M10.6 5.3A10.8 10.8 0 0 1 12 5c6.5 0 10 7 10 7a18.5 18.5 0 0 1-3.1 3.8M6.2 6.2C3.4 8.1 2 12 2 12s3.5 7 10 7a10.5 10.5 0 0 0 3.1-.5M9.9 9.9a3 3 0 0 0 4.2 4.2"/></svg>}</button></div></label>{error&&<div className="login-error">{error}</div>}<button className="btn primary login-btn" disabled={busy}>{busy?"Signing in…":"Sign in securely"}</button></form><div className="login-foot"><span>Supabase Auth</span><span>•</span><span>Tenant-isolated access</span></div></div></main>
}
