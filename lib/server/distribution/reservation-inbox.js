import {normalizeReservation} from './adapters/index.js';

const VALID_STATUSES = new Set(['confirmed','modified','cancelled','canceled','no_show','no-show','pending']);
const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

export function normalizeInboundReservation(provider, envelope) {
  const raw = envelope?.data && typeof envelope.data === 'object' ? envelope.data : envelope;
  const normalized = normalizeReservation(provider, raw);
  const checkIn = normalized.stay.check_in ? String(normalized.stay.check_in).slice(0, 10) : null;
  const checkOut = normalized.stay.check_out ? String(normalized.stay.check_out).slice(0, 10) : null;
  if (!normalized.external_reference) throw new Error('OTA reservation is missing its external confirmation/reference number.');
  const eventType = String(envelope?.event_type || envelope?.type || 'reservation').toLowerCase();
  const isCancellation = /cancel|canceled|cancelled/.test(eventType);
  // Many OTA cancellation webhooks contain only the external booking reference.
  // Preserve existing PMS guest/stay fields by omitting missing values on upsert.
  if (!isCancellation && (!checkIn || !checkOut || !ISO_DATE.test(checkIn) || !ISO_DATE.test(checkOut) || checkOut <= checkIn)) {
    throw new Error('OTA reservation has invalid or missing check-in/check-out dates.');
  }
  if (!isCancellation && !normalized.guest.name) throw new Error('OTA reservation is missing the primary guest name.');
  if (isCancellation && ((checkIn && !ISO_DATE.test(checkIn)) || (checkOut && !ISO_DATE.test(checkOut)))) {
    throw new Error('OTA cancellation contains an invalid check-in/check-out date.');
  }
  let status = VALID_STATUSES.has(normalized.status) ? normalized.status : 'pending';
  if (isCancellation) status = 'cancelled';
  else if (/modif|update|change/.test(eventType) && !['cancelled','canceled'].includes(status)) status = 'modified';
  const common = {
    provider_code: String(provider).toLowerCase(),
    external_reference: normalized.external_reference,
    event_type: eventType,
    reservation_status: status,
    raw_payload: raw,
  };
  const optionalGuestStay = {
    ...(normalized.guest.name ? {guest_name:normalized.guest.name} : {}),
    ...(normalized.guest.email ? {guest_email:normalized.guest.email} : {}),
    ...(normalized.guest.phone ? {guest_phone:normalized.guest.phone} : {}),
    ...(checkIn ? {check_in:checkIn} : {}),
    ...(checkOut ? {check_out:checkOut} : {}),
  };
  if (isCancellation) return {...common,...optionalGuestStay};
  const amount = Number.isFinite(normalized.amount) && normalized.amount >= 0 ? normalized.amount : 0;
  return {
    ...common,
    ...optionalGuestStay,
    adults: Math.max(1, Number(raw.adults || raw.numberOfAdults || 1) || 1),
    children: Math.max(0, Number(raw.children || raw.numberOfChildren || 0) || 0),
    amount,
    currency: String(normalized.currency || 'INR').toUpperCase(),
    external_room_code: raw.room_type_code || raw.roomTypeCode || raw.room?.code || raw.room_id || null,
    external_rate_code: raw.rate_plan_code || raw.ratePlanCode || raw.rate?.code || null,
  };
}
