import AnairaShell from '@/components/anaira/AnairaShell';
import PlatformStoreControl from '../../platform-store-control';
import GlobalStoreQR from '@/components/anaira/GlobalStoreQR';

export default function Page(){
 return <AnairaShell title="ANAIRA Store">
  <div className="anaira-store-admin-page">
   <div className="anaira-store-admin-hero">
    <div><span>SUPER ADMIN • ANAIRA CUSTOMER STORES</span><h1>ANAIRA Store Control Center</h1><p>Manage both platform-owned customer stores from one place: Hotel Marketplace and Restaurant Marketplace. Global presentation/settings stay here; hotel operations remain in HMS and restaurant operations remain in Restaurant SaaS.</p></div>
   </div>
   <GlobalStoreQR/>
   <PlatformStoreControl/>
  </div>
 </AnairaShell>
}
