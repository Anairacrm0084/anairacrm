'use client';

import {useEffect, useMemo, useState} from 'react';
import {AppShell, Header, Section} from '../../components';
import {supabase} from '../../../lib/supabase';

const ANAIRA_GRAPHICS_ID = '737d5047-39f0-480b-8279-c7b1262f9e6c';
const CATS = ['Graphics & Digital Design','Digital Printing','Web Design & Development','SEO & Local SEO','Social Media Marketing','Software & App Development','Signage & Display'];
const GROUPS = ['Websites & Web Projects','Anaira Products & SaaS','Client Software & Platforms','Design & Branding','Print & Signage','Other'];

const PAGE_GROUPS = {
  Business:[['businessName','Business Name'],['businessShort','Short Business Name'],['phone','Phone'],['phoneHref','Phone Link'],['whatsapp','WhatsApp Link'],['address','Address']],
  Navigation:[['navServices','Services'],['navWork','Our Work'],['navProcess','Process'],['navContact','Contact'],['navCta','Navigation CTA']],
  Hero:[['eyebrow','Eyebrow'],['heroTitle','Hero Title'],['heroDescription','Hero Description'],['heroPrimary','Primary Button'],['heroSecondary','Secondary Button'],['trust1','Trust Item 1'],['trust2','Trust Item 2'],['trust3','Trust Item 3'],['trust4','Trust Item 4'],['trust5','Trust Item 5'],['artChip1','Hero Chip 1'],['artChip2','Hero Chip 2'],['artChip3','Hero Chip 3']],
  Proof:[['proofTitle','Proof Title'],['proofText','Proof Text'],['proofLink','Proof Link']],
  Focus:[['focusKicker','Section Kicker'],['focusTitle','Focus Title'],['focusText','Focus Description'],['focusCtaTitle','Work Reel Title'],['focusCtaText','Work Reel Text'],['focusPill1','Pill 1'],['focusPill2','Pill 2'],['focusPill3','Pill 3'],['focusPill4','Pill 4'],['webKicker','Web Kicker'],['webTitle','Web Title'],['webText','Web Description'],['webAction','Web CTA'],['webViewAll','Web View All'],['softwareKicker','Software Kicker'],['softwareTitle','Software Title'],['softwareText','Software Description'],['softwareAction','Software CTA'],['softwareViewAll','Software View All'],['designKicker','Design Kicker'],['designTitle','Design Title'],['designText','Design Description'],['designAction','Design CTA'],['designViewAll','Design View All'],['printKicker','Print Kicker'],['printTitle','Print Title'],['printText','Print Description'],['printAction','Print CTA'],['printViewAll','Print View All'],['webChip1','Web Chip 1'],['webChip2','Web Chip 2'],['webChip3','Web Chip 3'],['webChip4','Web Chip 4'],['softwareChip1','Software Chip 1'],['softwareChip2','Software Chip 2'],['softwareChip3','Software Chip 3'],['softwareChip4','Software Chip 4'],['designChip1','Design Chip 1'],['designChip2','Design Chip 2'],['designChip3','Design Chip 3'],['designChip4','Design Chip 4'],['printChip1','Print Chip 1'],['printChip2','Print Chip 2'],['printChip3','Print Chip 3'],['printChip4','Print Chip 4'],['statsProjects','Projects Stat'],['statsProjectsLabel','Projects Label'],['statsClients','Clients Stat'],['statsClientsLabel','Clients Stat Label'],['statsYears','Experience Stat'],['statsYearsLabel','Experience Label'],['statsComplete','Complete Stat'],['statsCompleteText','Complete Stat Text']],
  Services:[['servicesKicker','Services Kicker'],['servicesTitle','Services Title'],['servicesText','Services Description']],
  Portfolio:[['portfolioKicker','Portfolio Kicker'],['portfolioTitle','Portfolio Title'],['portfolioText','Portfolio Description'],['webProjectsLabel','Web Projects Label'],['anairaProductsLabel','Anaira Products Label'],['clientSoftwareLabel','Client Software Label'],['servicesCountLabel','Services Count Label'],['websitesCategoryTitle','Websites Category Title'],['anairaProductsCategoryTitle','Anaira Products Category Title'],['clientSoftwareCategoryTitle','Client Software Category Title'],['moreWorkCategoryTitle','More Work Category Title'],['projectCountLabel','Project Count Label'],['systemCountLabel','System Count Label'],['marqueeLabel','Work Marquee Label']],
  Why:[['whyKicker','Why Kicker'],['whyTitle','Why Title'],['why1Title','Why #1 Title'],['why1Text','Why #1 Text'],['why2Title','Why #2 Title'],['why2Text','Why #2 Text'],['why3Title','Why #3 Title'],['why3Text','Why #3 Text']],
  Process:[['processKicker','Process Kicker'],['processTitle','Process Title'],['process1Title','Process 01 Title'],['process1Text','Process 01 Text'],['process2Title','Process 02 Title'],['process2Text','Process 02 Text'],['process3Title','Process 03 Title'],['process3Text','Process 03 Text'],['process4Title','Process 04 Title'],['process4Text','Process 04 Text']],
  CTA:[['ctaKicker','CTA Kicker'],['ctaTitle','CTA Title'],['ctaText','CTA Description'],['ctaButton','CTA Button']],
  CommerceUI:[['allServicesLabel','All Services Label'],['relatedServicesLabel','Related Services Label'],['closeLabel','Close Label'],['enquireLabel','Enquire Label'],['addToCartLabel','Add to Cart Label'],['viewDemoLabel','View Demo Label'],['serviceCountLabel','Service Count Label'],['showLessLabel','Show Less Label'],['showMoreLabel','Show More Label'],['viewAllLabel','View All Label'],['demoLabel','Demo Label'],['showingLabel','Showing Label'],['useLabel','Use Label'],['showMorePlainLabel','Show More Plain Label'],['orLabel','Or Label'],['viewAllPlainLabel','View All Plain Label'],['cartTitle','Cart Title'],['checkoutTitle','Checkout Title'],['selectedServicesTitle','Selected Services Title'],['cartEmptyText','Empty Cart Text'],['estimatedTotalLabel','Estimated Total Label'],['customQuoteLabel','Custom Quote Label'],['continueCheckoutLabel','Continue Checkout Label'],['deliveryNotesLabel','Delivery Notes Label'],['backLabel','Back Label'],['submittingLabel','Submitting Label'],['placeOrderLabel','Place Order Label']],
  Contact:[['contactKicker','Contact Kicker'],['websiteProjectTypeLabel','Website Project Type Label'],['softwareProjectTypeLabel','Software Project Type Label'],['nameLabel','Name Label'],['phoneLabel','Phone Label'],['emailLabel','Email Label'],['qtyLabel','Quantity Label'],['orderRequestSuccessPrefix','Order Success Prefix'],['receivedText','Order Received Text'],['contactTitle','Contact Title'],['contactText','Contact Description'],['contactButton','Contact Button'],['contactPhoneLabel','Phone Label'],['contactWhatsappLabel','WhatsApp Label'],['contactWhatsappText','WhatsApp Text'],['contactLocationLabel','Location Label'],['formNamePlaceholder','Name Placeholder'],['formPhonePlaceholder','Phone Placeholder'],['formEmailPlaceholder','Email Placeholder'],['formServiceLabel','Service Label'],['formServicePlaceholder','Service Placeholder'],['formMessageLabel','Message Label'],['formMessagePlaceholder','Message Placeholder'],['formSubmit','Form Submit'],['formSending','Form Sending'],['formSuccess','Form Success'],['footerTagline','Footer Tagline'],['footerCopyright','Footer Copyright']]
};

