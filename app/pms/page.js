'use client';

import { useEffect, useMemo, useState } from 'react';
import { AppShell, Header, Section, Table, Pill } from '../components';
import { supabase } from '../../lib/supabase';

const actions = [
  ['confirm', 'Confirm'],
  ['check_in', 'Check-in'],
  ['room_move', 'Room Move'],
  ['checkout', 'Check-out'],
  ['no_show', 'No-show'],
  ['cancel', 'Cancel'],
];

const getHospitalityLabel = (type) => {
  const labels = {
    hotel: 'Hotel',
    camp: 'Camping',
    homestay: 'Homestay',
    guest_house: 'Guest House',
    cottage: 'Cottage',
  };

  return labels[type] || 'Hotel';
};

export default function PMSPage() {
  const [session, setSession] = useState(null);
  const [restaurantId, setRestaurantId] = useState(null);
  const [rooms, setRooms] = useState([]);
  const [reservations, setReservations] = useState([]);
  const [busy, setBusy] = useState('');
  const [error, setError] = useState('');
  const [hospitalityType, setHospitalityType] = useState('hotel');

  const load = async (rid, type = hospitalityType) => {
    if (!rid) return;

    setError('');

    const [rq, rs] = await Promise.all([
      supabase
        .from('hms_rooms')
        .select(
          'id,room_number,floor,status,housekeeping_status,room_type_id,hospitality_type'
        )
        .eq('restaurant_id', rid)
        .eq('hospitality_type', type)
        .order('room_number'),

      supabase
        .from('hms_reservations')
        .select(
          'id,reservation_code,guest_id,room_id,check_in,check_out,status,adults,children,total_amount,hospitality_type'
        )
        .eq('restaurant_id', rid)
        .eq('hospitality_type', type)
        .order('check_in', { ascending: true })
        .limit(100),
    ]);

    if (rq.error) {
      setError(rq.error.message);
    }

    if (rs.error) {
      setError(rs.error.message);
    }

    setRooms(rq.data || []);
    setReservations(rs.data || []);
  };

  useEffect(() => {
    let mounted = true;

    (async () => {
      const { data } = await supabase.auth.getSession();

      if (!data.session) {
        location.href = '/login';
        return;
      }

      if (!mounted) return;

      setSession(data.session);

      const { data: profile, error: profileError } = await supabase
        .from('anaira_my_profile')
        .select('restaurant_id')
        .eq('id', data.session.user.id)
        .maybeSingle();

      if (profileError) {
        setError(profileError.message);
        return;
      }

      const rid = profile?.restaurant_id || null;

      if (!rid) {
        setRestaurantId(null);
        return;
      }

      setRestaurantId(rid);

      const { data: restaurant, error: restaurantError } = await supabase
        .from('restaurants')
        .select('hospitality_type,hospitality_types')
        .eq('id', rid)
        .maybeSingle();

      if (restaurantError) {
        setError(restaurantError.message);
        return;
      }

      const types =
        Array.isArray(restaurant?.hospitality_types) &&
        restaurant.hospitality_types.length
          ? restaurant.hospitality_types
          : [restaurant?.hospitality_type || 'hotel'];

      const requested =
        typeof window !== 'undefined'
          ? new URLSearchParams(window.location.search).get('type')
          : '';

      const activeType = types.includes(requested) ? requested : types[0];

      if (!mounted) return;

      setHospitalityType(activeType);
      await load(rid, activeType);
    })();

    return () => {
      mounted = false;
    };
  }, []);

  const today = new Date().toISOString().slice(0, 10);

  const arrivals = useMemo(
    () =>
      reservations.filter(
        (x) =>
          x.check_in === today &&
          ['confirmed', 'pending'].includes(x.status)
      ),
    [reservations, today]
  );

  const inhouse = useMemo(
    () =>
      reservations.filter((x) =>
        ['checked_in', 'in_house'].includes(x.status)
      ),
    [reservations]
  );

  const departures = useMemo(
    () =>
      reservations.filter(
        (x) =>
          x.check_out === today &&
          ['checked_in', 'in_house'].includes(x.status)
      ),
    [reservations, today]
  );

  async function transition(r, action) {
    setBusy(r.id + action);
    setError('');

    let roomId = r.room_id;

    if (action === 'check_in' || action === 'room_move') {
      roomId =
        prompt(
          action === 'check_in'
            ? 'Room ID for check-in'
            : 'Target room ID',
          roomId || ''
        ) || null;

      if (!roomId) {
        setBusy('');
        return;
      }
    }

    const { data, error: transitionError } = await supabase.rpc(
      'anaira_phase13_pms_transition',
      {
        p_restaurant_id: restaurantId,
        p_reservation_id: r.id,
        p_action: action,
        p_room_id: roomId,
        p_notes: null,
      }
    );

    if (transitionError) {
      setError(transitionError.message);
    } else if (data?.ok) {
      await load(restaurantId, hospitalityType);
    } else {
      setError('PMS transition was not accepted.');
    }

    setBusy('');
  }

  if (!session) {
    return (
      <AppShell>
        <div className="notice">Connecting to PMS…</div>
      </AppShell>
    );
  }

  const propertyLabel = getHospitalityLabel(hospitalityType);

  return (
    <AppShell active="/pms">
      <Header
        eyebrow={`${hospitalityType.toUpperCase()} PMS`}
        title={`Anaira ${propertyLabel} PMS`}
        subtitle="Front desk, unit assignment, stay lifecycle and housekeeping handoff. Booking Engine and CRM remain optional integrations."
        actions={
          <button
            className="btn"
            onClick={() => load(restaurantId, hospitalityType)}
          >
            Refresh
          </button>
        }
      />

      {error && <div className="notice error">{error}</div>}

      <div className="grid kpis">
        <div className="kpi">
          <span>Arrivals</span>
          <b>{arrivals.length}</b>
          <small>Today</small>
        </div>

        <div className="kpi">
          <span>In-House</span>
          <b>{inhouse.length}</b>
          <small>Current</small>
        </div>

        <div className="kpi">
          <span>Departures</span>
          <b>{departures.length}</b>
          <small>Today</small>
        </div>

        <div className="kpi">
          <span>
            {hospitalityType === 'camp' ? 'Camps / Tents' : 'Rooms'}
          </span>
          <b>{rooms.length}</b>
          <small>Property</small>
        </div>
      </div>

      <Section
        title="Front Desk — Reservations"
        meta="Live HMS data"
      >
        <Table
          columns={[
            'Code',
            'Check-in',
            'Check-out',
            'Status',
            'Room',
            'Total',
            'Actions',
          ]}
          rows={reservations.map((r) => [
            r.reservation_code,

            r.check_in,

            r.check_out,

            <Pill key={`${r.id}-status`}>
              {r.status}
            </Pill>,

            r.room_id || 'Unassigned',

            String(r.total_amount ?? 0),

            <div
              key={`${r.id}-actions`}
              style={{
                display: 'flex',
                gap: 6,
                flexWrap: 'wrap',
              }}
            >
              {actions.map(([a, label]) => (
                <button
                  key={a}
                  className="btn"
                  disabled={!!busy}
                  onClick={() => transition(r, a)}
                >
                  {busy === r.id + a ? '…' : label}
                </button>
              ))}
            </div>,
          ])}
        />
      </Section>

      <Section
        title={
          hospitalityType === 'camp'
            ? 'Camp / Tent Status'
            : 'Room Status'
        }
        meta="Live HMS rooms"
      >
        <Table
          columns={[
            hospitalityType === 'camp' ? 'Camp / Tent' : 'Room',
            'Floor',
            'Status',
            'Housekeeping',
          ]}
          rows={rooms.map((r) => [
            r.room_number,
            r.floor || '—',
            <Pill key={`${r.id}-room-status`}>
              {r.status}
            </Pill>,
            <Pill key={`${r.id}-housekeeping`}>
              {r.housekeeping_status || '—'}
            </Pill>,
          ])}
        />
      </Section>
    </AppShell>
  );
}