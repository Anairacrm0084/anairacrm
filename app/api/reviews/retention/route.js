import {requireCron} from '../../../../lib/server/auth';
import {retentionCleanup} from '../../../../lib/server/review-engine';
export async function POST(req){try{requireCron(req);return Response.json({ok:true,...await retentionCleanup()})}catch(e){return Response.json({ok:false,error:e.message},{status:500})}}
export async function GET(req){return POST(req)}
