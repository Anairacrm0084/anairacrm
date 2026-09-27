/** Real integration contracts. No provider is reported connected until an adapter validates it. */
export const PAYMENT_STATUSES=['created','pending','authorized','paid','failed','cancelled','partially_refunded','refunded'];
export const INTEGRATION_STATUSES=['not_configured','credentials_saved','validating','verified','connected','error','disabled'];
export function assertAdapter(adapter){for(const m of ['validate','createPayment','verifyPayment','refundPayment','handleWebhook']) if(typeof adapter?.[m]!=='function') throw new Error(`Integration adapter missing ${m}()`);}
export function integrationState(result){return result?.verified?'verified':'error';}