async function getToken(){
  const {data} = await supabase.auth.getSession();
  return data?.session?.access_token || '';
}

function PageTextSettings({initial, onSaved}){
  const [f,setF] = useState(initial || {});
  const [busy,setBusy] = useState(false);
  const [msg,setMsg] = useState('');

  useEffect(()=>setF(initial || {}),[initial]);
  const setField = (key,value)=>setF(x=>({...x,[key]:value}));

  async function save(){
    setBusy(true); setMsg('');
    try{
      const token = await getToken();
      const r = await fetch('/api/anaira-graphics/content',{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify({action:'save_settings',settings:f})});
      const j = await r.json();
      if(!r.ok) throw new Error(j.error || 'Unable to save page settings');
      const next = j.settings || f;
      setF(next); onSaved?.(next); setMsg('✓ All landing-page settings saved.');
    }catch(e){setMsg(e.message)}finally{setBusy(false)}
  }

  async function uploadFocus(key,label,file){
    if(!file) return;
    try{
      const token = await getToken();
      const fd = new FormData(); fd.append('file',file);
      const r = await fetch('/api/anaira-graphics/content',{method:'POST',headers:{Authorization:`Bearer ${token}`},body:fd});
      const j = await r.json();
      if(!r.ok) throw new Error(j.error || 'Upload failed');
      setField(key,j.url); setMsg(`${label} uploaded. Save All Changes to publish.`);
    }catch(e){setMsg(e.message)}
  }

  return (
    <div className="ag-page-settings">
      <div className="ag-page-settings-intro">
        <div><div className="ag-kicker">MASTER LANDING CONTROL</div><h2>Edit the complete Anaira Graphics landing from one place.</h2><p>All landing-page content is tenant-scoped. Existing services and projects load automatically from Supabase; add a new record only when you actually create new content.</p></div>
        <button className="ag-settings-primary" onClick={save} disabled={busy}>{busy ? 'Saving…' : 'Save All Changes'}</button>
      </div>
      {msg && <div className="ag-settings-msg">{msg}</div>}
      <section className="ag-page-settings-group">
        <div className="ag-page-settings-group-head"><span>00</span><h3>Focus Visuals</h3></div>
        <div className="ag-focus-settings-images">
          {[['webImage','Web showcase'],['softwareImage','Software showcase'],['designImage','Design showcase'],['printImage','Printing showcase']].map(([key,label])=>(
            <label key={key}>{label}<input type="file" accept="image/*" onChange={e=>uploadFocus(key,label,e.target.files?.[0])}/>{f[key] && <img src={f[key]} alt={label}/>}</label>
          ))}
        </div>
      </section>
      {Object.entries(PAGE_GROUPS).map(([group,fields],index)=>(
        <section className="ag-page-settings-group" key={group}>
          <div className="ag-page-settings-group-head"><span>{String(index+1).padStart(2,'0')}</span><h3>{group}</h3></div>
          <div className="ag-page-settings-grid">
            {fields.map(([key,label])=>(
              <label key={key}>{label}<textarea rows={key.toLowerCase().includes('description') || key.toLowerCase().includes('text') ? 3 : 2} value={f[key] || ''} onChange={e=>setField(key,e.target.value)} /></label>
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}

function ModalEditor({item,kind,onClose,onSaved}){
  const empty = kind==='service'
    ? {title:'',description:'',category:CATS[0],tag:'',icon:'✦',price:0,currency:'INR',unit:'service',buy_enabled:false,demo_url:'',alt_text:'',image_url:'',sort_order:0,status:'active'}
    : {title:'',description:'',portfolio_group:GROUPS[0],type:'website',tag:'',live_url:'',alt_text:'',image_url:'',gallery:[],sort_order:0,status:'active'};
  const [f,setF] = useState({...empty,...(item || {})});
  const [busy,setBusy] = useState(false);
  const [msg,setMsg] = useState('');
  const setField = (key,value)=>setF(x=>({...x,[key]:value}));

  async function upload(file){
    if(!file) return; setBusy(true); setMsg('');
    try{
      const token=await getToken(); const fd=new FormData(); fd.append('file',file);
      const r=await fetch('/api/anaira-graphics/content',{method:'POST',headers:{Authorization:`Bearer ${token}`},body:fd});
      const j=await r.json(); if(!r.ok) throw new Error(j.error || 'Upload failed');
      setField('image_url',j.url); setMsg('Cover image uploaded. Save to publish it.');
    }catch(e){setMsg(e.message)}finally{setBusy(false)}
  }

  async function uploadGallery(files){
    if(!files?.length) return; setBusy(true); setMsg('');
    try{
      const token=await getToken(); const urls=[];
      for(const file of Array.from(files)){
        const fd=new FormData(); fd.append('file',file);
        const r=await fetch('/api/anaira-graphics/content',{method:'POST',headers:{Authorization:`Bearer ${token}`},body:fd});
        const j=await r.json(); if(!r.ok) throw new Error(j.error || 'Gallery upload failed'); urls.push(j.url);
      }
      setField('gallery',[...(f.gallery || []),...urls]); setMsg(`${urls.length} gallery image(s) uploaded. Save to publish.`);
    }catch(e){setMsg(e.message)}finally{setBusy(false)}
  }

  function removeGallery(index){setField('gallery',(f.gallery || []).filter((_,n)=>n!==index));}

  async function save(e){
    e.preventDefault(); setBusy(true); setMsg('');
    try{
      const token=await getToken();
      const r=await fetch('/api/anaira-graphics/content',{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify({action:'save',kind,...f})});
      const j=await r.json(); if(!r.ok) throw new Error(j.error || 'Save failed'); onSaved(j.item);
    }catch(e2){setMsg(e2.message)}finally{setBusy(false)}
  }

  return (
    <div className="ag-settings-modal">
      <div className="ag-settings-modal-card">
        <div className="ag-settings-modal-head"><div><div className="ag-kicker">{kind==='service' ? 'SERVICE' : 'PROJECT'}</div><h2>{item?.id ? 'Edit' : 'Add'} {kind==='service' ? 'Service' : 'Project'}</h2></div><button type="button" onClick={onClose}>×</button></div>
        <form onSubmit={save} className="ag-settings-form">
          <label>Title<input required value={f.title || ''} onChange={e=>setField('title',e.target.value)} placeholder={kind==='service' ? 'e.g. Logo Design' : 'e.g. Anaira POS'}/></label>
          <label>Description<textarea rows="4" value={f.description || ''} onChange={e=>setField('description',e.target.value)} placeholder="Explain what this service/project actually does."/></label>
          {kind==='service' ? (
            <>
              <label>Price (₹)<input type="number" min="0" value={f.price ?? 0} onChange={e=>setField('price',e.target.value)}/></label>
              <label>Billing Unit<input value={f.unit || 'service'} onChange={e=>setField('unit',e.target.value)} placeholder="service / page / month / piece"/></label>
              <label>Buy Online<select value={f.buy_enabled ? 'yes' : 'no'} onChange={e=>setField('buy_enabled',e.target.value==='yes')}><option value="no">No — enquiry only</option><option value="yes">Yes — add to cart</option></select></label>
              <label>Demo URL<input type="url" value={f.demo_url || ''} onChange={e=>setField('demo_url',e.target.value)} placeholder="https://..."/></label>
              <label>Service Category<select value={f.category || CATS[0]} onChange={e=>setField('category',e.target.value)}>{CATS.map(x=><option key={x} value={x}>{x}</option>)}</select></label>
              <label>Short Tag<input value={f.tag || ''} onChange={e=>setField('tag',e.target.value)} placeholder="Branding / Print / SEO / Software"/></label>
              <label>Icon / Symbol<input value={f.icon || '✦'} onChange={e=>setField('icon',e.target.value)}/></label>
            </>
          ) : (
            <>
              <label>Portfolio Group<select value={f.portfolio_group || GROUPS[0]} onChange={e=>setField('portfolio_group',e.target.value)}>{GROUPS.map(x=><option key={x} value={x}>{x}</option>)}</select></label>
              <label>Type<select value={f.type || 'website'} onChange={e=>setField('type',e.target.value)}><option value="website">Website / Web Project</option><option value="software">Software / SaaS</option></select></label>
              <label>Tag / Technology<input value={f.tag || ''} onChange={e=>setField('tag',e.target.value)} placeholder="WordPress / POS / CRM / Hospitality SaaS"/></label>
              <label>Live / Demo URL<input type="url" value={f.live_url || ''} onChange={e=>setField('live_url',e.target.value)} placeholder="https://..."/></label>
            </>
          )}
          <label>Image Alt Text<input value={f.alt_text || ''} onChange={e=>setField('alt_text',e.target.value)} placeholder="Describe this image"/></label>
          <label>Cover / Display Image<input type="file" accept="image/*" onChange={e=>upload(e.target.files?.[0])}/></label>
          {f.image_url && <img className="ag-settings-preview" src={f.image_url} alt={f.alt_text || f.title}/>} 
          {kind==='portfolio' && (
            <>
              <label>Project Gallery — multiple images<input type="file" accept="image/*" multiple onChange={e=>uploadGallery(e.target.files)}/></label>
              {(f.gallery || []).length > 0 && <div className="ag-settings-gallery">{(f.gallery || []).map((url,index)=><div key={`${url}-${index}`}><img src={url} alt={`${f.title || 'Project'} gallery ${index+1}`}/><button type="button" onClick={()=>removeGallery(index)}>×</button></div>)}</div>}
            </>
          )}
          <label>Display Order<input type="number" value={f.sort_order ?? 0} onChange={e=>setField('sort_order',e.target.value)}/></label>
          <label>Status<select value={f.status || 'active'} onChange={e=>setField('status',e.target.value)}><option value="active">Published</option><option value="inactive">Hidden</option></select></label>
          {msg && <div className="ag-settings-msg">{msg}</div>}
          <div className="ag-settings-actions"><button type="button" onClick={onClose}>Cancel</button><button className="ag-settings-primary" disabled={busy}>{busy ? 'Saving…' : kind==='service' ? 'Save Service' : 'Save Project'}</button></div>
        </form>
      </div>
    </div>
  );
}

export default function AnairaGraphicsSettings(){
  const [services,setServices]=useState([]);
  const [portfolio,setPortfolio]=useState([]);
  const [settings,setSettings]=useState({});
  const [tab,setTab]=useState('services');
  const [edit,setEdit]=useState(null);
  const [kind,setKind]=useState('service');
  const [loading,setLoading]=useState(true);
  const [msg,setMsg]=useState('');

  useEffect(()=>{
    const q=new URLSearchParams(window.location.search); const requested=q.get('tab');
    if(['page','services','websites','anaira','clients','software','all'].includes(requested)) setTab(requested);
  },[]);

  async function load(){
    setLoading(true); setMsg('');
    try{
      const token=await getToken();
      let r=await fetch('/api/anaira-graphics/content?admin=1',{headers:{Authorization:`Bearer ${token}`}});
      let j=await r.json();
      if(!r.ok) throw new Error(j.error || 'Unable to load settings');
      if(j.needsSeed){
        const sr=await fetch('/api/anaira-graphics/content',{method:'POST',headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},body:JSON.stringify({action:'seed'})});
        const sj=await sr.json(); if(!sr.ok) throw new Error(sj.error || 'Unable to initialize content');
        r=await fetch('/api/anaira-graphics/content?admin=1',{headers:{Authorization:`Bearer ${token}`}}); j=await r.json(); if(!r.ok) throw new Error(j.error || 'Unable to reload content');
      }
      setServices(j.services || []); setPortfolio(j.portfolio || []); setSettings(j.settings || {});
    }catch(e){setMsg(e.message)}finally{setLoading(false)}
  }

  useEffect(()=>{load()},[]);

  async function remove(id){
    if(!confirm('Delete this item and its uploaded images from Anaira Graphics?')) return;
    const token=await getToken();
    const r=await fetch(`/api/anaira-graphics/content?id=${id}`,{method:'DELETE',headers:{Authorization:`Bearer ${token}`}});
    const j=await r.json(); if(!r.ok){setMsg(j.error || 'Delete failed');return;} setMsg('Deleted successfully.'); load();
  }

  const shown=useMemo(()=>{
    if(tab==='services') return services;
    return portfolio.filter(x=>{
      if(tab==='websites') return x.type==='website';
      if(tab==='software') return x.type==='software';
      if(tab==='clients') return x.portfolio_group==='Client Software & Platforms';
      if(tab==='anaira') return x.portfolio_group==='Anaira Products & SaaS';
      return true;
    });
  },[tab,services,portfolio]);

  function add(){
    if(tab==='services'){
      setKind('service');
      setEdit({title:'',description:'',category:CATS[0],tag:'',icon:'✦',price:0,currency:'INR',unit:'service',buy_enabled:false,demo_url:'',alt_text:'',image_url:'',sort_order:services.length,status:'active'});
      return;
    }
    setKind('portfolio');
    setEdit({title:'',description:'',portfolio_group:tab==='clients' ? 'Client Software & Platforms' : tab==='anaira' ? 'Anaira Products & SaaS' : 'Websites & Web Projects',type:(tab==='software'||tab==='clients'||tab==='anaira') ? 'software' : 'website',tag:'',live_url:'',alt_text:'',image_url:'',gallery:[],sort_order:portfolio.length,status:'active'});
  }

  function setTabAndUrl(next){
    setTab(next);
    const url=new URL(window.location.href); url.searchParams.set('tab',next); window.history.replaceState({},'',url.toString());
  }

  return (
    <AppShell active="/anaira-graphics/settings">
      <Header eyebrow="ANAIRA GRAPHICS" title="Production Portfolio Manager" subtitle="Control every service, website, software product, client project and image from one premium workspace."/>
      <Section title="Landing Content" meta={`${services.length} services · ${portfolio.length} projects`}>
        <div className="ag-settings-shell">
          <div className="ag-settings-toolbar">
            <div className="ag-settings-tabs">
              {['page','services','websites','anaira','clients','software','all'].map(value=><button key={value} className={tab===value?'active':''} onClick={()=>setTabAndUrl(value)}>{value==='page'?'Page Settings':value==='services'?'Services':value==='websites'?'Websites':value==='anaira'?'Anaira Products':value==='clients'?'Client Software':value==='software'?'All Software':'All Projects'}</button>)}
            </div>
            <div className="ag-settings-toolbar-actions">
              <button className="ag-settings-preview-btn" onClick={()=>window.open(`/business/it_agency/landing?business=${ANAIRA_GRAPHICS_ID}`,'_blank')}>Preview Landing ↗</button>
              {tab!=='page' && <button className="ag-settings-primary" onClick={add}>+ Add {tab==='services'?'Service':'Project'}</button>}
            </div>
          </div>
          {msg && <div className="ag-settings-msg">{msg}</div>}
          {loading ? <div className="ag-settings-empty">Loading production content…</div> : tab==='page' ? <PageTextSettings initial={settings} onSaved={setSettings}/> : (
            <div className="ag-settings-list">
              {shown.map(x=><article key={x.id} className="ag-settings-row">
                <div className="ag-settings-thumb">{x.image_url ? <img src={x.image_url} alt={x.alt_text || x.title}/> : <span>{tab==='services' ? (x.icon || '✦') : x.type==='software' ? '⌘' : '↗'}</span>}</div>
                <div className="ag-settings-row-main"><div className="ag-settings-row-meta"><b>{x.title}</b><span>{tab==='services' ? x.category : (x.portfolio_group || x.type)}</span></div><p>{x.description}</p><small>{x.tag || ''}{x.live_url ? ` · ${x.live_url}` : ''}</small></div>
                <div className="ag-settings-row-actions"><button onClick={()=>{setKind(tab==='services'?'service':'portfolio');setEdit(x)}}>Edit</button><button className="danger" onClick={()=>remove(x.id)}>Delete</button></div>
              </article>)}
              {!shown.length && <div className="ag-settings-empty">No content in this section yet. Add your first item above.</div>}
            </div>
          )}
        </div>
      </Section>
      {edit && <ModalEditor item={edit} kind={kind} onClose={()=>setEdit(null)} onSaved={()=>{setEdit(null);setMsg('Saved. Landing page content is now updated.');load()}}/>}
    </AppShell>
  );
}
