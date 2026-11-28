import {NextResponse} from 'next/server';
import {supabase} from '../../../../lib/supabase';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const EMAIL_TO = 'techanaira@gmail.com';
const clean = (value, max = 1000) => String(value ?? '').trim().slice(0, max);

async function sendNotificationEmail(property) {
  const apiKey = process.env.RESEND_API_KEY;
  const from = process.env.RESEND_FROM || process.env.SEO_REPORT_FROM;
  if (!apiKey || !from) return {sent: false, reason: 'email_provider_not_configured'};

  const text = [
    'NEW PROPERTY REGISTRATION',
    'ANAIRA STAYS & EXPERIENCES',
    '================================',
    '',
    'PROPERTY DETAILS',
    `Property Name: ${property.property_name}`,
    `Property Type: ${property.property_type}`,
    `Rooms / Units: ${property.units}`,
    '',
    'CONTACT DETAILS',
    `Contact Person: ${property.contact_name}`,
    `Email: ${property.email}`,
    `Phone / WhatsApp: ${property.phone}`,
    '',
    'LOCATION',
    `Address: ${property.address}`,
    `City / Destination: ${property.city}`,
    `State: ${property.state}`,
    '',
    `Website: ${property.website || 'Not provided'}`,
    '',
    'ADDITIONAL INFORMATION',
    property.message || 'Not provided',
    '',
    '================================',
    'Submitted through ANAIRA Hotels Marketplace.'
  ].join('\n');

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from,
      to: [EMAIL_TO],
      reply_to: property.email,
      subject: `New Property Registration: ${property.property_name}`,
      text
    })
  });

  const result = await response.json().catch(() => ({}));
  if (!response.ok) {
    console.error('[ANAIRA List Property] Resend rejected notification:', result);
    return {sent: false, reason: 'email_delivery_failed'};
  }
  return {sent: true, messageId: result.id || null};
}

export async function POST(request) {
  try {
    const body = await request.json();

    if (clean(body.website_confirm, 200)) {
      return NextResponse.json({ok: true, emailSent: false});
    }

    const property = {
      property_name: clean(body.property_name, 150),
      contact_name: clean(body.contact_name, 120),
      email: clean(body.email, 254).toLowerCase(),
      phone: clean(body.phone, 20),
      property_type: clean(body.property_type, 30),
      address: clean(body.address, 1000),
      city: clean(body.city, 100),
      state: clean(body.state, 100),
      units: Number(body.units),
      website: clean(body.website, 500),
      message: clean(body.message, 3000)
    };

    const allowedTypes = ['hotel', 'homestay', 'camp', 'guest_house', 'cottage'];
    if (
      !property.property_name ||
      !property.contact_name ||
      !property.email ||
      !property.phone ||
      !property.address ||
      !property.city ||
      !property.state ||
      !allowedTypes.includes(property.property_type) ||
      !Number.isInteger(property.units) ||
      property.units < 1 ||
      property.units > 10000
    ) {
      return NextResponse.json(
        {error: 'Please complete all required fields with valid values.'},
        {status: 400}
      );
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(property.email)) {
      return NextResponse.json({error: 'Please enter a valid email address.'}, {status: 400});
    }
    if (!/^[+()\d\s.-]{7,20}$/.test(property.phone)) {
      return NextResponse.json({error: 'Please enter a valid mobile number.'}, {status: 400});
    }
    if (property.website && !/^https?:\/\/[^\s]+$/i.test(property.website)) {
      return NextResponse.json({error: 'Please enter a valid website URL.'}, {status: 400});
    }

    const {error: insertError} = await supabase
      .from('anaira_property_listing_inquiries')
      .insert({...property, status: 'pending'});

    if (insertError) {
      console.error('[ANAIRA List Property] Supabase insert failed:', insertError);
      return NextResponse.json(
        {error: 'We could not save your registration. Please try again later.'},
        {status: 503}
      );
    }

    const email = await sendNotificationEmail(property);
    return NextResponse.json({
      ok: true,
      saved: true,
      emailSent: email.sent,
      emailStatus: email.sent ? 'sent' : email.reason
    });
  } catch (error) {
    console.error('[ANAIRA List Property] Request failed:', error);
    return NextResponse.json(
      {error: 'Unable to process your property registration right now.'},
      {status: 500}
    );
  }
}
