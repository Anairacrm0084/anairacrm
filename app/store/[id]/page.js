'use client';

import {useEffect, useMemo, useState} from 'react';
import {useParams} from 'next/navigation';
import {supabase} from '../../../lib/supabase';

const DEFAULT_PAGE = {
  section_order:['header','hero','highlights','popular','categories','about','gallery','offer','reviews','reservation','footer'],
  visibility:{header:true,hero:true,highlights:true,popular:true,categories:true,about:true,gallery:true,offer:true,reviews:true,reservation:true,footer:true},
  highlights:[
    {icon:'🌿',title:'100% Vegetarian',description:'Pure & Healthy Food',action_type:'none',action_value:'',enabled:true},
    {icon:'👨‍🍳',title:'Authentic Taste',description:'Himachali & Indian Flavours',action_type:'none',action_value:'',enabled:true},
    {icon:'🍃',title:'Fresh Ingredients',description:'Locally Sourced',action_type:'none',action_value:'',enabled:true},
    {icon:'♡',title:'Family Friendly',description:'Great Food, Great Vibes',action_type:'none',action_value:'',enabled:true}
  ],
  about_features:[
    {icon:'🌿',title:'Local Flavors',description:'Authentic regional taste',enabled:true},
    {icon:'♨',title:'Hygienic Kitchen',description:'Clean and careful preparation',enabled:true},
    {icon:'🏡',title:'Cozy Ambience',description:'A warm mountain dining experience',enabled:true},
    {icon:'✦',title:'Best Service',description:'Warm hospitality for every guest',enabled:true}
  ],
  testimonials:[],
  reservation:{enabled:true,eyebrow:'BOOK A TABLE',title:'Plan Your Visit',text:'Reserve your table for a delightful dining experience.',cta_label:'Book Now'},
  footer:{description:'Good food, warm hospitality and memorable moments.',artwork:true},
  labels:{
    hero_eyebrow:'GOOD FOOD',
    hero_cta_1:'View Menu',
    hero_cta_2:'Visit Us',
    highlights_eyebrow:'',
    popular_eyebrow:'OUR SPECIALTIES',
    popular_title:'Popular Dishes',
    categories_eyebrow:'EXPLORE OUR',
    categories_title:'Menu Categories',
    categories_subtitle:'',
    about_eyebrow:'ABOUT US',
    about_title:'',
    about_subtitle:'',
    about_cta:'Our Story',
    gallery_eyebrow:'OUR RESTAURANT GALLERY',
    gallery_title:'Our Restaurant Gallery',
    gallery_subtitle:'',
    gallery_cta:'View Gallery',
    offer_eyebrow:'SPECIAL OFFER',
    offer_title:'Delicious Food, Special Moments',
    offer_text:'Get a special offer on your first visit or online order!',
    offer_cta:'Order Now',
    reviews_eyebrow:'WHAT OUR CUSTOMERS SAY',
    reviews_title:'What Our Customers Say',
    reviews_subtitle:'',
    reservation_eyebrow:'BOOK A TABLE',
    reservation_title:'Plan Your Visit',
    reservation_text:'Reserve your table for a delightful dining experience.',
    reservation_cta:'Book Now'
  },
  theme:{primary:'#063b2b',gold:'#d9a93a',cream:'#f7f3ea',maroon:'#8b1215',text:'#17352a',radius:14}
};

const GLOBAL_STORE_TYPES = ['restaurant'];

function mergePage(raw){
  const p = raw && typeof raw === 'object' ? raw : {};
  return {
    ...DEFAULT_PAGE,
    ...p,
    visibility:{...DEFAULT_PAGE.visibility,...(p.visibility||{})},
    labels:{...DEFAULT_PAGE.labels,...(p.labels||{})},
    theme:{...DEFAULT_PAGE.theme,...(p.theme||{})},
    highlights:Array.isArray(p.highlights)?p.highlights:DEFAULT_PAGE.highlights,
    about_features:Array.isArray(p.about_features)?p.about_features:DEFAULT_PAGE.about_features,
    testimonials:Array.isArray(p.testimonials)?p.testimonials:[],
    section_order:Array.isArray(p.section_order)&&p.section_order.length?p.section_order:DEFAULT_PAGE.section_order,
    reservation:{...DEFAULT_PAGE.reservation,...(p.reservation||{})},
    footer:{...DEFAULT_PAGE.footer,...(p.footer||{})}
  };
}

