import assert from 'node:assert/strict';
import {normalizeInboundReservation} from '../../lib/server/distribution/reservation-inbox.js';

const sample = normalizeInboundReservation('booking_com', {
  event_type: 'reservation',
  data: {
    confirmationNumber: 'BK-12345', status: 'confirmed',
    guest: {name: 'Test Guest', email: 'guest@example.com', phone: '+911234567890'},
    checkIn: '2026-12-10', checkOut: '2026-12-12', adults: 2,
    totalAmount: 4500, currencyCode: 'INR', roomTypeCode: 'DLX', ratePlanCode: 'BAR'
  }
});
assert.equal(sample.external_reference, 'BK-12345');
assert.equal(sample.check_in, '2026-12-10');
assert.equal(sample.check_out, '2026-12-12');
assert.equal(sample.guest_name, 'Test Guest');
assert.equal(sample.amount, 4500);
assert.equal(sample.external_room_code, 'DLX');
assert.equal(sample.external_rate_code, 'BAR');
const changed = normalizeInboundReservation('booking_com', {event_type:'reservation.updated',data:{confirmationNumber:'BK-12345',guest_name:'Test Guest',check_in:'2026-12-10',check_out:'2026-12-12'}});
assert.equal(changed.reservation_status,'modified');
const cancelled = normalizeInboundReservation('booking_com', {event_type:'reservation.cancelled',data:{confirmationNumber:'BK-12345',guest_name:'Test Guest',check_in:'2026-12-10',check_out:'2026-12-12'}});
assert.equal(cancelled.reservation_status,'cancelled');
const minimalCancellation = normalizeInboundReservation('booking_com', {
  event_type:'reservation.cancelled',
  data:{confirmationNumber:'BK-12345'}
});
assert.equal(minimalCancellation.external_reference,'BK-12345');
assert.equal(minimalCancellation.reservation_status,'cancelled');
assert.equal(Object.hasOwn(minimalCancellation,'check_in'),false);
assert.equal(Object.hasOwn(minimalCancellation,'guest_name'),false);
assert.equal(Object.hasOwn(minimalCancellation,'amount'),false);
assert.throws(() => normalizeInboundReservation('booking_com', {data:{guest_name:'No dates'}}), /reference number/);
assert.throws(() => normalizeInboundReservation('booking_com', {data:{confirmation_number:'X',guest_name:'Guest',check_in:'2026-12-12',check_out:'2026-12-10'}}), /invalid or missing/);
console.log(JSON.stringify({status:'PASS',checks:16,scope:'normalization and validation only; no live OTA call'}, null, 2));
