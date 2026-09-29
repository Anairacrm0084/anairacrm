'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter, useSearchParams } from 'next/navigation';
import { resolveRestaurantId } from '../../../../../lib/publicProperty';
import { supabase } from '../../../../../lib/supabase';

const PAGE_CSS = `
body{margin:0;background:#f8f3eb;color:#3d2415;font-family:Montserrat,Arial,sans-serif}
.rd{min-height:100vh;padding:28px 20px 80px}
.rd-top{max-width:1180px;margin:auto;display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;position:sticky;top:0;z-index:10;padding:12px 0;background:rgba(248,243,235,.92);backdrop-filter:blur(12px)}
.rd-top button{border:0;background:transparent;color:#8b5c32;font-weight:700;cursor:pointer}.rd-top span{font:500 22px Georgia,serif}
.rd-hero{max-width:1180px;margin:auto;display:grid;grid-template-columns:1.15fr .85fr;gap:34px;align-items:stretch}.rd-main-image{min-height:560px;border-radius:20px;overflow:hidden;background:#e9e1d5;display:grid;place-items:center;color:#8b5c32;font:600 30px Georgia,serif;box-shadow:0 18px 50px rgba(65,39,19,.12)}.rd-main-image img{width:100%;height:100%;object-fit:cover}
.rd-info{background:#fff;border:1px solid #e4d9cc;border-radius:20px;padding:42px;display:flex;flex-direction:column;justify-content:center;box-shadow:0 18px 50px rgba(65,39,19,.08)}
.rd-info small,.direct small{letter-spacing:2px;font-size:10px;color:#b88a4a;font-weight:700}.rd-info h1{font:500 clamp(42px,5vw,68px) Georgia,serif;margin:10px 0 18px}.rd-info p{font-size:14px;line-height:1.8;color:#756b62}.chips{display:flex;flex-wrap:wrap;gap:8px;margin:20px 0}.chips span,.amenities span{background:#f5f0e7;padding:9px 11px;border-radius:7px;font-size:10px}
.rate-box{margin-top:22px;border-top:1px solid #e5dbcf;padding-top:20px;display:flex;justify-content:space-between;gap:15px;align-items:center}.rate-box b{font:600 26px Georgia,serif;color:#8b5c32}.rate-box em{font-size:10px;color:#82786e;font-style:normal}.rate-box button,.sticky-book,.direct a{border:0;background:linear-gradient(135deg,#a86f2e,#7d4e25);color:#fff;padding:14px 18px;border-radius:9px;font-weight:700;cursor:pointer;text-decoration:none;box-shadow:0 10px 24px rgba(126,79,35,.22)}
.premium-hero{position:relative}.premium-hero:after{content:'ANAIRA VERIFIED HOSPITALITY';position:absolute;top:18px;left:18px;background:rgba(255,255,255,.92);color:#8b5c32;border:1px solid #d9b77e;border-radius:999px;padding:9px 14px;font-size:9px;letter-spacing:1.8px;font-weight:800;z-index:2}
.premium-highlights{max-width:1180px;margin:24px auto;display:grid;grid-template-columns:repeat(4,1fr);gap:12px}.premium-highlights>div{background:linear-gradient(145deg,#fff,#f7f0e6);border:1px solid #e2d4c3;border-radius:16px;padding:18px 16px;box-shadow:0 10px 28px rgba(74,45,23,.06)}.premium-highlights span{display:block;color:#b17a35;font-size:18px;margin-bottom:8px}.premium-highlights b{display:block;font-size:12px;letter-spacing:.4px}.premium-highlights small{display:block;color:#8c8177;margin-top:5px;font-size:10px}
.gallery{max-width:1180px;margin:24px auto 50px;display:grid;grid-template-columns:repeat(3,1fr);gap:12px}.gallery img{width:100%;height:220px;object-fit:cover;border-radius:16px;border:1px solid #e1d3c2;box-shadow:0 12px 30px rgba(74,45,23,.08)}
.rd-grid{max-width:1180px;margin:auto;display:grid;grid-template-columns:1.2fr .8fr;gap:22px}.box{background:#fff;border:1px solid #e4d9cc;border-radius:20px;padding:30px;box-shadow:0 14px 38px rgba(74,45,23,.07)}.box h2{font:500 27px Georgia,serif;margin:0 0 22px}.box h3{font:500 22px Georgia,serif;margin:28px 0 12px}.detail-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}.detail-grid div{padding:14px;background:#faf7f1;border-radius:10px;display:grid;gap:5px}.detail-grid b,.rate-row b{font-size:11px}.detail-grid span,.rate-row span{font-size:11px;color:#756b62}.amenities{display:flex;flex-wrap:wrap;gap:8px}.rate-row{display:flex;justify-content:space-between;gap:15px;padding:15px 0;border-bottom:1px solid #eee5da}.rate-row div{display:grid;gap:5px}.rate-row strong{font:600 20px Georgia,serif;color:#8b5c32}.sticky-book{width:100%;margin-top:18px}.policies{max-width:1180px;margin:22px auto}.policies>div{display:grid;grid-template-columns:130px 1fr;gap:12px;font-size:12px}.policies span{color:#756b62}.direct{max-width:1180px;margin:22px auto;display:flex;justify-content:space-between;align-items:center;gap:20px;background:#3d2415;color:#fff}.direct h2{margin:7px 0;color:#fff}.direct p{margin:0;color:#dfd3c6;font-size:12px}.direct a{background:#25a45a;white-space:nowrap}
@media(max-width:850px){.rd-hero,.rd-grid{grid-template-columns:1fr}.rd-main-image{min-height:360px}.direct{display:block}.direct a{display:inline-block;margin-top:18px}}@media(max-width:520px){.rd{padding:18px 14px 50px}.rd-info{padding:24px}.detail-grid{grid-template-columns:1fr}.rate-box{display:block}.rate-box button{width:100%;margin-top:15px}.policies>div{grid-template-columns:1fr}}@media(max-width:800px){.premium-highlights{grid-template-columns:repeat(2,1fr)}.gallery{grid-template-columns:1fr}.gallery img{height:240px}.rd-hero{grid-template-columns:1fr}.rd-main-image{min-height:380px}}
`;

