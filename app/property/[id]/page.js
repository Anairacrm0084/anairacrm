'use client';
import {useEffect,useMemo,useState} from 'react';
import {useParams,useSearchParams} from 'next/navigation';
import {supabase} from '../../../lib/supabase';

const datePlus=n=>{const d=new Date();d.setDate(d.getDate()+n);return d.toISOString().slice(0,10)};
export default function HospitalityPropertyLanding(){
 const {id}=useParams(); const search=useSearchParams();
 const [data,setData]=useState(null),[units,setUnits]=useState([]),[loading,setLoading]=useState(true),[error,setError]=useState('');
 const [checkIn,setCheckIn]=useState(search.get('check_in')||datePlus(1)),[checkOut,setCheckOut]=useState(search.get('check_out')||datePlus(2)),[adults,setAdults]=useState(Number(search.get('adults')||2)),[children,setChildren]=useState(Number(search.get('children')||0));
 useEffect(()=>{if(!id)return;(async()=>{try{
  const [{data:b,error:be},{data:h,error:he},{data:c,error:ce},{data:r,error:re},{data:rooms,error:rme}]=await Promise.all([
   supabase.from('restaurants').select('id,name,city,address,phone,email,website,logo,cover_image').eq('id',id).maybeSingle(),
   supabase.from('hms_settings').select('*').eq('restaurant_id',id).maybeSingle(),
   supabase.from('camp_properties').select('*').eq('restaurant_id',id).eq('active',true).maybeSingle(),
   supabase.from('hms_room_types').select('*').eq('restaurant_id',id).eq('active',true).order('name'),
   supabase.from('hms_rooms').select('id,room_type_id,status,active,booking_enabled').eq('restaurant_id',id).eq('active',true)
  ]);
  if(be)throw be;if(he)throw he;if(ce)throw ce;if(re)throw re;if(rme)throw rme;
  if(!b&&!h&&!c)throw new Error('This property is not available.');
  const propertyType=h?.hospitality_type||c?.hospitality_type||'hotel';
  setData({business:b||{},settings:h||{},camp:c||{},type:propertyType});
  const roomCounts=new Map();(rooms||[]).filter(x=>x.booking_enabled!==false).forEach(x=>roomCounts.set(x.room_type_id,(roomCounts.get(x.room_type_id)||0)+1));
  setUnits((r||[]).map(x=>({...x,available_count:roomCounts.get(x.id)||0})));
 }catch(e){setError(e.message||'Unable to load property.')}finally{setLoading(false)}})()},[id]);
 const s=data?.settings||{},b=data?.business||{},c=data?.camp||{}; const isCamp=data?.type==='camp';
 const title=s.hotel_name||b.name||c.name||'Hospitality Property';
 const cover=s.cover_image_url||b.cover_image||'';const logo=s.logo_url||b.logo||'';
 const gallery=Array.isArray(s.gallery)?s.gallery:[];
 const destination=s.city||b.city||c.destination||'';
 const address=s.address||b.address||c.address||'';
 const bookHref=`/book/${id}?stay_type=${encodeURIComponent(data?.type||'hotel')}&check_in=${encodeURIComponent(checkIn)}&check_out=${encodeURIComponent(checkOut)}&adults=${adults}&children=${children}`;
 if(loading)return <main className="property-loading">Loading property…</main>;
 if(error||!data)return <main className="property-loading">{error||'Property not found.'}</main>;
 return <main className="property-page">
  <header className="property-hero" style={cover?{backgroundImage:`linear-gradient(90deg,rgba(8,28,20,.78),rgba(8,28,20,.22)),url("${cover}")`}:{}}>
   <div className="property-hero-inner">{logo&&<img className="property-logo" src={logo} alt={`${title} logo`}/>}<div className="property-kicker">ANAIRA {isCamp?'CAMPS':'HOSPITALITY'} · DIRECT BOOKING</div><h1>{title}</h1><p>{[destination,address].filter(Boolean).join(' · ')}</p><div className="property-contact">{s.phone||b.phone||''}{(s.email||b.email)?` · ${s.email||b.email}`:''}</div><a className="property-hero-cta" href="#availability">Check availability ↓</a></div>
  </header>
  <section className="property-booking" id="availability"><div><small>DIRECT {isCamp?'CAMPING':'STAY'} BOOKING</small><h2>Plan your {isCamp?'camping':'stay'}</h2></div><div className="property-fields"><label>Check-in<input type="date" value={checkIn} onChange={e=>setCheckIn(e.target.value)}/></label><label>Check-out<input type="date" min={checkIn} value={checkOut} onChange={e=>setCheckOut(e.target.value)}/></label><label>Adults<input type="number" min="1" value={adults} onChange={e=>setAdults(Math.max(1,Number(e.target.value)||1))}/></label><label>Children<input type="number" min="0" value={children} onChange={e=>setChildren(Math.max(0,Number(e.target.value)||0))}/></label><a className="property-book-btn" href={bookHref}>View availability & book →</a></div></section>
  {(s.description||c.description)&&<section className="property-about"><small>ABOUT {title.toUpperCase()}</small><h2>Welcome to {title}</h2><p>{s.description||c.description}</p></section>}
  <section className="property-units"><div className="property-section-head"><div><small>{isCamp?'CAMPS & TENTS':'ROOMS & ACCOMMODATION'}</small><h2>Choose your accommodation</h2></div><span>{units.length} options</span></div>
   {units.length?<div className="property-unit-grid">{units.map(u=><article className="property-unit" key={u.id}>{u.image_urls?.[0]&&<img src={u.image_urls[0]} alt={u.name}/>}<div><h3>{u.name}</h3><p>{u.description||u.short_description||`${u.max_adults||u.max_guests||2} adults${u.max_children?`, ${u.max_children} children`:''}`}</p><div className="property-unit-meta"><b>₹{Number(u.base_rate||0).toLocaleString('en-IN')}</b><span>{u.pricing_mode==='per_person'?'per person / night':'per unit / night'}</span><span>{u.available_count} {isCamp?'tents':'rooms'} configured</span></div></div></article>)}</div>:<p className="property-empty">Accommodation details are being updated. Please contact the property for availability.</p>}
  </section>
  {gallery.length>0&&<section className="property-gallery"><small>GALLERY</small><h2>Explore {title}</h2><div>{gallery.map((src,i)=><img key={`${src}-${i}`} src={src} alt={`${title} gallery ${i+1}`}/>)}</div></section>}
  <footer className="property-footer"><div><b>{title}</b><span>{address}</span></div><a href={bookHref}>Book directly →</a></footer>
  <style jsx>{`
  .property-page{min-height:100vh;background:#f7f4ed;color:#17372b;font-family:Arial,sans-serif}.property-loading{padding:100px 20px;text-align:center;color:#17372b}.property-hero{min-height:440px;background-color:#17372b;background-size:cover;background-position:center;display:flex;align-items:end;color:#fff}.property-hero-inner{width:min(1180px,calc(100% - 40px));margin:auto;padding:70px 0 60px}.property-logo{width:76px;height:76px;object-fit:cover;border-radius:16px;border:2px solid #fff;margin-bottom:18px}.property-kicker,.property-about small,.property-units small,.property-gallery small,.property-booking small{color:#d7b45d;font-size:10px;font-weight:900;letter-spacing:.18em}.property-hero h1{font:700 clamp(42px,6vw,76px)/1.05 Georgia,serif;margin:12px 0}.property-hero p,.property-contact{font-size:14px;color:#edf2ee}.property-hero-cta,.property-book-btn{display:inline-flex;margin-top:22px;padding:14px 22px;border-radius:10px;background:#d4ad52;color:#17372b;text-decoration:none;font-weight:900}.property-booking{width:min(1120px,calc(100% - 40px));margin:-35px auto 60px;position:relative;background:#fff;border:1px solid #e5dccb;border-radius:20px;padding:25px;box-shadow:0 20px 55px #17372b18}.property-booking h2,.property-about h2,.property-section-head h2,.property-gallery h2{font:700 34px Georgia,serif;margin:7px 0 20px}.property-fields{display:grid;grid-template-columns:1fr 1fr .65fr .65fr 1.2fr;gap:10px;align-items:end}.property-fields label{display:grid;gap:7px;font-size:11px;font-weight:800;color:#637168}.property-fields input{padding:13px;border:1px solid #ddd5c8;border-radius:10px;font:600 13px Arial}.property-book-btn{margin:0;justify-content:center;text-align:center}.property-about,.property-units,.property-gallery{width:min(1120px,calc(100% - 40px));margin:0 auto 60px}.property-about p{max-width:850px;color:#65736b;line-height:1.8}.property-section-head{display:flex;align-items:end;justify-content:space-between;margin-bottom:20px}.property-section-head h2{margin-bottom:0}.property-section-head>span{font-size:12px;color:#7a867f}.property-unit-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px}.property-unit{background:#fff;border:1px solid #e4dccf;border-radius:16px;overflow:hidden}.property-unit img{width:100%;height:210px;object-fit:cover}.property-unit>div{padding:18px}.property-unit h3{font:700 24px Georgia,serif;margin:0 0 8px}.property-unit p{font-size:12px;color:#68766e;min-height:30px}.property-unit-meta{display:flex;flex-wrap:wrap;align-items:center;gap:10px;border-top:1px solid #eee6da;padding-top:12px;font-size:11px;color:#66746b}.property-unit-meta b{font:700 22px Georgia,serif;color:#17372b}.property-empty{padding:28px;background:#fff;border-radius:14px;color:#65736b}.property-gallery>div{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}.property-gallery img{width:100%;height:230px;object-fit:cover;border-radius:14px}.property-footer{background:#17372b;color:#fff;padding:26px max(20px,calc((100% - 1120px)/2));display:flex;justify-content:space-between;gap:20px;align-items:center}.property-footer div{display:grid;gap:7px}.property-footer span{font-size:12px;color:#d2ddd6}.property-footer a{color:#e3bf6a;font-weight:800;text-decoration:none}@media(max-width:850px){.property-fields{grid-template-columns:1fr 1fr}.property-book-btn{min-height:46px}.property-unit-grid{grid-template-columns:1fr 1fr}}@media(max-width:560px){.property-hero{min-height:360px}.property-fields,.property-unit-grid,.property-gallery>div{grid-template-columns:1fr}.property-booking{width:calc(100% - 24px);padding:18px}.property-about,.property-units,.property-gallery{width:calc(100% - 24px)}.property-section-head{display:block}.property-footer{align-items:flex-start;flex-direction:column}}
  `}</style>
 </main>;
}
