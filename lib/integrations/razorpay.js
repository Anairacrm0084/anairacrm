/** Server-side adapter contract. Credentials must be supplied by a server secret manager; never expose them to the browser. */
export function createRazorpayAdapter({keyId, keySecret, fetchImpl=fetch}={}){
 if(!keyId||!keySecret) throw new Error('Razorpay credentials are not configured');
 const auth='Basic '+Buffer.from(`${keyId}:${keySecret}`).toString('base64');
 return {
  async validate(){const r=await fetchImpl('https://api.razorpay.com/v1/orders?count=1',{headers:{Authorization:auth}});return {verified:r.ok,status:r.status};},
  async createPayment({amount,currency='INR',receipt,notes={}}){const r=await fetchImpl('https://api.razorpay.com/v1/orders',{method:'POST',headers:{Authorization:auth,'Content-Type':'application/json'},body:JSON.stringify({amount:Math.round(amount*100),currency,receipt,notes})});return r.json();},
  async verifyPayment(){throw new Error('Use server-side signature verification with Razorpay webhook/payment signature contract');},
  async refundPayment({paymentId,amount}){const r=await fetchImpl(`https://api.razorpay.com/v1/payments/${paymentId}/refunds`,{method:'POST',headers:{Authorization:auth,'Content-Type':'application/json'},body:JSON.stringify(amount?{amount:Math.round(amount*100)}:{})});return r.json();},
  async handleWebhook(){throw new Error('Webhook signature verification must be performed by the server endpoint before this adapter is called');}
 };
}
