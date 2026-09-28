'use client';
import {useEffect,useState} from 'react';
import Link from 'next/link';
import {MapPin,Hotel,CalendarDays,ArrowRight,ShieldCheck,Sparkles,ChevronRight,Star,Search,Compass} from 'lucide-react';
import {supabase} from '../../../lib/supabase';

const defaults={
 hotel_marketplace_enabled:true,hotel_home_title:'Exceptional stays. Beautiful destinations.',hotel_home_subtitle:'Discover verified hotels, live room availability and direct booking experiences across ANAIRA.',
 hotel_home_show_search:true,hotel_home_show_banners:true,hotel_home_show_destinations:true,hotel_home_show_trust:true,hotel_home_show_footer:true,
 hotel_home_hero_image:'',hotel_home_hero_mobile_image:'',hotel_home_hero_overlay:'0.48',hotel_home_hero_cta:'Explore hotels',hotel_home_hero_cta_url:'#hotels',
 hotel_home_primary_color:'#17372b',hotel_home_accent_color:'#c7a15a',hotel_home_background_color:'#f6f3ed',hotel_home_surface_color:'#ffffff',hotel_home_text_color:'#20362d',
 hotel_home_container_width:1240,hotel_home_card_radius:22,hotel_home_hotel_columns:3,hotel_home_destination_columns:5,
 hotel_home_destination_title:'Top destinations',hotel_home_destination_subtitle:'Explore the places guests are discovering across ANAIRA.',
 hotel_home_footer_text:'ANAIRA Hotels — discover stays, compare live availability and book with confidence.'
};

function datePlus(days){const d=new Date();d.setDate(d.getDate()+days);return d.toISOString().slice(0,10)}

