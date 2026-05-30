// Validated environment variables. Throws at module load time if anything is
// missing so misconfiguration fails loudly rather than silently at runtime.
//
// Public (NEXT_PUBLIC_) vars are safe to import in both server and client code.
// Server-only vars live in lib/env.server.ts guarded by "server-only".

function req(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`Missing required environment variable: ${name}`);
  return v;
}

export const SUPABASE_URL = req("NEXT_PUBLIC_SUPABASE_URL");
export const SUPABASE_ANON_KEY = req("NEXT_PUBLIC_SUPABASE_ANON_KEY");
