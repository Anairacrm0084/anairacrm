'use client';

import { Suspense, useEffect } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';

function CampingManagementContent() {
  const params = useSearchParams();
  const router = useRouter();

  useEffect(() => {
    const q = new URLSearchParams();
    const property = params.get('property');

    if (property) q.set('property', property);
    q.set('type', 'camp');

    router.replace(`/hotel-management?${q.toString()}`);
  }, [params, router]);

  return <main style={{ padding: 24 }}>Opening Camping Management…</main>;
}

export default function CampingManagement() {
  return (
    <Suspense fallback={<main style={{ padding: 24 }}>Opening Camping Management…</main>}>
      <CampingManagementContent />
    </Suspense>
  );
}
