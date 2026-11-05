import {redirect} from 'next/navigation';

/**
 * Legacy camping storefront URLs now resolve to the canonical hospitality
 * storefront. Camps, hotels, homestays and cottages share /book/[restaurantId]
 * so the customer always sees the business-specific profile and one booking
 * engine instead of a second generic camping storefront.
 */
export default async function LegacyCampingStoreRedirect({params,searchParams}) {
  const {id} = await params;
  const query = await searchParams;
  const values = new URLSearchParams({stay_type:'camp'});
  for (const key of ['check_in','check_out','adults','children']) {
    const value = query?.[key];
    if (typeof value === 'string' && value) values.set(key,value);
  }
  redirect(`/book/${encodeURIComponent(id)}?${values.toString()}`);
}
