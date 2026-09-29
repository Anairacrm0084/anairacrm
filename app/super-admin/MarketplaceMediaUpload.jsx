'use client';
import {useState} from 'react';
import {Upload,Image as ImageIcon,Video, X, Loader2} from 'lucide-react';
import {supabase} from '../../lib/supabase';

export default function MarketplaceMediaUpload({
  label='Media', value='', onChange, folder='marketplace', mediaType='image',
  onMediaTypeChange, hint='JPG, PNG, WebP, AVIF or MP4/WebM • max 50 MB'
}){
 const [busy,setBusy]=useState(false),[error,setError]=useState('');
 const isVideo=mediaType==='video';
 async function upload(file){
  if(!file)return;
  const ok=isVideo?/^video\/(mp4|webm|quicktime)$/.test(file.type):/^image\/(jpeg|png|webp|avif)$/.test(file.type);
  if(!ok){setError(isVideo?'Please select MP4, WebM or MOV video.':'Please select JPG, PNG, WebP or AVIF image.');return}
  const max=isVideo?50*1024*1024:8*1024*1024;
  if(file.size>max){setError(`File must be ${isVideo?'50 MB':'8 MB'} or smaller.`);return}
  setBusy(true);setError('');
  const ext=(file.name.split('.').pop()|| (isVideo?'mp4':'jpg')).toLowerCase();
  const path=`${folder}/${Date.now()}-${Math.random().toString(36).slice(2,9)}.${ext}`;
  const up=await supabase.storage.from('anaira-media').upload(path,file,{upsert:false,contentType:file.type});
  if(up.error){setError(up.error.message);setBusy(false);return}
  const {data}=supabase.storage.from('anaira-media').getPublicUrl(path);
  onChange(data.publicUrl);setBusy(false);
 }
 return <div className="market-image-field">
  <div className="market-image-label"><span>{label}</span><small>{hint}</small></div>
  {onMediaTypeChange&&<div className="market-media-type-toggle">
   <button type="button" className={!isVideo?'active':''} onClick={()=>onMediaTypeChange('image')}><ImageIcon size={14}/> Image</button>
   <button type="button" className={isVideo?'active':''} onClick={()=>onMediaTypeChange('video')}><Video size={14}/> Video</button>
  </div>}
  <div className="market-image-row">
   <div className="market-image-preview">
    {value?(isVideo?<video src={value} muted autoPlay loop playsInline controls/>:<img src={value} alt="Preview"/>):<div>{isVideo?<Video size={25}/>:<ImageIcon size={25}/>}<span>No {isVideo?'video':'image'}</span></div>}
   </div>
   <div className="market-image-actions">
    <label className="btn primary market-upload-btn"><Upload size={15}/>{busy?'Uploading…':`Upload ${isVideo?'Video':'Image'}`}<input type="file" accept={isVideo?'video/mp4,video/webm,video/quicktime':'image/jpeg,image/png,image/webp,image/avif'} disabled={busy} onChange={e=>upload(e.target.files?.[0])}/></label>
    {value&&<button type="button" className="btn" onClick={()=>onChange('')}><X size={14}/> Remove</button>}
    <input value={value} onChange={e=>onChange(e.target.value)} placeholder={`Or paste ${isVideo?'video':'image'} URL…`}/>
   </div>
  </div>
  {busy&&<small className="market-image-error"><Loader2 size={13}/> Uploading…</small>}
  {error&&<small className="market-image-error">{error}</small>}
 </div>
}
