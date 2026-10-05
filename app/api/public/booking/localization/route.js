import {NextResponse} from 'next/server';
import {SUPPORTED_LANGUAGES,SUPPORTED_CURRENCIES,getLanguage,getCurrency} from '../../../../../lib/server/booking-localization.js';
export const runtime='nodejs';
export async function GET(req){
 const {searchParams}=new URL(req.url);
 const language=getLanguage(searchParams.get('language')||'en-IN');
 const currency=getCurrency(searchParams.get('currency')||'INR');
 return NextResponse.json({ok:true,defaultLanguage:language,defaultCurrency:currency,languages:SUPPORTED_LANGUAGES,currencies:SUPPORTED_CURRENCIES,version:'2026-10-03'});
}
