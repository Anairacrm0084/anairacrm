import {NextResponse} from 'next/server';

const hostOnly=value=>String(value||'').split(',').map(x=>x.trim().toLowerCase()).filter(Boolean);

export async function proxy(request){
 const {pathname}=request.nextUrl;
 if(pathname.startsWith('/_next')||pathname.startsWith('/api/')||pathname==='/favicon.ico'||pathname.startsWith('/robots.txt')||pathname.startsWith('/sitemap'))return NextResponse.next();
 const host=(request.headers.get('x-forwarded-host')||request.headers.get('host')||'').split(',')[0].trim().toLowerCase().replace(/:\\d+$/,'');
 if(!host||host==='localhost'||host==='127.0.0.1'||host.endsWith('.vercel.app'))return NextResponse.next();
 const configuredHosts=hostOnly(process.env.ANAIRA_PLATFORM_HOSTNAMES);
 try{
  const domainsUrl=new URL('/api/public/platform-domains',request.url);
  const domainsResponse=await fetch(domainsUrl,{headers:{'x-anaira-platform-host-check':'proxy'},cache:'no-store'});
  if(domainsResponse.ok){const domains=await domainsResponse.json();if(Array.isArray(domains?.hostnames))configuredHosts.push(...domains.hostnames.map(x=>String(x||'').trim().toLowerCase()));}
 }catch{}
 if(configuredHosts.includes(host)||host==='crm.anairapos.in'||host==='anaira.com'||host==='www.anaira.com')return NextResponse.next();
 const base=String(process.env.ANAIRA_STORE_DOMAIN||'').trim().toLowerCase().replace(/^\*\./,'');
 if(base&&(host===base||host===`www.${base}`))return NextResponse.next();
 try{
  const resolveUrl=new URL('/api/public/property-store/resolve-domain',request.url);
  resolveUrl.searchParams.set('host',host);
  const response=await fetch(resolveUrl,{headers:{'x-anaira-domain-resolution':'proxy'},cache:'no-store'});
  if(!response.ok)return NextResponse.next();
  const result=await response.json();
  const route=String(result?.route_path||'');
  if(!route.startsWith('/property/')&&!route.startsWith('/stay/'))return NextResponse.rewrite(new URL('/domain-not-found',request.url));
  const target=new URL(route,request.url);
  if(pathname!=='/'){const suffix=pathname.replace(/^\//,'');target.pathname=`${target.pathname.replace(/\/$/,'')}/${suffix}`;}
  request.nextUrl.searchParams.forEach((value,key)=>{if(!target.searchParams.has(key))target.searchParams.set(key,value)});
  return NextResponse.rewrite(target);
 }catch{
  return NextResponse.next();
 }
}

export const config={matcher:['/((?!_next/static|_next/image|favicon.ico|api/).*)']};
