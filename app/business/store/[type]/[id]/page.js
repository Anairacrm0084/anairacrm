'use client';
import {useEffect,useMemo,useState} from 'react';
import {useParams} from 'next/navigation';

export default function UniversalBusinessStore(){
  const {type,id}=useParams();
  const [data,setData]=useState(null),[selected,setSelected]=useState([]),[customer,setCustomer]=useState({name:'',phone:'',email:''});
  const [scheduledAt,setScheduledAt]=useState(''),[payment,setPayment]=useState('pay_later'),[notes,setNotes]=useState('');
  const [conversation,setConversation]=useState(null),[message,setMessage]=useState(''),[status,setStatus]=useState(''),[loading,setLoading]=useState(true);
  useEffect(()=>{if(type&&id)fetch(`/api/business/engine?type=${encodeURIComponent(type)}&business=${encodeURIComponent(id)}`).then(r=>r.json()).then(x=>{setData(x);setLoading(false)}).catch(e=>{setStatus(e.message);setLoading(false)})},[type,id]);
  const total=useMemo(()=>selected.reduce((s,x)=>s+Number(x.price||0),0),[selected]);
  function toggle(item){setSelected(a=>a.some(x=>x.id===item.id)?a.filter(x=>x.id!==item.id):[...a,item]);}
  async function submit(){
    if(!customer.name&&!customer.phone&&!customer.email){setStatus('Please enter your name, phone or email.');return}
    setStatus('Submitting…');
    const r=await fetch('/api/business/engine',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({
      business_id:id,type,items:selected,customer,scheduled_at:scheduledAt||null,payment_method:payment,notes,idempotency_key:crypto.randomUUID()
    })});
    const x=await r.json(); if(!r.ok){setStatus(x.error||'Unable to submit');return}
    setStatus(`Request created: ${x.transaction.id}`);
    if(payment==='online'&&x.transaction?.id){
      setStatus('Transaction created. Online payment is ready through the configured provider; complete provider checkout from your payment flow.');
    }
  }
  async function sendChat(){
    if(!message.trim())return;
    const r=await fetch('/api/business/chat',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({business_id:id,conversation_id:conversation?.id,customer,message})});
    const x=await r.json(); if(!r.ok){setStatus(x.error||'Chat failed');return}
    setConversation(x.conversation);setMessage('');setStatus('Message sent.');
  }
  if(loading)return <main style={styles.wrap}>Loading business…</main>;
  if(!data?.business)return <main style={styles.wrap}>Business not found.</main>;
  const cfg=data.config;
  return <main style={styles.wrap}>
    <header style={styles.hero}>
      <div><div style={styles.eyebrow}>{cfg.icon} {cfg.label}</div><h1>{data.business.name}</h1><p>{data.business.description||'Book, buy, enquire or request a service online.'}</p></div>
      <div style={styles.badge}>{data.business.city||''}</div>
    </header>
    <section style={styles.journey}>{cfg.journey.map((x,i)=><span key={x}>{i+1}. {x}</span>)}</section>
    <div style={styles.grid}>
      <section style={styles.card}><h2>{cfg.selectionLabel}</h2>
        {(data.catalog||[]).length===0?<p>No catalog items are published yet. You can still send an enquiry below.</p>:
        <div style={styles.items}>{data.catalog.map(item=><button key={item.id} onClick={()=>toggle(item)} style={{...styles.item,...(selected.some(x=>x.id===item.id)?styles.selected:{})}}>
          <strong>{item.name}</strong><span>{item.description}</span><b>{item.price>0?`${item.currency||'INR'} ${item.price}`:'Contact / Enquire'}</b>
        </button>)}</div>}
      </section>
      <section style={styles.card}><h2>Customer & checkout</h2>
        <input placeholder="Name" value={customer.name} onChange={e=>setCustomer({...customer,name:e.target.value})}/>
        <input placeholder="Phone" value={customer.phone} onChange={e=>setCustomer({...customer,phone:e.target.value})}/>
        <input placeholder="Email" value={customer.email} onChange={e=>setCustomer({...customer,email:e.target.value})}/>
        <input type="datetime-local" value={scheduledAt} onChange={e=>setScheduledAt(e.target.value)}/>
        <textarea placeholder="Notes / requirements" value={notes} onChange={e=>setNotes(e.target.value)}/>
        <select value={payment} onChange={e=>setPayment(e.target.value)}><option value="pay_later">Pay later / confirm first</option><option value="online">Online payment</option></select>
        <div style={styles.total}>Total: INR {total.toFixed(2)}</div>
        <button style={styles.primary} onClick={submit}>{total>0?'Continue / Submit':'Send Request'}</button>
        {status&&<p>{status}</p>}
      </section>
    </div>
    <section style={styles.card}><h2>Chat with business</h2><p>Ask a question or continue a booking/order enquiry. The conversation can be linked to the transaction.</p>
      <div style={styles.chatbox}>{conversation?<div style={styles.messages}>Conversation {conversation.id}</div>:null}
      <textarea value={message} onChange={e=>setMessage(e.target.value)} placeholder="Write your message…"/>
      <button style={styles.primary} onClick={sendChat}>Send message</button></div>
    </section>
  </main>
}
const styles={wrap:{maxWidth:1200,margin:'0 auto',padding:24,fontFamily:'Arial,sans-serif'},hero:{padding:32,borderRadius:20,background:'#0d3b2e',color:'#fff',display:'flex',justifyContent:'space-between',gap:20},eyebrow:{fontWeight:700,opacity:.85},badge:{alignSelf:'flex-start',padding:'8px 12px',borderRadius:20,background:'#fff2',color:'#fff'},journey:{display:'flex',gap:8,overflowX:'auto',padding:'16px 0'},grid:{display:'grid',gridTemplateColumns:'1.4fr 1fr',gap:20},card:{marginTop:20,padding:24,border:'1px solid #ddd',borderRadius:16,background:'#fff'},items:{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(220px,1fr))',gap:12},item:{textAlign:'left',padding:16,border:'1px solid #ddd',borderRadius:12,background:'#fff',display:'grid',gap:8,cursor:'pointer'},selected:{border:'2px solid #0d3b2e',background:'#eef7f2'},primary:{padding:'12px 18px',border:0,borderRadius:10,background:'#0d3b2e',color:'#fff',fontWeight:700,cursor:'pointer'},total:{fontSize:20,fontWeight:700,padding:'12px 0'},chatbox:{display:'grid',gap:10},messages:{padding:12,background:'#f4f4f4',borderRadius:10}};
