import {requireSeoFeature} from '../../../../lib/server/seoRuntime';
import {keywordIntelligence} from '../../../../lib/server/marketParity';
export const runtime='nodejs';
export async function POST(req){try{const b=await req.json();await requireSeoFeature(req,b.siteId,'keyword_research_enabled','seo-system.manage');return Response.json({ok:true,...await keywordIntelligence({siteId:b.siteId,seed:b.seed,location:b.location||'India',language:b.language||'en',device:b.device||'desktop',limit:b.limit||200})})}catch(e){return Response.json({ok:false,error:e.message},{status:400})}}