const parseList = (value) => {
  if (Array.isArray(value)) return value;
  if (typeof value !== 'string') return [];
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return value.split(',').map((item) => item.trim()).filter(Boolean);
  }
};

export default function RoomDetails() {
  const params = useParams();
  const router = useRouter();
  const search = useSearchParams();
  const key = params?.id || '';
  const roomId = params?.room_type || '';
  const [stayType] = useState(() => {
    if (typeof window === 'undefined') return 'hotel';
    return new URLSearchParams(window.location.search).get('stay_type') || 'hotel';
  });
  const [hotel, setHotel] = useState(null);
  const [room, setRoom] = useState(null);
  const [rates, setRates] = useState([]);
  const [msg, setMsg] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const property = await resolveRestaurantId(key);
        if (!property) throw new Error('Property not found.');

        const [{ data: hotelData }, { data: roomData }, { data: rateData }] = await Promise.all([
          supabase.from('hms_settings').select('hotel_name,short_name,logo_url,cover_image_url,address,city,state,country,phone,whatsapp,currency,cancellation_policy,child_policy,pet_policy,smoking_policy,check_in_time,check_out_time,payment_settings').eq('restaurant_id', property.id).maybeSingle(),
          supabase.from('hms_room_types').select('*').eq('id', roomId).eq('restaurant_id', property.id).eq('hospitality_type', stayType).maybeSingle(),
          supabase.from('hms_rate_plans').select('id,name,code,room_type_id,hospitality_type,board_type,rate,weekend_rate,active,refundable,deposit_percent,cancellation_policy,description').eq('restaurant_id', property.id).eq('room_type_id', roomId).eq('hospitality_type', stayType).eq('active', true).order('rate'),
        ]);

        let resolvedRoom = roomData;
        let resolvedRates = rateData || [];

        if (stayType === 'camp') {
          const { data: legacyById } = await supabase.from('camp_unit_types').select('*').eq('id', roomId).eq('restaurant_id', property.id).maybeSingle();
          const { data: legacyMatches } = await supabase.from('camp_unit_types').select('*').eq('restaurant_id', property.id).eq('active', true);
          const legacy = legacyById || (legacyMatches || []).find((item) => {
            const sameCode = resolvedRoom?.code && item.code === resolvedRoom.code;
            const sameName = resolvedRoom?.name && String(item.name || '').toLowerCase() === String(resolvedRoom.name || '').toLowerCase();
            return sameCode || sameName;
          });

          if (!resolvedRoom && legacy) {
            resolvedRoom = {
              ...legacy,
              id: legacy.id,
              room_type_id: legacy.id,
              hospitality_type: 'camp',
              short_description: legacy.short_description || legacy.description || '',
              description: legacy.description || legacy.short_description || '',
              base_rate: legacy.base_rate ?? legacy.rate ?? 0,
              extra_adult_price: legacy.extra_adult_price ?? legacy.extra_adult ?? 0,
              extra_child_price: legacy.extra_child_price ?? legacy.extra_child ?? 0,
              image_urls: legacy.image_urls ?? legacy.photos ?? [],
              amenities: legacy.amenities ?? [],
              number_of_beds: legacy.number_of_beds ?? legacy.beds ?? 1,
              pricing_mode: legacy.pricing_mode || 'per_person',
            };
          }

          if (legacy) {
            const { data: legacyRates } = await supabase.from('camp_rate_plans').select('*').eq('restaurant_id', property.id).eq('unit_type_id', legacy.id).eq('active', true).order('rate');
            if ((!resolvedRates || resolvedRates.length === 0) && legacyRates?.length) {
              resolvedRoom = {
                ...legacy,
                id: legacy.id,
                room_type_id: legacy.id,
                hospitality_type: 'camp',
                short_description: legacy.short_description || legacy.description || '',
                description: legacy.description || legacy.short_description || '',
                base_rate: legacy.base_rate ?? legacy.rate ?? 0,
                extra_adult_price: legacy.extra_adult_price ?? legacy.extra_adult ?? 0,
                extra_child_price: legacy.extra_child_price ?? legacy.extra_child ?? 0,
                image_urls: legacy.image_urls ?? legacy.photos ?? [],
                amenities: legacy.amenities ?? [],
                number_of_beds: legacy.number_of_beds ?? legacy.beds ?? 1,
                pricing_mode: legacy.pricing_mode || 'per_person',
              };
              resolvedRates = legacyRates.map((item) => ({
                ...item,
                room_type_id: legacy.id,
                hospitality_type: 'camp',
                pricing_mode: item.pricing_mode || 'per_person',
                source: 'legacy_camp',
                legacy_unit_type_id: item.unit_type_id,
              }));
            }
          }
        }

        if (!resolvedRoom) throw new Error(stayType === 'camp' ? 'Camp / tent type not found.' : 'Room type not found.');
        if (cancelled) return;
        setHotel({ id: property.id, ...hotelData });
        setRoom(resolvedRoom);
        setRates(resolvedRates);
        setLoading(false);
      } catch (error) {
        if (cancelled) return;
        setMsg(error?.message || 'Unable to load room details.');
        setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, [key, roomId, stayType]);

  if (loading) return <main className="rd"><div className="box">Loading room details…</div></main>;
  if (!room) return <main className="rd"><div className="box">{msg || 'Room not found.'}</div></main>;

  const firstRate = rates[0];
  const bookingQuery = new URLSearchParams({
    stay_type: stayType,
    room_type: String(room.id),
    rate_plan: String(firstRate?.id || ''),
    check_in: search.get('check_in') || '',
    check_out: search.get('check_out') || '',
    adults: search.get('adults') || '2',
    children: search.get('children') || '0',
  }).toString();

  const bookingUrl = stayType === 'camp' && firstRate?.source === 'legacy_camp'
    ? `/camping/${key}/checkout?unit_type=${encodeURIComponent(firstRate.legacy_unit_type_id || room.id)}&rate_plan=${encodeURIComponent(firstRate.id || '')}&check_in=${encodeURIComponent(search.get('check_in') || '')}&check_out=${encodeURIComponent(search.get('check_out') || '')}&adults=${encodeURIComponent(search.get('adults') || '2')}&children=${encodeURIComponent(search.get('children') || '0')}`
    : `/book/${key}/checkout?${bookingQuery}`;

  const images = parseList(room.image_urls || room.photos);
  const amenities = parseList(room.amenities);
  const unitLabel = stayType === 'camp' ? 'Camp / Tent' : stayType === 'homestay' ? 'Homestay' : stayType === 'guest_house' ? 'Guest House' : stayType === 'cottage' ? 'Cottage' : 'Room';
  const capacity = room.max_guests || ((Number(room.max_adults) || 0) + (Number(room.max_children) || 0));
  const startingRate = Number(firstRate?.rate ?? room.base_rate ?? 0).toLocaleString('en-IN');
  const pricingLabel = firstRate?.pricing_mode === 'per_person' || room.pricing_mode === 'per_person' ? 'person / night' : 'unit / night';
  const payment = hotel?.payment_settings && typeof hotel.payment_settings === 'object' ? hotel.payment_settings : {};
  void payment;

  const goToBooking = () => router.push(bookingUrl);

  return (
    <main className="rd">
      <div className="rd-top">
        <button onClick={() => router.push(`/book/${key}?stay_type=${encodeURIComponent(stayType)}`)}>← Back to rooms</button>
        <span>{hotel?.hotel_name || 'Property'}</span>
      </div>

      <section className="rd-hero premium-hero">
        <div className="rd-main-image">
          {images[0] ? <img src={images[0]} alt={room.name || unitLabel} /> : <div>{unitLabel}</div>}
        </div>
        <div className="rd-info">
          <small>{stayType === 'camp' ? 'CAMP / TENT' : unitLabel.toUpperCase()}</small>
          <h1>{room.name}</h1>
          <p>{room.description || room.short_description || `A comfortable ${unitLabel.toLowerCase()} prepared for a relaxed stay.`}</p>
          <div className="chips">
            <span>{room.max_adults || 0} Adults</span>
            {Number(room.max_children || 0) > 0 && <span>{room.max_children} Children</span>}
            {room.bed_type && <span>{room.bed_type}</span>}
            <span>{room.number_of_beds || 1} Bed{Number(room.number_of_beds || 1) > 1 ? 's' : ''}</span>
          </div>
          <div className="rate-box">
            <div><b>From ₹{startingRate}</b><em> / {pricingLabel}</em></div>
            <button onClick={goToBooking}>BOOK THIS {unitLabel.toUpperCase()} →</button>
          </div>
        </div>
      </section>

      <section className="premium-highlights">
        <div><span>✦</span><b>Verified {unitLabel}</b><small>Live property data</small></div>
        <div><span>◈</span><b>Direct Booking</b><small>No third-party inventory</small></div>
        <div><span>◇</span><b>Flexible Rates</b><small>Choose your rate plan</small></div>
        <div><span>✓</span><b>Secure Reservation</b><small>Contact verification required</small></div>
      </section>

      {images.length > 1 && (
        <section className="gallery">
          {images.map((src, index) => (
            <img key={`${src}-${index}`} src={src} alt={`${room.name || unitLabel} ${index + 1}`} />
          ))}
        </section>
      )}

      <section className="rd-grid">
        <div className="box">
          <h2>{unitLabel} Details</h2>
          <div className="detail-grid">
            <div><b>Capacity</b><span>{capacity} guests · {room.max_adults || 0} adults</span></div>
            <div><b>{stayType === 'camp' ? 'Stay Type' : 'Bed'}</b><span>{room.bed_type || unitLabel} · {room.number_of_beds || 1}</span></div>
            <div><b>Extra Adult</b><span>₹{Number(room.extra_adult_price ?? room.extra_adult ?? 0).toLocaleString('en-IN')}</span></div>
            <div><b>Extra Child</b><span>₹{Number(room.extra_child_price ?? room.extra_child ?? 0).toLocaleString('en-IN')}</span></div>
            {room.floor && <div><b>Floor</b><span>{room.floor}</span></div>}
            {room.size && <div><b>Size</b><span>{room.size}</span></div>}
            {room.unit_count && <div><b>Units</b><span>{room.unit_count}</span></div>}
          </div>
          {amenities.length > 0 && (
            <>
              <h3>Amenities</h3>
              <div className="amenities">
                {amenities.map((amenity, index) => <span key={`${amenity}-${index}`}>✓ {amenity}</span>)}
              </div>
            </>
          )}
        </div>

        <aside className="box">
          <h2>Rate Plans</h2>
          {rates.length > 0 ? rates.map((rate) => (
            <div className="rate-row" key={rate.id}>
              <div>
                <b>{rate.name}</b>
                <span>{rate.board_type || 'Room only'} · {rate.refundable ? 'Refundable' : 'Non-refundable'}</span>
              </div>
              <strong>₹{Number(rate.rate || 0).toLocaleString('en-IN')}</strong>
            </div>
          )) : <p>No active rate plan configured.</p>}
          <button className="sticky-book" onClick={goToBooking}>BOOK NOW</button>
        </aside>
      </section>

      <section className="policies box">
        <h2>Property Policies</h2>
        <div>
          <b>Check-in</b><span>{hotel?.check_in_time || '12:00'}</span>
          <b>Check-out</b><span>{hotel?.check_out_time || '11:00'}</span>
          <b>Cancellation</b><span>{hotel?.cancellation_policy || 'As per selected rate plan.'}</span>
          <b>Children</b><span>{hotel?.child_policy || 'As per room capacity.'}</span>
        </div>
      </section>

      <section className="direct box">
        <div>
          <small>DIRECT BOOKING</small>
          <h2>Need help before booking?</h2>
          <p>Chat with the property directly on WhatsApp for {unitLabel.toLowerCase()} questions or booking assistance.</p>
        </div>
        {hotel?.whatsapp && (
          <a href={`https://wa.me/${String(hotel.whatsapp).replace(/\D/g, '')}`} target="_blank" rel="noreferrer">WHATSAPP PROPERTY →</a>
        )}
      </section>

      <style jsx global>{PAGE_CSS}</style>
    </main>
  );
}