export default function RestaurantStoreId(){
  const {id}=useParams();
  const [loading,setLoading]=useState(true),[error,setError]=useState('');
  const [restaurant,setRestaurant]=useState(null),[membership,setMembership]=useState(null),[settings,setSettings]=useState(null);
  const [banners,setBanners]=useState([]),[featured,setFeatured]=useState([]),[categories,setCategories]=useState([]),[items,setItems]=useState([]),[offers,setOffers]=useState([]);
  const [page,setPage]=useState(DEFAULT_PAGE);
  const [cart,setCart]=useState([]),[selected,setSelected]=useState(null),[variants,setVariants]=useState([]),[addons,setAddons]=useState([]),[chosenVariant,setChosenVariant]=useState(null),[chosenAddons,setChosenAddons]=useState([]);
  const [heroIndex,setHeroIndex]=useState(0),[menuOpen,setMenuOpen]=useState(false),[cartOpen,setCartOpen]=useState(false),[galleryIndex,setGalleryIndex]=useState(null);
  const [category,setCategory]=useState('all'),[query,setQuery]=useState(''),[coupon,setCoupon]=useState('');
  const [orderForm,setOrderForm]=useState({name:'',phone:'',address:''}),[mode,setMode]=useState('delivery'),[busy,setBusy]=useState(false),[message,setMessage]=useState('');
  const [reservation,setReservation]=useState({name:'',phone:'',date:'',time:'19:30',party:2}),[reservationBusy,setReservationBusy]=useState(false),[reservationMsg,setReservationMsg]=useState('');

  useEffect(()=>{
    if(!id)return;
    (async()=>{
      try{
        let store=null;
        const {data:storeById}=await supabase.from('anaira_platform_stores').select('id,restaurant_id,enabled,published,store_name,slug,is_platform_store').eq('id',id).eq('is_platform_store',false).maybeSingle();
        if(storeById) store=storeById;
        if(!store){const {data:stores,error:storeError}=await supabase.from('anaira_platform_stores').select('id,restaurant_id,enabled,published,store_name,slug,is_platform_store').eq('restaurant_id',id).eq('store_type','restaurant').eq('is_platform_store',false).eq('enabled',true).eq('published',true).limit(1); if(storeError)throw storeError; store=stores?.[0];}
        if(!store){setError('Restaurant property store is not published.');return;}
        const propertyId=store.restaurant_id||id;
        const {data:m,error:me}=await supabase.from('anaira_store_memberships').select('*').eq('restaurant_id',propertyId).eq('store_id',store.id).eq('enabled',true).maybeSingle();
        if(me)throw me;
        if(!m){setError('This restaurant is not published in the Restaurant Store.');return;}
        const o=m.listing_override||{}, sc=m.store_config||{};
        const [{data:ss},{data:fi},{data:cats},{data:menu},{data:of},{data:hb},{data:property}]=await Promise.all([
          supabase.from('anaira_store_settings').select('*').eq('restaurant_id',propertyId).eq('store_id',store.id).eq('store_type','restaurant').maybeSingle(),
          supabase.from('anaira_marketplace_featured_items').select('*').eq('restaurant_id',propertyId).eq('store_id',store.id).eq('active',true).order('display_order'),
          supabase.from('anaira_store_categories').select('*').eq('restaurant_id',propertyId).eq('store_id',store.id).eq('active',true).order('display_order').order('name'),
          supabase.from('anaira_marketplace_menu_items').select('*').eq('restaurant_id',id).eq('active',true).order('display_order').order('item_name').limit(1000),
          supabase.from('anaira_store_offers').select('*').eq('restaurant_id',propertyId).eq('store_id',store.id).eq('active',true).order('created_at',{ascending:false}),
          supabase.from('anaira_store_banners').select('*').eq('restaurant_id',propertyId).eq('store_id',store.id).eq('active',true).order('display_order'),
          supabase.from('restaurants').select('id,name,cuisine,city,address,phone,website,logo,cover_image').eq('id',propertyId).maybeSingle()
        ]);
        if(property) setRestaurant({...property,...o,listing_override:o,store_config:sc,store_id:store.id});
        else setRestaurant({id,...o,listing_override:o,store_config:sc,store_id:store.id});
        setMembership(m);setSettings(ss||null);setPage(mergePage(sc.store_page));
        setBanners(hb||[]);setFeatured(fi||[]);setCategories(cats||[]);
        setItems((menu||[]).map(i=>({...i,variants:i.variants||[],addons:i.addons||[]})));
        setOffers(of||[]);
      }catch(e){setError(e?.message||'Unable to load restaurant store.');}
      finally{setLoading(false);}
    })();
  },[id]);

  const sc=restaurant?.store_config||{};
  const labels=page.labels||DEFAULT_PAGE.labels;
  const visibility=page.visibility||DEFAULT_PAGE.visibility;
  const title=restaurant?.title||restaurant?.name||'Restaurant';
  const tagline=restaurant?.tagline||restaurant?.cuisine||'Fresh food • warm hospitality';
  const description=restaurant?.description||'Enjoy fresh food, authentic flavours and warm hospitality in a beautiful dining experience.';
  const logo=restaurant?.logo_url||restaurant?.logo||'/assets/anaira-logo.webp';
  const gallery=Array.isArray(restaurant?.gallery)?restaurant.gallery:[];
  const heroSlides=banners.length?banners:[{id:'fallback',image_url:restaurant?.cover_url||restaurant?.cover_image||'',mobile_image_url:'',title:title,subtitle:description,cta_label:labels.hero_cta_1,cta_url:'#menu'}];
  const featuredItems=featured.map(f=>items.find(i=>String(i.id)===String(f.external_item_id))).filter(Boolean);
  const visible=useMemo(()=>items.filter(i=>(category==='all'||String(i.category_id)===String(category)||i.category_name===category)&&(!query||`${i.item_name||i.name} ${i.description||''}`.toLowerCase().includes(query.toLowerCase()))),[items,category,query]);
  const subtotal=cart.reduce((s,i)=>s+Number(i.unit_price||0)*i.quantity,0);
  const offer=offers.find(o=>String(o.code||'').toUpperCase()===coupon.trim().toUpperCase()&&subtotal>=Number(o.min_order_amount||0));
  const discount=offer?(offer.discount_type==='percent'?Math.min(subtotal,subtotal*Number(offer.discount_value||0)/100):Math.min(subtotal,Number(offer.discount_value||0))):0;
  const deliveryFee=mode==='delivery'?Number(settings?.delivery_fee??sc.delivery_fee??0):0;
  const tax=Math.max(0,subtotal-discount)*Number(settings?.tax_percent??sc.tax_percent??0)/100;
  const total=Math.max(0,subtotal-discount)+deliveryFee+tax;
  const modes=[['delivery','Delivery'],['pickup','Pickup'],['dine_in','Dine-in']].filter(([m])=>sc[m]!==false);
  const currentHero=heroSlides[heroIndex%heroSlides.length];

  useEffect(()=>{if(heroSlides.length<2)return;const t=setInterval(()=>setHeroIndex(i=>(i+1)%heroSlides.length),5000);return()=>clearInterval(t)},[heroSlides.length]);

  function openDish(item){setSelected(item);setVariants(item.variants||[]);setAddons(item.addons||[]);setChosenVariant(null);setChosenAddons([]);}
  function addSelected(){
    if(!selected)return;
    const unit=Number(selected.discount_price ?? selected.price ?? 0)+Number(chosenVariant?.price||0)+chosenAddons.reduce((s,a)=>s+Number(a.price||0),0);
    const key=`${selected.id}:${chosenVariant?.id||'base'}:${chosenAddons.map(a=>a.id).sort().join(',')}`;
    setCart(c=>{const found=c.find(x=>x.key===key);return found?c.map(x=>x.key===key?{...x,quantity:x.quantity+1}:x):[...c,{key,name:selected.item_name||selected.name,menu_item_id:selected.id,quantity:1,unit_price:unit,modifiers:{variant:chosenVariant?{id:chosenVariant.id,name:chosenVariant.name,price:chosenVariant.price}:null,addons:chosenAddons.map(a=>({id:a.id,name:a.name,price:a.price}))}}]});
    setSelected(null);setCartOpen(true);
  }
  function updateQty(key,d){setCart(c=>c.map(x=>x.key===key?{...x,quantity:x.quantity+d}:x).filter(x=>x.quantity>0));}
  async function checkout(){
    if(!cart.length||!orderForm.name||!orderForm.phone){setMessage('Name, phone and at least one item are required.');return;}
    setBusy(true);setMessage('');
    try{
      const response=await fetch(`/api/marketplace/restaurant/${id}/order`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({client_request_id:globalThis.crypto?.randomUUID?.()||String(Date.now()),customer:{name:orderForm.name,phone:orderForm.phone},address:{text:orderForm.address,type:mode,coupon:coupon||null,delivery_fee:deliveryFee,tax,discount},items:cart.map(i=>({menu_item_id:i.menu_item_id,quantity:i.quantity,modifiers:i.modifiers})),offer_id:offer?.id||null})});
      const data=await response.json();
      if(!response.ok||!data.ok)throw new Error(data.error||'Unable to place order.');
      setMessage(`Order ${data.order?.order_id||''} received by the restaurant.`);setCart([]);setCoupon('');
    }catch(e){setMessage(e.message)}finally{setBusy(false);}
  }
  async function bookTable(){
    if(!reservation.name||!reservation.phone||!reservation.date||!reservation.time){setReservationMsg('Name, phone, date and time are required.');return;}
    setReservationBusy(true);setReservationMsg('');
    try{
      const key=globalThis.crypto?.randomUUID?.()||`${Date.now()}-${Math.random()}`;
      const {data,error:e}=await supabase.rpc('anaira_create_restaurant_reservation_v2',{p_restaurant_id:propertyId,p_guest_name:reservation.name,p_guest_phone:reservation.phone,p_guest_email:null,p_date:reservation.date,p_time:reservation.time,p_party_size:Number(reservation.party),p_duration_minutes:90,p_source:'anaira_store_id',p_table_id:null,p_idempotency_key:key,p_special_request:null});
      if(e)throw e;
      setReservationMsg(`Reservation ${data?.reservation_code||''} confirmed.`);
    }catch(e){setReservationMsg(e?.message||'Unable to confirm reservation. Please try another time.');}
    finally{setReservationBusy(false);}
  }
  function scrollTo(id){document.getElementById(id)?.scrollIntoView({behavior:'smooth',block:'start'});}
  function heroAction(url){if(!url||url==='#menu'){setMenuOpen(true);return;} if(url.startsWith('#')){scrollTo(url.slice(1));return;} window.location.href=url;}

  if(loading)return <main className="store-id-page"><div className="sid-loading">Loading restaurant experience…</div></main>;
  if(error||!restaurant)return <main className="store-id-page"><div className="sid-loading">{error||'Restaurant unavailable.'}</div></main>;

  const sec=(name,content)=>visibility[name]!==false?content:null; const ord=(name,content)=>visibility[name]!==false?<div className="sid-order-block" style={{order:Math.max(0,page.section_order.indexOf(name))}}>{content}</div>:null;
  return <main className="store-id-page" style={{'--green':page.theme.primary,'--gold':page.theme.gold,'--cream':page.theme.cream,'--maroon':page.theme.maroon,'--text':page.theme.text,'--radius':`${page.theme.radius||14}px`}}>
    {sec('header',<header className="sid-header"><div className="sid-header-inner"><a className="sid-brand" href="#top"><img src={logo} alt={title}/><span><b>{title}</b><small>100% VEG RESTAURANT &amp; DHABA</small></span></a><nav><a href="#top">Home</a><a href="#about">About Us</a><button onClick={()=>setMenuOpen(true)}>Menu</button><a href="#gallery">Gallery</a><a href="#reservation">Reservations</a><a href="#footer">Contact</a></nav><button className="sid-order-btn" onClick={()=>setMenuOpen(true)}>Order Now →</button><button className="sid-mobile-menu" onClick={()=>setMenuOpen(true)}>☰</button></div></header>)}

    <div id="top"/>
    <div className="sid-content-order">{ord('hero',<section className="sid-hero" style={{backgroundImage:currentHero.image_url?`linear-gradient(90deg,rgba(3,29,21,.86),rgba(3,29,21,.18)),url(${currentHero.image_url})`:`linear-gradient(120deg,var(--green),#14563e)`}}>
      <div className="sid-hero-inner"><div className="sid-hero-copy"><span className="sid-script">{currentHero.eyebrow||labels.hero_eyebrow}</span><h1>{currentHero.title||title}</h1><p>{currentHero.subtitle||description}</p><div className="sid-hero-meta"><span>🌿 Tasty</span><span>• Healthy</span><span>• 100% Vegetarian</span></div><div className="sid-hero-actions"><button className="sid-gold-btn" onClick={()=>heroAction(currentHero.cta_url||'#menu')}>{currentHero.cta_label||labels.hero_cta_1} →</button><button className="sid-ghost-btn" onClick={()=>scrollTo('about')}>{labels.hero_cta_2} ↗</button></div></div><div className="sid-hero-controls">{heroSlides.length>1&&<><button onClick={()=>setHeroIndex(i=>(i-1+heroSlides.length)%heroSlides.length)}>‹</button><span>{heroIndex+1} / {heroSlides.length}</span><button onClick={()=>setHeroIndex(i=>(i+1)%heroSlides.length)}>›</button></>}</div></div>
    </section>)}

    {ord('highlights',<section className="sid-highlights">{page.highlights.filter(x=>x.enabled!==false).slice(0,8).map((h,i)=><button key={i} onClick={()=>{if(h.action_type==='menu')setMenuOpen(true);else if(h.action_type==='reservation')scrollTo('reservation');else if(h.action_type==='gallery')scrollTo('gallery');else if(h.action_type==='about')scrollTo('about');else if(h.action_type==='offers')scrollTo('offer');else if(h.action_type==='url'&&h.action_value)window.location.href=h.action_value;}}><i>{h.icon||'✦'}</i><b>{h.title}</b><small>{h.description}</small></button>)}</section>)}

    {ord('popular',<section className="sid-section sid-popular"><div className="sid-section-head"><div><span>{labels.popular_eyebrow}</span><h2>{labels.popular_title}</h2></div><button onClick={()=>setMenuOpen(true)}>View Full Menu →</button></div><div className="sid-dish-grid">{featuredItems.slice(0,8).map((item,i)=><article key={item.id||i} onClick={()=>openDish(item)}><div className="sid-dish-image">{item.image_url?<img src={item.image_url} alt={item.item_name||item.name}/>:<div>🍽️</div>}<em>POPULAR</em></div><h3>{item.item_name||item.name}</h3><p>{item.description||item.category_name||'Traditional restaurant special'}</p><strong>₹{item.discount_price??item.price}</strong></article>)}</div>{!featuredItems.length&&<div className="sid-empty">Select popular dishes from Store Builder to display them here.</div>}</section>)}

    {ord('categories',<section className="sid-category-band"><div className="sid-section-head centered"><div><span>{labels.categories_eyebrow}</span><h2>{labels.categories_title}</h2></div></div><div className="sid-category-row">{categories.slice(0,12).map(c=><button key={c.id} onClick={()=>{setCategory(String(c.id));setMenuOpen(true)}}>{c.image_url?<img src={c.image_url} alt={c.name}/>:<i>🍲</i>}<b>{c.name}</b><small>{c.description||'Explore dishes'}</small></button>)}</div></section>)}

    {ord('about',<section className="sid-section sid-about" id="about"><div className="sid-about-image">{gallery[0]?<img src={gallery[0]} alt={title}/>:<div className="sid-placeholder">Restaurant</div>}</div><div className="sid-about-copy"><span>{labels.about_eyebrow}</span><h2>{labels.about_title||title}</h2><h4>{labels.about_subtitle||tagline}</h4><p>{description}</p><p>{sc.about_text||''}</p><div className="sid-about-features">{page.about_features.filter(x=>x.enabled!==false).slice(0,4).map((f,i)=><div key={i}><i>{f.icon||'✦'}</i><b>{f.title}</b><small>{f.description}</small></div>)}</div><button className="sid-gold-btn" onClick={()=>scrollTo('footer')}>{labels.about_cta} →</button></div></section>)}

    {ord('gallery',<section className="sid-section sid-gallery" id="gallery"><div className="sid-section-head"><div><span>{labels.gallery_eyebrow}</span><h2>{labels.gallery_title}</h2></div><button onClick={()=>setGalleryIndex(0)}>{labels.gallery_cta} →</button></div><div className="sid-gallery-grid">{gallery.slice(0,4).map((u,i)=><button key={`${u}-${i}`} onClick={()=>setGalleryIndex(i)}><img src={u} alt={`${title} ${i+1}`}/></button>)}</div></section>)}

    {ord('offer',<section className="sid-offer" id="offer">{offers[0]&&<><div><span>{labels.offer_eyebrow}</span><h2>{labels.offer_title}</h2><p>{labels.offer_text||offers[0].title}</p><button className="sid-gold-btn" onClick={()=>setMenuOpen(true)}>{labels.offer_cta} →</button></div><div className="sid-offer-image">{offers[0].image_url? <img src={offers[0].image_url} alt="Offer"/>:<div>10%<small>OFF</small></div>}<b>{offers[0].discount_type==='percent'?`${offers[0].discount_value}% OFF`:`₹${offers[0].discount_value} OFF`}</b></div></>}{!offers[0]&&<div className="sid-offer-empty">Create a special offer in Store Builder to display this section.</div>}</section>)}

    {ord('reviews',<section className="sid-section sid-reviews" id="reviews"><div className="sid-section-head centered"><div><span>{labels.reviews_eyebrow}</span><h2>{labels.reviews_title}</h2><small>{labels.reviews_subtitle}</small></div></div><div className="sid-review-grid">{page.testimonials.slice(0,6).map((t,i)=><article key={i}>{t.photo_url&&<img src={t.photo_url} alt={t.name||'Customer'}/>}<div className="stars">★★★★★</div><p>“{t.text||t.review||''}”</p><b>{t.name||'Guest'}</b>{t.meta&&<small>{t.meta}</small>}</article>)}</div>{!page.testimonials.length&&<div className="sid-empty">Add customer reviews in Store Builder.</div>}</section>)}

    {ord('reservation',<section className="sid-reservation" id="reservation"><div><span>{page.reservation.eyebrow}</span><h2>{page.reservation.title}</h2><p>{page.reservation.text}</p></div><div className="sid-reservation-card"><input placeholder="Your Name" value={reservation.name} onChange={e=>setReservation({...reservation,name:e.target.value})}/><input placeholder="Phone Number" value={reservation.phone} onChange={e=>setReservation({...reservation,phone:e.target.value})}/><input type="date" value={reservation.date} onChange={e=>setReservation({...reservation,date:e.target.value})}/><input type="number" min="1" value={reservation.party} onChange={e=>setReservation({...reservation,party:e.target.value})} placeholder="Number of People"/><input type="time" value={reservation.time} onChange={e=>setReservation({...reservation,time:e.target.value})}/><button onClick={bookTable} disabled={reservationBusy}>{reservationBusy?'Confirming…':page.reservation.cta_label+' →'}</button>{reservationMsg&&<small>{reservationMsg}</small>}</div></section>)}

    </div>
    {sec('footer',<footer className="sid-footer" id="footer"><div className="sid-footer-brand"><img src={logo} alt={title}/><h3>{title}</h3><p>{page.footer.description||description}</p></div><div><h4>Quick Links</h4><a href="#top">Home</a><a href="#about">About Us</a><button onClick={()=>setMenuOpen(true)}>Menu</button><a href="#gallery">Gallery</a><a href="#reservation">Reservations</a><a href="#footer">Contact</a></div><div><h4>Contact Us</h4><span>📍 {restaurant.address||restaurant.city||'India'}</span><span>☎ {restaurant.phone||'Contact restaurant'}</span><span>✉ {restaurant.website||''}</span><div className="sid-social">{restaurant.social_instagram&&<a href={restaurant.social_instagram}>Instagram</a>}{restaurant.social_facebook&&<a href={restaurant.social_facebook}>Facebook</a>}{restaurant.social_whatsapp&&<a href={restaurant.social_whatsapp}>WhatsApp</a>}</div></div><div><h4>Opening Hours</h4><span>◷ {settings?.timings?.open||sc.open_time||'09:00'} - {settings?.timings?.close||sc.close_time||'23:00'}</span><span>Mon - Sun</span></div><div className="sid-footer-bottom">© {new Date().getFullYear()} {title}. All Rights Reserved. <span>Privacy Policy&nbsp; | &nbsp;Terms &amp; Conditions</span></div></footer>)}

    {menuOpen&&<div className="sid-overlay" onClick={()=>setMenuOpen(false)}><div className="sid-menu-drawer" onClick={e=>e.stopPropagation()}><div className="sid-drawer-head"><div><span>MENU</span><h2>{title}</h2></div><button onClick={()=>setMenuOpen(false)}>×</button></div><div className="sid-menu-toolbar"><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Search dishes…"/><div>{categories.map(c=><button className={category===String(c.id)?'active':''} key={c.id} onClick={()=>setCategory(String(c.id))}>{c.name}</button>)}</div></div><div className="sid-drawer-items">{visible.map(item=><article key={item.id} onClick={()=>openDish(item)}><div>{item.image_url?<img src={item.image_url} alt=""/>:<span>🍽️</span>}</div><section><b>{item.item_name||item.name}</b><small>{item.description||''}</small><strong>₹{item.discount_price??item.price}</strong></section><button onClick={e=>{e.stopPropagation();openDish(item)}}>Add +</button></article>)}{!visible.length&&<div className="sid-empty">No dishes found.</div>}</div></div></div>}

    {cartOpen&&<div className="sid-overlay" onClick={()=>setCartOpen(false)}><aside className="sid-cart-drawer" onClick={e=>e.stopPropagation()}><div className="sid-drawer-head"><div><span>YOUR ORDER</span><h2>Cart</h2></div><button onClick={()=>setCartOpen(false)}>×</button></div><div className="sid-mode-row">{modes.map(([v,l])=><button className={mode===v?'active':''} key={v} onClick={()=>setMode(v)}>{l}</button>)}</div><div className="sid-cart-lines">{cart.map(i=><div key={i.key}><div><b>{i.name}</b><small>{i.modifiers?.variant?.name||''}{i.modifiers?.addons?.length?` · ${i.modifiers.addons.map(a=>a.name).join(', ')}`:''}</small><strong>₹{i.unit_price}</strong></div><div><button onClick={()=>updateQty(i.key,-1)}>−</button><b>{i.quantity}</b><button onClick={()=>updateQty(i.key,1)}>+</button></div></div>)}{!cart.length&&<p>Your cart is empty.</p>}</div><div className="sid-checkout"><input value={coupon} onChange={e=>setCoupon(e.target.value)} placeholder="Coupon code"/><div><span>Subtotal <b>₹{Math.round(subtotal)}</b></span><span>Discount <b>−₹{Math.round(discount)}</b></span><span>Delivery <b>₹{Math.round(deliveryFee)}</b></span><span>Tax <b>₹{Math.round(tax)}</b></span><strong>Total <b>₹{Math.round(total)}</b></strong></div><input placeholder="Full name" value={orderForm.name} onChange={e=>setOrderForm({...orderForm,name:e.target.value})}/><input placeholder="Mobile number" value={orderForm.phone} onChange={e=>setOrderForm({...orderForm,phone:e.target.value})}/><textarea placeholder={mode==='delivery'?'Delivery address':'Table / pickup note'} value={orderForm.address} onChange={e=>setOrderForm({...orderForm,address:e.target.value})}/><button className="sid-place" disabled={busy||!cart.length} onClick={checkout}>{busy?'Placing…':'Place Order · ₹'+Math.round(total)}</button>{message&&<p>{message}</p>}</div></aside></div>}

    {selected&&<div className="sid-overlay" onClick={()=>setSelected(null)}><div className="sid-dish-modal" onClick={e=>e.stopPropagation()}><button className="sid-close" onClick={()=>setSelected(null)}>×</button>{selected.image_url&&<img src={selected.image_url} alt=""/>}<span>{selected.category_name||'Menu'}</span><h2>{selected.item_name||selected.name}</h2><p>{selected.description||''}</p><h3>₹{selected.discount_price??selected.price}</h3>{variants.length>0&&<div><h4>Choose Variant</h4>{variants.map(v=><label key={v.id}><input type="radio" name="variant" checked={chosenVariant?.id===v.id} onChange={()=>setChosenVariant(v)}/><span>{v.name}</span><b>+₹{v.price}</b></label>)}</div>}{addons.length>0&&<div><h4>Add-ons</h4>{addons.map(a=><label key={a.id}><input type="checkbox" checked={chosenAddons.some(x=>x.id===a.id)} onChange={e=>setChosenAddons(c=>e.target.checked?[...c,a]:c.filter(x=>x.id!==a.id))}/><span>{a.name}</span><b>+₹{a.price}</b></label>)}</div>}<button className="sid-place" onClick={addSelected}>Add to Cart</button></div></div>}

    {galleryIndex!==null&&gallery[galleryIndex]&&<div className="sid-lightbox" onClick={()=>setGalleryIndex(null)}><button onClick={()=>setGalleryIndex(null)}>×</button><img src={gallery[galleryIndex]} alt=""/>{gallery.length>1&&<><button className="prev" onClick={e=>{e.stopPropagation();setGalleryIndex((galleryIndex-1+gallery.length)%gallery.length)}}>‹</button><button className="next" onClick={e=>{e.stopPropagation();setGalleryIndex((galleryIndex+1)%gallery.length)}}>›</button></>}</div>}

    <style jsx global>{`
      *{box-sizing:border-box}.store-id-page{background:var(--cream);color:var(--text);min-height:100vh;font-family:Arial,Helvetica,sans-serif}.store-id-page button,.store-id-page a{font:inherit}.sid-content-order{display:flex;flex-direction:column}.sid-order-block{width:100%}.sid-header{position:sticky;top:0;z-index:80;background:rgba(3,48,34,.98);color:#fff}.sid-header-inner{max-width:1400px;margin:auto;min-height:72px;padding:8px 24px;display:flex;align-items:center;gap:28px}.sid-brand{display:flex;align-items:center;gap:10px;text-decoration:none;color:#fff;min-width:260px}.sid-brand img{width:48px;height:48px;object-fit:contain}.sid-brand b{display:block;font-family:Georgia,serif;font-size:15px}.sid-brand small{display:block;color:var(--gold);font-size:7px;font-weight:800;letter-spacing:.6px;margin-top:3px}.sid-header nav{display:flex;align-items:center;gap:25px;margin-left:auto}.sid-header nav a,.sid-header nav button{color:#fff;background:none;border:0;text-decoration:none;font-size:12px;cursor:pointer}.sid-header nav a:hover,.sid-header nav button:hover{color:var(--gold)}.sid-order-btn,.sid-gold-btn{border:0;background:var(--gold);color:#3c2700;border-radius:999px;padding:12px 20px;font-weight:900;cursor:pointer}.sid-mobile-menu{display:none;border:0;background:none;color:#fff;font-size:26px}.sid-hero{min-height:490px;background-size:cover;background-position:center;display:flex;align-items:center;color:#fff}.sid-hero-inner{max-width:1400px;width:100%;margin:auto;padding:70px 7%;position:relative}.sid-hero-copy{max-width:670px}.sid-script{font-family:cursive;color:var(--gold);font-size:34px;font-style:italic}.sid-hero h1{font-family:Georgia,serif;font-size:52px;line-height:1.03;margin:8px 0 15px;max-width:650px}.sid-hero p{font-size:14px;line-height:1.65;color:#eee;max-width:600px}.sid-hero-meta{display:flex;gap:12px;flex-wrap:wrap;margin:18px 0;color:#f7e7ba;font-size:12px}.sid-hero-actions{display:flex;gap:10px}.sid-ghost-btn{background:transparent;color:#fff;border:1px solid #fff;border-radius:999px;padding:11px 20px;cursor:pointer}.sid-hero-controls{position:absolute;right:7%;bottom:35px;display:flex;align-items:center;gap:8px}.sid-hero-controls button{width:38px;height:38px;border-radius:50%;border:1px solid #fff;background:#ffffff22;color:#fff;font-size:22px;cursor:pointer}.sid-highlights{display:grid;grid-template-columns:repeat(4,1fr);background:#941519;color:#fff}.sid-highlights button{min-height:105px;background:none;color:#fff;border:0;border-right:1px solid #ffffff66;display:grid;place-items:center;align-content:center;gap:4px;cursor:pointer}.sid-highlights i{font-style:normal;color:#f0c850;font-size:25px}.sid-highlights b{font-family:Georgia,serif;font-size:14px}.sid-highlights small{font-size:10px;color:#f4dede}.sid-section{max-width:1320px;margin:auto;padding:56px 28px}.sid-section-head{display:flex;justify-content:space-between;align-items:end;gap:20px;margin-bottom:25px}.sid-section-head.centered{justify-content:center;text-align:center}.sid-section-head span,.sid-offer span,.sid-reservation span{font-size:10px;letter-spacing:2px;color:#8d6b24;font-weight:900}.sid-section-head h2{font-family:Georgia,serif;font-size:32px;margin:6px 0 0;color:#15271f}.sid-section-head small{color:#777}.sid-section-head>button{border:1px solid #d3ad54;background:#fffaf0;color:#31543f;border-radius:999px;padding:10px 18px;font-weight:800;cursor:pointer}.sid-dish-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:16px}.sid-dish-grid article{background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 7px 24px #17352a12;cursor:pointer;border:1px solid #e8e1d6}.sid-dish-image{height:180px;position:relative;background:#e9e2d7}.sid-dish-image img,.sid-gallery-grid img{width:100%;height:100%;object-fit:cover;display:block}.sid-dish-image>div{height:100%;display:grid;place-items:center;font-size:40px}.sid-dish-image em{position:absolute;top:10px;left:10px;background:#8b1215;color:#fff;padding:5px 8px;border-radius:999px;font-size:8px;font-style:normal}.sid-dish-grid h3{font-family:Georgia,serif;font-size:16px;margin:12px 14px 4px}.sid-dish-grid p{font-size:11px;color:#777;margin:0 14px;min-height:30px}.sid-dish-grid strong{display:block;margin:8px 14px 15px;color:#183f2e}.sid-category-band{background:#063b2b;color:#fff;padding:52px 28px}.sid-category-band .sid-section-head h2{color:#fff}.sid-category-band .sid-section-head span{color:var(--gold)}.sid-category-row{max-width:1220px;margin:auto;display:flex;justify-content:center;gap:24px;flex-wrap:wrap}.sid-category-row button{width:130px;border:0;background:none;color:#fff;display:grid;place-items:center;gap:7px;cursor:pointer}.sid-category-row img,.sid-category-row i{width:82px;height:82px;border-radius:50%;object-fit:cover;border:2px solid var(--gold);background:#fff7df;display:grid;place-items:center;font-size:28px;font-style:normal}.sid-category-row b{font-size:12px}.sid-category-row small{font-size:9px;color:#c7d9d1}.sid-about{display:grid;grid-template-columns:1.05fr 1fr;gap:55px;align-items:center}.sid-about-image{height:390px;border-radius:22px;overflow:hidden}.sid-about-image img{width:100%;height:100%;object-fit:cover}.sid-placeholder{height:100%;display:grid;place-items:center;background:#d9d0bf;font-family:Georgia,serif;font-size:28px}.sid-about-copy>span{font-size:10px;letter-spacing:2px;color:#8d6b24;font-weight:900}.sid-about-copy h2{font-family:Georgia,serif;font-size:40px;margin:7px 0}.sid-about-copy h4{font-family:Georgia,serif;color:#8b6d2e;margin:0 0 14px}.sid-about-copy p{line-height:1.7;color:#5c655f;font-size:13px}.sid-about-features{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin:22px 0}.sid-about-features div{text-align:center}.sid-about-features i{width:44px;height:44px;border-radius:50%;display:grid;place-items:center;margin:auto;border:1px solid #d5ac50;background:#fff7df;font-style:normal}.sid-about-features b,.sid-about-features small{display:block}.sid-about-features b{font-size:10px;margin-top:6px}.sid-about-features small{font-size:8px;color:#777;margin-top:3px}.sid-gallery-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:14px}.sid-gallery-grid button{height:190px;border:0;border-radius:13px;overflow:hidden;padding:0;cursor:pointer;background:#ddd}.sid-gallery-grid img{transition:.3s}.sid-gallery-grid button:hover img{transform:scale(1.04)}.sid-offer{max-width:1320px;margin:0 auto 25px;min-height:270px;padding:42px 50px;background:linear-gradient(100deg,#8b1215,#5b090d);border-radius:0;color:#fff;display:flex;justify-content:space-between;align-items:center;overflow:hidden}.sid-offer h2{font-family:Georgia,serif;font-size:38px;line-height:1;margin:10px 0}.sid-offer p{max-width:560px;color:#f7e9e4}.sid-offer-image{position:relative;width:280px;height:210px;display:grid;place-items:center}.sid-offer-image img{width:100%;height:100%;object-fit:cover;border-radius:50%}.sid-offer-image>div{width:130px;height:130px;border:2px solid #e9c762;border-radius:50%;display:grid;place-items:center;font-size:34px;font-weight:900}.sid-offer-image>div small{font-size:14px}.sid-offer-image>b{position:absolute;right:0;top:15px;background:#6e0c10;border:1px solid #e9c762;border-radius:50%;width:78px;height:78px;display:grid;place-items:center;text-align:center;font-size:12px}.sid-reviews{background:#faf7f0}.sid-review-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:20px}.sid-review-grid article{background:#fff;padding:24px;border-radius:12px;border:1px solid #e7dfd3;box-shadow:0 5px 20px #00000008}.sid-review-grid img{width:40px;height:40px;border-radius:50%;object-fit:cover}.stars{color:#e8af21;letter-spacing:2px}.sid-review-grid p{font-size:13px;line-height:1.6;min-height:55px;color:#555}.sid-review-grid b,.sid-review-grid small{display:block}.sid-review-grid small{color:#888;margin-top:4px}.sid-reservation{max-width:1320px;margin:0 auto 0;padding:45px 40px;background:linear-gradient(100deg,#17140fdd,#173b2edd),url('/assets/restaurant-bg.jpg');background-size:cover;color:#fff;display:grid;grid-template-columns:1fr 1.15fr;gap:35px;align-items:center}.sid-reservation h2{font-family:Georgia,serif;font-size:40px;margin:8px 0}.sid-reservation p{color:#e5e5df}.sid-reservation-card{background:#fff;border-radius:13px;padding:14px;display:grid;grid-template-columns:1fr 1fr;gap:9px}.sid-reservation-card input{padding:12px;border:1px solid #ddd;border-radius:8px}.sid-reservation-card button{grid-column:1/-1;border:0;background:#e9b63d;color:#3c2700;border-radius:8px;padding:13px;font-weight:900;cursor:pointer}.sid-reservation-card small{grid-column:1/-1;color:#555}.sid-footer{background:#003b2b;color:#fff;padding:45px 7% 0;display:grid;grid-template-columns:1.5fr 1fr 1.2fr 1fr;gap:35px;position:relative}.sid-footer-brand img{width:62px;height:62px;object-fit:contain}.sid-footer h3{font-family:Georgia,serif;margin:7px 0}.sid-footer h4{color:var(--gold);margin:0 0 14px}.sid-footer p,.sid-footer span,.sid-footer a,.sid-footer button{display:block;color:#c9d8d2;font-size:11px;line-height:1.7}.sid-footer a,.sid-footer button{background:none;border:0;text-decoration:none;cursor:pointer;text-align:left;padding:0}.sid-footer-bottom{grid-column:1/-1;border-top:1px solid #ffffff22;padding:16px 0;font-size:10px;color:#c6d2cd}.sid-footer-bottom span{float:right;display:inline}.sid-social{display:flex;gap:12px;margin-top:10px}.sid-social a{display:inline}.sid-overlay{position:fixed;inset:0;background:#0009;z-index:200;display:flex;justify-content:flex-end}.sid-menu-drawer,.sid-cart-drawer{height:100%;width:min(620px,96vw);background:#fff;overflow:auto;padding:24px}.sid-cart-drawer{width:min(520px,96vw)}.sid-drawer-head{display:flex;justify-content:space-between;align-items:start;border-bottom:1px solid #eee;padding-bottom:15px}.sid-drawer-head span{font-size:9px;letter-spacing:2px;color:#9b762d;font-weight:900}.sid-drawer-head h2{font-family:Georgia,serif;margin:5px 0}.sid-drawer-head button,.sid-close{border:0;background:#eee;border-radius:50%;width:35px;height:35px;font-size:23px;cursor:pointer}.sid-menu-toolbar{padding:16px 0}.sid-menu-toolbar input,.sid-checkout input,.sid-checkout textarea{width:100%;border:1px solid #ddd;border-radius:9px;padding:12px}.sid-menu-toolbar>div{display:flex;gap:7px;overflow:auto;margin-top:10px}.sid-menu-toolbar button,.sid-mode-row button{border:1px solid #ddd;background:#fff;border-radius:999px;padding:7px 12px;cursor:pointer;white-space:nowrap}.sid-menu-toolbar button.active,.sid-mode-row button.active{background:#063b2b;color:#fff;border-color:#063b2b}.sid-drawer-items{display:grid;gap:9px}.sid-drawer-items article{display:grid;grid-template-columns:80px 1fr auto;gap:12px;align-items:center;border:1px solid #eee;border-radius:12px;padding:9px;cursor:pointer}.sid-drawer-items article>div{height:70px;border-radius:8px;overflow:hidden;background:#eee}.sid-drawer-items img{width:100%;height:100%;object-fit:cover}.sid-drawer-items article>div>span{height:100%;display:grid;place-items:center}.sid-drawer-items section b,.sid-drawer-items section small,.sid-drawer-items section strong{display:block}.sid-drawer-items section small{color:#777;font-size:10px;margin:4px 0}.sid-drawer-items article>button{border:0;background:#e9b63d;border-radius:999px;padding:8px 12px;font-weight:800;cursor:pointer}.sid-mode-row{display:flex;gap:7px;padding:14px 0}.sid-cart-lines{display:grid;gap:10px}.sid-cart-lines>div{display:flex;justify-content:space-between;gap:10px;border-bottom:1px solid #eee;padding-bottom:10px}.sid-cart-lines b,.sid-cart-lines small,.sid-cart-lines strong{display:block}.sid-cart-lines small{color:#777;font-size:10px;margin:3px 0}.sid-cart-lines>div>div:last-child{display:flex;align-items:center;gap:8px}.sid-cart-lines button{border:1px solid #ddd;background:#fff;border-radius:50%;width:27px;height:27px;cursor:pointer}.sid-checkout{display:grid;gap:10px;margin-top:18px}.sid-checkout>div{display:grid;gap:6px;padding:12px;background:#f8f5ed;border-radius:10px}.sid-checkout>div span,.sid-checkout>div strong{display:flex;justify-content:space-between}.sid-place{border:0;background:#e9b63d;color:#3c2700;padding:13px;border-radius:10px;font-weight:900;cursor:pointer}.sid-dish-modal{width:min(560px,94vw);max-height:90vh;overflow:auto;background:#fff;border-radius:18px;padding:22px;position:relative}.sid-dish-modal>img{width:100%;height:220px;object-fit:cover;border-radius:12px}.sid-dish-modal>span{display:block;color:#8d6b24;font-size:10px;margin-top:12px}.sid-dish-modal h2{font-family:Georgia,serif;margin:6px 0}.sid-dish-modal label{display:grid;grid-template-columns:20px 1fr auto;gap:8px;padding:10px;border:1px solid #eee;border-radius:9px;margin:7px 0}.sid-lightbox{position:fixed;inset:0;background:#000e;z-index:300;display:grid;place-items:center;padding:40px}.sid-lightbox img{max-width:90vw;max-height:85vh;object-fit:contain}.sid-lightbox>button{position:absolute;right:25px;top:20px;border:0;background:#fff;border-radius:50%;width:38px;height:38px;font-size:25px;cursor:pointer}.sid-lightbox .prev,.sid-lightbox .next{top:50%;right:auto;left:20px}.sid-lightbox .next{left:auto;right:20px}.sid-loading{min-height:70vh;display:grid;place-items:center;font-family:Georgia,serif;font-size:22px}.sid-empty,.sid-offer-empty{padding:30px;text-align:center;color:#777;background:#fff;border:1px dashed #d8d0c2;border-radius:12px}@media(max-width:950px){.sid-header nav{display:none}.sid-mobile-menu{display:block;margin-left:auto}.sid-order-btn{display:none}.sid-dish-grid{grid-template-columns:repeat(2,1fr)}.sid-about{grid-template-columns:1fr}.sid-about-image{height:300px}.sid-gallery-grid{grid-template-columns:repeat(2,1fr)}.sid-review-grid{grid-template-columns:1fr}.sid-reservation{grid-template-columns:1fr}.sid-footer{grid-template-columns:repeat(2,1fr)}.sid-highlights{grid-template-columns:repeat(2,1fr)}}@media(max-width:600px){.sid-header-inner{padding:7px 14px}.sid-brand{min-width:0}.sid-brand b{font-size:12px}.sid-hero{min-height:570px}.sid-hero-inner{padding:45px 22px}.sid-script{font-size:28px}.sid-hero h1{font-size:40px}.sid-highlights{grid-template-columns:repeat(2,1fr)}.sid-section{padding:42px 16px}.sid-section-head{align-items:start}.sid-section-head h2{font-size:27px}.sid-dish-grid{grid-template-columns:1fr}.sid-category-row{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}.sid-category-row button{width:auto}.sid-category-row img,.sid-category-row i{width:70px;height:70px}.sid-about-copy h2{font-size:32px}.sid-about-features{grid-template-columns:repeat(2,1fr)}.sid-gallery-grid{grid-template-columns:1fr}.sid-gallery-grid button{height:220px}.sid-offer{margin:0;padding:35px 22px;display:block}.sid-offer-image{margin:20px auto 0}.sid-reservation{padding:35px 18px}.sid-reservation-card{grid-template-columns:1fr}.sid-reservation-card button{grid-column:1}.sid-footer{grid-template-columns:1fr;padding:35px 20px 0}.sid-footer-bottom{grid-column:1}.sid-footer-bottom span{float:none;margin-top:8px}.sid-hero-actions{flex-wrap:wrap}}
    `}</style>
  </main>;
}
