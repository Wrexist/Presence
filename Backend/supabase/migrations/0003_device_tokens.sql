-- Presence — device tokens for push notifications.
-- One row per (user, token). Tokens rotate when the user reinstalls or
-- toggles permission — we upsert by token so duplicates can't pile up.
-- The user_id index supports the fan-out query in waves push.

create table if not exists public.device_tokens (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.users(id) on delete cascade,
  token         text not null unique,
  platform      text not null check (platform in ('ios','android')),
  environment   text not null check (environment in ('production','sandbox')),
  last_seen_at  timestamptz not null default now(),
  created_at    timestamptz not null default now()
);

create index if not exists device_tokens_user_idx on public.device_tokens(user_id);

alter table public.device_tokens enable row level security;
create policy "deny_all_anon" on public.device_tokens for all to anon using (false);
