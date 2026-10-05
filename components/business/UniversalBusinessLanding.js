'use client';
import {Suspense,useEffect,useMemo,useState} from 'react';
import {useSearchParams} from 'next/navigation';
import {supabase} from '../../lib/supabase';
import {businessConfig} from '../../app/businessTypeConfig';

const moduleTitle=(key)=>({primary:'Featured Services & Products',team:'Our Team',products:'Products',services:'Services',treatments:'Treatments',packages:'Packages',portfolio:'Portfolio',collections:'Collections',projects:'Projects',programs:'Programs',memberships:'Memberships',spaces:'Spaces',venues:'Venues',destinations:'Destinations',courses:'Courses',testimonials:'Testimonials',offers:'Special Offers',customers:'Customers',case_studies:'Case Studies'})[key]||String(key||'').replace(/[_-]/g,' ').replace(/\b\w/g,m=>m.toUpperCase());
const sectionEnabled=(landing,key)=>landing?.sections?.length?landing.sections.find(x=>x.key===key)?.enabled!==false:true;
function UniversalBusinessLandingInner({type}){
 const cfg=businessConfig(type),search=useSearchParams(),businessId=search.get('business')||search.get('id');
 const [business,setBusiness]=useState(null),[landing,setLanding]=useState(null),[records,setRecords]=useState([]),[media,setMedia]=useState([]),[loading,setLoading]=useState(!!businessId);
 useEffect(()=>{(async()=>{
  if(!businessId){setLoading(false);return;}
  try{
   const token=(await supabase.auth.getSession()).data.session?.access_token;
   const r=await fetch(`/api/business/landing?business=${encodeURIComponent(businessId)}&type=${encodeURIComponent(type)}`,{headers:token?{Authorization:`Bearer ${token}`}:{}});
   const d=await r.json();
   if(!r.ok) throw new Error(d.error||'Unable to load business website');
   setBusiness(d.business);setLanding(d.landing);setRecords(d.records||[]);setMedia(d.media||[]);setOffers(d.offers||[]);setLoading(false);
  }catch(e){setBusiness(null);setLoading(false);setErr(e.message)}
 })()},[businessId,type]);
 const [err,setErr]=useState('');
 const [offers,setOffers]=useState([]);
 const grouped=useMemo(()=>records.reduce((a,r)=>{(a[r.module_key] ||= []).push(r);return a},{}),[records]);
 const name=landing?.headline||business?.name||cfg.name,sub=landing?.subheadline||business?.description||`A premium ${cfg.name.toLowerCase()} experience powered by Anaira.`;
 const gallery=media.filter(m=>m.media_type==='gallery').map(m=>m.url);
 const testimonials=grouped.testimonials||[];
 if(loading)return <main className="premium-site"><div className="premium-loading">Loading {cfg.name}…</div></main>;
 if(!business)return <main className="premium-site"><div className="premium-loading"><strong>{err||'Business not found.'}</strong><p>Check the business ID, login session, and website publication status.</p></div></main>;
 return <main className="premium-site" style={{'--accent':landing?.theme?.accent||'#c8a35b'}}>
  {sectionEnabled(landing,'hero')&&<section className="premium-hero" style={landing?.hero_image_url?{backgroundImage:`linear-gradient(90deg,rgba(4,24,18,.92),rgba(4,24,18,.45)),url(${landing.hero_image_url})`}:{}}><nav className="premium-nav"><div className="premium-logo">{landing?.logo_url?<img src={landing.logo_url} alt=""/>:<span>{cfg.icon}</span>}<b>{business?.name||cfg.name}</b></div><div className="premium-nav-links"><a href="#services">Explore</a><a href="#about">About</a><a href="#contact">Contact</a><a className="premium-nav-cta" href={business?.phone?`tel:${business.phone}`:'#contact'}>{landing?.cta_text||'Get Started'}</a></div></nav><div className="premium-hero-content"><div className="premium-eyebrow">{cfg.name.toUpperCase()} · ANAIRA</div><h1>{name}</h1><p>{sub}</p><div className="premium-actions"><a className="premium-btn primary" href={business?.phone?`tel:${business.phone}`:'#contact'}>{landing?.cta_text||'Book / Enquire'} →</a>{business?.email&&<a className="premium-btn" href={`mailto:${business.email}`}>Contact</a>}</div></div></section>}
  {sectionEnabled(landing,'about')&&<section id="about" className="premium-section premium-about"><div className="premium-kicker">OUR STORY</div><h2>{business?.name||cfg.name}, thoughtfully presented.</h2><p>{landing?.about||business?.description||`Discover our services, people and offerings, all in one place.`}</p><div className="premium-stats"><div><b>{grouped.primary?.length||0}+</b><span>Featured offerings</span></div><div><b>{grouped.team?.length||0}+</b><span>Team members</span></div><div><b>{gallery.length||0}+</b><span>Gallery stories</span></div></div></section>}
  {sectionEnabled(landing,'catalog')&&<section id="services" className="premium-section premium-catalog"><div className="premium-kicker">{cfg.primary?.toUpperCase()||'FEATURED'}</div><h2>{cfg.primary}</h2>{grouped.primary?.length?<div className="premium-grid">{grouped.primary.map(r=><article className="premium-card" key={r.id}>{(r.data?.image_url||r.data?.photo_url)&&<img src={r.data.image_url||r.data.photo_url} alt={r.title}/>}<div><span>{r.data?.category||r.data?.type||cfg.name}</span><h3>{r.title}</h3><p>{r.data?.description||r.data?.bio||r.data?.itinerary||''}</p>{r.data?.price!=null&&<strong>₹{Number(r.data.price).toLocaleString('en-IN')}</strong>}</div></article>)}</div>:<div className="premium-empty">Add {cfg.primary.toLowerCase()} from Setup Studio.</div>}</section>}
  {sectionEnabled(landing,'team')&&grouped.team?.length>0&&<section className="premium-section"><div className="premium-kicker">THE PEOPLE</div><h2>Meet our team</h2><div className="premium-team">{grouped.team.map(r=><article key={r.id}>{(r.data?.photo_url||r.data?.image_url)&&<img src={r.data.photo_url||r.data.image_url} alt={r.title}/>}<h3>{r.title}</h3><p>{r.data?.specialization||r.data?.role||''}</p></article>)}</div></section>}
  {sectionEnabled(landing,'offers')&&offers.length>0&&<section className="premium-section premium-offers"><div className="premium-kicker">EXCLUSIVE</div><h2>Special offers</h2><div className="premium-offer-grid">{offers.map(o=><article key={o.id}><span>LIMITED OFFER</span><h3>{o.title}</h3><p>{o.description||''}</p><b>{o.discount_type==='percent'?`${o.discount_value}% OFF`:o.discount_type==='fixed'?`₹${o.discount_value} OFF`:'Special pricing'}</b></article>)}</div></section>}
  {sectionEnabled(landing,'gallery')&&gallery.length>0&&<section className="premium-section"><div className="premium-kicker">GALLERY</div><h2>A closer look</h2><div className="premium-gallery">{gallery.map((u,i)=><img key={u+i} src={u} alt={`${cfg.name} gallery ${i+1}`}/>)}</div></section>}
  {sectionEnabled(landing,'testimonials')&&testimonials.length>0&&<section className="premium-section premium-testimonials"><div className="premium-kicker">KIND WORDS</div><h2>What people say</h2><div className="premium-quote-grid">{testimonials.map(r=><blockquote key={r.id}>{r.data?.photo_url&&<img src={r.data.photo_url} alt=""/>}<p>“{r.data?.quote||''}”</p><footer><b>{r.title}</b>{r.data?.company&&<span> · {r.data.company}</span>}</footer></blockquote>)}</div></section>}
  {sectionEnabled(landing,'contact')&&<section id="contact" className="premium-contact"><div><div className="premium-kicker">VISIT / CONTACT</div><h2>Let’s create something memorable.</h2><p>{[business?.address,business?.city,business?.state,business?.country].filter(Boolean).join(', ')}</p></div><div className="premium-contact-actions">{business?.phone&&<a className="premium-btn primary" href={`tel:${business.phone}`}>Call {business.phone}</a>}{business?.email&&<a className="premium-btn" href={`mailto:${business.email}`}>{business.email}</a>}</div></section>}
  <footer className="premium-footer"><span>© {new Date().getFullYear()} {business?.name||cfg.name}</span><span>Powered by Anaira</span></footer>
 </main>;
}


export default function UniversalBusinessLanding(props){ return <Suspense fallback={<main className="domain-engine-page"><div className="card">Loading…</div></main>}><UniversalBusinessLandingInner {...props}/></Suspense>; }
