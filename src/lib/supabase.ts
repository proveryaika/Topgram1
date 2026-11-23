import { createClient } from "@supabase/supabase-js";

// These are public client settings, not service-role credentials.
// Environment variables may override them in CI; the public defaults keep
// the static GitHub Pages build connected without manually adding Actions secrets.
const url = (import.meta.env.VITE_SUPABASE_URL as string | undefined) || "https://wcaribszxpmiqwbzgtke.supabase.co";
const key = (import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined) || "sb_publishable_Huac5EmoI5XUzA-xi3Tw2A_TQpfBGXT";

export const isSupabaseConfigured = Boolean(url && key && !url.includes("YOUR_PROJECT"));
export const supabase = isSupabaseConfigured ? createClient(url, key) : null;
