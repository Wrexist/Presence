-- Presence — chat rooms + chat messages.
-- A chat room is created the moment a wave becomes mutual (status = waved_back).
-- Each room has a hard 10-minute window — the product's core forcing function
-- per CLAUDE.md § Known Pitfalls. Server-side enforcement of ends_at is the
-- source of truth; the iOS countdown is just UI.

create table if not exists public.chat_rooms (
  id          uuid primary key default gen_random_uuid(),
  wave_id     uuid not null unique references public.waves(id) on delete cascade,
  user_a      uuid not null references public.users(id) on delete cascade,
  user_b      uuid not null references public.users(id) on delete cascade,
  started_at  timestamptz not null default now(),
  ends_at     timestamptz not null,
  check (user_a <> user_b),
  check (ends_at > started_at),
  check (ends_at <= started_at + interval '10 minutes')
);

create index if not exists chat_rooms_user_a_idx on public.chat_rooms(user_a);
create index if not exists chat_rooms_user_b_idx on public.chat_rooms(user_b);

create table if not exists public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  room_id     uuid not null references public.chat_rooms(id) on delete cascade,
  sender_id   uuid not null references public.users(id) on delete cascade,
  body        text not null check (char_length(body) between 1 and 500),
  created_at  timestamptz not null default now()
);

create index if not exists chat_messages_room_idx on public.chat_messages(room_id, created_at);

alter table public.chat_rooms enable row level security;
alter table public.chat_messages enable row level security;
create policy "deny_all_anon" on public.chat_rooms     for all to anon using (false);
create policy "deny_all_anon" on public.chat_messages  for all to anon using (false);
