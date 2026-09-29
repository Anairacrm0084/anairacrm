'use client';
import {useEffect,useState} from 'react';
import Link from 'next/link';
import {MapPin,Hotel,Home,House,CalendarDays,ArrowRight,ShieldCheck,Sparkles,ChevronRight,Star,Search,Compass,BadgeCheck,MapPinned,IndianRupee,CalendarCheck2,Headphones,SlidersHorizontal,LockKeyhole,BedDouble,Building2,CreditCard,FileCheck2,Bell,Heart,Globe2} from 'lucide-react';
import {supabase} from '../../../lib/supabase';

const defaults={
 hotel_marketplace_enabled:true,hotel_home_title:'Exceptional stays. Beautiful destinations.',hotel_home_subtitle:'Discover verified hotels, live room availability and direct booking experiences across ANAIRA.',
 hotel_home_show_search:true,hotel_home_show_banners:true,hotel_home_show_destinations:true,hotel_home_show_trust:true,hotel_home_show_footer:true,
 hotel_home_hero_image:'',hotel_home_hero_mobile_image:'',hotel_home_hero_overlay:'0.48',hotel_home_background_media_type:'image',hotel_home_background_image:'',hotel_home_background_video:'',hotel_home_background_mobile_media_type:'image',hotel_home_background_mobile_image:'',hotel_home_background_mobile_video:'',hotel_home_background_overlay:'0',hotel_home_hero_cta:'Explore hotels',hotel_home_hero_cta_url:'#hotels',
 hotel_home_primary_color:'#17372b',hotel_home_accent_color:'#c7a15a',hotel_home_background_color:'#f6f3ed',hotel_home_surface_color:'#ffffff',hotel_home_text_color:'#20362d',
 hotel_home_container_width:1240,hotel_home_card_radius:22,hotel_home_hotel_columns:3,hotel_home_destination_columns:5,
 hotel_home_destination_title:'Top destinations',hotel_home_destination_subtitle:'Explore the places guests are discovering across ANAIRA.',
 hotel_home_footer_text:'ANAIRA Hotels — discover stays, compare live availability and book with confidence.'
};

function datePlus(days){const d=new Date();d.setDate(d.getDate()+days);return d.toISOString().slice(0,10)}

