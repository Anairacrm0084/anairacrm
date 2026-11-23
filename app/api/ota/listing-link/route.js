import {NextResponse} from 'next/server';
import {db} from '../../../../lib/server/provider';
import {requireTenant} from '../../../../lib/server/auth';

const ALLOWED = new Set(['booking_com','airbnb','agoda','expedia','makemytrip','goibibo','trip_com','hostelworld']);
const TYPES = new Set(['hotel','hotel_resort','hotel_restaurant','camp','camping','homestay','guest_house','cottage','resort','villa','hostel','farm_stay','lodge','motel','glamping']);

export async function POST(req) {
  try {
    const body = await req.json().catch(() => ({}));
    const restaurantId = String(body.restaurant_id || '').trim();
    const provider = String(body.provider_code || '').trim().toLowerCase();
    const listingId = String(body.external_listing_id || '').trim();
    const accountEmail = String(body.account_email || '').trim().toLowerCase();
    const channelManager = String(body.channel_manager || 'direct').trim().toLowerCase();
    const connectionMode = String(body.connection_mode || 'property_managed').trim().toLowerCase();
    if (!['anaira_managed','property_managed'].includes(connectionMode)) throw new Error('Choose Anaira central API or property-owned OTA account.');
    if (!ALLOWED.has(provider)) throw new Error('Select a supported OTA provider.');
    if (!listingId || listingId.length > 180) throw new Error('Enter the existing OTA listing / property ID.');
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(accountEmail)) throw new Error('Enter the email used for the existing OTA account.');
    if (body.consent !== true) throw new Error('Property owner authorization is required.');
    const {user, profile} = await requireTenant(req, restaurantId);
    if (!profile.is_super_admin && !['admin','business_admin','owner','property_admin','hotel_admin'].includes(String(profile.role || '').toLowerCase())) {
      throw new Error('Only the property owner or admin can request an OTA account link.');
    }
    const service = db();
    const {data: property, error: propertyError} = await service.from('restaurants')
      .select('id,name,business_type,hospitality_type,hospitality_types').eq('id', restaurantId).maybeSingle();
    if (propertyError) throw propertyError;
    const types = [property?.business_type, property?.hospitality_type, ...(property?.hospitality_types || [])].map(x => String(x || '').toLowerCase());
    if (!property || !types.some(x => TYPES.has(x))) throw new Error('OTA linking is available only for accommodation properties.');
    const {data: prior, error: priorError} = await service.from('anaira_ota_listing_link_requests')
      .select('id,status').eq('restaurant_id', restaurantId).eq('provider_code', provider).eq('external_listing_id', listingId).maybeSingle();
    if (priorError) throw priorError;
    if (prior?.status === 'connected') throw new Error('This existing OTA listing is already linked. Contact Anaira Super Admin if you need to relink it.');
    const {data, error} = await service.from('anaira_ota_listing_link_requests').upsert({
      restaurant_id: restaurantId,
      provider_code: provider,
      external_listing_id: listingId,
      account_email: accountEmail,
      channel_manager: channelManager,
      connection_mode: connectionMode,
      status: 'authorization_requested',
      owner_authorized_at: new Date().toISOString(),
      requested_by: user.id,
      updated_at: new Date().toISOString(),
    }, {onConflict: 'restaurant_id,provider_code,external_listing_id'}).select('id,restaurant_id,provider_code,external_listing_id,account_email,channel_manager,connection_mode,status,created_at').single();
    if (error) throw error;
    return NextResponse.json({ok:true,request:data,message:'Existing listing recorded using the selected connection route. Anaira will verify the relevant central provider account or property authorization; no OTA login password was collected and no live sync has been enabled.'});
  } catch (error) {
    return NextResponse.json({ok:false,error:error?.message || 'Unable to submit OTA linking request.'},{status:400});
  }
}
