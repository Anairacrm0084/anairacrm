import {NextResponse} from 'next/server';
import {adminDb} from '../../../../lib/server/provider';
export const runtime='nodejs';
export const dynamic='force-dynamic';
const DEFAULT_HOSTS=['crm.anairapos.in','anaira.com','www.anaira.com'];
export async function GET(){try{const {data,error}=await adminDb().from('anaira_platform_settings').select('value').eq('key','anaira_platform_hostnames').maybeSingle();if(error)throw error;const saved=Array.isArray(data?.value?.value)?data.value.value:[];const hostnames=[...new Set([...DEFAULT_HOSTS,...saved.map(x=>String(x||'').trim().toLowerCase()).filter(Boolean)])];return NextResponse.json({ok:true,hostnames},{headers:{'Cache-Control':'no-store, max-age=0'}})}catch{return NextResponse.json({ok:true,hostnames:DEFAULT_HOSTS},{headers:{'Cache-Control':'no-store, max-age=0'}})}}