export default function Hotels(){
 const [settings,setSettings]=useState(defaults),[banners,setBanners]=useState([]),[destinations,setDestinations]=useState([]),
 [q,setQ]=useState(''),[inDate,setInDate]=useState(''),[outDate,setOutDate]=useState(''),[adults,setAdults]=useState(2),[children,setChildren]=useState(0),
 [rows,setRows]=useState([]),[loading,setLoading]=useState(false),[msg,setMsg]=useState(''),[bannerIndex,setBannerIndex]=useState(0),[stayType,setStayType]=useState('hotel');
 const bannerSlides=banners.length?banners.map((_,i)=>[0,1,2].map(offset=>banners[(i+offset)%banners.length])):[];

 useEffect(()=>{(async()=>{
   const params=typeof window!=='undefined'?new URLSearchParams(window.location.search):null;
   const destinationParam=params?.get('destination')||'';
   const requestedType=['camp','homestay','guest_house','cottage'].includes(params?.get('stay_type'))?params.get('stay_type'):'hotel';
   setStayType(requestedType);
   const {data}=await supabase.from('anaira_platform_settings').select('key,value').in('key',Object.keys(defaults));
   const x={...defaults};(data||[]).forEach(r=>x[r.key]=r.value?.value??r.value);setSettings(x);
   if(destinationParam)setQ(destinationParam);
   const {data:s}=await supabase.from('anaira_platform_stores').select('id').eq('store_type','hotel').maybeSingle();
   if(s){
     const [{data:b},{data:d}]=await Promise.all([
       supabase.from('anaira_hotel_store_banners').select('*').eq('store_id',s.id).eq('active',true).order('display_order'),
       supabase.from('anaira_hotel_store_destinations').select('*').eq('store_id',s.id).eq('active',true).order('display_order')
     ]);
     setBanners(b||[]);setDestinations(d||[]);
   }
   const next=datePlus(1),after=datePlus(2);setInDate(next);setOutDate(after);
   setLoading(true);
   const initialRpc=requestedType==='hotel'?'anaira_marketplace_hotel_search':'anaira_marketplace_hms_hospitality_search';
   const initialArgs=requestedType==='hotel'?{p_check_in:next,p_check_out:after,p_adults:2,p_children:0,p_destination:destinationParam||null}:{p_hospitality_type:requestedType,p_check_in:next,p_check_out:after,p_adults:1,p_children:0,p_destination:destinationParam||null};
   const {data:live}=await supabase.rpc(initialRpc,initialArgs);
   setRows(live||[]);setLoading(false);
 })()},[]);

 useEffect(()=>{
   if(bannerSlides.length<2){setBannerIndex(0);return}
   const timer=setInterval(()=>setBannerIndex(i=>(i+1)%bannerSlides.length),5000);
   return()=>clearInterval(timer);
 },[bannerSlides.length]);
 function previousBanner(){setBannerIndex(i=>(i-1+bannerSlides.length)%bannerSlides.length)}
 function nextBanner(){setBannerIndex(i=>(i+1)%bannerSlides.length)}

 async function runSearch(type=stayType,destination=q,checkIn=inDate,checkOut=outDate){
   if(!checkIn||!checkOut){setMsg('Select check-in and check-out dates.');return}
   if(checkOut<=checkIn){setMsg('Check-out must be after check-in.');return}
   setLoading(true);setMsg('');
   const rpc=type==='hotel'?'anaira_marketplace_hotel_search':'anaira_marketplace_hms_hospitality_search';
   const rpcArgs=type==='hotel'?{p_check_in:checkIn,p_check_out:checkOut,p_adults:Math.max(1,Number(adults)||1),p_children:Math.max(0,Number(children)||0),p_destination:destination||null}:{p_hospitality_type:type,p_check_in:checkIn,p_check_out:checkOut,p_adults:Math.max(1,Number(adults)||1),p_children:Math.max(0,Number(children)||0),p_destination:destination||null};
   const {data,error}=await supabase.rpc(rpc,rpcArgs);
   setLoading(false);
   if(error){setRows([]);setMsg(error.message);return}
   setRows(data||[]);
   if(!(data||[]).length)setMsg(type==='camp'?`No published camps with live availability found${destination?` in ${destination}`:''}.`:`No published hotels with available room inventory were found${destination?` in ${destination}`:''}.`);
   document.getElementById('hotel-results')?.scrollIntoView({behavior:'smooth',block:'start'});
 }
 async function search(){return runSearch(stayType,q,inDate,outDate)}
 async function chooseDestination(name){setQ(name);setMsg('');const next=inDate||datePlus(1),after=outDate||datePlus(2);if(!inDate)setInDate(next);if(!outDate)setOutDate(after);return runSearch(stayType,name,next,after)}
 async function switchStayType(type){setStayType(type);setRows([]);setMsg('');return runSearch(type,q,inDate||datePlus(1),outDate||datePlus(2))}
 const css={
  '--hotel-primary':settings.hotel_home_primary_color||'#17372b','--hotel-accent':settings.hotel_home_accent_color||'#c7a15a',
  '--hotel-bg':settings.hotel_home_background_color||'#f6f3ed','--hotel-surface':settings.hotel_home_surface_color||'#fff',
  '--hotel-text':settings.hotel_home_text_color||'#20362d','--hotel-width':`${settings.hotel_home_container_width||1240}px`,
  '--hotel-radius':`${settings.hotel_home_card_radius||22}px`,'--hotel-cols':settings.hotel_home_hotel_columns||3,
  '--hotel-dest-cols':settings.hotel_home_destination_columns||5,'--hotel-overlay':settings.hotel_home_hero_overlay||.48
 };
 return <main className="hotel-market-pro hotel-market-full" style={css}>

  <section className="hotel-pro-hero">
   {(settings.hotel_home_background_media_type==='video'&&settings.hotel_home_background_video)||settings.hotel_home_background_image||settings.hotel_home_background_mobile_image||settings.hotel_home_background_mobile_video?
    <div className="hotel-pro-hero-background" aria-hidden="true">
      {settings.hotel_home_background_media_type==='video'&&settings.hotel_home_background_video?
        <video className="hotel-pro-bg-video hotel-pro-bg-desktop" src={settings.hotel_home_background_video} autoPlay muted loop playsInline/>:
        settings.hotel_home_background_image?<img className="hotel-pro-bg-image hotel-pro-bg-desktop" src={settings.hotel_home_background_image} alt=""/>:null}
      {(settings.hotel_home_background_mobile_media_type==='video'&&settings.hotel_home_background_mobile_video)?
        <video className="hotel-pro-bg-video hotel-pro-bg-mobile" src={settings.hotel_home_background_mobile_video} autoPlay muted loop playsInline/>:
        (settings.hotel_home_background_mobile_image||settings.hotel_home_background_image)?
        <img className="hotel-pro-bg-image hotel-pro-bg-mobile" src={settings.hotel_home_background_mobile_image||settings.hotel_home_background_image} alt=""/>:null}
      <span className="hotel-pro-hero-background-overlay" style={{opacity:Math.max(0,Math.min(1,Number(settings.hotel_home_background_overlay??0)))}}/>
    </div>:null}
   <div className="hotel-pro-hero-grid">
    <div className="hotel-pro-copy">
     <div className="hotel-pro-kicker"><Sparkles size={14}/> {stayType==='hotel'?'HOTELS':stayType==='camp'?'CAMPS':stayType==='homestay'?'HOMESTAYS':stayType==='guest_house'?'GUEST HOUSES':'COTTAGES'} • LIVE AVAILABILITY</div>
     <h1>{settings.hotel_home_title}</h1><p>{settings.hotel_home_subtitle}</p>
     {settings.hotel_home_show_search!==false&&<div className="hotel-pro-search-wrap" id="hotel-search">
     <div className="hotel-stay-switch" role="tablist" aria-label="Stay type">{[['hotel','Hotels',Hotel],['camp','Camps',Compass],['homestay','Homestays',Home],['guest_house','Guest Houses',Building2],['cottage','Cottages',House]].map(([v,l,I])=><button key={v} type="button" className={stayType===v?'active':''} onClick={()=>switchStayType(v)}><I size={16}/> {l}</button>)}</div>
     <div className="hotel-pro-search">
      <label><MapPin size={17}/><span>Destination<input value={q} onChange={e=>setQ(e.target.value)} placeholder="Kullu, Manali, Goa…"/></span></label>
      <label><CalendarDays size={17}/><span>Check-in<input type="date" value={inDate} onChange={e=>setInDate(e.target.value)}/></span></label>
      <label><CalendarDays size={17}/><span>Check-out<input type="date" value={outDate} onChange={e=>setOutDate(e.target.value)}/></span></label>
      <label>{stayType==='camp'?<Compass size={17}/>:<Hotel size={17}/>}<span>Guests<div className="hotel-pro-guests"><div className="hotel-pro-guest-field"><small>Adults</small><input aria-label="Adults" type="number" min="1" value={adults} onChange={e=>setAdults(e.target.value)}/></div><div className="hotel-pro-guest-field"><small>Children</small><input aria-label="Children" type="number" min="0" value={children} onChange={e=>setChildren(e.target.value)}/></div></div></span></label>
      <button onClick={search} disabled={loading}>{loading?'Searching…':`Search ${stayType==='hotel'?'hotels':stayType==='camp'?'camps':stayType==='guest_house'?'guest houses':stayType==='homestay'?'homestays':'cottages'}`} <ArrowRight size={16}/></button>
     </div></div>}
     <a className="hotel-pro-cta" href={settings.hotel_home_hero_cta_url||'#hotel-results'}>{settings.hotel_home_hero_cta||'Explore hotels'} <ChevronRight size={16}/></a>
    </div>
    {(settings.hotel_home_hero_media_type==='video'&&settings.hotel_home_hero_video)||settings.hotel_home_hero_image?
      <div className="hotel-pro-hero-media">
       {(settings.hotel_home_hero_mobile_media_type==='video'&&settings.hotel_home_hero_mobile_video)?
         <video className="hotel-pro-hero-media-mobile" src={settings.hotel_home_hero_mobile_video} autoPlay muted loop playsInline/>:
         (settings.hotel_home_hero_mobile_image||settings.hotel_home_hero_image)?<img className="hotel-pro-hero-media-mobile" src={settings.hotel_home_hero_mobile_image||settings.hotel_home_hero_image} alt="ANAIRA Hotels"/>:null}
       {settings.hotel_home_hero_media_type==='video'&&settings.hotel_home_hero_video?
         <video className="hotel-pro-hero-media-desktop" src={settings.hotel_home_hero_video} autoPlay muted loop playsInline/>:
         settings.hotel_home_hero_image?<img className="hotel-pro-hero-media-desktop" src={settings.hotel_home_hero_image} alt="ANAIRA Hotels"/>:null}
      </div>:
      <div className="hotel-pro-hero-placeholder"><div><Compass size={46}/><b>ANAIRA HOTELS</b><span>Curated stays • Live availability • Direct booking</span></div></div>}
   </div>
  </section>

  {settings.hotel_home_show_trust!==false&&<div className="hotel-pro-trust"><span><ShieldCheck size={16}/> Verified {stayType==='hotel'?'hotel':stayType==='camp'?'camp':stayType==='homestay'?'homestay':stayType==='guest_house'?'guest house':'cottage'} listings</span><span><CalendarDays size={16}/> Live availability</span><span><Hotel size={16}/> Direct inventory</span><span><Sparkles size={16}/> ANAIRA customer continuity</span></div>}

  <section className="hotel-pro-wrap">
   {settings.hotel_home_show_destinations!==false&&destinations.length>0&&<section className="hotel-pro-destinations">
    <div className="hotel-pro-section-head"><div><small>EXPLORE BY DESTINATION</small><h2>{settings.hotel_home_destination_title}</h2><p>{settings.hotel_home_destination_subtitle}</p></div><span>{destinations.length} curated places</span></div>
    <div className="hotel-destination-grid">
     {destinations.map(d=><button className="hotel-destination-card" key={d.id} onClick={()=>chooseDestination(d.name)}>
      <picture>{d.mobile_image_url&&<source media="(max-width:760px)" srcSet={d.mobile_image_url}/>}<img src={d.image_url} alt={d.name}/></picture>
      <div className="hotel-destination-overlay"><small>ANAIRA DESTINATION</small><strong>{d.name}</strong><span>{d.subtitle||'Discover stays'}</span><em>{stayType==='camp'?'Explore camps':(d.cta_label||'Explore hotels')} <ArrowRight size={14}/></em></div>
     </button>)}
    </div>
   </section>}


   <section className="hotel-pro-why" aria-label="Why book with Anaira Hotel and Camping Marketplace">
    <div className="hotel-pro-section-center"><small>EXPLORE · BOOK · STAY · WITH ANAIRA</small><h2>Why Book with Anaira Hotel & Camping Marketplace?</h2><p>More destinations, better stays, camps and a smoother booking experience for every traveler.</p></div>
    <div className="hotel-pro-feature-grid">
     <article><i><BadgeCheck size={22}/></i><b>Verified Hotels & Camps</b><span>Handpicked and verified properties</span></article>
     <article><i><MapPinned size={22}/></i><b>Top Destinations</b><span>Explore the best Himalayan locations</span></article>
     <article><i><IndianRupee size={22}/></i><b>Best Price Guarantee</b><span>Compare rates, plans and offers</span></article>
     <article><i><CalendarCheck2 size={22}/></i><b>Real-time Availability</b><span>Live room inventory and instant booking</span></article>
     <article><i><Headphones size={22}/></i><b>24×7 Support</b><span>Help throughout your booking journey</span></article>
     <article><i><SlidersHorizontal size={22}/></i><b>Flexible Booking</b><span>Easy cancellation and modified plans</span></article>
     <article><i><LockKeyhole size={22}/></i><b>Safe & Secure</b><span>Trusted booking and payment flow</span></article>
     <article><i><Compass size={22}/></i><b>Hotels, Camps & Experiences</b><span>Stay, camp and local experiences</span></article>
    </div>
   </section>

   {settings.hotel_home_show_banners!==false&&banners.length>0&&<section className="hotel-pro-banner-carousel" aria-label="Hotel promotions">
    <div className="hotel-pro-banner-viewport">
     <div className="hotel-pro-banner-track" style={{transform:`translate3d(-${bannerIndex*100}%,0,0)`}}>
      {bannerSlides.map((slide,slideIndex)=><div className="hotel-pro-banner-slide" key={`banner-slide-${slideIndex}`}>
       {slide.map(b=><a key={`${slideIndex}-${b.id}`} href={b.cta_url||'#hotel-results'} className="hotel-pro-banner">
        {b.media_type==='video'&&b.video_url?<video className="hotel-pro-banner-media hotel-pro-banner-desktop" src={b.video_url} autoPlay muted loop playsInline/>:<img className="hotel-pro-banner-media hotel-pro-banner-desktop" src={b.image_url} alt={b.title||''}/>}
        {b.mobile_media_type==='video'&&b.mobile_video_url?<video className="hotel-pro-banner-media hotel-pro-banner-mobile" src={b.mobile_video_url} autoPlay muted loop playsInline/>:<img className="hotel-pro-banner-media hotel-pro-banner-mobile" src={b.mobile_image_url||b.image_url} alt={b.title||''}/>}
        <span className="hotel-pro-banner-shade"/>
        <div className="hotel-pro-banner-content"><small>{b.subtitle||'ANAIRA Hotels'}</small><b>{b.title}</b>{b.cta_label&&<span>{b.cta_label}<ChevronRight size={14}/></span>}</div>
       </a>)}
      </div>)}
     </div>
     {bannerSlides.length>1&&<>
      <button type="button" className="hotel-banner-arrow hotel-banner-prev" onClick={previousBanner} aria-label="Previous banner">‹</button>
      <button type="button" className="hotel-banner-arrow hotel-banner-next" onClick={nextBanner} aria-label="Next banner">›</button>
      <div className="hotel-banner-dots">{bannerSlides.map((_,i)=><button type="button" key={i} className={i===bannerIndex?'active':''} onClick={()=>setBannerIndex(i)} aria-label={`Show banner set ${i+1}`}/>)}</div>
     </>}
    </div>
   </section>}   <section id="hotel-results">
    <div className="hotel-pro-section-head"><div><small>LIVE {stayType.replace('_',' ').toUpperCase()} DISCOVERY</small><h2>{q?`${stayType.replace('_',' ')}s in ${q}`:`Featured ${stayType.replace('_',' ')}s with live availability`}</h2><p>{stayType==='hotel'?'Rooms, availability and booking flow are sourced from the canonical Hotel Management System.':'Live availability, guest-based pricing and booking flow are sourced from the canonical Anaira stay engine.'}</p></div><span>{rows.length?`${rows.length} live results`:'No matching live results'}</span></div>
    {msg&&<div className="hotel-pro-message">{msg}</div>}
    {loading?<div className="hotel-pro-empty"><Search size={30}/><h3>Finding available {stayType==='camp'?'camps':'hotels'}…</h3><p>Checking live {stayType==='camp'?'camp':'room'} inventory.</p></div>:
     rows.length?<div className="hotel-pro-grid">{rows.map(x=>['homestay','guest_house','cottage'].includes(stayType)?<article className="hotel-pro-card" key={x.restaurant_id}><div className="hotel-pro-cover">{x.cover_image?<img src={x.cover_image} alt=""/>:<div><Home size={42}/></div>}<span>{stayType.replace('_',' ').toUpperCase()}</span><button aria-label="Stay property"><Star size={14}/></button></div><div className="hotel-pro-card-body"><div className="hotel-pro-location"><MapPin size={13}/>{x.destination||x.city||'Destination'}</div><h3>{x.property_name||x.name}</h3><p>Live availability · {x.pricing_mode==='per_person'?'Per-person pricing':'Per-unit pricing'} · Secure booking</p><div className="hotel-pro-stats"><span>{x.available_units||0} available</span><span>From ₹{Number(x.rate||0).toLocaleString('en-IN')} / {x.pricing_mode==='per_person'?'person':'unit'}</span></div><Link className="hotel-pro-book" href={`/book/${x.restaurant_id}?stay_type=${stayType}&check_in=${inDate}&check_out=${outDate}&adults=${adults}&children=${children}`}>View & book <ArrowRight size={15}/></Link></div></article>:stayType==='camp'?<article className="hotel-pro-card" key={x.restaurant_id}><div className="hotel-pro-cover">{x.cover_image?<img src={x.cover_image} alt=""/>:<div><Compass size={42}/></div>}<span>LIVE CAMP</span><button aria-label="Camping property"><Star size={14}/></button></div><div className="hotel-pro-card-body"><div className="hotel-pro-location"><MapPin size={13}/>{x.destination||x.city||x.address||'Destination'}</div><h3>{x.property_name||x.name||x.name}</h3><p>{x.description||'Live camps · Per-person pricing · Secure booking'}</p><div className="hotel-pro-stats"><span>{x.available_units||0} camp types</span><span>From ₹{Number(x.rate||0).toLocaleString('en-IN')} / person</span></div><Link className="hotel-pro-book" href={`/book/${x.restaurant_id}?stay_type=${stayType}&check_in=${inDate}&check_out=${outDate}&adults=${adults}&children=${children}`}>View camps & book <ArrowRight size={15}/></Link></div></article>:<article className="hotel-pro-card" key={x.restaurant_id}><div className="hotel-pro-cover">{(x.listing_override?.cover_url||x.cover_image)?<img src={x.listing_override?.cover_url||x.cover_image} alt=""/>:<div><Hotel size={42}/></div>}<span>LIVE HOTEL</span><button aria-label="Featured hotel"><Star size={14}/></button></div><div className="hotel-pro-card-body"><div className="hotel-pro-location"><MapPin size={13}/>{x.city||x.address||'Destination'}</div><h3>{x.listing_override?.title||x.hotel_name}</h3><p>{x.listing_override?.tagline||'Live rooms · Direct booking · Secure guest journey'}</p><div className="hotel-pro-stats"><span>{x.available_room_types||0} room types</span><span>{inDate} → {outDate}</span></div><Link className="hotel-pro-book" href={`/book/${x.restaurant_id}?stay_type=${stayType}&check_in=${inDate}&check_out=${outDate}&adults=${adults}&children=${children}`}>View rooms & book <ArrowRight size={15}/></Link></div></article>)}</div>:
     <div className="hotel-pro-empty"><Hotel size={30}/><h3>Search live {stayType==='hotel'?'hotel':stayType==='camp'?'camping':stayType==='guest_house'?'guest house':stayType==='homestay'?'homestay':'cottage'} inventory</h3><p>Choose dates and a destination above. Results are always sourced from the published inventory for the selected stay type.</p></div>}
   </section>
  </section>

  <section className="hotel-pro-about" aria-label="About Anaira Hotel Engine">
   <div className="hotel-pro-about-copy">
    <small>ABOUT ANAIRA HOTEL & CAMPING ENGINE</small>
    <h2>A New Generation<br/>Hospitality Platform</h2>
    <div className="hotel-pro-gold-line"/>
    <p><strong>Anaira Graphics & Digital Solution</strong> is a technology and digital solutions company established in <strong>2013</strong>, serving businesses with creative, digital, web and technology solutions.</p>
    <p>With years of experience working with businesses, particularly in the hospitality and local-business ecosystem, Anaira has now expanded into <strong>hospitality technology</strong> with its own Hotel Booking Engine, Camping Booking Engine and combined Hotel & Camping Marketplace platform.</p>
    <h3>Built for Hotels. Designed for Travelers.</h3>
    <p>Our goal is to create a connected hospitality ecosystem where <strong>hotels can manage their digital booking presence</strong> and travelers can discover and book suitable properties through a simple and transparent experience.</p>
   </div>
   <div className="hotel-pro-about-media">
    {settings.hotel_home_hero_media_type==='video'&&settings.hotel_home_hero_video?<video className="hotel-about-desktop" src={settings.hotel_home_hero_video} autoPlay muted loop playsInline/>:settings.hotel_home_hero_image?<img className="hotel-about-desktop" src={settings.hotel_home_hero_image} alt="Anaira Hotel Engine"/>:null}
    {settings.hotel_home_hero_mobile_media_type==='video'&&settings.hotel_home_hero_mobile_video?<video className="hotel-about-mobile" src={settings.hotel_home_hero_mobile_video} autoPlay muted loop playsInline/>:(settings.hotel_home_hero_mobile_image||settings.hotel_home_hero_image)?<img className="hotel-about-mobile" src={settings.hotel_home_hero_mobile_image||settings.hotel_home_hero_image} alt="Anaira Hotel Engine"/>:null}
   </div>
  </section>

  <div className="hotel-pro-about-stats">
   <article><i><CalendarCheck2 size={20}/></i><div><b>2013</b><span>Company established</span></div></article>
   <article><i><Building2 size={20}/></i><div><b>100+ Hotels</b><span>Connected hotel partners</span></div></article>
   <article><i><Compass size={20}/></i><div><b>50+ Camps</b><span>Camping stays across destinations</span></div></article>
   <article><i><Heart size={20}/></i><div><b>Thousands of Travelers</b><span>Hotels, camps and experiences</span></div></article>
  </div>

  <section className="hotel-pro-workflow" aria-label="Anaira Hotel and Camping Engine workflow">
   <div className="hotel-pro-section-center"><small>HOW ANAIRA WORKS</small><h2>From Search to Stay / Camp — Simplified</h2><p>A complete booking experience for hotels and camps, with real-time availability, flexible pricing and secure booking.</p></div>
   <div className="hotel-pro-workflow-grid">
    <article><i><Search size={21}/></i><b>Search Destinations</b><span>Find hotels in your favorite locations</span></article>
    <article><i><Building2 size={21}/></i><b>Explore Options</b><span>View hotels, camps, photos, amenities and reviews</span></article>
    <article><i><BedDouble size={21}/></i><b>Select Rooms / Tents</b><span>Choose rooms or tents for 1 or more guests</span></article>
    <article><i><CalendarCheck2 size={21}/></i><b>Check Availability</b><span>Live inventory and dynamic pricing</span></article>
    <article><i><CreditCard size={21}/></i><b>Book & Pay</b><span>Easy and secure online booking</span></article>
    <article><i><FileCheck2 size={21}/></i><b>Get Confirmation</b><span>Instant booking confirmation</span></article>
    <article><i><Bell size={21}/></i><b>Manage Your Stay</b><span>Modify or cancel when needed</span></article>
    <article><i><Heart size={21}/></i><b>Enjoy Your Journey</b><span>Comfortable stays, camps and great experiences</span></article>
   </div>
  </section>

  <section className="hotel-pro-tech">
   <div><small>OUR HOSPITALITY TECHNOLOGY</small><h2>One connected hotel & camping ecosystem.</h2><p>Hotel rooms and camping tents use separate operational inventory, while the marketplace connects destination search, live availability, pricing, guest verification, payments, confirmations and booking management through one consistent guest journey.</p></div>
   <div className="hotel-pro-tech-pills"><span><MapPinned size={16}/> Destination search</span><span><BedDouble size={16}/> Rooms & rates</span><span><Compass size={16}/> Camps & tents</span><span><CalendarCheck2 size={16}/> Live availability</span><span><IndianRupee size={16}/> Smart pricing</span><span><CreditCard size={16}/> Payments</span><span><ShieldCheck size={16}/> Secure booking</span></div>
  </section>

  {settings.hotel_home_show_footer!==false&&<footer className="hotel-pro-footer"><b>ANAIRA HOTELS</b><span>{settings.hotel_home_footer_text}</span><Link href="/anaira/platform">ANAIRA Platform</Link></footer>}

<style jsx>{`
.hotel-pro-search-wrap{width:100%}.hotel-stay-switch{display:flex;gap:6px;margin:0 0 8px}.hotel-stay-switch button{display:inline-flex;align-items:center;gap:7px;border:1px solid rgba(255,255,255,.5);background:rgba(255,255,255,.92);color:#17372b;border-radius:999px;padding:8px 14px;font:800 11px Montserrat,Arial,sans-serif;cursor:pointer}.hotel-stay-switch button.active{background:#17372b;color:#fff;border-color:#17372b}.hotel-pro-search{display:grid;grid-template-columns:minmax(235px,1.35fr) minmax(155px,1fr) minmax(155px,1fr) minmax(170px,1.05fr) auto;align-items:stretch;padding:9px;gap:8px;border:1px solid rgba(255,255,255,.5);border-radius:22px;background:rgba(255,255,255,.96);box-shadow:0 22px 65px rgba(0,0,0,.24),0 4px 16px rgba(0,0,0,.10);backdrop-filter:blur(14px);overflow:hidden}
.hotel-pro-search label{min-width:0;margin:0;border:1px solid #e7ece7;border-radius:15px;background:#fff;padding:10px 13px;display:flex;align-items:center;gap:10px;box-shadow:inset 0 1px 0 rgba(255,255,255,.8);transition:border-color .2s ease,box-shadow .2s ease}
.hotel-pro-search label:focus-within{border-color:#c7a15a;box-shadow:0 0 0 3px rgba(199,161,90,.12)}
.hotel-pro-search label>svg{flex:0 0 auto;color:#a17b32}
.hotel-pro-search label span{min-width:0;width:100%;display:block;color:#6f776f;font-size:9px;font-weight:800;letter-spacing:.08em;text-transform:uppercase}
.hotel-pro-search input{display:block;width:100%;max-width:100%;margin-top:4px;padding:0;border:0;outline:0;background:transparent;color:#17372b;font:700 12px/1.25 Montserrat,Arial,sans-serif;min-width:0}
.hotel-pro-search input::placeholder{color:#849087;opacity:1}
.hotel-pro-search input[type=date]{font-size:11px;color:#17372b}
.hotel-pro-search button{min-width:148px;align-self:stretch;justify-content:center;gap:8px;padding:0 20px;border:0;border-radius:15px;background:linear-gradient(135deg,#d4b15f,#b98d35);color:#17372b;font:800 12px Montserrat,Arial,sans-serif;letter-spacing:.01em;box-shadow:0 9px 22px rgba(145,111,43,.28);cursor:pointer;transition:transform .2s ease,box-shadow .2s ease}
.hotel-pro-search button:hover:not(:disabled){transform:translateY(-1px);box-shadow:0 13px 28px rgba(145,111,43,.34)}
.hotel-pro-search button:disabled{opacity:.72;cursor:wait}
.hotel-pro-guests{display:grid;grid-template-columns:1fr 1fr;gap:7px;margin-top:4px}
.hotel-pro-guests input{margin:0;background:#f3f6f2;border-radius:8px;padding:5px 6px;text-align:center;border:1px solid #e5ebe5}
.hotel-pro-banner-carousel{position:relative;margin-bottom:38px}
 .hotel-pro-banner-viewport{position:relative;overflow:hidden;border-radius:var(--hotel-radius);box-shadow:0 20px 55px rgba(20,40,30,.12);background:transparent}
 .hotel-pro-banner-track{display:flex;width:100%;transition:transform .72s cubic-bezier(.22,.61,.36,1);will-change:transform}
 .hotel-pro-banner-slide{flex:0 0 100%;width:100%;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px;padding:0}
 .hotel-pro-banner-track .hotel-pro-banner{position:relative;min-width:0;min-height:330px;overflow:hidden;text-decoration:none;border-radius:18px;background:transparent}
 .hotel-pro-banner-track .hotel-pro-banner-media{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
 .hotel-pro-banner-track .hotel-pro-banner-shade{position:absolute;inset:0;background:linear-gradient(90deg,rgba(6,35,26,.78),rgba(6,35,26,.24) 58%,rgba(6,35,26,.08))}
 .hotel-pro-banner-track .hotel-pro-banner-content{position:absolute;z-index:2;left:clamp(22px,5vw,58px);right:clamp(22px,5vw,58px);bottom:clamp(22px,5vw,52px);display:flex;flex-direction:column;align-items:flex-start;gap:8px;color:#fff;max-width:720px}
 .hotel-pro-banner-track .hotel-pro-banner-content small{font-size:11px;letter-spacing:.14em;text-transform:uppercase;opacity:.86}
 .hotel-pro-banner-track .hotel-pro-banner-content b{font-size:clamp(24px,3.2vw,46px);line-height:1.04}
 .hotel-pro-banner-track .hotel-pro-banner-content>span{display:inline-flex;align-items:center;gap:6px;background:#c7a15a;color:#17372b;border-radius:999px;padding:9px 14px;font-size:12px;font-weight:800}
 .hotel-banner-arrow{position:absolute;top:50%;transform:translateY(-50%);z-index:5;width:44px;height:44px;border-radius:50%;border:1px solid rgba(255,255,255,.55);background:rgba(10,35,27,.62);color:#fff;font-size:30px;line-height:1;display:grid;place-items:center;cursor:pointer;backdrop-filter:blur(8px);box-shadow:0 8px 22px rgba(0,0,0,.18)}
 .hotel-banner-arrow:hover{background:rgba(199,161,90,.96);color:#17372b}
 .hotel-banner-prev{left:16px}.hotel-banner-next{right:16px}
 .hotel-banner-dots{position:absolute;z-index:6;left:50%;bottom:16px;transform:translateX(-50%);display:flex;gap:7px;align-items:center}
 .hotel-banner-dots button{width:8px;height:8px;border:0;border-radius:50%;padding:0;background:rgba(255,255,255,.58);cursor:pointer;transition:all .25s ease}
 .hotel-banner-dots button.active{width:25px;border-radius:999px;background:#c7a15a}
 @media(max-width:1200px){.hotel-pro-search{grid-template-columns:minmax(200px,1.25fr) minmax(140px,1fr) minmax(140px,1fr) minmax(150px,1fr) auto}.hotel-pro-search button{min-width:132px;padding:0 15px}}
 @media(max-width:1050px){.hotel-pro-search{grid-template-columns:repeat(2,minmax(0,1fr))}.hotel-pro-search button{min-height:54px}.hotel-pro-banner-slide{grid-template-columns:repeat(2,minmax(0,1fr))}.hotel-pro-banner-track .hotel-pro-banner{min-height:330px}}
 @media(max-width:700px){.hotel-pro-search{grid-template-columns:1fr;padding:8px;border-radius:18px}.hotel-pro-search label{border:1px solid #e7ece7;min-height:52px}.hotel-pro-search button{min-height:54px}.hotel-pro-banner-slide{grid-template-columns:1fr}.hotel-pro-banner-viewport{border-radius:18px}.hotel-pro-banner-track .hotel-pro-banner{min-height:250px}.hotel-banner-arrow{width:36px;height:36px;font-size:25px}.hotel-banner-prev{left:10px}.hotel-banner-next{right:10px}}

/* FINAL PREMIUM HERO / SEARCH REFINEMENT */
.hotel-pro-hero{background:transparent;min-height:0;padding-top:18px;padding-bottom:34px}
.hotel-pro-hero-background-overlay{position:absolute;inset:0;background:#062a1c;pointer-events:none;display:block!important;z-index:1}.hotel-pro-hero-background img,.hotel-pro-hero-background video{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}.hotel-pro-hero-grid{position:relative;z-index:2}
.hotel-pro-hero-grid{grid-template-columns:1fr;gap:0;max-width:var(--hotel-width);margin:34px auto 0;align-items:start}
.hotel-pro-copy{width:100%;max-width:none}
.hotel-pro-copy h1{max-width:900px}
.hotel-pro-copy p{max-width:820px}
.hotel-pro-search{width:100%;box-sizing:border-box;grid-template-columns:minmax(0,1.55fr) minmax(155px,1fr) minmax(155px,1fr) minmax(185px,1.05fr) minmax(145px,auto);margin-top:22px;padding:9px;gap:8px;overflow:visible}
.hotel-pro-search label{min-width:0;height:68px;box-sizing:border-box;padding:10px 13px;overflow:hidden}
.hotel-pro-search label span{min-width:0;overflow:hidden}
.hotel-pro-search input{font-size:12px;line-height:1.25;text-overflow:ellipsis}
.hotel-pro-search input[type=date]{font-size:11px;min-width:0}
.hotel-pro-search button{height:68px;min-width:145px}
.hotel-pro-guests{display:grid!important;grid-template-columns:1fr 1fr;gap:7px!important;margin-top:4px;width:100%}
.hotel-pro-guest-field{display:grid;grid-template-columns:auto 1fr;align-items:center;gap:5px;min-width:0;background:#f3f6f2;border:1px solid #e5ebe5;border-radius:8px;padding:3px 6px}
.hotel-pro-guest-field small{font-size:8px;font-weight:800;color:#7b857e;text-transform:uppercase;letter-spacing:.04em;white-space:nowrap}
.hotel-pro-guest-field input{background:transparent!important;border:0!important;padding:2px!important;text-align:center!important;min-width:24px}
.hotel-pro-hero-media{display:none}
.hotel-pro-hero-placeholder{display:none}
.hotel-pro-banner-carousel{margin-top:8px}
.hotel-pro-banner-track .hotel-pro-banner{min-height:350px}
@media(max-width:1180px){
 .hotel-pro-search{grid-template-columns:minmax(0,1.4fr) minmax(135px,1fr) minmax(135px,1fr) minmax(165px,1.05fr) minmax(132px,auto)}
 .hotel-pro-search button{min-width:132px}
}
@media(max-width:900px){
 .hotel-pro-search{grid-template-columns:repeat(2,minmax(0,1fr))}
 .hotel-pro-search button{min-height:56px;height:56px}
 .hotel-pro-search label{height:60px}
}
@media(max-width:700px){
 .hotel-pro-hero{padding-bottom:24px}
 .hotel-pro-hero-grid{margin-top:24px}
 .hotel-pro-search{grid-template-columns:1fr;padding:8px}
 .hotel-pro-search label{height:58px}
 .hotel-pro-search button{height:56px}
 .hotel-pro-banner-track .hotel-pro-banner{min-height:250px}
}

/* ANAIRA MARKETPLACE CONTENT SECTIONS */
.hotel-pro-why{margin:34px auto 42px;width:min(var(--hotel-width),calc(100vw - 56px));padding:8px 0 0}
.hotel-pro-section-center{text-align:center;margin:0 auto 24px;max-width:900px}
.hotel-pro-section-center small,.hotel-pro-about-copy>small,.hotel-pro-tech small{display:block;color:#a17b32;font-size:10px;font-weight:900;letter-spacing:.18em;text-transform:uppercase}
.hotel-pro-section-center h2{margin:7px 0 5px;font:700 clamp(28px,3vw,43px)/1.08 Georgia,serif;color:#17372b}
.hotel-pro-section-center p{margin:0;color:#66736c;font-size:13px;line-height:1.65}
.hotel-pro-feature-grid{display:grid;grid-template-columns:repeat(8,minmax(0,1fr));gap:10px}
.hotel-pro-feature-grid article{min-height:145px;border:1px solid #e7e1d4;background:#fff;border-radius:15px;padding:20px 12px 15px;display:flex;flex-direction:column;align-items:center;text-align:center;box-shadow:0 8px 22px rgba(23,55,43,.035);transition:transform .2s ease,box-shadow .2s ease,border-color .2s ease}
.hotel-pro-feature-grid article:hover{transform:translateY(-3px);box-shadow:0 15px 34px rgba(23,55,43,.09);border-color:#dbc58e}
.hotel-pro-feature-grid i,.hotel-pro-about-stats i,.hotel-pro-workflow i{width:48px;height:48px;border-radius:50%;display:grid;place-items:center;color:#b18425;background:#fbf5e5;border:1px solid #ead49d;flex:0 0 auto}
.hotel-pro-feature-grid b{margin-top:13px;color:#172d25;font-size:12px;line-height:1.25}
.hotel-pro-feature-grid span{margin-top:6px;color:#6d7871;font-size:10px;line-height:1.4}

.hotel-pro-about{width:min(var(--hotel-width),calc(100vw - 56px));margin:56px auto 0;display:grid;grid-template-columns:1fr 1.18fr;min-height:390px;border:1px solid #e5dcc9;border-left:4px solid #d1a83f;border-radius:22px;overflow:hidden;background:linear-gradient(135deg,#fffefb,#f6f2e8);box-shadow:0 18px 48px rgba(24,43,34,.08)}
.hotel-pro-about-copy{padding:48px 46px 42px;display:flex;flex-direction:column;justify-content:center}
.hotel-pro-about-copy h2{margin:9px 0 9px;font:700 clamp(31px,3.3vw,50px)/1.05 Georgia,serif;color:#142d24}
.hotel-pro-gold-line{width:52px;height:3px;background:#d2a93e;margin:7px 0 18px}
.hotel-pro-about-copy p{max-width:570px;margin:0 0 12px;color:#4f6259;font-size:13px;line-height:1.72}
.hotel-pro-about-copy h3{margin:13px 0 4px;color:#a17b32;font-size:13px}
.hotel-pro-about-media{position:relative;min-height:390px;background:transparent;overflow:hidden}
.hotel-pro-about-media img,.hotel-pro-about-media video{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;display:block}
.hotel-about-mobile{display:none!important}
.hotel-pro-about-quote{display:none!important;position:absolute;z-index:3;left:-102px;top:50%;transform:translateY(-50%);width:205px;min-height:176px;padding:26px 22px;box-sizing:border-box;border-radius:16px;background:#101d19;color:#fff;box-shadow:0 18px 40px rgba(0,0,0,.24);display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center}
.hotel-pro-about-quote span{font:700 42px/1 Georgia,serif;color:#d2a93e;height:34px}
.hotel-pro-about-quote b{font:700 15px/1.45 Georgia,serif}
.hotel-pro-about-quote em{display:block;width:36px;height:2px;background:#d2a93e;margin-top:16px}
.hotel-pro-about-stats{width:min(var(--hotel-width),calc(100vw - 56px));margin:0 auto 44px;display:grid;grid-template-columns:repeat(4,1fr);gap:10px;position:relative;z-index:4}
.hotel-pro-about-stats article{margin-top:-1px;background:#fffdf8;border:1px solid #e5dcc9;border-radius:14px;padding:15px 18px;display:flex;align-items:center;gap:12px;box-shadow:0 8px 22px rgba(23,55,43,.05)}
.hotel-pro-about-stats article b{display:block;color:#172d25;font-size:14px;line-height:1.2}
.hotel-pro-about-stats article span{display:block;color:#6c7771;font-size:10px;margin-top:4px}

.hotel-pro-workflow{width:min(var(--hotel-width),calc(100vw - 56px));margin:0 auto 34px;border:1px solid #e5dcc9;border-radius:20px;background:#fffdf9;padding:32px 22px 28px}
.hotel-pro-workflow-grid{display:grid;grid-template-columns:repeat(8,minmax(0,1fr));gap:4px}
.hotel-pro-workflow-grid article{position:relative;text-align:center;padding:4px 8px 5px;display:flex;flex-direction:column;align-items:center;min-width:0}
.hotel-pro-workflow-grid article:not(:last-child)::after{content:'';position:absolute;right:-2px;top:27px;width:24px;border-top:2px dotted #e0bd68}
.hotel-pro-workflow-grid b{margin-top:9px;color:#172d25;font-size:11px;line-height:1.2}
.hotel-pro-workflow-grid span{margin-top:5px;color:#69756e;font-size:9px;line-height:1.4;max-width:120px}

.hotel-pro-tech{width:min(var(--hotel-width),calc(100vw - 56px));margin:0 auto 45px;padding:30px 34px;border-radius:20px;background:linear-gradient(135deg,#0d2d22,#173b2d 58%,#244b39);color:#fff;display:grid;grid-template-columns:1.2fr .8fr;gap:28px;align-items:center;box-shadow:0 20px 50px rgba(14,45,34,.18)}
.hotel-pro-tech h2{margin:7px 0 9px;font:700 clamp(25px,2.5vw,37px)/1.1 Georgia,serif}
.hotel-pro-tech p{margin:0;color:#c9d7d0;font-size:12px;line-height:1.7;max-width:800px}
.hotel-pro-tech-pills{display:grid;grid-template-columns:repeat(2,1fr);gap:8px}
.hotel-pro-tech-pills span{display:flex;align-items:center;gap:7px;padding:11px 12px;border:1px solid rgba(224,191,104,.28);border-radius:10px;background:rgba(255,255,255,.05);color:#f2e5c0;font-size:10px;font-weight:800}
.hotel-pro-tech-pills svg{color:#d6b257}

@media(max-width:1200px){
 .hotel-pro-feature-grid{grid-template-columns:repeat(4,1fr)}
 .hotel-pro-workflow-grid{grid-template-columns:repeat(4,1fr);row-gap:22px}
 .hotel-pro-workflow-grid article:nth-child(4)::after,.hotel-pro-workflow-grid article:nth-child(8)::after{display:none}
 .hotel-pro-about-quote{left:-75px}
}
@media(max-width:900px){
 .hotel-pro-why,.hotel-pro-about,.hotel-pro-about-stats,.hotel-pro-workflow,.hotel-pro-tech{width:calc(100vw - 32px)}
 .hotel-pro-feature-grid{grid-template-columns:repeat(2,1fr)}
 .hotel-pro-about{grid-template-columns:1fr;min-height:0}
 .hotel-pro-about-media{min-height:350px;order:-1}
 .hotel-pro-about-quote{left:24px;top:auto;bottom:20px;transform:none;width:230px;min-height:130px;padding:20px}
 .hotel-pro-about-stats{grid-template-columns:repeat(2,1fr)}
 .hotel-pro-tech{grid-template-columns:1fr}
}
@media(max-width:700px){
 .hotel-pro-why{margin-top:28px}
 .hotel-pro-section-center{margin-bottom:18px}
 .hotel-pro-feature-grid{grid-template-columns:1fr 1fr;gap:8px}
 .hotel-pro-feature-grid article{min-height:132px;padding:15px 9px 12px}
 .hotel-pro-feature-grid i{width:42px;height:42px}
 .hotel-pro-feature-grid b{font-size:11px}
 .hotel-pro-about{margin-top:38px;border-radius:16px}
 .hotel-pro-about-copy{padding:30px 22px}
 .hotel-pro-about-media{min-height:280px}
 .hotel-about-desktop{display:none!important}
 .hotel-about-mobile{display:block!important}
 .hotel-pro-about-quote{left:14px;bottom:14px;width:calc(100% - 28px);min-height:auto}
 .hotel-pro-about-stats{grid-template-columns:1fr;margin-bottom:30px}
 .hotel-pro-about-stats article{padding:13px 14px}
 .hotel-pro-workflow{padding:25px 12px 18px}
 .hotel-pro-workflow-grid{grid-template-columns:repeat(2,1fr);gap:20px 5px}
 .hotel-pro-workflow-grid article:not(:last-child)::after{display:none}
 .hotel-pro-tech{padding:25px 20px;border-radius:16px}
 .hotel-pro-tech-pills{grid-template-columns:1fr}
}
`}</style>


 </main>
}