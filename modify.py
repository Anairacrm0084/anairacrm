from pathlib import Path
root=Path('/mnt/data/audit_work')

# 1) Replace setup-components with dynamic context + exact HMS menu for all hospitality types.
p=root/'app/hotel-management/setup-components.js'
s=p.read_text()
# add meta helpers before useTenantProperty
needle="export function useTenantProperty(){"
helper="""export const HOSPITALITY_META={
 hotel:{label:'Hotel',plural:'Hotels',unit:'Room',units:'Rooms',unitType:'Room Type',unitTypes:'Room Types',inventory:'Room Inventory',dashboard:'Hotel Dashboard',profile:'Hotel Profile',pms:'PMS / Front Desk',housekeeping:'Housekeeping',reservation:'Reservations',booking:'Hotel Booking Engine'},
 camp:{label:'Camping',plural:'Camps',unit:'Camp / Tent',units:'Camps / Tents',unitType:'Camp / Tent Type',unitTypes:'Camp / Tent Types',inventory:'Camp Inventory',dashboard:'Camping Dashboard',profile:'Camping Property',pms:'Camp Front Desk',housekeeping:'Camp Housekeeping',reservation:'Reservations',booking:'Camping Booking Engine'},
 homestay:{label:'Homestay',plural:'Homestays',unit:'Accommodation',units:'Accommodations',unitType:'Accommodation Type',unitTypes:'Accommodation Types',inventory:'Homestay Inventory',dashboard:'Homestay Dashboard',profile:'Homestay Property',pms:'Homestay Front Desk',housekeeping:'Homestay Housekeeping',reservation:'Reservations',booking:'Homestay Booking Engine'},
 guest_house:{label:'Guest House',plural:'Guest Houses',unit:'Accommodation',units:'Accommodations',unitType:'Accommodation Type',unitTypes:'Accommodation Types',inventory:'Guest House Inventory',dashboard:'Guest House Dashboard',profile:'Guest House Property',pms:'Guest House Front Desk',housekeeping:'Guest House Housekeeping',reservation:'Reservations',booking:'Guest House Booking Engine'},
 cottage:{label:'Cottage',plural:'Cottages',unit:'Cottage',units:'Cottages',unitType:'Cottage Type',unitTypes:'Cottage Types',inventory:'Cottage Inventory',dashboard:'Cottage Dashboard',profile:'Cottage Property',pms:'Cottage Front Desk',housekeeping:'Cottage Housekeeping',reservation:'Reservations',booking:'Cottage Booking Engine'}
};
export function hospitalityMeta(type){return HOSPITALITY_META[type]||HOSPITALITY_META.hotel}

"""
s=s.replace(needle,helper+needle)
# change ctx initial + query properties to include hospitality_type
s=s.replace("{loading:true,session:null,super:false,rid:null,properties:[],error:''}","{loading:true,session:null,super:false,rid:null,properties:[],hospitalityType:'hotel',error:''}")
s=s.replace("supabase.from('restaurants').select('id,name,status').order('name')","supabase.from('restaurants').select('id,name,status,hospitality_type').order('name')")
old="setCtx({loading:false,session,super:isSuper,rid:isSuper?(requested||p?.restaurant_id||''):p?.restaurant_id||null,properties,error:''});"
new="""const selectedRid=isSuper?(requested||p?.restaurant_id||''):p?.restaurant_id||null;
    const selected=properties.find(x=>x.id===selectedRid);
    setCtx({loading:false,session,super:isSuper,rid:selectedRid,properties,hospitalityType:selected?.hospitality_type||'hotel',error:''});"""
