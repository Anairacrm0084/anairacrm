"use client";
import {useEffect,useState} from "react";
import {supabase} from "../../lib/supabase";
import {redirect} from "next/navigation";

export default function Login(){
 const [email,setEmail]=useState(""); const [password,setPassword]=useState(""); const [busy,setBusy]=useState(false); const [error,setError]=useState("");
 useEffect(()=>{(async()=>{if(!supabase)return;const {data}=await supabase.auth.getSession();if(!data.session)return;const {data:p}=await supabase.from('anaira_my_profile').select('is_super_admin,role').eq('id',data.session.user.id).maybeSingle();window.location.href=(p?.is_super_admin||p?.role==='super_admin')?'/admin':'/'})()},[]);
 async function submit(e){e.preventDefault();setBusy(true);setError("");
  if(!supabase){setError("Supabase configuration is missing.");setBusy(false);return}
  const {data,error}=await supabase.auth.signInWithPassword({email:email.trim(),password});
  if(error){setError(error.message === "Invalid login credentials" ? "Invalid email or password. Make sure this account exists in the connected Anaira Supabase project and use the current Supabase Auth password." : error.message);setBusy(false);return}
  const {data:profile}=await supabase.from("anaira_my_profile").select("is_super_admin,role,restaurant_id").eq("id",data.user.id).maybeSingle();
  if(!profile){await supabase.auth.signOut();setError("Account profile is not configured.");setBusy(false);return}
  if(profile.is_super_admin || profile.role==="super_admin") window.location.href="/admin"; else window.location.href="/";
 }
 return <main className="login-page"><div className="login-shell"><div className="login-brand"><img src="/assets/anaira-logo.webp" alt="Anaira"/><span>ANAIRA</span></div><div className="eyebrow">ENTERPRISE HOSPITALITY PLATFORM</div><h1>Welcome back</h1><p className="login-sub">Sign in to Anaira CRM & Hospitality Command Center.</p><form onSubmit={submit}><label>Email<input type="email" autoComplete="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="you@company.com" required/></label><label>Password<input type="password" autoComplete="current-password" value={password} onChange={e=>setPassword(e.target.value)} placeholder="••••••••" required/></label>{error&&<div className="login-error">{error}</div>}<button className="btn primary login-btn" disabled={busy}>{busy?"Signing in…":"Sign in securely"}</button></form><div className="login-foot"><span>Supabase Auth</span><span>•</span><span>Tenant-isolated access</span></div></div></main>
}
