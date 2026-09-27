
import crypto from 'node:crypto';
import {seoChecks,abs,TECHNICAL_RULE_REGISTRY,TECHNICAL_RULE_VERSION} from '../../app/seo-review-utils';

const sleep=ms=>new Promise(r=>setTimeout(r,Math.max(0,ms||0)));
const hash=v=>crypto.createHash('sha256').update(String(v||'')).digest('hex');
const normalize=(url,base)=>{
  try{
    const u=new URL(url,base); u.hash='';
    return u.href;
  }catch{return null}
};

async function request(url,{userAgent='AnairaSEO/4.0',renderJs=false,timeout=20000}={}){
  const started=Date.now();
  const headers={'user-agent':userAgent,'accept':'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'};
  let current=url, redirects=[];
  if(renderJs){
    if(!process.env.BROWSERLESS_API_TOKEN)throw new Error('BROWSERLESS_API_TOKEN is required for JS rendering');
    const endpoint=process.env.BROWSERLESS_CONTENT_URL||'https://chrome.browserless.io/content';
    const u=new URL(endpoint);u.searchParams.set('token',process.env.BROWSERLESS_API_TOKEN);u.searchParams.set('url',url);
    const r=await fetch(u,{headers,signal:AbortSignal.timeout(timeout)});
    const text=await r.text();
    return {r,text,ms:Date.now()-started,redirects:[],redirectLoop:false};
  }
  for(let step=0;step<=5;step++){
    const r=await fetch(current,{redirect:'manual',headers,signal:AbortSignal.timeout(timeout)});
    if(r.status<300||r.status>=400){
      return {r,text:r.headers.get('content-type')?.includes('text/html')||/xml/i.test(r.headers.get('content-type')||'')?await r.text():'',ms:Date.now()-started,redirects,redirectLoop:false};
    }
    const loc=r.headers.get('location');
    if(!loc)return {r,text:'',ms:Date.now()-started,redirects,redirectLoop:false};
    const next=normalize(loc,current);
    if(!next)return {r,text:'',ms:Date.now()-started,redirects,redirectLoop:false};
    if(redirects.includes(next)||next===current)return {r,text:'',ms:Date.now()-started,redirects:[...redirects,next],redirectLoop:true};
    redirects.push(next);current=next;
  }
  throw new Error('Too many redirects');
}

