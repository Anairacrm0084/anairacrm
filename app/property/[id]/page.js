'use client';
import {useEffect,useMemo,useState} from 'react';
import {useParams,useSearchParams} from 'next/navigation';
import {ArrowRight,MapPin,CalendarDays,Users,ShieldCheck,Wifi,Utensils,Car,Image as ImageIcon,Home,Hotel,Compass} from 'lucide-react';

const datePlus=n=>{const d=new Date();d.setDate(d.getDate()+n);return d.toISOString().slice(0,10)};
const safeDate=(value,fallback)=>/^\d{4}-\d{2}-\d{2}$/.test(value||'')?value:fallback;
const defaultTheme={primary_color:'#17372b',accent_color:'#c7a15a',background_color:'#f7f4ed',surface_color:'#ffffff',text_color:'#20362d'};

export default function HospitalityPropertyLanding(){
 const {id}=useParams();
 const search=useSearchParams();
 const [payload,setPayload]=useState(null),[loading,setLoading]=useState(true),[error,setError]=useState('');
 const [checkIn,setCheckIn]=useState(safeDate(search.get('check_in'),datePlus(1)));
 const [checkOut,setCheckOut]=useState(safeDate(search.get('check_out'),datePlus(2)));
 const [adults,setAdults]=useState(Math.max(1,Number(search.get('adults')||2)));
 const [children,setChildren]=useState(Math.max(0,Number(search.get('children')||0)));
 const requestedType=search.get('stay_type')||'';
 const requestedSource=search.get('booking_source')==='anaira-global-marketplace'?'anaira-global-marketplace':'anaira-property-store';

 useEffect(()=>{
  if(!id)return;
  let alive=true;
  (async()=>{
   setLoading(true);setError('');
   try{
    const qs=new URLSearchParams();if(requestedType)qs.set('stay_type',requestedType);
    const query=qs.toString();
    const response=await fetch(`/api/public/hospitality/property/${encodeURIComponent(id)}${query?`?${query}`:''}`,{cache:'no-store'});
    const result=await response.json();
    if(!response.ok||!result?.ok)throw new Error(result?.error||'This property is not available for public booking.');
    if(alive)setPayload(result);
   }catch(e){if(alive)setError(e.message||'Unable to load property storefront.');}
   finally{if(alive)setLoading(false);}
  })();
  return()=>{alive=false};
 },[id,requestedType]);

 const property=payload?.property||{};
 const store=payload?.public_store_config||{};
 const theme={...defaultTheme,...store};
 const type=property.hospitality_type||requestedType||'hotel';
 const isCamp=type==='camp';
 const title=property.title||property.hotel_name||'Hospitality Property';
 const coverCandidate=property.cover_url||property.cover_image_url||property.cover_image||'';
 const cover=/^https?:\/\//i.test(coverCandidate)?coverCandidate:'';
 const logo=property.logo_url||property.logo||'';
 const gallery=Array.isArray(property.gallery)?property.gallery:[];
 const heroGallery=gallery.filter(src=>src!==cover).slice(0,2);
 const remainingGallery=gallery.filter(src=>src!==cover).slice(2);
 const catalog=payload?.catalog||{rooms:[],rates:[]};
 const units=useMemo(()=>{
  const rooms=(catalog.rooms||[]).filter(r=>!r.hospitality_type||r.hospitality_type===type);
  return rooms.map(room=>{
   const rates=(catalog.rates||[]).filter(rate=>String(rate.room_type_id)===String(room.id)&&rate.active!==false);
   const rate=rates.sort((a,b)=>Number(a.rate||0)-Number(b.rate||0))[0];
   return {...room,selected_rate:rate||null,display_rate:Number(rate?.rate??room.base_rate??0)};
  });
 },[catalog,type]);
 const amenities=useMemo(()=>{
  const values=new Set();
  units.forEach(unit=>(Array.isArray(unit.amenities)?unit.amenities:[]).forEach(x=>values.add(x)));
  (Array.isArray(property.hospitality_highlights)?property.hospitality_highlights:[]).forEach(x=>values.add(typeof x==='string'?x:x?.title));
  return [...values].filter(Boolean).slice(0,12);
 },[units,property.hospitality_highlights]);
 const accommodationsHref='#accommodations';
 const checkoutHref=(unit,rate)=>{const q=new URLSearchParams({stay_type:type,room_type:String(unit.id),rate_plan:String(rate.id),check_in:checkIn,check_out:checkOut,adults:String(adults),children:String(children),booking_source:requestedSource});return `/property/${encodeURIComponent(id)}/checkout?${q.toString()}`;};
 const validDates=checkIn&&checkOut&&checkOut>checkIn;

 if(loading)return <main className="ps-loading">Loading property store…</main>;
 if(error||!payload)return <main className="ps-loading"><h1>Property store unavailable</h1><p>{error||'Property not found.'}</p><a href="/anaira/hotels">Explore Anaira Stays</a></main>;

 return <main className="property-storefront" style={{'--ps-primary':theme.primary_color,'--ps-accent':theme.accent_color,'--ps-bg':theme.background_color,'--ps-surface':theme.surface_color,'--ps-text':theme.text_color}}>
  {store.announcement&&<div className="ps-announcement">{store.announcement}</div>}
  <header className="ps-hero">
   <nav className="ps-nav"><a href="/anaira/hotels" className="ps-brand">ANAIRA STAYS</a><a href="#availability">Check availability <ArrowRight size={15}/></a></nav>
   <div className="ps-hero-layout"><div className="ps-hero-copy">{logo&&<img className="ps-logo" src={logo} alt={`${title} logo`}/>}<span className="ps-eyebrow">{isCamp?'ANAIRA CAMPS':'ANAIRA PRIVATE COLLECTION'} · DIRECT BOOKING</span><h1>{title}</h1><p>{property.tagline||property.description||'A considered stay, thoughtfully hosted. Discover the property and book directly.'}</p>{store.show_location!==false&&<div className="ps-location"><MapPin size={16}/>{[property.city,property.state,property.country].filter(Boolean).join(', ')||property.address||'Explore this destination'}</div>}<a className="ps-hero-cta" href="#availability">{store.hero_cta_label||'Check availability'} <ArrowRight size={16}/></a></div><div className={`ps-hero-mosaic ${heroGallery.length?'has-side':''}`}>{cover?<img className="ps-mosaic-main" src={cover} alt={`${title} property view`}/>:<div className="ps-mosaic-empty"><Home size={38}/><span>Welcome to {title}</span></div>}{heroGallery.map((src,i)=><img className={`ps-mosaic-side ps-mosaic-side-${i+1} ${heroGallery.length===1?'single':''}`} key={`${src}-${i}`} src={src} alt={`${title} view ${i+1}`}/>)}</div></div>
  </header>

  <section className="ps-booking" id="availability">
   <div><span className="ps-eyebrow dark">BOOK DIRECT</span><h2>Plan your {isCamp?'camping experience':'stay'}</h2><p>Choose your dates and guests to continue to the secure booking flow.</p></div>
   <div className="ps-fields">
    <label><CalendarDays size={15}/> Check-in<input type="date" value={checkIn} onChange={e=>setCheckIn(e.target.value)}/></label>
    <label><CalendarDays size={15}/> Check-out<input type="date" min={checkIn} value={checkOut} onChange={e=>setCheckOut(e.target.value)}/></label>
    <label><Users size={15}/> Adults<input type="number" min="1" max="30" value={adults} onChange={e=>setAdults(Math.max(1,Math.min(30,Number(e.target.value)||1)))}/></label>
    <label><Users size={15}/> Children<input type="number" min="0" max="20" value={children} onChange={e=>setChildren(Math.max(0,Math.min(20,Number(e.target.value)||0)))}/></label>
    <a className={`ps-book-btn ${!validDates?'disabled':''}`} href={validDates?accommodationsHref:'#availability'} aria-disabled={!validDates}>{store.hero_cta_label||'Check availability'} <ArrowRight size={16}/></a>
   </div>
  </section>

  {store.show_about!==false&&<section className="ps-about"><div><span className="ps-eyebrow dark">WELCOME</span><h2>Stay at {title}</h2><p>{property.description||'Explore the property, browse accommodation options and book directly through Anaira.'}</p>{store.show_location!==false&&property.address&&<p className="ps-address"><MapPin size={15}/>{property.address}</p>}</div><div className="ps-trust"><span><ShieldCheck/> Direct property booking</span><span><CalendarDays/> Live booking journey</span><span><Home/> Property-managed stay</span></div></section>}

  {store.show_units!==false&&<section className="ps-units" id="accommodations"><div className="ps-section-head"><div><span className="ps-eyebrow dark">{isCamp?'CAMPS & UNITS':'ROOMS & ACCOMMODATION'}</span><h2>Choose your accommodation</h2><p>Rates shown are starting rates from the active property rate plans. Final availability and total price are checked during booking.</p></div><span className="ps-count">{units.length} options</span></div>
   {units.length?<div className="ps-unit-grid">{units.map(unit=><article className="ps-unit" key={unit.id}>{unit.image_urls?.[0]?<img src={unit.image_urls[0]} alt={unit.name}/>:<div className="ps-unit-placeholder">{isCamp?<Compass size={32}/>:<Hotel size={32}/>}</div>}<div className="ps-unit-content"><h3>{unit.name}</h3><p>{unit.short_description||unit.description||`${unit.max_adults||unit.max_guests||2} guests maximum`}</p><div className="ps-unit-meta"><strong>₹{unit.display_rate.toLocaleString('en-IN')}</strong><span>/ {unit.selected_rate?.pricing_mode==='per_person'?'person':'unit'} / night</span></div>{unit.selected_rate&&<small>{unit.selected_rate.name||unit.selected_rate.code||'Available rate plan'}{unit.selected_rate.refundable?' · Refundable':''}</small>}{unit.selected_rate?<a href={checkoutHref(unit,unit.selected_rate)}>Continue to secure booking <ArrowRight size={15}/></a>:<span className="ps-rate-unavailable">Booking rate not configured</span>}</div></article>)}</div>:<div className="ps-empty">Accommodation options are being configured. Please contact the property for assistance.</div>}
  </section>}

  {store.show_amenities!==false&&amenities.length>0&&<section className="ps-amenities"><span className="ps-eyebrow dark">PROPERTY FEATURES</span><h2>What this property offers</h2><div>{amenities.map((item,i)=><span key={`${item}-${i}`}><ShieldCheck size={15}/>{item}</span>)}</div></section>}
  {store.show_gallery!==false&&remainingGallery.length>0&&<section className="ps-gallery"><span className="ps-eyebrow dark">GALLERY</span><h2>Explore {title}</h2><div>{remainingGallery.map((src,i)=><img key={`${src}-${i}`} src={src} alt={`${title} gallery ${i+1}`} loading="lazy"/>)}</div></section>}
  <footer className="ps-footer"><div><b>{title}</b><span>{store.show_location!==false?(property.address||property.city||''):null}</span>{store.footer_text&&<small>{store.footer_text}</small>}</div><div>{property.phone&&<a href={`tel:${property.phone}`}>{property.phone}</a>}{property.website&&<a href={property.website} target="_blank" rel="noreferrer">Property website</a>}</div><a className="ps-footer-cta" href={accommodationsHref}>Choose accommodation <ArrowRight size={15}/></a></footer>
  <style jsx>{`
   .property-storefront{min-height:100vh;background:var(--ps-bg);color:var(--ps-text);font-family:Arial,sans-serif}.ps-loading{min-height:60vh;display:grid;place-content:center;text-align:center;padding:30px;color:#17372b}.ps-loading a{color:#a47b2f;font-weight:800}.ps-announcement{background:var(--ps-primary);color:white;text-align:center;padding:10px 16px;font-size:12px;font-weight:700}.ps-hero{min-height:480px;background-color:var(--ps-primary);background-size:cover;background-position:center;display:flex;flex-direction:column;color:white}.ps-nav{width:min(1200px,calc(100% - 40px));margin:0 auto;padding:22px 0;display:flex;justify-content:space-between;align-items:center}.ps-nav a{color:white;text-decoration:none;font-size:13px;font-weight:800;display:flex;align-items:center;gap:8px}.ps-brand{letter-spacing:.14em}.ps-hero-copy{width:min(1200px,calc(100% - 40px));margin:auto;padding:65px 0 75px}.ps-logo{width:76px;height:76px;border-radius:18px;object-fit:cover;border:2px solid #ffffffaa;margin-bottom:18px}.ps-eyebrow{font-size:10px;letter-spacing:.17em;font-weight:900;color:var(--ps-accent)}.ps-eyebrow.dark{color:#9c7939}.ps-hero h1{font:700 clamp(40px,6vw,76px)/1.05 Georgia,serif;margin:14px 0;max-width:850px}.ps-hero-copy>p{max-width:720px;color:#f0f4f1;line-height:1.7}.ps-location{display:flex;align-items:center;gap:8px;font-size:13px;color:#e8eee9;margin-top:18px}.ps-booking{width:min(1160px,calc(100% - 36px));margin:-38px auto 62px;position:relative;background:var(--ps-surface);border:1px solid #e5ddcf;border-radius:20px;padding:25px;box-shadow:0 20px 55px #102a1e18}.ps-booking h2,.ps-about h2,.ps-section-head h2,.ps-amenities h2,.ps-gallery h2{font:700 32px Georgia,serif;margin:8px 0}.ps-booking p,.ps-section-head p{font-size:13px;color:#748077}.ps-fields{display:grid;grid-template-columns:repeat(4,minmax(100px,1fr)) minmax(170px,1.2fr);gap:10px;align-items:end;margin-top:20px}.ps-fields label{display:grid;grid-template-columns:16px 1fr;gap:7px;align-items:center;font-size:11px;font-weight:800;color:#637168}.ps-fields input{grid-column:1/-1;width:100%;box-sizing:border-box;padding:12px;border:1px solid #ded8cd;border-radius:10px;font:600 13px Arial;color:#243b30}.ps-book-btn{display:flex;align-items:center;justify-content:center;gap:8px;min-height:43px;padding:0 14px;border-radius:10px;background:var(--ps-accent);color:#17372b;text-decoration:none;font-size:12px;font-weight:900}.ps-book-btn.disabled{opacity:.5;pointer-events:none}.ps-about,.ps-units,.ps-amenities,.ps-gallery{width:min(1160px,calc(100% - 36px));margin:0 auto 62px}.ps-about{display:grid;grid-template-columns:1.4fr 1fr;gap:50px;align-items:center}.ps-about p{line-height:1.8;color:#68766e;max-width:800px}.ps-address{display:flex;align-items:center;gap:8px}.ps-trust{display:grid;gap:13px;background:var(--ps-surface);padding:22px;border-radius:16px;border:1px solid #e6dfd4}.ps-trust span{display:flex;align-items:center;gap:10px;font-size:12px;font-weight:700}.ps-trust :global(svg){width:17px;height:17px;color:#a17b37}.ps-section-head{display:flex;justify-content:space-between;align-items:end;margin-bottom:20px}.ps-count{font-size:12px;color:#758178}.ps-unit-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px}.ps-unit{background:var(--ps-surface);border:1px solid #e5ded2;border-radius:17px;overflow:hidden}.ps-unit>img,.ps-unit-placeholder{width:100%;height:210px;object-fit:cover}.ps-unit-placeholder{display:grid;place-items:center;background:#e9e7dd;color:var(--ps-primary)}.ps-unit-content{padding:18px}.ps-unit h3{font:700 23px Georgia,serif;margin:0 0 8px}.ps-unit p{font-size:12px;color:#6e7a72;min-height:32px;line-height:1.5}.ps-unit-meta{display:flex;align-items:baseline;gap:7px;border-top:1px solid #eee8df;padding-top:12px}.ps-unit-meta strong{font:700 22px Georgia,serif}.ps-unit-meta span,.ps-unit-content small{font-size:11px;color:#78847c}.ps-unit-content small{display:block;margin-top:7px}.ps-unit-content>a{display:flex;justify-content:space-between;align-items:center;margin-top:15px;padding:12px;border-radius:9px;background:var(--ps-primary);color:white;text-decoration:none;font-size:12px;font-weight:800}.ps-rate-unavailable{display:block;margin-top:15px;padding:12px;border-radius:9px;background:#f4eee5;color:#8b6a3a;font-size:11px;font-weight:800}.ps-empty{background:var(--ps-surface);border-radius:14px;padding:30px;color:#68766e}.ps-amenities>div{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-top:20px}.ps-amenities>div span{display:flex;align-items:center;gap:8px;background:var(--ps-surface);border:1px solid #e8e1d6;border-radius:10px;padding:13px;font-size:12px}.ps-amenities>div :global(svg){color:#a17b37}.ps-gallery>div{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-top:18px}.ps-gallery img{width:100%;height:230px;object-fit:cover;border-radius:14px}.ps-footer{background:var(--ps-primary);color:white;padding:28px max(18px,calc((100% - 1160px)/2));display:flex;justify-content:space-between;align-items:center;gap:20px}.ps-footer>div:first-child{display:grid;gap:7px}.ps-footer span,.ps-footer small{font-size:11px;color:#d8e1da}.ps-footer>div:nth-child(2){display:flex;gap:15px;flex-wrap:wrap}.ps-footer a{color:#f1d28a;text-decoration:none;font-size:12px;font-weight:800}.ps-footer-cta{display:flex;align-items:center;gap:8px;background:var(--ps-accent);color:#17372b!important;padding:12px 16px;border-radius:10px}@media(max-width:900px){.ps-fields{grid-template-columns:repeat(2,minmax(0,1fr))}.ps-book-btn{grid-column:1/-1}.ps-unit-grid{grid-template-columns:repeat(2,minmax(0,1fr))}.ps-about{grid-template-columns:1fr;gap:22px}}@media(max-width:600px){.ps-hero{min-height:390px}.ps-hero-copy{padding:45px 0 65px}.ps-booking{padding:18px}.ps-fields,.ps-unit-grid,.ps-amenities>div,.ps-gallery>div{grid-template-columns:1fr}.ps-section-head{align-items:start;gap:10px}.ps-footer{align-items:flex-start;flex-direction:column}.ps-footer>div:nth-child(2){flex-direction:column;gap:8px}}
  `}</style>
 </main>;
}
