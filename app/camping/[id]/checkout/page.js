import { redirect } from 'next/navigation';

/**
 * Keep the legacy camping checkout URL working, but send customers to the
 * canonical premium hospitality checkout. The canonical checkout supports
 * legacy camp_unit_types and camp_rate_plans through stay_type=camp.
 */
export default async function CampingCheckoutRedirect({ params, searchParams }) {
  const { id } = await params;
  const query = await searchParams;
  const unitType = query?.unit_type || query?.room_type;

  // Without a selected tent/unit, return to the public camping store so the
  // guest can choose an available unit before entering checkout.
  if (!unitType) {
    const browse = new URLSearchParams({ stay_type: 'camp' });
    for (const key of ['check_in', 'check_out', 'adults', 'children']) {
      const value = query?.[key];
      if (typeof value === 'string' && value) browse.set(key, value);
    }
    redirect(`/book/${encodeURIComponent(id)}?${browse.toString()}`);
  }

  const values = new URLSearchParams({
    stay_type: 'camp',
    room_type: String(unitType),
  });
  const ratePlan = query?.rate_plan || query?.rate_plan_id;
  if (typeof ratePlan === 'string' && ratePlan) values.set('rate_plan', ratePlan);
  for (const key of ['check_in', 'check_out', 'adults', 'children']) {
    const value = query?.[key];
    if (typeof value === 'string' && value) values.set(key, value);
  }
  redirect(`/book/${encodeURIComponent(id)}/checkout?${values.toString()}`);
}
