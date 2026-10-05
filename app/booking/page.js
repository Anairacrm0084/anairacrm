import { redirect } from 'next/navigation';

export default async function Page({ searchParams }) {
  const params = await searchParams;

  let qs = '';
  if (params instanceof URLSearchParams) {
    qs = params.toString();
  } else if (params && typeof params === 'object') {
    const normalized = new URLSearchParams();
    for (const [key, value] of Object.entries(params)) {
      if (Array.isArray(value)) {
        for (const item of value) {
          if (item != null) normalized.append(key, String(item));
        }
      } else if (value != null) {
        normalized.set(key, String(value));
      }
    }
    qs = normalized.toString();
  }

  redirect(`/booking-engine${qs ? `?${qs}` : ''}`);
}
