// AAY BEE Supabase browser configuration. Publishable keys are safe for client use.
// Database access must still be protected by Supabase Row Level Security.
window.AAYBEE_SUPABASE_URL = "https://uubrgnpcmzopdhpqhrqf.supabase.co";
window.AAYBEE_SUPABASE_PUBLISHABLE_KEY = "sb_publishable_K--sq8XcASGp3k0DNeJubg_oXumA1Vo";
window.aaybeeSupabase = window.supabase.createClient(
  window.AAYBEE_SUPABASE_URL,
  window.AAYBEE_SUPABASE_PUBLISHABLE_KEY,
  { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } }
);