s=s.replace(old,new)
# dynamic setup nav exact hotel routes for all types
start=s.find("export function SetupNav(")
end=s.find("export function ensureSelected",start)
replacement="""export function SetupNav({hospitalityType='hotel'}){
 const m=hospitalityMeta(hospitalityType);
 const q='?property=';
 return <Section title={`${m.label} Management Setup`} meta="Canonical HMS master data"><div className="module-grid">
  <a className="module-card" href={`/hotel-management`}><h3>{m.dashboard}</h3><p>Operational dashboard using the same ANAIRA HMS master data.</p></a>
  <a className="module-card" href={`/hotel-management/setup`}><h3>{m.profile}</h3><p>Identity, address, policies, tax, media and operating timings.</p></a>
  <a className="module-card" href={`/hotel-management/room-types`}><h3>{m.unitTypes}</h3><p>Create categories with capacity, pricing, amenities and photos.</p></a>
  <a className="module-card" href={`/hotel-management/rooms`}><h3>{m.units}</h3><p>Create every physical sellable unit and its live status.</p></a>
  <a className="module-card" href={`/hotel-management/inventory`}><h3>{m.inventory}</h3><p>Automatic date-wise inventory from physical units and bookings.</p></a>
  <a className="module-card" href={`/hotel-management/rates`}><h3>Rate Plans</h3><p>Per-unit or per-person pricing, weekend, seasonal and stay rules.</p></a>
  <a className="module-card" href={`/booking`}><h3>{m.reservation}</h3><p>Same booking control center, payment and confirmation lifecycle.</p></a>
  <a className="module-card" href={`/pms`}><h3>{m.pms}</h3><p>Check-in, stay lifecycle, room/unit assignment and checkout.</p></a>
  <a className="module-card" href={`/housekeeping`}><h3>{m.housekeeping}</h3><p>Cleaning, inspection, readiness and maintenance workflow.</p></a>
  <a className="module-card" href={`/store-builder?kind=${hospitalityType}`}><h3>My {m.label} Store</h3><p>Same premium preview, branding, banners, SEO and publishing controls.</p></a>
 </div></Section>
}
"""
s=s[:start]+replacement+s[end:]
p.write_text(s)

# 2) Make AppShell navigation use the same hotel-management routes for all types and plugin control.
p=root/'app/components.js'; s=p.read_text()
start=s.find('const HOSPITALITY_MANAGEMENT_GROUPS = {')
end=s.find('function normalizeGroups',start)
new="""const HOSPITALITY_MANAGEMENT_GROUPS = {
  hotel: {title:'HOTEL MANAGEMENT', items:[]},
  camp: {title:'CAMPING MANAGEMENT', items:[]},
  homestay: {title:'HOMESTAY MANAGEMENT', items:[]},
  guest_house: {title:'GUEST HOUSE MANAGEMENT', items:[]},
  cottage: {title:'COTTAGE MANAGEMENT', items:[]}
};
const HOSPITALITY_MENU_META={
 hotel:['Hotel','Hotel','Hotel'],camp:['Camping','Camp','Camping'],homestay:['Homestay','Accommodation','Homestay'],guest_house:['Guest House','Accommodation','Guest House'],cottage:['Cottage','Cottage','Cottage']
};
Object.entries(HOSPITALITY_MANAGEMENT_GROUPS).forEach(([type,g])=>{
 const [label,unit,short]=HOSPITALITY_MENU_META[type];
 g.items=[
  ['▦',`${label} Dashboard`,'/hotel-management','hms.room.view','hotel-management-suite'],
  ['⌂',`${label} Profile`,'/hotel-management/setup','business.settings','hotel-management-suite'],
  ['▣',type==='hotel'?'Room Types':`${unit} Types`,'/hotel-management/room-types','hms.room.view','hotel-management-suite'],
  ['▣',type==='hotel'?'Rooms':`${unit}s`,'/hotel-management/rooms','hms.room.view','hotel-management-suite'],
  ['▦',type==='hotel'?'Room Inventory':`${label} Inventory`,'/hotel-management/inventory','hms.room.view','hotel-management-suite'],
  ['₹','Rate Plans','/hotel-management/rates','booking.view','hotel-management-suite'],
  ['⌂','Reservations','/booking','booking.view','hotel-booking'],
  ['▤',`${label} PMS / Front Desk`,'/pms','pms.room.view','hotel-pms'],
  ['⌂',`${label} Housekeeping`,'/housekeeping','housekeeping.task.view','hotel-pms']
 ];
});

"""
s=s[:start]+new+s[end:]
# Replace sidebar label on hotel brand
s=s.replace("<span>ANAIRA</span><span>HOTEL & RESTAURANT CRM</span>","<span>ANAIRA</span><span>HOSPITALITY & RESTAURANT CRM</span>")
# Make ADMIN_ONLY include common routes already existing; no change.
p.write_text(s)

