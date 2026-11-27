'use client';
import {useEffect,useState} from 'react';
import {useParams,useRouter,useSearchParams} from 'next/navigation';
import {BadgeCheck,CalendarDays,Download,FileCheck2,Hotel,MapPin,Phone,Mail,ArrowLeft,Users,IndianRupee,ShieldCheck} from 'lucide-react';
import {supabase} from '../../../../lib/supabase';

const money=value=>`₹${Number(value||0).toLocaleString('en-IN',{minimumFractionDigits:2,maximumFractionDigits:2})}`;
const pretty=value=>String(value||'').replaceAll('_',' ').replace(/\b\w/g,x=>x.toUpperCase());
const date=value=>value?new Date(`${value}T12:00:00`).toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'}):'—';

export default function BookingConfirmationPage(){
 const {id}=useParams(); const router=useRouter(); const search=useSearchParams();
 const restaurantId=search.get('restaurant_id')||''; const source=search.get('source')||'hms';
 const [booking,setBooking]=useState(null),[loading,setLoading]=useState(true),[error,setError]=useState(''),[downloading,setDownloading]=useState(false),[whatsappBusy,setWhatsappBusy]=useState(false);
 useEffect(()=>{let alive=true;(async()=>{
  try{
   const {data:{session}}=await supabase.auth.getSession();
   if(!session?.access_token)throw new Error('Please sign in again to view this booking confirmation.');
   const response=await fetch(`/api/booking/confirmation/${encodeURIComponent(id)}?restaurant_id=${encodeURIComponent(restaurantId)}&source=${encodeURIComponent(source)}`,{headers:{Authorization:`Bearer ${session.access_token}`},cache:'no-store'});
   const payload=await response.json().catch(()=>({}));
   if(!response.ok||!payload?.ok)throw new Error(payload?.error||'Booking confirmation could not be loaded.');
   if(alive)setBooking(payload.booking);
  }catch(e){if(alive)setError(e.message||'Booking confirmation could not be loaded.');}
  finally{if(alive)setLoading(false)}
 })();return()=>{alive=false}},[id,restaurantId,source]);
 async function downloadPdf(){
  setDownloading(true);setError('');
  try{
   const {data:{session}}=await supabase.auth.getSession();
   if(!session?.access_token)throw new Error('Please sign in again.');
   const response=await fetch(`/api/booking/confirmation/${encodeURIComponent(id)}/pdf?restaurant_id=${encodeURIComponent(restaurantId)}&source=${encodeURIComponent(source)}`,{headers:{Authorization:`Bearer ${session.access_token}`},cache:'no-store'});
   if(!response.ok){const j=await response.json().catch(()=>({}));throw new Error(j.error||'PDF download failed.');}
   const blob=await response.blob();const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download=`ANAIRA-Booking-${booking?.booking_code||id}.pdf`;document.body.appendChild(a);a.click();a.remove();URL.revokeObjectURL(url);
  }catch(e){setError(e.message||'PDF download failed.')}finally{setDownloading(false)}
 }
 async function sharePdfOnWhatsApp(){
  setWhatsappBusy(true);setError('');
  let waDigits=String(booking?.guest_phone||'').replace(/\\D/g,'').replace(/^0+/,'');if(waDigits.length===10)waDigits='91'+waDigits;
  if(!waDigits){setError('Guest mobile number is missing. Add the booking phone number before sharing.');setWhatsappBusy(false);return;}
  const waUrl=`https://wa.me/${waDigits}?text=${encodeURIComponent(`Hello ${booking?.guest_name||'Guest'}, your ANAIRA booking confirmation is ready. Booking reference: ${booking?.booking_code||id}. Please find the PDF confirmation attached.`)}`;
  const popup=window.open('about:blank','_blank');
  try{
   const {data:{session}}=await supabase.auth.getSession();
   if(!session?.access_token)throw new Error('Please sign in again.');
   const response=await fetch(`/api/booking/confirmation/${encodeURIComponent(id)}/pdf?restaurant_id=${encodeURIComponent(restaurantId)}&source=${encodeURIComponent(source)}`,{headers:{Authorization:`Bearer ${session.access_token}`},cache:'no-store'});
   if(!response.ok){const j=await response.json().catch(()=>({}));throw new Error(j.error||'PDF preparation failed.');}
   const blob=await response.blob();
   const file=new File([blob],`ANAIRA-Booking-${booking?.booking_code||id}.pdf`,{type:'application/pdf'});
   const objectUrl=URL.createObjectURL(blob);
   const a=document.createElement('a');a.href=objectUrl;a.download=file.name;document.body.appendChild(a);a.click();a.remove();
   if(popup)popup.location.href=waUrl;else window.location.href=waUrl;
   setError('WhatsApp chat opened for the guest. Attach the downloaded booking PDF and press Send.');
   window.setTimeout(()=>URL.revokeObjectURL(objectUrl),60000);
  }catch(e){if(popup)popup.close();setError(e.message||'WhatsApp sharing failed.');}
  finally{setWhatsappBusy(false);}
 }
 if(loading)return <main className="bc-page"><div className="bc-card bc-loading">Loading booking confirmation…</div><style jsx>{styles}</style></main>;
 if(error&&!booking)return <main className="bc-page"><div className="bc-card bc-error"><h1>Confirmation unavailable</h1><p>{error}</p><button onClick={()=>router.push('/booking-engine')}><ArrowLeft size={16}/> Back to Booking Engine</button></div><style jsx>{styles}</style></main>;
 const confirmed=String(booking?.status||'').toLowerCase()==='confirmed';
 return <main className="bc-page">
  <div className="bc-shell">
   <button className="bc-back" onClick={()=>router.push('/booking-engine')}><ArrowLeft size={16}/> Booking Control Center</button>
   <section className="bc-card">
    <div className="bc-topline"><div className="bc-brand"><span className="bc-mark">A</span><div><b>ANAIRA STAYS</b><small>HOSPITALITY BOOKING ENGINE</small></div></div><span className={`bc-status ${confirmed?'ok':''}`}><BadgeCheck size={15}/>{confirmed?'BOOKING CONFIRMED':pretty(booking?.status||'pending')}</span></div>
    <div className="bc-success-icon"><FileCheck2 size={30}/></div>
    <div className="bc-heading"><small>RESERVATION CONFIRMATION</small><h1>{confirmed?'Your booking is confirmed.':'Booking status updated.'}</h1><p>{confirmed?'The property reservation has been approved and its booking reference is ready.':'This reservation is not yet confirmed. Please review its current status.'}</p></div>
    <div className="bc-reference"><div><span>BOOKING REFERENCE</span><strong>{booking?.booking_code||'—'}</strong></div><div><span>RESERVATION ID</span><strong className="bc-id">{booking?.reservation_id||id}</strong></div></div>
    <div className="bc-grid">
     <article><small><Hotel size={14}/> PROPERTY & ACCOMMODATION</small><b>{booking?.property_name||'Property'}</b><span>{booking?.accommodation||`${pretty(booking?.stay_type)} accommodation`}</span>{booking?.accommodation_code&&<em>Unit code: {booking.accommodation_code}</em>}<span>{[booking?.property_city,booking?.property_address].filter(Boolean).join(' · ')}</span></article>
     <article><small><Users size={14}/> GUEST DETAILS</small><b>{booking?.guest_name||'Guest'}</b>{booking?.guest_phone&&<span><Phone size={13}/>{booking.guest_phone}</span>}{booking?.guest_email&&<span><Mail size={13}/>{booking.guest_email}</span>}</article>
     <article><small><CalendarDays size={14}/> STAY DETAILS</small><b>{date(booking?.check_in)} – {date(booking?.check_out)}</b><span>{Number(booking?.adults||0)} Adults · {Number(booking?.children||0)} Children</span><em>{pretty(booking?.stay_type)}</em></article>
     <article><small><IndianRupee size={14}/> PAYMENT SUMMARY</small><b>{money(booking?.total_amount)}</b><span>Paid {money(booking?.paid_amount)}</span><span>Balance {money(booking?.balance_amount)}</span><em>Payment: {pretty(booking?.payment_status)}</em></article>
    </div>
    {error&&<div className="bc-inline-error">{error}</div>}
    <div className="bc-actions"><button className="bc-primary" onClick={downloadPdf} disabled={!confirmed||downloading}><Download size={17}/>{downloading?'Preparing PDF…':'Download Confirmation PDF'}</button>{confirmed&&booking?.guest_phone&&<button className="bc-whatsapp" onClick={sharePdfOnWhatsApp} disabled={whatsappBusy}><Phone size={17}/>{whatsappBusy?'Preparing WhatsApp PDF…':'Open WhatsApp & Attach PDF'}</button>}<button className="bc-secondary" onClick={()=>router.push('/booking-engine')}>Return to bookings</button></div>
    <div className="bc-foot"><ShieldCheck size={15}/> Verified from the property’s booking record · Keep your booking reference for check-in</div>
   </section>
  </div>
  <style jsx>{styles}</style>
 </main>;
}

