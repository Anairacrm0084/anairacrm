'use client';
import {useMemo,useState,useEffect} from 'react';

export default function MarketplaceQR({restaurantId,hotelName='Hotel',compact=false}){
 const [copied,setCopied]=useState(false);
 const [origin,setOrigin]=useState('');
 const path=`/book/${restaurantId}`;
 const link=useMemo(()=>origin?`${origin}${path}`:path,[origin,restaurantId]);
 const qr=useMemo(()=>`https://api.qrserver.com/v1/create-qr-code/?size=600x600&margin=12&data=${encodeURIComponent(link)}`,[link]);
 useEffect(()=>{setOrigin(process.env.NEXT_PUBLIC_SITE_URL||window.location.origin)},[]);
 async function copy(){try{await navigator.clipboard.writeText(link);setCopied(true);setTimeout(()=>setCopied(false),1800)}catch{setCopied(false)}}
 return <div style={{display:'grid',gridTemplateColumns:compact?'120px 1fr':'180px 1fr',gap:18,alignItems:'center',padding:18,border:'1px solid #e5dccd',borderRadius:16,background:'#fff'}}>
   <div style={{textAlign:'center'}}><img src={qr} alt={`Booking QR for ${hotelName}`} style={{width:compact?120:180,height:compact?120:180,objectFit:'contain',background:'#fff',borderRadius:10,border:'1px solid #eee'}}/></div>
   <div><div style={{fontSize:11,fontWeight:800,letterSpacing:1.3,color:'#8b6b27'}}>DIRECT HOTEL BOOKING QR</div><h3 style={{margin:'5px 0'}}>{hotelName}</h3><p style={{fontSize:12,color:'#667',margin:'0 0 10px'}}>Scan this QR to open this hotel's customer-facing booking page. Room availability and booking flow remain connected to HMS.</p><div style={{display:'flex',gap:8,flexWrap:'wrap'}}><button type="button" className="btn primary" onClick={copy}>{copied?'Copied ✓':'Copy Booking Link'}</button><a className="btn" href={qr} target="_blank" rel="noreferrer">Open / Save QR ↗</a><a className="btn" href={link} target="_blank" rel="noreferrer">Preview Booking ↗</a></div><div style={{marginTop:9,fontSize:11,color:'#777',wordBreak:'break-all'}}>{link}</div></div>
 </div>
}
