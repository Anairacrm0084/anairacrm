import { createClient } from "@supabase/supabase-js";

// Anaira production Supabase project. Environment variables can override this for staging/local deployments.
const url = process.env.NEXT_PUBLIC_SUPABASE_URL || "https://bhptqdoteucuymmdzsmg.supabase.co";
const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "sb_publishable_H5-rIfJOSp7kibp8oXsqow_-vDpdrRd";

export const supabase = createClient(url, key);
