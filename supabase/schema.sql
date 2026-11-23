-- TopGram initial schema. Run in Supabase SQL Editor on a clean project.
create extension if not exists pgcrypto;

create table if not exists public.tg_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text not null default 'TopGram user',
  bio text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tg_username_format check (username is null or username ~ '^[a-zA-Z0-9_]{4,32}$')
);

create table if not exists public.tg_conversations (
  id uuid primary key default gen_random_uuid(),
  kind text not null default 'direct' check (kind in ('direct','group','channel')),
  title text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.tg_conversation_members (
  conversation_id uuid not null references public.tg_conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','member')),
  joined_at timestamptz not null default now(),
  primary key (conversation_id,user_id)
);

create table if not exists public.tg_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.tg_conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 10000),
  created_at timestamptz not null default now(),
  edited_at timestamptz
);

create index if not exists tg_messages_conversation_created_idx on public.tg_messages(conversation_id,created_at desc);
create index if not exists tg_members_user_idx on public.tg_conversation_members(user_id);

alter table public.tg_profiles enable row level security;
alter table public.tg_conversations enable row level security;
alter table public.tg_conversation_members enable row level security;
alter table public.tg_messages enable row level security;

create policy "Profiles visible to authenticated users" on public.tg_profiles for select to authenticated using (true);
create policy "Users create own profile" on public.tg_profiles for insert to authenticated with check (id = (select auth.uid()));
create policy "Users update own profile" on public.tg_profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy "Members can view conversations" on public.tg_conversations for select to authenticated
using (exists (select 1 from public.tg_conversation_members m where m.conversation_id=id and m.user_id=(select auth.uid())));
create policy "Authenticated users create conversations" on public.tg_conversations for insert to authenticated with check (created_by=(select auth.uid()));

create policy "Members can view membership" on public.tg_conversation_members for select to authenticated
using (exists (select 1 from public.tg_conversation_members m where m.conversation_id=conversation_id and m.user_id=(select auth.uid())));
create policy "Conversation creator adds first members" on public.tg_conversation_members for insert to authenticated
with check (user_id=(select auth.uid()) or exists (select 1 from public.tg_conversations c where c.id=conversation_id and c.created_by=(select auth.uid())));

create policy "Members can read messages" on public.tg_messages for select to authenticated
using (exists (select 1 from public.tg_conversation_members m where m.conversation_id=tg_messages.conversation_id and m.user_id=(select auth.uid())));
create policy "Members can send messages as themselves" on public.tg_messages for insert to authenticated
with check (sender_id=(select auth.uid()) and exists (select 1 from public.tg_conversation_members m where m.conversation_id=tg_messages.conversation_id and m.user_id=(select auth.uid())));

-- Create a profile automatically when a new Auth user registers.
create or replace function public.tg_handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.tg_profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function public.tg_handle_new_user() from public;
drop trigger if exists tg_on_auth_user_created on auth.users;
create trigger tg_on_auth_user_created after insert on auth.users
for each row execute procedure public.tg_handle_new_user();

-- Realtime publication for messages (safe if already present).
do $$
begin
  alter publication supabase_realtime add table public.tg_messages;
exception when duplicate_object then null;
end $$;

grant select, insert, update on public.tg_profiles to authenticated;
grant select, insert on public.tg_conversations to authenticated;
grant select, insert on public.tg_conversation_members to authenticated;
grant select, insert on public.tg_messages to authenticated;
