# TopGram

TopGram — самостоятельный мессенджер с аккаунтами, личными и групповыми чатами, каналами и realtime-сообщениями. Это отдельный проект, не клиент и не копия серверной инфраструктуры Telegram.

## Stack
- React + TypeScript + Vite
- Supabase Auth, Postgres, Realtime
- Row Level Security policies

## Local development
1. Install Node.js 20+.
2. Run `npm install`.
3. Copy `.env.example` to `.env.local` and fill in your Supabase project URL and publishable key.
4. Run the SQL in `supabase/schema.sql` in the Supabase SQL Editor.
5. Run `npm run dev`.

Without Supabase environment variables, the app opens in a local demo mode. Never put a Supabase service-role or secret key in browser environment variables.

## Current foundation
- Responsive messenger interface
- Supabase email/password sign-in and registration
- Profiles, username search, conversation, membership and message schema
- Stars ledger, gift catalog and inventory, collectible usernames, audit-log foundation
- RLS-protected data and realtime message subscription

## Next milestones
- Group invitations, channel publishing and contact-request UI
- Message attachments, reactions, and media handling
- Stars, gifts and collectible usernames
- Server-side moderation and a protected admin console
