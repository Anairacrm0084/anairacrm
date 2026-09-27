import fs from 'node:fs';import path from 'node:path';
import {db} from '../../../../lib/server/provider';
import {requireSeoFeature} from '../../../../lib/server/seoRuntime';
const VERSION='2026-09-25-AZ-1';
const gates=['data_model','security_rls','api_runtime','ui','provider','persistence_history','error_retry','e2e','production_build','documentation'];
export async function GET(req){
 try{
  const siteId=new URL(req.url).searchParams.get('siteId');await requireSeoFeature(req,siteId,null,'seo-system.view');
  const root=process.cwd();const checklist=path.join(root,'MASTER_CHECKLIST.md');const lock=path.join(root,'docs','SEO_MASTER_A_TO_Z_LOCK_2026-09-25.md');
  const files={checklist:fs.existsSync(checklist),lock:fs.existsSync(lock),routes:fs.existsSync(path.join(root,'app','api','seo')),tests:fs.existsSync(path.join(root,'tests','seo'))};
  const {data:latest}=await db().from('crm_seo_certification_runs').select('*').eq('site_id',siteId).order('started_at',{ascending:false}).limit(1).maybeSingle();
  return Response.json({ok:true,version:VERSION,gates,files,latest:latest||null,certified:false,reason:'A-TO-Z certification requires every gate to pass; provider/build/E2E gates are never inferred from source presence.'});
 }catch(e){return Response.json({ok:false,error:e.message},{status:400})}
}
