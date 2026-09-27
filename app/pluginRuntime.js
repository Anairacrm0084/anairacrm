import {getPluginDefinition} from './pluginEngine';

// Compatibility adapter for older consumers. The Phase 22 completion runtime
// is owned by pluginEngine; no action is merely declarative anymore.
export function runtimeFor(pluginKey){
  const def=getPluginDefinition(pluginKey);
  if(!def)return {createFields:[],actions:[],statusField:null,searchFields:[]};
  return {createFields:def.createFields,actions:def.actions.map(x=>x.name),statusField:def.statusField,searchFields:def.fields.filter(x=>['name','full_name','company_name','title','domain','code','source','customer_id'].includes(x)).slice(0,8)};
}
