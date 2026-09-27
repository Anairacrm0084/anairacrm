import SimplePage from '../SimplePage';
export default function Page(){return <SimplePage active="/activity" eyebrow="ACTIVITY" title="Activity Log" subtitle="Tenant-scoped CRM audit activity." table="crm_audit_logs" orderBy="created_at" fields={['actor_id','entity_type','entity_id','action','created_at']} columns={['Actor','Entity','Entity ID','Action','Created']} />}
