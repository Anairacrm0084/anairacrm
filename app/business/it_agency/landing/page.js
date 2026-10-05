import BusinessLanding from '../../../../components/business/BusinessLanding';
import AnairaGraphicsPage from '../../../anaira-graphics/page';
import ItAgencyPremiumLanding from '../../../../components/business/ItAgencyPremiumLanding';
import {supabaseAdmin} from '../../../../lib/supabaseAdmin';

const ANAIRA_GRAPHICS_ID = '737d5047-39f0-480b-8279-c7b1262f9e6c';

export default async function Page({searchParams}){
  const params = await searchParams;
  const businessId = params?.business || params?.id || '';

  if (businessId) {
    try {
      const admin = supabaseAdmin();
      const {data: business} = await admin
        .from('restaurants')
        .select('id,name,email,business_type')
        .eq('id', businessId)
        .maybeSingle();

      if (business?.id === ANAIRA_GRAPHICS_ID && business?.business_type === 'it_agency') {
        return <AnairaGraphicsPage />;
      }

      if (business?.business_type === 'it_agency') {
        return <ItAgencyPremiumLanding />;
      }
    } catch {
      // Fall through to the existing universal IT Agency landing.
    }
  }

  return <BusinessLanding type='it_agency'/>;
}
