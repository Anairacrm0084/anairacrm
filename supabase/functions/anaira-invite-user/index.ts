import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Content-Type': 'application/json',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: CORS });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ error: 'METHOD_NOT_ALLOWED' }, 405);

  try {
    const token = (req.headers.get('authorization') || '').replace(/^Bearer\s+/i, '');
    if (!token) return json({ error: 'AUTH_REQUIRED' }, 401);

    const url = Deno.env.get('SUPABASE_URL');
    const serviceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!url || !serviceRole) return json({ error: 'FUNCTION_ENV_MISSING' }, 500);

    const admin = createClient(url, serviceRole, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: authData, error: authError } = await admin.auth.getUser(token);
    if (authError || !authData.user) {
      return json({ error: 'AUTH_INVALID', detail: authError?.message || 'Invalid session' }, 401);
    }

    const { data: caller, error: callerError } = await admin
      .from('profiles')
      .select('id,restaurant_id,role,is_super_admin')
      .eq('id', authData.user.id)
      .maybeSingle();

    if (callerError || !caller) {
      return json({ error: 'PROFILE_NOT_FOUND', detail: callerError?.message || 'Profile not found' }, 403);
    }

    const body = await req.json();
    const email = String(body.email || '').trim().toLowerCase();
    const restaurantId = String(body.restaurant_id || '').trim();
    const role = String(body.role || 'staff').trim();
    const fullName = String(body.full_name || '').trim() || null;

    if (!email || !restaurantId) return json({ error: 'EMAIL_AND_RESTAURANT_REQUIRED' }, 400);

    const superAdmin = caller.is_super_admin === true || caller.role === 'super_admin';
    const businessAdmin = caller.restaurant_id === restaurantId && caller.role === 'admin';

    if (!superAdmin && !businessAdmin) return json({ error: 'ADMIN_REQUIRED' }, 403);
    if (!superAdmin && role === 'admin') return json({ error: 'ONLY_SUPER_ADMIN_CAN_CREATE_BUSINESS_ADMIN' }, 403);
    if (!['admin', 'manager', 'staff'].includes(role)) return json({ error: 'INVALID_ROLE' }, 400);

    const { data: property, error: propertyError } = await admin
      .from('restaurants')
      .select('id,name')
      .eq('id', restaurantId)
      .maybeSingle();

    if (propertyError || !property) {
      return json({ error: 'PROPERTY_NOT_FOUND', detail: propertyError?.message || 'Property not found' }, 404);
    }

    const { data: invitation, error: inviteError } = await admin.auth.admin.inviteUserByEmail(email, {
      data: {
        full_name: fullName,
        anaira_restaurant_id: restaurantId,
        anaira_role: role,
      },
    });

    if (inviteError) return json({ error: 'INVITE_FAILED', detail: inviteError.message }, 400);
    if (!invitation.user) return json({ error: 'AUTH_USER_NOT_CREATED' }, 500);

    const { error: profileError } = await admin.from('profiles').upsert({
      id: invitation.user.id,
      email,
      full_name: fullName,
      role,
      is_super_admin: false,
      status: 'active',
      restaurant_id: restaurantId,
      updated_at: new Date().toISOString(),
    }, { onConflict: 'id' });

    if (profileError) {
      return json({ error: 'PROFILE_CREATE_FAILED', detail: profileError.message, user_id: invitation.user.id }, 500);
    }

    return json({
      ok: true,
      user_id: invitation.user.id,
      email,
      role,
      restaurant_id: restaurantId,
      property_name: property.name,
      message: 'Invitation sent successfully',
    });
  } catch (error) {
    return json({ error: 'FUNCTION_ERROR', detail: error instanceof Error ? error.message : String(error) }, 500);
  }
});