# 3) Dynamic setup page labels and context; preserve exact form/layout.
p=root/'app/hotel-management/setup/page.js'; s=p.read_text()
s=s.replace("import {useTenantProperty,SetupHeader,SetupShell,Field,SelectField,SetupNav,ensureSelected} from '../setup-components';","import {useTenantProperty,SetupHeader,SetupShell,Field,SelectField,SetupNav,ensureSelected,hospitalityMeta} from '../setup-components';")
s=s.replace("const id=ensureSelected(ctx,rid);","const id=ensureSelected(ctx,rid); const meta=hospitalityMeta(form.hospitality_type||ctx.hospitalityType||'hotel');",1)
s=s.replace("title=\"Hotel Property\" subtitle=\"Business Admin property master: identity, contact, location, policies, media and booking settings.\"","title={`${meta.label} Property`} subtitle={`Business Admin property master: identity, contact, location, policies, media and booking settings.`}")
s=s.replace("title=\"Hotel Property\" subtitle=\"Property master data\"","title={`${meta.label} Property`} subtitle=\"Property master data\"")
s=s.replace("<Field label=\"Hotel Name *\"","<Field label={`${meta.label} Name *`}")
s=s.replace("<Field label=\"Short Name\"","<Field label=\"Short Name\"")
s=s.replace("setMsg('Hotel property profile saved successfully.')","setMsg(`${meta.label} property profile saved successfully.`)")
# replace final SetupNav call with type
s=s.replace('<SetupNav/>','<SetupNav hospitalityType={form.hospitality_type||ctx.hospitalityType||\'hotel\'}/>')
p.write_text(s)

# 4) Dynamic labels in Room Types.
p=root/'app/hotel-management/room-types/page.js'; s=p.read_text()
s=s.replace("import {useTenantProperty,SetupHeader,SetupShell,Field,ensureSelected,SetupNav} from '../setup-components';","import {useTenantProperty,SetupHeader,SetupShell,Field,ensureSelected,SetupNav,hospitalityMeta} from '../setup-components';")
s=s.replace("const id=ensureSelected(ctx,rid);", "const id=ensureSelected(ctx,rid); const m=hospitalityMeta(ctx.hospitalityType);")
s=s.replace("title=\"Room Types\" subtitle=\"Create every room category with pricing, capacity, amenities and photos.\"","title={m.unitTypes} subtitle={`Create every ${m.unitType.toLowerCase()} with pricing, capacity, amenities and photos.`}")
s=s.replace("title=\"Room Types\" subtitle=\"\"", "title={m.unitTypes} subtitle=\"\"")
s=s.replace('label="Room Type Name"','label={`${m.unitType} Name`}')
s=s.replace('label="Room Type"','label={m.unitType}')
s=s.replace("'Room type name is required.'", "`${m.unitType} name is required.`")
s=s.replace("'Room type saved successfully.'", "`${m.unitType} saved successfully.`")
s=s.replace("'A room type with this name or code already exists for this property.'", "`A ${m.unitType.toLowerCase()} with this name or code already exists for this property.`")
s=s.replace('label="Room Type Photos"','label={`${m.unitType} Photos`}')
s=s.replace('<SetupNav/>',"<SetupNav hospitalityType={ctx.hospitalityType}/>")
p.write_text(s)

