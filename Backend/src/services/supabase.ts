//  Presence backend
//  supabase.ts
//  Server-side Supabase client. Uses the service-role key, which bypasses
//  Row-Level Security — this client MUST NEVER be exposed to the iOS app.
//  Returns null if Supabase is not configured so dev can run without it.

import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { config, featureFlags } from "../config.js";

let client: SupabaseClient | null = null;

export function getSupabase(): SupabaseClient | null {
  if (!featureFlags.supabaseEnabled) return null;
  if (!client) {
    client = createClient(config.SUPABASE_URL!, config.SUPABASE_SERVICE_ROLE_KEY!, {
      auth: { persistSession: false, autoRefreshToken: false }
    });
  }
  return client;
}
