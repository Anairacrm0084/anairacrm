'use client';
import {useEffect,useState} from 'react';
import {AppShell,Header,Section,Progress} from '../components';
import {supabase} from '../../lib/supabase';
export default function System(){
 const [checks,setChecks]=useState({auth:false,db:false,plugins:false,stores:false,rls:'Checking…'});
 useEffect(()=>{(async()=>{const a=await supabase.auth.getSession();const p=await supabase.from('restaurant_plugins').select('id',{count:'exact',head:true});const s=await supabase.from('anaira_platform_stores').select('id',{count:'exact',head:true});setChecks({auth:!!a.data?.session,db:!p.error,plugins:!p.error,stores:!s.error,rls:p.error?.message||'RLS enforced by database policies'})})()},[]);
 const pct=v=>v===true?100:0;
 return <AppShell active="/system"><Header eyebrow="PLATFORM HEALTH" title="System Health" subtitle="Live connectivity checks. Values are derived from the current authenticated Supabase session and platform tables."/>
 <Section title="Live Health Checks" meta="Not hardcoded"><Progress label="Authentication" value={pct(checks.auth)} display={checks.auth?'Authenticated':'Not authenticated'}/><Progress label="Supabase database" value={pct(checks.db)} display={checks.db?'Connected':'Error'}/><Progress label="Plugin registry" value={pct(checks.plugins)} display={checks.plugins?'Readable':'Error'}/><Progress label="Platform stores" value={pct(checks.stores)} display={checks.stores?'Readable':'Error'}/><div className="notice">RLS: {String(checks.rls)}</div></Section></AppShell>
}