# 5) Dynamic labels in Rooms.
p=root/'app/hotel-management/rooms/page.js'; s=p.read_text()
s=s.replace("import {useTenantProperty,SetupHeader,SetupShell,Field,SelectField,ensureSelected,SetupNav} from '../setup-components';","import {useTenantProperty,SetupHeader,SetupShell,Field,SelectField,ensureSelected,SetupNav,hospitalityMeta} from '../setup-components';")
s=s.replace("const id=ensureSelected(ctx,rid);", "const id=ensureSelected(ctx,rid); const m=hospitalityMeta(ctx.hospitalityType);")
s=s.replace('title="Individual Rooms" subtitle="Create actual room numbers under each room type."','title={m.units} subtitle={`Create actual ${m.unit.toLowerCase()} identifiers under each ${m.unitType.toLowerCase()}.`}')
s=s.replace('title="Individual Rooms" subtitle=""','title={m.units} subtitle=""')
s=s.replace('label="Room Type"','label={m.unitType}')
s=s.replace('label="Room Number"','label={`${m.unit} Number`}')
s=s.replace('label="Room Inventory"','label={`${m.unit} Inventory`}')
s=s.replace("`${edit?'Update':'Add'} Room`", "`${edit?'Update':'Add'} ${m.unit}`")
s=s.replace("'Room number is required.'", "`${m.unit} number is required.`")
s=s.replace('<SetupNav/>',"<SetupNav hospitalityType={ctx.hospitalityType}/>")
p.write_text(s)

# 6) Dynamic inventory labels.
p=root/'app/hotel-management/inventory/page.js'; s=p.read_text()
s=s.replace("import {useTenantProperty,SetupHeader,SetupShell,SetupNav,ensureSelected} from '../setup-components';","import {useTenantProperty,SetupHeader,SetupShell,SetupNav,ensureSelected,hospitalityMeta} from '../setup-components';")
s=s.replace("const id=ensureSelected(ctx,rid);", "const id=ensureSelected(ctx,rid); const m=hospitalityMeta(ctx.hospitalityType);")
s=s.replace('title="Smart Room Inventory" subtitle="Automatic room inventory from your physical rooms and confirmed reservations."','title={`Smart ${m.label} Inventory`} subtitle={`Automatic ${m.unit.toLowerCase()} inventory from your physical units and confirmed reservations.`}')
s=s.replace('title="Smart Room Inventory" subtitle="Rooms are created once in Hotel Management → Rooms. Daily inventory is generated automatically."','title={`Smart ${m.label} Inventory`} subtitle={`${m.units} are created once in ${m.label} Management → ${m.units}. Daily inventory is generated automatically.`}')
s=s.replace('Total rooms come from <b>Individual Rooms</b>.','Total inventory comes from <b>Physical Units</b>.')
s=s.replace('title="Room Type Inventory"','title={`${m.unitType} Inventory`}')
s=s.replace('room{rooms.length===1?\'\':\'s\'}','unit{rooms.length===1?\'\':\'s\'}')
s=s.replace('>Rooms:</b>', '>Units:</b>')
s=s.replace('Room {r.room_number}', '{m.unit} {r.room_number}')
s=s.replace("['Booking','Guest','Room Type','Room','Check-in','Check-out','Status']", "['Booking','Guest',m.unitType,m.unit,'Check-in','Check-out','Status']")
s=s.replace('<SetupNav/>',"<SetupNav hospitalityType={ctx.hospitalityType}/>")
p.write_text(s)

