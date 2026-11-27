'use client';
import HospitalityStorePage from '../../_components/HospitalityStorePage';

/** Preserve the /book/{id} URL family; no canonical redirect. */
export default function BookPropertyPage() {
  return <HospitalityStorePage routeBase="/book" />;
}
