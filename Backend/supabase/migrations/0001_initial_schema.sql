-- Presence — initial schema.
-- Apply via the Supabase SQL editor or `supabase db push` after linking a project.
-- Mirrors the schema in CLAUDE.md § Database Schema.

create extension if not exists postgis;
create extension if not exists "uuid-ossp";

-- ─── Users ────────────────────────────────────────────────────────────────────

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  username text unique not null check (char_length(username) between 3 and 24),
  bio text check (bio is null or char_length(bio) <= 60),
  avatar_url text,
  created_at timestamptz not null default now()
);

-- ─── Presences (ephemeral) ────────────────────────────────────────────────────

create table if not exists public.presences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  location geography(point, 4326) not null,
  venue_name text,
  venue_type text check (venue_type in ('cafe','park','gym','library','bar','coworking','other')),
  started_at timestamptz not null default now(),
  expires_at timestamptz not null,
  is_active boolean not null default true,
  check (expires_at > started_at),
  check (expires_at <= started_at + interval '3 hours')
);

create index if not exists presences_location_idx on public.presences using gist(location);
create index if not exists presences_active_idx on public.presences(is_active, expires_at);

-- ─── Waves ────────────────────────────────────────────────────────────────────

create table if not exists public.waves (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.users(id) on delete cascade,
  receiver_id uuid not null references public.users(id) on delete cascade,
  icebreaker text not null check (char_length(icebreaker) between 20 and 200),
  status text not null default 'sent' check (status in ('sent','waved_back','expired','blocked')),
  sent_at timestamptz not null default now(),
  responded_at timestamptz,
  expires_at timestamptz not null,
  check (sender_id <> receiver_id)
);

create index if not exists waves_receiver_idx on public.waves(receiver_id, status);
create index if not exists waves_sender_idx on public.waves(sender_id, sent_at desc);

-- ─── Connections ──────────────────────────────────────────────────────────────

create table if not exists public.connections (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.users(id) on delete cascade,
  user_b uuid not null references public.users(id) on delete cascade,
  venue_name text,
  connected_at timestamptz not null default now(),
  check (user_a <> user_b)
);

create index if not exists connections_user_a_idx on public.connections(user_a, connected_at desc);
create index if not exists connections_user_b_idx on public.connections(user_b, connected_at desc);

-- ─── Blocks ───────────────────────────────────────────────────────────────────

create table if not exists public.blocks (
  blocker_id uuid not null references public.users(id) on delete cascade,
  blocked_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

-- ─── Venue Partners (B2B) ─────────────────────────────────────────────────────

create table if not exists public.venue_partners (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location geography(point, 4326),
  tier text not null default 'standard' check (tier in ('standard','hub','premium')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- ─── Auto-expire presences ────────────────────────────────────────────────────

create or replace function public.expire_presences() returns void as $$
  update public.presences
     set is_active = false
   where is_active = true and expires_at < now();
$$ language sql;

-- ─── Row-level security ───────────────────────────────────────────────────────
-- The backend uses the service-role key and bypasses RLS. Once Supabase Auth
-- is wired up (Sprint 1), enable RLS and write policies that let the
-- authenticated user read only their own waves / connections / blocks.

alter table public.users enable row level security;
alter table public.presences enable row level security;
alter table public.waves enable row level security;
alter table public.connections enable row level security;
alter table public.blocks enable row level security;

-- Placeholder policies that deny all anon access. Replace in Sprint 1.
create policy "deny_all_anon" on public.users        for all to anon using (false);
create policy "deny_all_anon" on public.presences    for all to anon using (false);
create policy "deny_all_anon" on public.waves        for all to anon using (false);
create policy "deny_all_anon" on public.connections  for all to anon using (false);
create policy "deny_all_anon" on public.blocks       for all to anon using (false);
