export async function requestWithConnection(connection,credentials,{path,method='GET',body,timeoutMs=20000}={}){
 if(!connection.base_url) throw new Error('Provider Base URL is not configured.');
 const base=String(connection.base_url).replace(/\/$/,''); const p=String(path||'').startsWith('/')?String(path):`/${path||''}`;
 const headers={'content-type':'application/json','accept':'application/json'}; const type=String(connection.auth_type||'api_key');
 if(type==='api_key'&&credentials.api_key) headers.authorization=`Bearer ${credentials.api_key}`;
 if(type==='basic'&&credentials.username) headers.authorization=`Basic ${Buffer.from(`${credentials.username}:${credentials.password||''}`).toString('base64')}`;
 if(type==='oauth2'&&credentials.access_token) headers.authorization=`Bearer ${credentials.access_token}`;
 if(type==='hmac'&&credentials.api_key) headers['x-api-key']=credentials.api_key;
 if(credentials.headers&&typeof credentials.headers==='object')Object.assign(headers,credentials.headers);
 const ctrl=new AbortController();const timer=setTimeout(()=>ctrl.abort(),timeoutMs);
 try{const response=await fetch(`${base}${p}`,{method,headers,body:body===undefined?undefined:JSON.stringify(body),signal:ctrl.signal,cache:'no-store'});const raw=await response.text();let data={};try{data=raw?JSON.parse(raw):{}}catch{data={raw}};if(!response.ok){const e=new Error(data?.message||data?.error||`Provider HTTP ${response.status}`);e.status=response.status;throw e;}return {status:response.status,data};}finally{clearTimeout(timer)}
}
