'use client';
import {useEffect,useMemo,useState} from 'react';
import {supabase} from '../../lib/supabase';

const defaultFeatures=[
 {icon:'🍽️',title:'Multiple Restaurants',text:'Choose from the best local restaurants'},
 {icon:'🥬',title:'Fresh & Hygienic Food',text:'Quality food, prepared with care'},
 {icon:'🚴',title:'Fast Delivery',text:'Hot & fresh food at your doorstep'},
 {icon:'💳',title:'Secure Payments',text:'Multiple safe payment options'},
 {icon:'🎁',title:'Exclusive Offers',text:'Best deals and discounts'},
 {icon:'📞',title:'24/7 Support',text:'We are always here to help'},
];
const defaultCategories=['North Indian','Chinese','Fast Food','Tandoori','Pizza','Burgers','Momos','Thali','Beverages','Desserts'];
const categoryIcons=['🍛','🥡','🍔','🔥','🍕','🍔','🥟','🍱','☕','🍰'];
export default function Marketplace(){
 const [mode,setMode]=useState('all'),[city,setCity]=useState(''),[search,setSearch]=useState(''),[items,setItems]=useState([]),[loading,setLoading]=useState(true),[error,setError]=useState('');
 const [heroSlides,setHeroSlides]=useState([]),[heroIndex,setHeroIndex]=useState(0),[features,setFeatures]=useState(defaultFeatures),[dishes,setDishes]=useState([]),[dishIndex,setDishIndex]=useState(0),[categories,setCategories]=useState([]),[offers,setOffers]=useState([]),[globalCategories,setGlobalCategories]=useState([]);
 async function load(){
  setLoading(true);setError('');
  const [{data,error:rpcError},{data:store},{data:featureRows},{data:ps}]=await Promise.all([
   supabase.rpc('anaira_marketplace_businesses',{p_city:city||null,p_mode:mode==='all'?'all':mode}),
   supabase.from('anaira_platform_stores').select('id').eq('store_type','restaurant').eq('enabled',true).eq('published',true).maybeSingle(),
   supabase.from('anaira_platform_settings').select('key,value').in('key',['restaurant_home_feature_icons','restaurant_home_categories','restaurant_home_hero_image','restaurant_home_hero_mobile_image']),
   supabase.from('anaira_platform_settings').select('key,value').in('key',['restaurant_home_title','restaurant_home_subtitle'])
  ]);
  if(rpcError)setError(rpcError.message);else setItems(data||[]);
  const parsed=featureRows?.find(x=>x.key==='restaurant_home_feature_icons')?.value?.value??featureRows?.find(x=>x.key==='restaurant_home_feature_icons')?.value;
  if(Array.isArray(parsed)&&parsed.length)setFeatures(parsed);
  const catSetting=featureRows?.find(x=>x.key==='restaurant_home_categories')?.value?.value??featureRows?.find(x=>x.key==='restaurant_home_categories')?.value;
  if(Array.isArray(catSetting)&&catSetting.length){setGlobalCategories(catSetting);setCategories(catSetting.map(x=>x.name));}
  const ids=(data||[]).map(x=>x.restaurant_id).filter(Boolean);
  if(store?.id){
   const {data:b}=await supabase.from('anaira_store_banners').select('*').eq('store_id',store.id).is('restaurant_id',null).eq('active',true).order('display_order');
   setHeroSlides(b||[]);
  }
  if(ids.length){
   const [{data:f},{data:m}]=await Promise.all([
    supabase.from('anaira_marketplace_featured_items').select('*').in('restaurant_id',ids).eq('active',true).order('display_order'),
    supabase.from('anaira_marketplace_menu_items').select('id,item_name,name,price,discount_price,image_url,image,restaurant_id,category_name,description').in('restaurant_id',ids).eq('active',true).limit(500)
   ]);
   const menu=m||[];
   setDishes((f||[]).map(x=>{const i=menu.find(y=>String(y.id)===String(x.external_item_id)&&String(y.restaurant_id)===String(x.restaurant_id));return i?{...i,...x,item_name:x.title_override||i.item_name||i.name,image_url:x.image_override||i.image_url||i.image}:null}).filter(Boolean).slice(0,30));
   const cats=[];menu.forEach(x=>{if(x.category_name&&!cats.includes(x.category_name))cats.push(x.category_name)});if(!(Array.isArray(catSetting)&&catSetting.length))setCategories(cats.length?cats.slice(0,10):defaultCategories);
   const liveOffers=[];for(const rid of ids.slice(0,80)){try{const res=await fetch(`/api/marketplace/restaurant/${rid}`,{cache:'no-store'});const j=await res.json();(j?.data?.offers||[]).slice(0,2).forEach(o=>liveOffers.push({...o,restaurant_id:rid,restaurantName:(data||[]).find(x=>x.restaurant_id===rid)?.name||'Restaurant'}))}catch{}}
   setOffers(liveOffers.slice(0,8));
  } else {setDishes([]);setCategories(defaultCategories);setOffers([])}
  setLoading(false);
 }
 useEffect(()=>{load()},[mode]);
 useEffect(()=>{if(heroSlides.length<2)return;const t=setInterval(()=>setHeroIndex(i=>(i+1)%heroSlides.length),5000);return()=>clearInterval(t)},[heroSlides.length]);
 useEffect(()=>{if(dishes.length<6)return;const t=setInterval(()=>setDishIndex(i=>(i+1)%Math.max(1,dishes.length-5)),4200);return()=>clearInterval(t)},[dishes.length]);
 const filtered=useMemo(()=>items.filter(x=>`${x.name||''} ${x.city||''} ${x.cuisine||''} ${x.address||''}`.toLowerCase().includes(search.toLowerCase())),[items,search]);
 const visibleDishes=useMemo(()=>dishes.slice(dishIndex,dishIndex+6),[dishes,dishIndex]);
 const hero=heroSlides[heroIndex];
 return <main className="anaira-marketplace-pro">
  <header className="amp-top"><div className="amp-brand"><span className="amp-logo">♨</span><div><b>ANAIRA</b><small>FOOD MARKETPLACE</small></div></div><nav><a href="/marketplace">Home</a><a href="#restaurants">Restaurants</a><a href="#categories">Categories</a><a href="#dishes">Popular Dishes</a><a href="#offers">Offers</a><a href="#about">About</a><a href="#contact">Contact</a></nav><div className="amp-top-actions"><span>📍 {city||'Manali, Himachal'}</span><a href="/login">Account</a><a href="#cart">🛒</a></div></header>
  <section className="amp-hero" style={{backgroundImage:hero?.image_url?`linear-gradient(90deg,rgba(3,24,16,.86),rgba(3,24,16,.20)),url(${hero.image_url})`:'linear-gradient(120deg,#062d22,#176047)'}}>
   <div className="amp-hero-copy"><span className="amp-script">Delicious Food</span><h1>{hero?.title||'From Your Favourite Restaurants'}</h1><p>{hero?.subtitle||'Order food from the best restaurants in Manali & nearby areas. Fresh · Tasty · Hygienic · Fast Delivery.'}</p><div className="amp-search"><input value={city} onChange={e=>setCity(e.target.value)} placeholder="📍 Deliver to Manali, Himachal"/><input value={search} onChange={e=>setSearch(e.target.value)} placeholder="Search restaurant, cuisine or dish…"/><button onClick={load}>⌕ Search</button></div><div className="amp-chips"><span>Popular Searches</span>{['Momos','Pizza','Thali','North Indian','Chinese','Cafe','Tandoori'].map(x=><button key={x} onClick={()=>setSearch(x)}>{x}</button>)}</div></div>
   {heroSlides.length>1&&<div className="amp-slider"><button onClick={()=>setHeroIndex(i=>(i-1+heroSlides.length)%heroSlides.length)}>‹</button><span>{heroIndex+1} / {heroSlides.length}</span><button onClick={()=>setHeroIndex(i=>(i+1)%heroSlides.length)}>›</button></div>}
  </section>
  <section className="amp-feature-strip" id="categories">{categories.map((c,i)=><article key={c}><div>{categoryIcons[i%categoryIcons.length]}</div><b>{c}</b><small>Explore dishes</small></article>)}</section>
  <section className="amp-section" id="dishes"><div className="amp-head"><div><span>RESTAURANT-SPECIFIC</span><h2>Popular Dishes</h2><p>Popular dishes selected from the restaurant that actually serves them.</p></div><a href="#restaurants">View all restaurants →</a></div>{visibleDishes.length?<div className="amp-dish-grid">{visibleDishes.map(d=><a key={`${d.restaurant_id}-${d.id}`} className="amp-dish" href={`/store/${d.restaurant_id}?dish=${encodeURIComponent(d.id)}`}><div className="amp-dish-img">{d.image_url?<img src={d.image_url} alt=""/>:<div>🍽️</div>}<b>POPULAR</b><button type="button" onClick={e=>e.stopPropagation()}>♡</button></div><h3>{d.item_name}</h3><p>{d.restaurantName||'Restaurant'} · {d.category_name||'Special'}</p><strong>₹{d.discount_price??d.price}</strong><small>Open dish ↗</small></a>)}</div>:<div className="amp-empty">Add restaurant-specific popular dishes from Super Admin Marketplace Settings or Restaurant Store Builder.</div>}</section>
  <section className="amp-section compact-section" id="restaurants"><div className="amp-head"><div><span>DISCOVER THE BEST</span><h2>Top Rated Restaurants</h2><p>Explore approved restaurants and order directly through Anaira.</p></div><span>{loading?'Loading…':`${filtered.length} restaurants`}</span></div><div className="amp-rest-grid">{filtered.map(x=><article className="amp-rest" key={x.restaurant_id}><div className="amp-rest-cover" style={{backgroundImage:x.cover_image?`url(${x.cover_image})`:'linear-gradient(135deg,#0b4d37,#d4aa4c)'}}><span>★ {x.rating||'4.8'}</span></div><div className="amp-rest-body"><h3>{x.name}</h3><p>📍 {x.address||x.city||'India'}</p><small>{x.cuisine||'Multi Cuisine'} · {x.delivery_enabled===false?'Pickup':'Delivery'}</small><div className="amp-rest-actions">{x.food_ordering_enabled&&<a href={`/store/${x.restaurant_id}`}>Order Food →</a>}{x.restaurant_reservation_enabled&&<a className="light" href={`/restaurant-reservation/${x.restaurant_id}`}>Reserve</a>}</div></div></article>)}</div>{!loading&&!filtered.length&&<div className="amp-empty">No approved marketplace restaurants found.</div>}</section>
  {offers.length>0&&<section className="amp-promo-row" id="offers">{offers.slice(0,2).map((o,i)=><article key={o.id||i}><div><span>SPECIAL OFFER</span><h2>{o.title||'Delicious Food Special'}</h2><p>{o.description||'Enjoy a special offer from a participating restaurant.'}</p><b>{o.discount_type==='percent'?`${o.discount||o.discount_value}% OFF`:`₹${o.discount||o.discount_value} OFF`}</b><a href={`/store/${o.restaurant_id}`}>Order Now →</a></div><div className="promo-art">🍛</div></article>)}</section>}
  <section className="amp-benefits" id="about"><div><span>WHY CHOOSE ANAIRA FOOD?</span><h2>A better food experience for everyone.</h2><p>One premium marketplace connecting customers with real restaurant menus and the existing Anaira ordering flow.</p></div><div className="amp-benefit-grid">{features.slice(0,6).map((f,i)=><article key={i}><b>{f.icon||'✦'}</b><strong>{f.title}</strong><p>{f.text}</p></article>)}</div></section>
  <section className="amp-landscape"><div><span>TASTE THE FLAVOURS</span><h2>Flavours of Himachal</h2><p>From local favourites to global cuisines, discover great food in one place.</p><a href="#restaurants">Explore Restaurants →</a></div></section>
  <section className="amp-how"><div className="amp-head centered"><div><span>SIMPLE & FAST</span><h2>How It Works?</h2><p>Get your favourite food in just a few steps.</p></div></div><div className="amp-how-grid">{[['📍','Choose Location','Select your delivery address'],['🍽️','Find a Restaurant','Explore multiple restaurants near you'],['🛍️','Place Your Order','Add items & make payment'],['🛵','Get It Delivered','Enjoy your delicious food']].map((x,i)=><article key={x[1]}><b>{x[0]}</b><strong>{x[1]}</strong><small>{x[2]}</small>{i<3&&<em>→</em>}</article>)}</div></section>
  <section className="amp-app-promo"><div><span>ORDER ON THE GO</span><h2>Download Our App</h2><p>Get the best food delivery experience with our mobile app.</p><div><button>▶ Google Play</button><button> App Store</button></div></div><div className="amp-phone-art">📱</div><ul><li>🎁 Exclusive App Offers</li><li>⚡ Faster Ordering</li><li>📍 Live Order Tracking</li><li>↻ Easy Reordering</li></ul></section>
  <section className="amp-reviews"><div className="amp-head centered"><div><span>REAL REVIEWS</span><h2>What Our Customers Say</h2><p>Real reviews from food lovers.</p></div></div><div className="amp-review-grid">{[['👨🏻','Rohit Sharma','Amazing food quality and super fast delivery. Best food experience in Manali!'],['👩🏻','Priya Verma','Loved the variety of restaurants and local Himachali cuisine.'],['👨🏻','Amit Negi','Fresh food, great taste and friendly support.']].map(x=><article key={x[1]}><span>{x[0]}</span><div>★★★★★</div><p>“{x[2]}”</p><b>{x[1]}</b></article>)}</div></section>
  <footer className="amp-footer" id="contact"><div><b>ANAIRA</b><span>Food Marketplace</span><p>Bringing the best restaurants, local flavours and delicious food to your doorstep.</p><div className="socials">◉ ◎ ▶ ◌</div></div><div><b>Quick Links</b><a href="/marketplace">Home</a><a href="#restaurants">Restaurants</a><a href="#categories">Categories</a><a href="#offers">Offers</a><a href="#about">About Us</a><a href="#contact">Contact</a></div><div><b>Customer Support</b><a href="#contact">Help Center</a><a href="#contact">Track Order</a><a href="#contact">Returns & Refunds</a><a href="#contact">Terms & Conditions</a><a href="#contact">Privacy Policy</a></div><div><b>Our App</b><button>▶ Google Play</button><button> App Store</button><small>Made with ♥ in Himachal</small></div><div className="amp-copyright">© 2026 Anaira Food Marketplace. All Rights Reserved.</div></footer>
 </main>
}