async function getRobots(base,userAgent){
  try{
    const r=await fetch(new URL('/robots.txt',base),{headers:{'user-agent':userAgent},signal:AbortSignal.timeout(10000)});
    return {status:r.status,text:r.ok?await r.text():''};
  }catch{return {status:0,text:''}}
}
function parseRobots(robots,userAgent='*'){
  const groups=[]; let current=null;
  for(const raw of String(robots||'').split(/\r?\n/)){
    const line=raw.split('#')[0].trim();if(!line)continue;
    if(/^user-agent:/i.test(line)){const ua=line.replace(/^user-agent:/i,'').trim().toLowerCase();current={agents:[ua],rules:[],sitemaps:[]};groups.push(current);continue;}
    if(!current)continue;
    if(/^allow:/i.test(line)||/^disallow:/i.test(line)){current.rules.push({allow:/^allow:/i.test(line),value:line.replace(/^(allow|disallow):/i,'').trim()});continue;}
    if(/^sitemap:/i.test(line))current.sitemaps.push(line.replace(/^sitemap:/i,'').trim());
  }
  const candidates=groups.filter(g=>g.agents.some(a=>a===userAgent.toLowerCase()||a==='*'));
  const g=candidates.find(x=>x.agents.includes(userAgent.toLowerCase()))||candidates[0];
  return {groups,group:g||{agents:[],rules:[],sitemaps:[]},sitemaps:[...new Set(groups.flatMap(x=>x.sitemaps).filter(Boolean))]};
}
function robotMatch(rule,path){
  const escaped=rule.replace(/[.+^${}()|[\]\\]/g,'\\$&').replace(/\*/g,'.*');
  try{return new RegExp(`^${escaped}`).test(path)}catch{return false}
}
function robotsBlocked(parsed,path){
  let best=null;
  for(const r of parsed.group?.rules||[]){if(robotMatch(r.value,path)&&(!best||r.value.length>best.value.length))best=r}
  return Boolean(best&&!best.allow);
}
async function sitemapUrls(base,robotsInfo){
  const urls=[];const candidates=[new URL('/sitemap.xml',base).href,...(robotsInfo.sitemaps||[])];
  const sources=[];let errors=0;
  for(const candidate of [...new Set(candidates)]){
    try{
      const r=await fetch(candidate,{headers:{'user-agent':'AnairaSEO/4.0'},signal:AbortSignal.timeout(15000)});
      sources.push({url:candidate,status:r.status,ok:r.ok});
      if(!r.ok){errors++;continue;}
      const xml=await r.text();
      for(const m of xml.matchAll(/<loc>\s*([^<]+)\s*<\/loc>/gi))urls.push(m[1].trim());
    }catch{errors++;sources.push({url:candidate,status:0,ok:false})}
  }
  return {urls:[...new Set(urls)],sources,errors,found:sources.some(x=>x.ok&&/xml/i.test(x.url))};
}
function sameOriginOrSubdomain(url,base,includeSubdomains){
  try{
    const a=new URL(url),b=new URL(base);
    return a.origin===b.origin||(includeSubdomains&&a.hostname.endsWith(`.${b.hostname}`));
  }catch{return false}
}
function soft404(status,text){
  if(status!==200)return false;
  const t=String(text||'').toLowerCase();
  return /(page not found|404 error|nothing here|doesn't exist|does not exist)/i.test(t)&&htmlTextLength(t)<800;
}
function htmlTextLength(s){return String(s||'').replace(/<[^>]+>/g,' ').replace(/\s+/g,' ').trim().length}

export async function runSiteCrawl(s,site,opts={}){
  const cfg={
    maxPages:500,renderJs:false,respectRobots:true,includeSubdomains:false,includePaths:[],excludePaths:[],
    crawlDelayMs:100,userAgent:'AnairaSEO/4.0',crawlDevice:'desktop',urlParamsMode:'ignore',
    ...site.crawl_settings,...opts
  };
  const base=new URL(site.domain.startsWith('http')?site.domain:`https://${site.domain}`);
  const robotsInfo=cfg.respectRobots?await getRobots(base,cfg.userAgent):{status:0,text:''};
  const robotsParsed=parseRobots(robotsInfo.text,cfg.userAgent);
  const sitemapInfo=await sitemapUrls(base,robotsParsed);
  const initialSitemap=sitemapInfo.urls;
  const queue=[];
  const addQueue=(u,d=0,source='crawl')=>{
    const n=normalize(u,base.href);if(!n)return;
    try{
      const x=new URL(n);
      if(cfg.urlParamsMode==='strip'){for(const k of [...x.searchParams.keys()])x.searchParams.delete(k)}
      else if(cfg.urlParamsMode==='ignore'&&x.search){/* preserve URL identity but no extra query crawl rules below */}
      queue.push({url:x.href,depth:d,source});
    }catch{}
  };
  addQueue(base.href,0,'homepage');
  for(const u of initialSitemap)addQueue(u,0,'sitemap');

  const seen=new Set(),pages=[],links=[],rawIssues=[],documents=new Map();
  const {data:audit,error:ae}=await s.from('crm_seo_audits').insert({
    site_id:site.id,audit_type:'crawl',status:'running',started_at:new Date().toISOString(),issues:[],
    recommendations:[],rule_version:TECHNICAL_RULE_VERSION,pages_scanned:0,crawl_config:cfg,crawl_mode:site.crawl_mode,max_pages:Number(cfg.maxPages)||500
  }).select('id').single();
  if(ae)throw ae;

  while(queue.length&&seen.size<Math.min(Number(cfg.maxPages)||500,10000)){
    const item=queue.shift();let u;
    try{u=new URL(item.url)}catch{continue}
    u.hash='';
    const normalized=u.href;
    if(seen.has(normalized)||!sameOriginOrSubdomain(normalized,base,Boolean(cfg.includeSubdomains)))continue;
    if(cfg.excludePaths?.some(x=>u.pathname.startsWith(String(x))))continue;
    if(cfg.includePaths?.length&&!cfg.includePaths.some(x=>u.pathname.startsWith(String(x))))continue;
    if(cfg.respectRobots&&robotsBlocked(robotsParsed,u.pathname))continue;
    if(cfg.urlParamsMode==='ignore'&&u.search&&/[?&](?:utm_|gclid|fbclid|msclkid)=/i.test(u.search))continue;
    seen.add(normalized);
    try{
      const {r,text,ms,redirects,redirectLoop}=await request(normalized,{userAgent:cfg.userAgent,renderJs:Boolean(cfg.renderJs),timeout:30000});
      const statusHeaders={
        hsts:r.headers.get('strict-transport-security'),csp:r.headers.get('content-security-policy'),
        xcto:r.headers.get('x-content-type-options'),xfo:r.headers.get('x-frame-options'),
        referrer:r.headers.get('referrer-policy'),permissions:r.headers.get('permissions-policy'),
        cache:r.headers.get('cache-control'),etag:r.headers.get('etag'),lastModified:r.headers.get('last-modified'),
        contentEncoding:r.headers.get('content-encoding'),vary:r.headers.get('vary'),pragma:r.headers.get('pragma'),
        expires:r.headers.get('expires'),contentType:r.headers.get('content-type'),poweredBy:r.headers.get('x-powered-by')
      };
      const ctx={
        status:r.status,statusHeaders,serverHeader:r.headers.get('server'),contentType:statusHeaders.contentType,
        redirects,redirectLoop,soft404:soft404(r.status,text),robotsPresent:Boolean(robotsInfo.text),robotsStatus:robotsInfo.status,robotsSitemap:robotsParsed.sitemaps.length>0,
        sitemapMissing:!sitemapInfo.found,sitemapErrors:sitemapInfo.errors,depth:item.depth,rootUrl:base.href,rootHost:base.hostname.replace(/^www\./,''),rootProtocol:base.protocol,
        multipleLocales:Boolean(cfg.multipleLocales||site.crawl_settings?.multipleLocales),simpleRobotsParser:true
      };
      const c=seoChecks(text,normalized,ctx);
      documents.set(normalized,{text,ctx,parsed:c});
      const contentHash=hash(c.text);
      const internal=c.internal.filter(x=>sameOriginOrSubdomain(x.url,base,Boolean(cfg.includeSubdomains)));
      pages.push({
        site_id:site.id,url:normalized,title:c.title,meta_description:c.desc,canonical_url:c.canonical?abs(c.canonical,normalized):null,
        robots:c.robots||null,h1:c.h1[0]||null,schema_json:c.scripts.map(x=>x.value??{valid:false,error:x.error}),
        content_score:Math.min(100,Math.round(c.wordCount/5)),technical_score:c.audit.score,keyword_score:0,total_score:c.audit.score,
        last_crawled_at:new Date().toISOString(),status:String(r.status),http_status:r.status,http_status_text:r.statusText,
        content_type:statusHeaders.contentType,response_time_ms:ms,content_length:Buffer.byteLength(text,'utf8'),word_count:c.wordCount,
        inlinks:0,outlinks:internal.length,crawl_depth:item.depth,indexable:!( /\bnoindex\b/i.test(c.robots||'') )&&r.status<400,
        language_code:c.lang||null,viewport_present:c.viewport,
        mixed_content:new URL(normalized).protocol==='https:'&&c.internal.some(x=>/^http:/i.test(x.url)),
        security_headers:statusHeaders,image_count:c.images.length,image_alt_missing:c.images.filter(x=>x.alt==null||x.alt==='').length,
        script_bytes:c.scriptSrc.join('').length,css_bytes:c.styles.join('').length,content_hash:contentHash,
        headings_json:c.headings,extracted_links:c.links,extracted_images:c.images,social_json:{og:c.og,twitter:c.twitter},
        crawl_redirect_chain:redirects,status_code_family:`${Math.floor(r.status/100)}xx`,orphan:false,canonical_conflict:false
      });
      for(const i of c.audit.issues){
        rawIssues.push({site_id:site.id,url:normalized,page_id:null,issue_type:i.code,code:i.code,category:i.category,
          severity:i.severity,impact:i.impact,message:i.message,recommendation:i.recommendation,
          auto_fixable:['missing_title','missing_meta_description','missing_h1','image_alt_missing'].includes(i.code),
          status:'open',fingerprint:hash(`${i.code}:${normalized}`),evidence:{status:r.status,redirects,robots:c.robots||'',url:normalized},
          checked_at:new Date().toISOString(),first_seen_at:new Date().toISOString(),last_seen_at:new Date().toISOString()
        });
      }
      for(const l of internal){
        links.push({audit_id:audit.id,site_id:site.id,source_url:normalized,target_url:l.url,link_type:'internal',
          anchor_text:l.anchor,nofollow:l.nofollow,status_code:null});
        if(l.url&&!seen.has(l.url))addQueue(l.url,item.depth+1,'internal');
      }
      await sleep(cfg.crawlDelayMs);
    }catch(e){
      pages.push({site_id:site.id,url:normalized,status:'crawl_error',total_score:0,technical_score:0,last_crawled_at:new Date().toISOString(),
        http_status:0,status_code_family:'0xx',indexable:false});
      rawIssues.push({site_id:site.id,url:normalized,issue_type:'crawl_error',code:'crawl_error',category:'crawlability',severity:'error',
        impact:'high',message:e.message,recommendation:'Fix the URL/server and recrawl',status:'open',
        fingerprint:hash(`crawl_error:${normalized}`),evidence:{url:normalized},checked_at:new Date().toISOString(),
        first_seen_at:new Date().toISOString(),last_seen_at:new Date().toISOString()});
    }
  }

  // Persist pages first and resolve page IDs for every issue.
  if(pages.length){
    const {error}=await s.from('crm_seo_pages').upsert(pages,{onConflict:'site_id,url'});
    if(error){await s.from('crm_seo_audits').update({status:'failed',completed_at:new Date().toISOString(),recommendations:[`Page persistence failed: ${error.message}`]}).eq('id',audit.id);throw error;}
  }
  const urls=[...new Set(pages.map(x=>x.url))];
  const pageMap=new Map();
  for(let start=0;start<urls.length;start+=500){
    const {data, error}=await s.from('crm_seo_pages').select('id,url').eq('site_id',site.id).in('url',urls.slice(start,start+500));
    if(error)throw error;
    for(const p of data||[])pageMap.set(p.url,p.id);
  }
  for(const i of rawIssues)i.page_id=pageMap.get(i.url)||null;

  // Recalculate the internal graph and validate link targets.
  const inCounts=new Map();
  for(const l of links)inCounts.set(l.target_url,(inCounts.get(l.target_url)||0)+1);
  const sitemapSet=new Set(initialSitemap.map(u=>normalize(u,base.href)).filter(Boolean));
  const orphanUrls=[];
  const crawledMap=new Map(pages.map(x=>[x.url,x]));
  const linkTargets=[...new Set(links.map(x=>x.target_url).filter(Boolean))].slice(0,Math.max(100,Math.min(Number(cfg.maxLinkChecks)||500,2000)));
  const linkStatusMap=new Map();
  for(let i=0;i<linkTargets.length;i++){
    const target=linkTargets[i];
    if(crawledMap.has(target)){linkStatusMap.set(target,Number(crawledMap.get(target).http_status||0));continue;}
    try{const r=await fetch(target,{redirect:'manual',headers:{'user-agent':cfg.userAgent},signal:AbortSignal.timeout(12000)});linkStatusMap.set(target,r.status);}catch{linkStatusMap.set(target,0)}
    await sleep(Math.min(100,Math.max(0,Number(cfg.linkProbeDelayMs??cfg.crawlDelayMs)||0)));
  }
  for(const p of pages){
    const inc=inCounts.get(p.url)||0;
    const orphan=inc===0&&p.url!==base.href;
    p.canonical_conflict=Boolean(p.canonical_url&&p.canonical_url!==p.url&&pages.some(x=>x.url===p.canonical_url));
    p.inlinks=inc;p.orphan=orphan;
    if(orphan)orphanUrls.push(p.url);
  }
  for(const l of links)l.status_code=linkStatusMap.get(l.target_url)??null;
  // Add target-status issues with exact source-page evidence.
  const pageIssue=(code,severity,message,recommendation,sourceUrl,target,status)=>{rawIssues.push({site_id:site.id,url:sourceUrl,page_id:pageMap.get(sourceUrl)||null,issue_type:code,code,category:'links',severity,impact:severity==='error'?'high':'medium',message,recommendation,auto_fixable:false,status:'open',fingerprint:hash(`${code}:${sourceUrl}:${target}`),evidence:{target,status},checked_at:new Date().toISOString(),first_seen_at:new Date().toISOString(),last_seen_at:new Date().toISOString()})};
  for(const l of links){const st=linkStatusMap.get(l.target_url);if(st==null)continue;if(st>=400||st===0){const external=!l.target_url.startsWith(base.origin);pageIssue(external?'broken_external_link':'broken_internal_link',external?'warning':'error',`${external?'External':'Internal'} link returns HTTP ${st||'network error'}`,external?'Fix or replace the external link':'Fix the broken internal link',l.source_url,l.target_url,st||0)}}
  for(const p of pages){
    const d=documents.get(p.url);if(!d)continue;
    const refreshed=seoChecks(d.text,p.url,{...d.ctx,inlinks:p.inlinks,orphan:p.orphan,linkStatusMap:Object.fromEntries(linkStatusMap)});
    p.total_score=refreshed.audit.score;p.technical_score=refreshed.audit.score;
    for(const i of refreshed.audit.issues){
      if(['broken_internal_link','broken_external_link','duplicate_title','duplicate_meta_description','duplicate_h1','duplicate_content_hash','orphan_page'].includes(i.code))continue;
      rawIssues.push({site_id:site.id,url:p.url,page_id:pageMap.get(p.url)||null,issue_type:i.code,code:i.code,category:i.category,severity:i.severity,impact:i.impact,message:i.message,recommendation:i.recommendation,auto_fixable:false,status:'open',fingerprint:hash(`${i.code}:${p.url}`),evidence:i.evidence||{},checked_at:new Date().toISOString(),first_seen_at:new Date().toISOString(),last_seen_at:new Date().toISOString()});
    }
  }
  if(pages.length){const {error}=await s.from('crm_seo_pages').upsert(pages,{onConflict:'site_id,url'});if(error)throw error;}
  if(links.length){await s.from('crm_seo_crawl_links').delete().eq('audit_id',audit.id);const {error}=await s.from('crm_seo_crawl_links').insert(links);if(error)throw error;}

  // Cross-page/link validation rules.
  const pageStatus=new Map(pages.map(p=>[p.url,p.http_status]));
  for(const l of links){
    const st=pageStatus.get(l.target_url);
    if(st!=null&&st>=400) rawIssues.push({site_id:site.id,url:l.source_url,page_id:pageMap.get(l.source_url)||null,issue_type:'broken_internal_link',code:'broken_internal_link',category:'links',severity:'error',impact:'high',message:`Internal link returns HTTP ${st}`,recommendation:'Fix or remove the broken internal link',auto_fixable:false,status:'open',fingerprint:hash(`broken_internal_link:${l.source_url}:${l.target_url}`),evidence:{source:l.source_url,target:l.target_url,status:st},checked_at:new Date().toISOString(),first_seen_at:new Date().toISOString(),last_seen_at:new Date().toISOString()});
  }
  const titleGroups=new Map(),descGroups=new Map(),h1Groups=new Map(),contentGroups=new Map();
  for(const p of pages){
    const add=(map,val)=>{const k=String(val||'').trim().toLowerCase();if(!k)return;(map.get(k)||map.set(k,[]).get(k)).push(p)};
    add(titleGroups,p.title);add(descGroups,p.meta_description);add(h1Groups,p.h1);add(contentGroups,p.content_hash);
  }
  const addCross=(code,category,severity,message,recommendation,url,evidence)=>rawIssues.push({
    site_id:site.id,url,page_id:pageMap.get(url)||null,issue_type:code,code,category,severity,impact:severity==='error'?'high':severity==='warning'?'medium':'low',
    message,recommendation,auto_fixable:false,status:'open',fingerprint:hash(`${code}:${url}`),evidence,checked_at:new Date().toISOString(),
    first_seen_at:new Date().toISOString(),last_seen_at:new Date().toISOString()
  });
  for(const [k,arr] of titleGroups)if(arr.length>1)for(const p of arr)addCross('duplicate_title','on_page','error','Duplicate title shared by multiple pages','Write a unique title for this page',p.url,{duplicates:arr.map(x=>x.url)});
  for(const [k,arr] of descGroups)if(arr.length>1)for(const p of arr)addCross('duplicate_meta_description','on_page','warning','Duplicate meta description shared by multiple pages','Write a unique meta description',p.url,{duplicates:arr.map(x=>x.url)});
  for(const [k,arr] of h1Groups)if(arr.length>1)for(const p of arr)addCross('duplicate_h1','on_page','warning','Duplicate H1 shared by multiple pages','Use a unique primary heading when appropriate',p.url,{duplicates:arr.map(x=>x.url)});
  for(const [k,arr] of contentGroups)if(arr.length>1&&k)for(const p of arr)addCross('duplicate_content_hash','content','warning','Pages share the same extracted content signature','Review duplicate/near-duplicate page intent',p.url,{duplicates:arr.map(x=>x.url)});
  for(const url of orphanUrls){addCross('orphan_page','links','error','Page has no inbound internal link from the crawl graph','Add a useful internal link or remove the URL from the sitemap',url,{source:sitemapSet.has(url)?'sitemap-or-crawl':'crawl',inlinks:0});if(sitemapSet.has(url))addCross('sitemap_orphan','links','error','Sitemap URL has no inbound internal link from the crawl graph','Add a useful internal link or remove the URL from the sitemap',url,{source:'sitemap',inlinks:0});}

  // Mark old issues not seen in the current crawl as resolved; reopen matching fingerprints.
  const {data:oldIssues}=await s.from('crm_seo_issues').select('id,fingerprint,status').eq('site_id',site.id);
  const currentFp=new Set(rawIssues.map(x=>x.fingerprint).filter(Boolean));
  const oldOpen=(oldIssues||[]).filter(x=>x.status==='open'||x.status==='in_progress');
  for(let start=0;start<rawIssues.length;start+=500){
    const batch=rawIssues.slice(start,start+500);
    const {error}=await s.from('crm_seo_issues').upsert(batch,{onConflict:'site_id,fingerprint'});
    if(error){
      await s.from('crm_seo_audits').update({status:'failed',completed_at:new Date().toISOString(),recommendations:[`Issue persistence failed: ${error.message}`]}).eq('id',audit.id);
      throw error;
    }
  }
  const stale=oldOpen.filter(x=>x.fingerprint&&!currentFp.has(x.fingerprint)).map(x=>x.id);
  if(stale.length){await s.from('crm_seo_issues').update({status:'resolved',resolved_at:new Date().toISOString(),last_seen_at:new Date().toISOString()}).in('id',stale);for(const id of stale)await s.from('crm_seo_issue_history').insert({site_id:site.id,issue_id:id,action:'resolve',after_data:{status:'resolved'},created_at:new Date().toISOString()});}

  const counts={error:rawIssues.filter(x=>x.severity==='error').length,warning:rawIssues.filter(x=>x.severity==='warning').length,notice:rawIssues.filter(x=>x.severity==='notice').length};
  const score=pages.length?Math.round(pages.reduce((a,p)=>a+Number(p.total_score||0),0)/pages.length):0;
  const now=new Date().toISOString();
  await s.from('crm_seo_audits').update({
    status:'completed',completed_at:now,score,pages_scanned:pages.length,discovered_urls:seen.size,
    issues:rawIssues,errors_count:counts.error,warnings_count:counts.warning,notices_count:counts.notice,
    recommendations:[...new Set(rawIssues.map(x=>x.recommendation).filter(Boolean))].slice(0,100)
  }).eq('id',audit.id);
  await s.from('crm_seo_score_history').insert({site_id:site.id,audit_id:audit.id,score,pages_scanned:pages.length,errors:counts.error,warnings:counts.warning,notices:counts.notice});

  const {data:prev}=await s.from('crm_seo_audits').select('id,score,issues').eq('site_id',site.id).neq('id',audit.id).eq('status','completed').order('completed_at',{ascending:false}).limit(1).maybeSingle();
  if(prev){
    const prevFp=new Set((prev.issues||[]).map(x=>x.fingerprint).filter(Boolean));
    const curFp=new Set(rawIssues.map(x=>x.fingerprint).filter(Boolean));
    let resolved=0,newCount=0,persistent=0;
    for(const x of prevFp){if(curFp.has(x))persistent++;else resolved++}
    for(const x of curFp){if(!prevFp.has(x))newCount++}
    await s.from('crm_seo_audit_comparisons').insert({
      site_id:site.id,previous_audit_id:prev.id,current_audit_id:audit.id,score_delta:score-Number(prev.score||0),
      new_issues:newCount,resolved_issues:resolved,regressed_issues:0,persistent_issues:persistent,
      details:{newFingerprints:[...curFp].filter(x=>!prevFp.has(x)).slice(0,500),resolvedFingerprints:[...prevFp].filter(x=>!curFp.has(x)).slice(0,500)}
    });
  }
  return {auditId:audit.id,pagesScanned:pages.length,discoveredUrls:seen.size,score,...counts,
    robotsRespected:Boolean(cfg.respectRobots),technicalRuleCount:TECHNICAL_RULE_REGISTRY.length,technicalIssueCount:rawIssues.length,technicalRuleVersion:TECHNICAL_RULE_VERSION,orphanPages:orphanUrls.length};
}