# 7) Dynamic rate plan labels + per-person control.
p=root/'app/hotel-management/rates/page.js'; s=p.read_text()
s=s.replace("import {useTenantProperty,SetupHeader,SetupShell,Field,SelectField,ensureSelected,SetupNav} from '../setup-components';","import {useTenantProperty,SetupHeader,SetupShell,Field,SelectField,ensureSelected,SetupNav,hospitalityMeta} from '../setup-components';")
s=s.replace("const id=ensureSelected(ctx,rid);", "const id=ensureSelected(ctx,rid); const m=hospitalityMeta(ctx.hospitalityType);")
s=s.replace("const [form,setForm]=useState({board_type:'room_only',active:true,min_stay:1})", "const [form,setForm]=useState({board_type:'room_only',pricing_mode:ctx.hospitalityType==='camp'?'per_person':'per_unit',active:true,min_stay:1})")
s=s.replace("const p={restaurant_id:id,room_type_id:form.room_type_id||null,name:form.name", "const p={restaurant_id:id,room_type_id:form.room_type_id||null,name:form.name")
s=s.replace("description:form.description,board_type:form.board_type,rate:Number(form.rate||0)", "description:form.description,board_type:form.board_type,pricing_mode:form.pricing_mode||'per_unit',rate:Number(form.rate||0)")
s=s.replace('title="Rate Plans" subtitle="Create EP, CP, MAP, seasonal and occupancy-based hotel pricing."','title="Rate Plans" subtitle={`Create ${m.unit.toLowerCase()} pricing, per-person/per-unit rates, weekend, seasonal and stay rules.`}')
s=s.replace('title="Rate Plans" subtitle=""','title="Rate Plans" subtitle=""')
s=s.replace('label="Room Type"','label={m.unitType}')
# Insert pricing mode field before meal plan
needle='<SelectField label="Meal Plan"'
insert='<SelectField label="Pricing Mode" value={form.pricing_mode||\'per_unit\'} onChange={v=>set(\'pricing_mode\',v)} options={[[\'per_unit\',`Per ${m.unit.toLowerCase()}`],[\'per_person\',\'Per Person\']]}/>'
s=s.replace(needle,insert+needle)
s=s.replace("<Field label=\"Rate\"", "<Field label={form.pricing_mode==='per_person'?'Rate / Person':'Rate'}")
s=s.replace("['Name','Room Type','Meal','Rate','Occupancy'", "['Name',m.unitType,'Pricing','Meal','Rate','Occupancy'")
s=s.replace("x.hms_room_types?.name||'Flexible',x.board_type,`₹${Number(x.rate||0).toLocaleString('en-IN')}`", "x.hms_room_types?.name||'Flexible',x.pricing_mode==='per_person'?'Per Person':'Per Unit',x.board_type,`₹${Number(x.rate||0).toLocaleString('en-IN')}`")
s=s.replace('<SetupNav/>',"<SetupNav hospitalityType={ctx.hospitalityType}/>")
p.write_text(s)

# 8) Dynamic PMS + housekeeping labels.
for fn in ['app/hotel-management/pms/page.js','app/hotel-management/housekeeping/page.js']:
 p=root/fn; s=p.read_text()
 s=s.replace("import {SetupShell,SetupHeader,useTenantProperty,ensureSelected,SelectField,Field,Section,Table,Pill} from '../setup-components';","import {SetupShell,SetupHeader,useTenantProperty,ensureSelected,SelectField,Field,Section,Table,Pill,hospitalityMeta} from '../setup-components';")
 s=s.replace("const id=ensureSelected(ctx,rid);", "const id=ensureSelected(ctx,rid); const m=hospitalityMeta(ctx.hospitalityType);")
 if fn.endswith('pms/page.js'):
  s=s.replace('title="PMS / Front Desk" subtitle="Arrivals, in-house guests, room assignment and departures."','title={`${m.label} PMS / Front Desk`} subtitle={`Arrivals, in-house guests, ${m.unit.toLowerCase()} assignment and departures.`}')
  s=s.replace('title="PMS / Front Desk" subtitle="Operational stay management"','title={`${m.label} PMS / Front Desk`} subtitle="Operational stay management"')
  s=s.replace("['Reservation','Guest','Dates','Room','Status','Actions']", "['Reservation','Guest','Dates',m.unit,'Status','Actions']")
 else:
  s=s.replace('title="Housekeeping" subtitle="Room board, cleaning, inspections and maintenance tasks."','title={`${m.label} Housekeeping`} subtitle={`${m.unit} board, cleaning, inspections and maintenance tasks.`}')
  s=s.replace('title="Housekeeping" subtitle="Operational room readiness"','title={`${m.label} Housekeeping`} subtitle="Operational unit readiness"')
  s=s.replace("['Room','Task','Priority','Status','Due','Actions']", "[m.unit,'Task','Priority','Status','Due','Actions']")
 p.write_text(s)

