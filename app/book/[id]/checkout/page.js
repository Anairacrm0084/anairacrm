import HotelBookingCheckout from '../../../../components/booking/HotelBookingCheckout';

/** Keep the established /book/{id}/checkout URL; do not redirect. */
export default function BookCheckoutPage() {
  return <HotelBookingCheckout routeBase="/book" />;
}