const styles=`
.bc-page{min-height:100vh;background:radial-gradient(circle at 10% 0%,#e8e2d1 0,transparent 32%),linear-gradient(135deg,#f6f4ee,#ece9df);padding:34px 18px;color:#17372b;font-family:Inter,system-ui,sans-serif}.bc-shell{width:min(940px,100%);margin:auto}.bc-back{display:inline-flex;align-items:center;gap:8px;border:0;background:transparent;color:#50645a;font-size:12px;font-weight:800;cursor:pointer;margin:0 0 16px}.bc-card{background:#fff;border:1px solid #e7e0d3;border-radius:26px;padding:clamp(22px,4vw,44px);box-shadow:0 24px 70px rgba(23,55,43,.11)}.bc-loading{padding:45px;text-align:center}.bc-error{max-width:620px;margin:10vh auto;text-align:center}.bc-error h1{font:700 32px Georgia,serif}.bc-error button{display:inline-flex;align-items:center;gap:8px;border:0;border-radius:10px;padding:12px 16px;background:#17372b;color:#fff;font-weight:800}.bc-topline{display:flex;justify-content:space-between;align-items:center;gap:16px;padding-bottom:22px;border-bottom:1px solid #eee9df}.bc-brand{display:flex;align-items:center;gap:11px}.bc-mark{width:42px;height:42px;border-radius:13px;background:linear-gradient(135deg,#17372b,#285b43);color:#e5c77d;display:grid;place-items:center;font:700 23px Georgia,serif}.bc-brand b,.bc-brand small{display:block}.bc-brand b{font:700 14px Georgia,serif;letter-spacing:2px}.bc-brand small{font-size:8px;letter-spacing:1.3px;color:#879188;margin-top:4px}.bc-status{display:inline-flex;align-items:center;gap:6px;padding:8px 12px;border-radius:999px;background:#f7f0df;color:#99722d;font-size:9px;font-weight:900;letter-spacing:.8px}.bc-status.ok{background:#eaf5ed;color:#287349}.bc-success-icon{width:62px;height:62px;border-radius:20px;background:#edf6ef;color:#2c8050;display:grid;place-items:center;margin:28px auto 15px}.bc-heading{text-align:center}.bc-heading small{color:#a17b32;font-size:9px;font-weight:900;letter-spacing:2px}.bc-heading h1{font:700 clamp(29px,4vw,42px)/1.1 Georgia,serif;margin:9px 0;color:#17372b}.bc-heading p{font-size:12px;color:#78847d;line-height:1.6}.bc-reference{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin:26px 0;padding:18px;border-radius:16px;background:#f8f6ef;border:1px solid #e9e2d5}.bc-reference span{display:block;color:#8a938d;font-size:8px;font-weight:900;letter-spacing:1.3px}.bc-reference strong{display:block;margin-top:7px;color:#17372b;font:700 20px Georgia,serif;overflow-wrap:anywhere}.bc-reference .bc-id{font:700 10px ui-monospace,monospace}.bc-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}.bc-grid article{min-width:0;padding:17px;border:1px solid #e9e4d9;border-radius:15px;display:grid;gap:7px}.bc-grid article>small{display:flex;align-items:center;gap:6px;color:#9a7939;font-size:8px;font-weight:900;letter-spacing:1px}.bc-grid article>b{font:700 18px Georgia,serif;color:#233c30}.bc-grid article>span{display:flex;align-items:center;gap:6px;color:#738078;font-size:11px;overflow-wrap:anywhere}.bc-grid article>em{font-style:normal;color:#a17b32;font-size:10px;font-weight:800}.bc-actions{display:flex;gap:10px;flex-wrap:wrap;margin-top:24px}.bc-actions button{min-height:46px;border-radius:12px;padding:0 18px;display:inline-flex;align-items:center;justify-content:center;gap:8px;font-weight:900;font-size:11px;cursor:pointer}.bc-primary{border:0;background:linear-gradient(135deg,#d9bc70,#bb9140);color:#1d3429;box-shadow:0 9px 22px rgba(164,126,49,.18)}.bc-primary:disabled{opacity:.5;cursor:not-allowed}.bc-secondary{border:1px solid #dfe5df;background:#fff;color:#345143}.bc-whatsapp{border:0;background:#1f9d57;color:#fff;box-shadow:0 9px 22px rgba(31,157,87,.16)}.bc-foot{display:flex;align-items:center;justify-content:center;gap:7px;margin-top:22px;color:#849087;font-size:9px;text-align:center}.bc-inline-error{margin-top:14px;padding:11px 13px;border-radius:10px;background:#fff0ed;color:#9a3f32;font-size:11px}@media(max-width:620px){.bc-page{padding:18px 10px}.bc-card{border-radius:18px;padding:20px 15px}.bc-topline{align-items:flex-start;flex-direction:column}.bc-reference,.bc-grid{grid-template-columns:1fr}.bc-reference strong{font-size:18px}.bc-actions{flex-direction:column}.bc-actions button{width:100%}.bc-foot{align-items:flex-start;line-height:1.5}}
`;
