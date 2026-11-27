import {NextResponse} from 'next/server';

const hostOnly=value=>String(value||'').split(',').map(x=>x.trim().toLowerCase()).filter(Boolean);

export async function proxy(request){
 const {pathname}=request.nextUrl;
 if(pathname!=='/')return NextResponse.next();
 const host=(request.headers.get('x-forwarded-host')||request.headers.get('host')||'').split(',')[0].trim().toLowerCase().replace(/:\\d+$/,'');
 if(!host||host==='localhost'||host==='127.0.0.1'||host.endsWith('.vercel.app'))return NextResponse.next();
 if(hostOnly(process.env.ANAIRA_PLATFORM_HOSTNAMES).includes(host))return NextResponse.next();
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
  return NextResponse.rewrite(new URL(route,request.url));
 }catch{
  return NextResponse.next();
 }
}

export const config={matcher:['/']};
