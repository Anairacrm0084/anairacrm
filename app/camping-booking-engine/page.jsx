import {redirect} from 'next/navigation';

export default function CampingBookingEngine({searchParams}) {
  const property = searchParams?.property ? `&property=${encodeURIComponent(searchParams.property)}` : '';
  redirect(`/booking-engine?type=camp${property}`);
}
