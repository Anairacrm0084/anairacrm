'use client';
import CrudPage from './CrudPage';
import {dataSources} from './dataSources';
export default function SimplePage({active,title,eyebrow='ANAIRA CRM',subtitle,table,columns=[],fields=[],orderBy='created_at',permissionNote}){const source=table?{table,fields,headers:columns,orderBy,tenantColumn:table.startsWith('crm_')?'tenant_id':undefined,title}:null; if(!source)return <CrudPage config={{active,title,eyebrow,subtitle,source:{table:'crm_tasks',fields:['title','status','priority','due_at','assigned_to'],headers:['Task','Status','Priority','Due','Assigned To'],orderBy:'due_at',tenantColumn:'tenant_id',title:permissionNote||'Workspace'}}}/>; return <CrudPage config={{active,title,eyebrow,subtitle,source}}/>}
