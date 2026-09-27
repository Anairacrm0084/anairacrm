import dns from 'node:dns/promises';
import {db} from '../../../../../lib/server/provider';
import {requireSeoFeature} from '../../../../../lib/server/seoRuntime';
export const runtime='nodejs';
export async function POST(req){try{const {siteId}=await req.json();const {site}=await requireSeoFeature(req,siteId,null,'seo-system.manage');const host=new URL(site.domain).hostname;const expected=`anaira-seo-verification=${site.public_token}`;const records=await dns.resolveTxt(host);const flat=records.map(x=>x.join(''));if(!flat.includes(expected))throw new Error(`TXT verification not found on ${host}. Expected: ${expected}`);const s=db();const {data,error}=await s.from('crm_seo_sites').update({verification_status:'verified',verified_at:new Date().toISOString(),verification_method:'dns_txt'}).eq('id',siteId).select().single();if(error)throw error;return Response.json({ok:true,verified:true,site:data})}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
