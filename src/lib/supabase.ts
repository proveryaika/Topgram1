import { createClient } from "@supabase/supabase-js";

// These are public client settings, not service-role credentials.
const url = (import.meta.env.VITE_SUPABASE_URL as string | undefined) || "https://wcaribszxpmiqwbzgtke.supabase.co";
const key = (import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined) || "sb_publishable_Huac5EmoI5XUzA-xi3Tw2A_TQpfBGXT";

export const isSupabaseConfigured = Boolean(url && key && !url.includes("YOUR_PROJECT"));
export const defaultSupabaseStorageKey = `sb-${new URL(url).hostname.split(".")[0]}-auth-token`;
const clients = new Map<string, ReturnType<typeof createClient>>();
const storedActiveKey = typeof localStorage !== "undefined" ? localStorage.getItem("topgram-active-auth-key") : null;

function clientFor(storageKey: string) {
  let client = clients.get(storageKey);
  if (!client && isSupabaseConfigured) {
    client = createClient(url, key, { auth: { storageKey, persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } });
    clients.set(storageKey, client);
  }
  return client ?? null;
}

export let supabase = clientFor(storedActiveKey || defaultSupabaseStorageKey);

export function getActiveSupabaseStorageKey() {
  return typeof localStorage !== "undefined"
    ? localStorage.getItem("topgram-active-auth-key") || defaultSupabaseStorageKey
    : defaultSupabaseStorageKey;
}

export function activateSupabaseAccount(storageKey: string) {
  const client = clientFor(storageKey);
  if (!client) return null;
  supabase = client;
  if (typeof localStorage !== "undefined") localStorage.setItem("topgram-active-auth-key", storageKey);
  return client;
}

export function createSupabaseAccount() {
  const storageKey = `topgram-auth-${crypto.randomUUID()}`;
  return activateSupabaseAccount(storageKey) ? storageKey : null;
}
