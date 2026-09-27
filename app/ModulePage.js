'use client';
import CrudPage from './CrudPage';
import {dataSources} from './dataSources';
export default function ModulePage({config}){const slug=config.dataSource || (config.active==='/'?'dashboard':config.active?.slice(1)); let source=dataSources[slug]; if(source&&source.table?.startsWith('crm_')) source={...source,tenantColumn:source.tenantColumn||'tenant_id'}; return <CrudPage config={{...config,source}}/>}
