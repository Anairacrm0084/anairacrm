import {requireSeoFeature} from '../../../../../lib/server/seoRuntime';
import {serpVisibility} from '../../../../../lib/server/marketParity';
export const runtime='nodejs';
export async function POST(req){try{const b=await req.json();await requireSeoFeature(req,b.siteId,'rank_tracking_enabled','seo-system.manage');return Response.json({ok:true,...await serpVisibility({siteId:b.siteId,keyword:b.keyword,location:b.location||'India',device:b.device||'desktop',engine:b.engine||'google'})})}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
