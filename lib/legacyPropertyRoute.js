/**
 * Canonicalize legacy /book URLs to the property-store route family while
 * retaining every query parameter (dates, occupancy, source, room and rate).
 */
export function legacyPropertyQueryString(query = {}) {
  const params = new URLSearchParams();
  for (const [key, raw] of Object.entries(query || {})) {
    if (Array.isArray(raw)) {
      for (const value of raw) {
        if (value !== undefined && value !== null && String(value) !== '') {
          params.append(key, String(value));
        }
      }
    } else if (raw !== undefined && raw !== null && String(raw) !== '') {
      params.set(key, String(raw));
    }
  }
  return params.toString();
}

export function canonicalPropertyUrl(id, suffix = '', query = {}) {
  const search = legacyPropertyQueryString(query);
  return `/property/${encodeURIComponent(String(id))}${suffix}${search ? `?${search}` : ''}`;
}
