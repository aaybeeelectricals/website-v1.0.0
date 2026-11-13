// AAY BEE Supabase browser configuration.
// Publishable keys are intended for browser use. Never place a service_role/secret key here.
window.AAYBEE_SUPABASE_URL = "https://iwulgwiiofypdzcnxzgp.supabase.co";
window.AAYBEE_SUPABASE_PUBLISHABLE_KEY = "sb_publishable_iEK3XM2dzxBkn5vdp9z-8w_qrMKxCW2";
window.aaybeeSupabase = window.supabase.createClient(
  window.AAYBEE_SUPABASE_URL,
  window.AAYBEE_SUPABASE_PUBLISHABLE_KEY,
  { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } }
);