# 9) Dashboard dynamic title/labels. Add meta and fetch restaurant type in existing effect.
p=root/'app/hotel-management/page.js'; s=p.read_text()
s=s.replace("import { AppShell, Header, Section, Table, Pill } from '../components';", "import { AppShell, Header, Section, Table, Pill } from '../components';\nimport { hospitalityMeta } from './setup-components';")
s=s.replace("const [busy,setBusy]=useState(''),[error,setError]=useState('');", "const [busy,setBusy]=useState(''),[error,setError]=useState(''),[hospitalityType,setHospitalityType]=useState('hotel');")
s=s.replace("setRestaurantId(p.data?.restaurant_id||null);\n    if(p.data?.restaurant_id)load(p.data.restaurant_id);", "setRestaurantId(p.data?.restaurant_id||null);\n    if(p.data?.restaurant_id){ const t=await supabase.from('restaurants').select('hospitality_type').eq('id',p.data.restaurant_id).maybeSingle(); setHospitalityType(t.data?.hospitality_type||'hotel'); load(p.data.restaurant_id); }")
s=s.replace("const today=new Date().toISOString().slice(0,10);", "const meta=hospitalityMeta(hospitalityType);\n  const today=new Date().toISOString().slice(0,10);")
s=s.replace('eyebrow="HOTEL OPERATIONS" title="Anaira Hotel Management System" subtitle="Front desk, reservations, room assignment, payment review and stay lifecycle."', 'eyebrow={`${meta.label.toUpperCase()} OPERATIONS`} title={`Anaira ${meta.label} Management System`} subtitle={`Front desk, reservations, ${meta.unit.toLowerCase()} assignment, payment review and stay lifecycle.`}')
s=s.replace('title="Reservations" meta="Canonical HMS reservations — Hotel Management master"','title="Reservations" meta={`Canonical HMS reservations — ${meta.label} Management master`}')
s=s.replace("'Room / Type'", "`${meta.unit} / Type`")
s=s.replace("`Room ID: ${r.room_id||'Not assigned'}`", "`${meta.unit} ID: ${r.room_id||'Not assigned'}`")
s=s.replace("`₹${Number(r.rate||0).toLocaleString('en-IN')}/night`", "`₹${Number(r.rate||0).toLocaleString('en-IN')}/${r.pricing_mode==='per_person'?'person':'unit'} / night`")
s=s.replace('title="Room Status" meta="Live HMS rooms"','title={`${meta.unit} Status`} meta={`Live HMS ${meta.units.toLowerCase()}`}')
s=s.replace("['Room','Floor','Type','Status','Housekeeping']", "[meta.unit,'Floor','Type','Status','Housekeeping']")
p.write_text(s)

