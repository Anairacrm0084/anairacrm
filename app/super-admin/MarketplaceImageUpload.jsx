'use client';
import {useState} from 'react';
import {Upload, Image as ImageIcon, X, Loader2} from 'lucide-react';
import {supabase} from '../../lib/supabase';

export default function MarketplaceImageUpload({label='Image',value='',onChange,folder='marketplace',hint='JPG, PNG or WebP • recommended 1920×800'}){
 const [busy,setBusy]=useState(false),[error,setError]=useState('');
 async function upload(file){
  if(!file)return;
  if(!/^image\/(jpeg|png|webp|avif)$/.test(file.type)){setError('Please select JPG, PNG, WebP or AVIF.');return}
  if(file.size>8*1024*1024){setError('Image must be 8 MB or smaller.');return}
  setBusy(true);setError('');
  const ext=(file.name.split('.').pop()||'jpg').toLowerCase();
  const path=`${folder}/${Date.now()}-${Math.random().toString(36).slice(2,9)}.${ext}`;
  const up=await supabase.storage.from('anaira-media').upload(path,file,{upsert:false,contentType:file.type});
  if(up.error){setError(up.error.message);setBusy(false);return}
  const {data}=supabase.storage.from('anaira-media').getPublicUrl(path);
  onChange(data.publicUrl);setBusy(false);
 }
 return <div className="market-image-field">
  <div className="market-image-label"><span>{label}</span><small>{hint}</small></div>
  <div className="market-image-row">
   <div className="market-image-preview">{value?<img src={value} alt="Preview"/>:<div><ImageIcon size={25}/><span>No image</span></div>}</div>
   <div className="market-image-actions">
    <label className="btn primary market-upload-btn"><Upload size={15}/>{busy?'Uploading…':'Upload Image'}<input type="file" accept="image/jpeg,image/png,image/webp,image/avif" disabled={busy} onChange={e=>upload(e.target.files?.[0])}/></label>
    {value&&<button type="button" className="btn" onClick={()=>onChange('')}><X size={14}/> Remove</button>}
    <input value={value} onChange={e=>onChange(e.target.value)} placeholder="Or paste image URL…"/>
   </div>
  </div>
  {error&&<small className="market-image-error">{error}</small>}
 </div>
}
