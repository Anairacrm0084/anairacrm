export const SUPPORTED_LANGUAGES=[
 {code:'en-IN',name:'English',nativeName:'English'},
 {code:'hi-IN',name:'Hindi',nativeName:'हिन्दी'},
 {code:'pa-IN',name:'Punjabi',nativeName:'ਪੰਜਾਬੀ'},
 {code:'bn-IN',name:'Bengali',nativeName:'বাংলা'},
 {code:'ta-IN',name:'Tamil',nativeName:'தமிழ்'},
 {code:'te-IN',name:'Telugu',nativeName:'తెలుగు'},
 {code:'mr-IN',name:'Marathi',nativeName:'मराठी'},
 {code:'gu-IN',name:'Gujarati',nativeName:'ગુજરાતી'},
 {code:'en-US',name:'English (US)',nativeName:'English'},
 {code:'en-GB',name:'English (UK)',nativeName:'English'},
 {code:'fr-FR',name:'French',nativeName:'Français'},
 {code:'de-DE',name:'German',nativeName:'Deutsch'},
 {code:'es-ES',name:'Spanish',nativeName:'Español'},
 {code:'ar-AE',name:'Arabic',nativeName:'العربية'}
];

export const SUPPORTED_CURRENCIES=[
 {code:'INR',symbol:'₹',name:'Indian Rupee',decimals:2},
 {code:'USD',symbol:'$',name:'US Dollar',decimals:2},
 {code:'EUR',symbol:'€',name:'Euro',decimals:2},
 {code:'GBP',symbol:'£',name:'British Pound',decimals:2},
 {code:'AED',symbol:'د.إ',name:'UAE Dirham',decimals:2},
 {code:'SGD',symbol:'S$',name:'Singapore Dollar',decimals:2},
 {code:'AUD',symbol:'A$',name:'Australian Dollar',decimals:2},
 {code:'CAD',symbol:'C$',name:'Canadian Dollar',decimals:2},
 {code:'JPY',symbol:'¥',name:'Japanese Yen',decimals:0}
];

export function getLanguage(code='en-IN'){
 const wanted=String(code).trim();
 return SUPPORTED_LANGUAGES.find(x=>x.code===wanted)||SUPPORTED_LANGUAGES.find(x=>x.code.split('-')[0]===wanted.split('-')[0])||SUPPORTED_LANGUAGES[0];
}
export function getCurrency(code='INR'){
 return SUPPORTED_CURRENCIES.find(x=>x.code===String(code).toUpperCase())||SUPPORTED_CURRENCIES[0];
}
export function formatBookingMoney(amount,currency='INR',locale){
 const c=getCurrency(currency); const n=Number(amount||0);
 try{return new Intl.NumberFormat(locale||getLanguage('en-IN').code,{style:'currency',currency:c.code,minimumFractionDigits:c.decimals,maximumFractionDigits:c.decimals}).format(n)}catch{return `${c.symbol}${n.toFixed(c.decimals)}`}
}
export function normalizeBookingLocale(locale='en-IN'){return getLanguage(locale).code}
