import "server-only";
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import type { Database } from "@/lib/database.types";
import { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } from "@/lib/env.server";

// Service-role client. Bypasses RLS — only ever import this from server code
// (server actions, route handlers, scripts). Never expose to the browser.
export function createAdminClient() {
  return createSupabaseClient<Database>(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
}