# 10) Booking admin dynamic labels and unified booking function for non-hotel.
p=root/'app/HotelBookingAdmin.js'; s=p.read_text()
s=s.replace("import {supabase} from '../lib/supabase';", "import {supabase} from '../lib/supabase';")
s=s.replace("const [earlyCheckIn,setEarlyCheckIn]=useState(false),[earlyCheckOut,setEarlyCheckOut]=useState(false);", "const [earlyCheckIn,setEarlyCheckIn]=useState(false),[earlyCheckOut,setEarlyCheckOut]=useState(false),[hospitalityType,setHospitalityType]=useState('hotel');")
s=s.replace("setProfile(p||{});if(p?.is_super_admin", "setProfile(p||{});if(p?.restaurant_id){const t=await supabase.from('restaurants').select('hospitality_type').eq('id',p.restaurant_id).maybeSingle();setHospitalityType(t.data?.hospitality_type||'hotel');}if(p?.is_super_admin")
s=s.replace("useEffect(()=>{if(rid)load()},[rid]);", "useEffect(()=>{if(rid){(async()=>{const t=await supabase.from('restaurants').select('hospitality_type').eq('id',rid).maybeSingle();setHospitalityType(t.data?.hospitality_type||'hotel');})();load()}},[rid]);")
# Generic booking function in createManual
s=s.replace("const data=await rpc('anaira_create_manual_hotel_booking',", "const data=await rpc('anaira_create_manual_hospitality_booking',")
# dynamic text broad replacements
old_head="eyebrow=\"HOTEL RESERVATIONS\" title=\"Hotel Booking Records\" subtitle={isSuper?\'All hotel booking operations • select a property\':\'Only this hotel’s booking records and operations\'}"
new_head="""eyebrow={`${hospitalityType.toUpperCase()} RESERVATIONS`} title={`${hospitalityType==='hotel'?'Hotel':hospitalityType==='camp'?'Camping':hospitalityType==='homestay'?'Homestay':hospitalityType==='guest_house'?'Guest House':'Cottage'} Booking Records`} subtitle={isSuper?`All ${hospitalityType} booking operations • select a property`:`Only this ${hospitalityType}’s booking records and operations`}"""
s=s.replace(old_head,new_head)
s=s.replace('Live Hotel Bookings','Live Hospitality Bookings')
s=s.replace('Manual Hotel Booking','Manual Booking')
s=s.replace('same HMS master data.','same HMS master data.')
p.write_text(s)

# 11) Store Builder: non-restaurant hospitality uses same hotel store/preview and HMS catalog.
p=root/'app/store-builder/page.js'; s=p.read_text()
s=s.replace("const kinds=[];\n   if(enabled.has('restaurant-store')||enabled.has('anaira-pos')||enabled.has('food-delivery'))kinds.push('restaurant');\n   if(enabled.has('hotel-booking')||enabled.has('hotel-management-suite')||enabled.has('hotel-pms'))kinds.push('hotel');\n   const safe=kinds.length?kinds:['restaurant'];", "const kinds=[];\n   if(enabled.has('restaurant-store')||enabled.has('anaira-pos')||enabled.has('food-delivery'))kinds.push('restaurant');\n   if(enabled.has('hotel-booking')||enabled.has('hotel-management-suite')||enabled.has('hotel-pms')){ const ht=r?.hospitality_type||'hotel'; kinds.push(ht==='restaurant'?'hotel':ht); }\n   const safe=kinds.length?kinds:['restaurant'];")
s=s.replace("const {data:s,error:se}=await supabase.from('anaira_platform_stores').select('*').eq('store_type',kind).maybeSingle();", "const storeType=kind==='restaurant'?'restaurant':'hotel';\n   const {data:s,error:se}=await supabase.from('anaira_platform_stores').select('*').eq('store_type',storeType).maybeSingle();")
s=s.replace("const listing=kind==='hotel'?{seo_title:form.seo_title,seo_description:form.seo_description}:{", "const listing=kind!=='restaurant'?{")
s=s.replace("catalog_source:m?.catalog_source||(kind==='restaurant'?'anaira_pos':'anaira_hms')", "catalog_source:m?.catalog_source||(kind==='restaurant'?'anaira_pos':'anaira_hms')")
s=s.replace("if(kind==='restaurant')", "if(kind==='restaurant')")
# add hospitality type display where obvious
s=s.replace("<Header eyebrow=\"STORE BUILDER\"", "<Header eyebrow=\"HOSPITALITY STORE BUILDER\"")
p.write_text(s)

# 12) Add audit report placeholder, populated after checks.
