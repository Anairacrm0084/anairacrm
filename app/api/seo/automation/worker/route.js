import {db} from '../../../../../lib/server/provider';
import {requireCron} from '../../../../../lib/server/auth';
import {runSiteCrawl} from '../../../../../lib/server/seoEngine';

export const runtime='nodejs';
const WORKFLOW_PATHS={crawl:'/api/seo/crawl',sync_gsc:'/api/seo/gsc',sync_ga4:'/api/seo/ga4',sync_rankings:'/api/seo/rank-sync',pagespeed:'/api/seo/pagespeed',competitors:'/api/seo/competitors'};
const JOB_PATHS={gsc_sync:'/api/seo/gsc',ga4_sync:'/api/seo/ga4',rank_sync:'/api/seo/rank-sync',pagespeed:'/api/seo/pagespeed',competitor_sync:'/api/seo/competitors',backlink_sync:'/api/seo/backlinks',geo_sync:'/api/seo/ai-visibility',sco_opportunity:'/api/seo/sco'};

async function internalPost(req,path,body){
  const r=await fetch(new URL(path,req.url),{method:'POST',headers:{Authorization:`Bearer ${process.env.CRON_SECRET}`,'content-type':'application/json'},body:JSON.stringify(body)});
  const j=await r.json().catch(()=>({}));
  if(!r.ok||!j.ok)throw new Error(j.error||`${path} failed`);
  return j;
}

async function runWorkflow(req,s,wf){
  for(const action of wf.actions||[]){
    const type=action?.type;const config=action?.config||{};
    if(WORKFLOW_PATHS[type]) await internalPost(req,WORKFLOW_PATHS[type],{siteId:wf.site_id,...config});
    else if(type==='send_report') await internalPost(req,'/api/seo/reports',{siteId:wf.site_id,action:'run',reportId:config.reportId});
    else if(type==='webhook'){
      if(!config.url)throw new Error('workflow webhook URL is required');
      const r=await fetch(config.url,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({siteId:wf.site_id,workflowId:wf.id,trigger:wf.trigger_type,config})});
      if(!r.ok)throw new Error(`workflow webhook failed: HTTP ${r.status}`);
    } else throw new Error(`Unsupported workflow action: ${type}`);
  }
}

function nextWorkflowRun(wf){
  const mins=Math.max(15,Number(wf.trigger_config?.interval_minutes)||1440);
  return new Date(Date.now()+(wf.trigger_type==='schedule'?mins:60)*60000).toISOString();
}

export async function GET(req){
  try{
    requireCron(req);const s=db();const now=new Date().toISOString();
    const {data:jobs,error}=await s.from('crm_seo_automation_jobs').select('*,crm_seo_sites(*)').eq('enabled',true).lte('next_run_at',now).order('next_run_at').limit(20);if(error)throw error;
    const {data:workflows,wfError}=await s.from('crm_seo_automation_workflows').select('*').eq('enabled',true).lte('next_run_at',now).limit(20);if(wfError)throw wfError;
    const out=[];
    for(const wf of workflows||[]){
      try{await runWorkflow(req,s,wf);await s.from('crm_seo_automation_workflows').update({last_run_at:now,next_run_at:nextWorkflowRun(wf),updated_at:now}).eq('id',wf.id);out.push({workflowId:wf.id,ok:true});}
      catch(e){await s.from('crm_seo_automation_workflows').update({next_run_at:new Date(Date.now()+60*60000).toISOString(),updated_at:now}).eq('id',wf.id);out.push({workflowId:wf.id,ok:false,error:e.message});}
    }
    for(const job of jobs||[]){
      const {data:op}=await s.from('crm_seo_operation_jobs').insert({site_id:job.site_id,job_type:job.job_type,status:'running',attempt:Number(job.settings?.attempts||0)+1,payload:job.settings||{},started_at:now}).select().single();
      const {data:run,error:re}=await s.from('crm_seo_automation_runs').insert({job_id:job.id,site_id:job.site_id,job_type:job.job_type,status:'running'}).select().single();if(re)throw re;
      try{
        let result;const site=job.crm_seo_sites;
        if(job.job_type==='crawl') result=await runSiteCrawl(s,site,{maxPages:job.settings?.maxPages||site.crawl_settings?.max_pages||500,renderJs:job.settings?.renderJs??site.crawl_settings?.render_js,respectRobots:job.settings?.respectRobots??site.crawl_settings?.respect_robots});
        else if(job.job_type==='report_monthly'){const {data:cfg,error:ce}=await s.from('crm_seo_report_configs').select('id').eq('site_id',job.site_id).eq('enabled',true).order('created_at',{ascending:false}).limit(1).maybeSingle();if(ce)throw ce;if(!cfg)throw new Error('No enabled SEO report configuration');result=await internalPost(req,'/api/seo/reports',{siteId:job.site_id,action:'run',reportId:cfg.id});} else {const p=JOB_PATHS[job.job_type];if(!p)throw new Error(`Unsupported SEO automation job: ${job.job_type}`);result=await internalPost(req,p,{siteId:job.site_id,...(job.settings||{})});}
        const next=new Date(Date.now()+Math.max(15,Number(job.interval_minutes)||1440)*60000).toISOString();
        const finished=new Date().toISOString();await s.from('crm_seo_automation_runs').update({status:'completed',result,completed_at:finished}).eq('id',run.id);if(op)await s.from('crm_seo_operation_jobs').update({status:'completed',finished_at:finished,duration_ms:Date.now()-new Date(op.started_at||now).getTime(),result}).eq('id',op.id);
        await s.from('crm_seo_automation_jobs').update({last_run_at:now,next_run_at:next,updated_at:now,settings:{...(job.settings||{}),attempts:0}}).eq('id',job.id);
        out.push({jobId:job.id,ok:true,result});
      }catch(e){
        const attempts=Number(job.settings?.attempts||0)+1;const delay=Math.min(24*60,Math.max(15,Number(job.interval_minutes)||1440)*Math.pow(2,Math.min(attempts,5)));const settings={...(job.settings||{}),attempts};
        const finished=new Date().toISOString();await s.from('crm_seo_automation_runs').update({status:'failed',error:e.message,completed_at:finished}).eq('id',run.id);if(op)await s.from('crm_seo_operation_jobs').update({status:'failed',finished_at:finished,duration_ms:Date.now()-new Date(op.started_at||now).getTime(),error_message:e.message}).eq('id',op.id);await s.from('crm_seo_alerts').insert({site_id:job.site_id,alert_type:'automation_failure',severity:'critical',title:`SEO automation failed: ${job.job_type}`,message:e.message,source:'automation-worker',payload:{jobId:job.id,operationId:op?.id||null}});
        await s.from('crm_seo_automation_jobs').update({last_run_at:now,next_run_at:new Date(Date.now()+delay*60000).toISOString(),settings,updated_at:now}).eq('id',job.id);
        out.push({jobId:job.id,ok:false,error:e.message,retryInMinutes:delay});
      }
    }
    return Response.json({ok:true,processed:out.length,results:out});
  }catch(e){return Response.json({ok:false,error:e.message},{status:401});}
}
