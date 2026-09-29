'use client';
import {useRef,useState} from 'react';
import {Upload,Image as ImageIcon,Video,Trash2,RefreshCw} from 'lucide-react';
import {supabase} from '../../lib/supabase';

const BUCKET='anaira-media';
const safe=(v)=>String(v||'').replace(/[^a-zA-Z0-9._-]+/g,'-').replace(/-+/g,'-').replace(/^-|-$/g,'');

export default function HotelMediaUpload({label='Media',imageValue='',videoValue='',mediaType='image',onChange,onTypeChange,restaurantId,folder='hotel/marketplace'}){
 const ref=useRef(null); const [busy,setBusy]=useState(false); const [error,setError]=useState('');
 async function upload(file){
  if(!file||!restaurantId)return;
  const isVideo=file.type.startsWith('video/');
  const isImage=file.type.startsWith('image/');
  if(!isImage&&!isVideo){setError('Please select an image or video file.');return}
  if(isVideo&&!['video/mp4','video/webm','video/quicktime'].includes(file.type)){setError('Supported video formats: MP4, WebM, MOV.');return}
  const max=isVideo?80:12;
  if(file.size>max*1024*1024){setError(`File must be ${max} MB or smaller.`);return}
  setBusy(true);setError('');
  const ext=(file.name.split('.').pop()||'bin').toLowerCase();
  const path=`${restaurantId}/${folder}/${Date.now()}-${safe(file.name)||`media.${ext}`}`;
  const up=await supabase.storage.from(BUCKET).upload(path,file,{cacheControl:'3600',upsert:false,contentType:file.type});
  if(up.error){setError(up.error.message);setBusy(false);return}
  const url=supabase.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;
  onTypeChange?.(isVideo?'video':'image'); onChange?.(url); setBusy(false); if(ref.current)ref.current.value='';
 }
 const value=mediaType==='video'?videoValue:imageValue;
 return <div className="hotel-media-upload">
  <div className="hotel-media-head"><div><b>{label}</b><small>Image or video · responsive media</small></div><div className="hotel-media-switch"><button type="button" className={mediaType==='image'?'active':''} onClick={()=>onTypeChange?.('image')}><ImageIcon size={14}/> Image</button><button type="button" className={mediaType==='video'?'active':''} onClick={()=>onTypeChange?.('video')}><Video size={14}/> Video</button></div></div>
  <div className="hotel-media-body">
   <div className="hotel-media-preview">{value?(mediaType==='video'?<video src={value} controls muted playsInline/>:<img src={value} alt="Preview"/>):<div className="hotel-media-empty"><ImageIcon size={24}/><span>No media selected</span></div>}</div>
   <div className="hotel-media-actions">
    <label className="btn primary"><Upload size={14}/>{busy?'Uploading…':'Upload / Replace'}<input ref={ref} hidden type="file" accept={mediaType==='video'?'video/mp4,video/webm,video/quicktime':'image/jpeg,image/png,image/webp,image/avif'} disabled={busy} onChange={e=>upload(e.target.files?.[0])}/></label>
    {value&&<button type="button" className="btn" onClick={()=>onChange?.('')}><Trash2 size={14}/> Remove</button>}
    {value&&<input value={value} onChange={e=>onChange?.(e.target.value)} placeholder="Or paste media URL…"/>}
   </div>
  </div>
  {error&&<div className="hotel-media-error">{error}</div>}
 </div>
}
