/** OTA distribution is reserved for accommodation businesses, never general tenants. */
export const OTA_PROPERTY_BUSINESS_TYPES = Object.freeze([
  'hotel_resort',
  'hotel_restaurant',
  'camping',
]);

export function isOtaPropertyBusinessType(value) {
  return OTA_PROPERTY_BUSINESS_TYPES.includes(String(value || '').trim().toLowerCase());
}

export async function requireOtaProperty(admin, restaurantId) {
  const id = String(restaurantId || '').trim();
  if (!id) throw new Error('Property is required for OTA distribution.');
  const { data: property, error } = await admin
    .from('restaurants')
    .select('id,name,business_type,status')
    .eq('id', id)
    .maybeSingle();
  if (error) throw error;
  if (!property || !isOtaPropertyBusinessType(property.business_type)) {
    throw new Error('OTA Channel Manager is available only for Hotel / Resort, Hotel + Restaurant, and Camping properties. Other business types cannot connect to OTAs.');
  }
  return property;
}
