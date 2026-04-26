-- Presence — user reports.
-- Reports are written client-side from any user-to-user surface (wave
-- compose, wave received, chat). Each report auto-blocks the reported
-- user (handled in the route) so the reporter doesn't have to take a
-- second action. Moderation triage happens via Supabase Studio in MVP;
-- a real admin queue lands post-launch.

create table if not exists public.reports (
  id              uuid primary key default gen_random_uuid(),
  reporter_id     uuid not null references public.users(id) on delete cascade,
  reported_id     uuid not null references public.users(id) on delete cascade,
  category        text not null check (category in (
    'harassment',
    'spam',
    'inappropriate',
    'unwanted_advances',
    'underage',
    'other'
  )),
  context         text not null check (context in ('wave','chat','presence','other')),
  reference_id   uuid,                              -- wave_id / chat_room_id / presence_id
  detail          text check (detail is null or char_length(detail) <= 1000),
  resolved_at     timestamptz,
  created_at      timestamptz not null default now(),
  check (reporter_id <> reported_id)
);

create index if not exists reports_reported_idx on public.reports(reported_id, created_at desc);
create index if not exists reports_unresolved_idx on public.reports(created_at desc) where resolved_at is null;

alter table public.reports enable row level security;
create policy "deny_all_anon" on public.reports for all to anon using (false);
