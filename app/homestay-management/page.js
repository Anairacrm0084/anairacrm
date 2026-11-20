import {redirect} from 'next/navigation';

export default async function HomestayManagement({searchParams}) {
  const params = await searchParams;
  const query = new URLSearchParams();
  if (params?.property) query.set('property', params.property);
  query.set('type', 'homestay');
  redirect(`/hotel-management?${query.toString()}`);
}