export default function Hotels(){
 const [settings,setSettings]=useState(defaults),[banners,setBanners]=useState([]),[destinations,setDestinations]=useState([]),
 [q,setQ]=useState(''),[inDate,setInDate]=useState(''),[outDate,setOutDate]=useState(''),[adults,setAdults]=useState(2),[children,setChildren]=useState(0),
 [rows,setRows]=useState([]),[loading,setLoading]=useState(false),[msg,setMsg]=useState('');

 useEffect(()=>{(async()=>{
   const {data}=await supabase.from('anaira_platform_settings').select('key,value').in('key',Object.keys(defaults));
   const x={...defaults};(data||[]).forEach(r=>x[r.key]=r.value?.value??r.value);setSettings(x);
   const {data:s}=await supabase.from('anaira_platform_stores').select('id').eq('store_type','hotel').maybeSingle();
   if(s){
     const [{data:b},{data:d}]=await Promise.all([
       supabase.from('anaira_hotel_store_banners').select('*').eq('store_id',s.id).eq('active',true).order('display_order'),
       supabase.from('anaira_hotel_store_destinations').select('*').eq('store_id',s.id).eq('active',true).order('display_order')
     ]);
     setBanners(b||[]);setDestinations(d||[]);
   }
   const next=datePlus(1),after=datePlus(2);setInDate(next);setOutDate(after);
   // Initial discovery uses the same canonical live availability RPC as explicit searches.
   setLoading(true);
   const {data:live}=await supabase.rpc('anaira_marketplace_hotel_search',{p_check_in:next,p_check_out:after,p_adults:2,p_children:0,p_destination:null});
   setRows(live||[]);setLoading(false);
 })()},[]);

 async function search(){
   if(!inDate||!outDate){setMsg('Select check-in and check-out dates.');return}
   if(outDate<=inDate){setMsg('Check-out must be after check-in.');return}
   setLoading(true);setMsg('');
   const {data,error}=await supabase.rpc('anaira_marketplace_hotel_search',{p_check_in:inDate,p_check_out:outDate,p_adults:Number(adults),p_children:Number(children),p_destination:q||null});
   setLoading(false);if(error){setRows([]);setMsg(error.message);return}
   setRows(data||[]);if(!(data||[]).length)setMsg('No published hotels with available room inventory were found for these dates.');
   document.getElementById('hotel-results')?.scrollIntoView({behavior:'smooth',block:'start'});
 }
 function chooseDestination(name){
   setQ(name);setMsg('');
   document.getElementById('hotel-search')?.scrollIntoView({behavior:'smooth',block:'center'});
 }
 const css={
  '--hotel-primary':settings.hotel_home_primary_color||'#17372b','--hotel-accent':settings.hotel_home_accent_color||'#c7a15a',
  '--hotel-bg':settings.hotel_home_background_color||'#f6f3ed','--hotel-surface':settings.hotel_home_surface_color||'#fff',
  '--hotel-text':settings.hotel_home_text_color||'#20362d','--hotel-width':`${settings.hotel_home_container_width||1240}px`,
  '--hotel-radius':`${settings.hotel_home_card_radius||22}px`,'--hotel-cols':settings.hotel_home_hotel_columns||3,
  '--hotel-dest-cols':settings.hotel_home_destination_columns||5,'--hotel-overlay':settings.hotel_home_hero_overlay||.48
 };
 return <main className="hotel-market-pro hotel-market-full" style={css}>

  <section className="hotel-pro-hero">
   <div className="hotel-pro-hero-grid">
    <div className="hotel-pro-copy">
     <div className="hotel-pro-kicker"><Sparkles size={14}/> CURATED STAYS • LIVE AVAILABILITY</div>
     <h1>{settings.hotel_home_title}</h1><p>{settings.hotel_home_subtitle}</p>
     {settings.hotel_home_show_search!==false&&<div className="hotel-pro-search" id="hotel-search">
      <label><MapPin size={17}/><span>Destination<input value={q} onChange={e=>setQ(e.target.value)} placeholder="Kullu, Manali, Goa…"/></span></label>
      <label><CalendarDays size={17}/><span>Check-in<input type="date" value={inDate} onChange={e=>setInDate(e.target.value)}/></span></label>
      <label><CalendarDays size={17}/><span>Check-out<input type="date" value={outDate} onChange={e=>setOutDate(e.target.value)}/></span></label>
      <label><Hotel size={17}/><span>Guests<div style={{display:'flex',gap:6}}><input aria-label="Adults" type="number" min="1" value={adults} onChange={e=>setAdults(e.target.value)}/><input aria-label="Children" type="number" min="0" value={children} onChange={e=>setChildren(e.target.value)}/></div></span></label>
      <button onClick={search} disabled={loading}>{loading?'Searching…':'Search stays'} <ArrowRight size={16}/></button>
     </div>}
     <a className="hotel-pro-cta" href={settings.hotel_home_hero_cta_url||'#hotel-results'}>{settings.hotel_home_hero_cta||'Explore hotels'} <ChevronRight size={16}/></a>
    </div>
    {settings.hotel_home_hero_image?
      <picture className="hotel-pro-hero-media"><source media="(max-width:760px)" srcSet={settings.hotel_home_hero_mobile_image||settings.hotel_home_hero_image}/><img src={settings.hotel_home_hero_image} alt="ANAIRA Hotels"/></picture>:
      <div className="hotel-pro-hero-placeholder"><div><Compass size={46}/><b>ANAIRA HOTELS</b><span>Curated stays • Live availability • Direct booking</span></div></div>}
   </div>
  </section>

  {settings.hotel_home_show_trust!==false&&<div className="hotel-pro-trust"><span><ShieldCheck size={16}/> Verified hotel listings</span><span><CalendarDays size={16}/> Live availability</span><span><Hotel size={16}/> Direct room inventory</span><span><Sparkles size={16}/> ANAIRA customer continuity</span></div>}

  <section className="hotel-pro-wrap">
   {settings.hotel_home_show_destinations!==false&&destinations.length>0&&<section className="hotel-pro-destinations">
    <div className="hotel-pro-section-head"><div><small>EXPLORE BY DESTINATION</small><h2>{settings.hotel_home_destination_title}</h2><p>{settings.hotel_home_destination_subtitle}</p></div><span>{destinations.length} curated places</span></div>
    <div className="hotel-destination-grid">
     {destinations.map(d=><button className="hotel-destination-card" key={d.id} onClick={()=>chooseDestination(d.name)}>
      <picture>{d.mobile_image_url&&<source media="(max-width:760px)" srcSet={d.mobile_image_url}/>}<img src={d.image_url} alt={d.name}/></picture>
      <div className="hotel-destination-overlay"><small>ANAIRA DESTINATION</small><strong>{d.name}</strong><span>{d.subtitle||'Discover stays'}</span><em>{d.cta_label||'Explore hotels'} <ArrowRight size={14}/></em></div>
     </button>)}
    </div>
   </section>}

   {settings.hotel_home_show_banners!==false&&banners.length>0&&<div className="hotel-pro-banners">{banners.map(b=><a key={b.id} href={b.cta_url||'#hotel-results'} className="hotel-pro-banner" style={{backgroundImage:`linear-gradient(90deg,#0c2119dd,#0c211922),url(${b.image_url})`}}><small>{b.subtitle||'ANAIRA Hotels'}</small><b>{b.title}</b>{b.cta_label&&<span>{b.cta_label}<ChevronRight size={14}/></span>}</a>)}</div>}

   <section id="hotel-results">
    <div className="hotel-pro-section-head"><div><small>LIVE HOTEL DISCOVERY</small><h2>{q?`Stays in ${q}`:'Featured hotels with live availability'}</h2><p>Rooms, availability and booking flow are sourced from the canonical Hotel Management System.</p></div><span>{rows.length?`${rows.length} live results`:'No matching live results'}</span></div>
    {msg&&<div className="hotel-pro-message">{msg}</div>}
    {loading?<div className="hotel-pro-empty"><Search size={30}/><h3>Finding available stays…</h3><p>Checking live room inventory.</p></div>:
     rows.length?<div className="hotel-pro-grid">{rows.map(x=><article className="hotel-pro-card" key={x.restaurant_id}>
       <div className="hotel-pro-cover">{(x.listing_override?.cover_url||x.cover_image)?<img src={x.listing_override?.cover_url||x.cover_image} alt=""/>:<div><Hotel size={42}/></div>}<span>LIVE STAY</span><button aria-label="Featured hotel"><Star size={14}/></button></div>
       <div className="hotel-pro-card-body"><div className="hotel-pro-location"><MapPin size={13}/>{x.city||x.address||'Destination'}</div><h3>{x.listing_override?.title||x.hotel_name}</h3><p>{x.listing_override?.tagline||'Live rooms · Direct booking · Secure guest journey'}</p><div className="hotel-pro-stats"><span>{x.available_room_types||0} room types</span><span>{inDate} → {outDate}</span></div><Link className="hotel-pro-book" href={`/book/${x.restaurant_id}?check_in=${inDate}&check_out=${outDate}&adults=${adults}&children=${children}`}>View rooms & book <ArrowRight size={15}/></Link></div>
     </article>)}</div>:
     <div className="hotel-pro-empty"><Hotel size={30}/><h3>Search live hotel inventory</h3><p>Choose dates and a destination above. Results are always sourced from published hotel inventory; no sample hotel cards are used.</p></div>}
   </section>
  </section>
  {settings.hotel_home_show_footer!==false&&<footer className="hotel-pro-footer"><b>ANAIRA HOTELS</b><span>{settings.hotel_home_footer_text}</span><Link href="/anaira/platform">ANAIRA Platform</Link></footer>}
 </main>
}
