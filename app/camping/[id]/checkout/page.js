import { redirect } from 'next/navigation';
import { canonicalPropertyUrl } from '../../../../lib/legacyPropertyRoute';

/** Legacy camping checkout: resolve to the canonical property-store journey. */
export default async function CampingCheckoutRedirect({ params, searchParams }) {
  const [{ id }, query] = await Promise.all([params, searchParams]);
  const unitType = query?.unit_type || query?.room_type;

  if (!unitType) {
    const browseQuery = { ...query, stay_type: 'camp' };
    delete browseQuery.unit_type;
    delete browseQuery.room_type;
    delete browseQuery.rate_plan;
    delete browseQuery.rate_plan_id;
    redirect(canonicalPropertyUrl(id, '', browseQuery));
  }

  const checkoutQuery = {
    ...query,
    stay_type: 'camp',
    room_type: String(unitType),
  };
  delete checkoutQuery.unit_type;
  const ratePlan = query?.rate_plan || query?.rate_plan_id;
  if (ratePlan) checkoutQuery.rate_plan = String(ratePlan);
  delete checkoutQuery.rate_plan_id;
  redirect(canonicalPropertyUrl(id, '/checkout', checkoutQuery));
}
