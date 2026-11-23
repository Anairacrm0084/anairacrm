/** OTA distribution is reserved for accommodation properties, never general tenants. */
export const OTA_PROPERTY_BUSINESS_TYPES = Object.freeze([
  'hotel_resort','hotel_restaurant','camping','hotel','camp','homestay','guest_house','cottage',
  'resort','villa','hostel','farm_stay','lodge','motel','glamping'
]);

export function isOtaPropertyBusinessType(value, property = null) {
  const allowed = new Set(OTA_PROPERTY_BUSINESS_TYPES);
  const values = [value, property?.hospitality_type, ...(Array.isArray(property?.hospitality_types) ? property.hospitality_types : [])]
    .map(item => String(item || '').trim().toLowerCase()).filter(Boolean);
  return values.some(item => allowed.has(item));
}

export async function requireOtaProperty(admin, restaurantId) {
  const id = String(restaurantId || '').trim();
  if (!id) throw new Error('Property is required for OTA distribution.');
  const { data: property, error } = await admin
    .from('restaurants')
    .select('id,name,business_type,hospitality_type,hospitality_types,status')
    .eq('id', id)
    .maybeSingle();
  if (error) throw error;
  if (!property || !isOtaPropertyBusinessType(property.business_type, property)) {
    throw new Error('OTA Channel Manager is available only for accommodation properties: hotels, resorts, camps, homestays, guest houses and cottages.');
  }
  return property;
}
