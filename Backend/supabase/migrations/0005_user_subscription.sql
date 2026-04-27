-- Presence — user subscription state.
-- `is_plus` is the server-side mirror of RevenueCat's presence_plus
-- entitlement. The iOS client posts the latest entitlement state via
-- POST /api/users/me/subscription on purchase / restore / launch.
-- A future webhook from RevenueCat will be the authoritative writer (E6);
-- until then we trust the client (acceptable for MVP — worst case is a
-- user spoofing themselves into Plus, which only affects their own usage
-- limits, not other users' data).

alter table public.users
  add column if not exists is_plus boolean not null default false,
  add column if not exists plus_expires_at timestamptz;

-- Helpful index for the (rare) "all current Plus users" query.
create index if not exists users_is_plus_idx on public.users(is_plus) where is_plus;
