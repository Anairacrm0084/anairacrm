import SimplePage from '../SimplePage';
export default function Page(){return <SimplePage active="/team-tasks" eyebrow="TEAM WORK" title="Team Tasks" subtitle="Manager view of the tenant task queue." table="crm_tasks" orderBy="due_at" fields={['title','status','priority','due_at','assigned_to']} columns={['Task','Status','Priority','Due','Assigned To']} />}
