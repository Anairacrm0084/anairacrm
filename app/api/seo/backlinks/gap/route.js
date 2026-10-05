import {requireSeoFeature} from '../../../../../lib/server/seoRuntime';
import {backlinkGap} from '../../../../../lib/server/marketParity';
export const runtime='nodejs';
export async function POST(req){try{const b=await req.json();await requireSeoFeature(req,b.siteId,'backlinks_enabled','seo-system.manage');return Response.json({ok:true,...await backlinkGap({siteId:b.siteId,competitorDomain:b.competitorDomain,limit:b.limit||500})})}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
