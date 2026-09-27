'use client';
import {useState} from 'react';
import {supabase} from '../lib/supabase';

export default function WorkflowAction({label,rpc,args,onDone,disabled=false,confirmText}) {
 const [busy,setBusy]=useState(false),[error,setError]=useState('');
 async function run(){
  if(confirmText && !window.confirm(confirmText)) return;
  setBusy(true); setError('');
  const {data,error:e}=await supabase.rpc(rpc,args||{});
  setBusy(false);
  if(e){setError(e.message);return}
  onDone?.(data);
 }
 return <span style={{display:'inline-flex',flexDirection:'column',gap:4}}>
  <button className="btn" disabled={disabled||busy} onClick={run}>{busy?'Processing…':label}</button>
  {error&&<small style={{color:'#b91c1c',maxWidth:260}}>{error}</small>}
 </span>
}
