-- Presence — RPC for nearby_presences.
-- Encapsulates the spatial query so the backend doesn't have to compose
-- PostGIS expressions through PostgREST. Stable so PostgREST treats it as
-- a read; SECURITY INVOKER (default) so it runs as the calling role —
-- callers must already be authorized at the API layer.
--
-- Excludes:
--   - the caller's own active presence
--   - mutually-blocked users (blocks table, either direction)
--   - inactive or expired rows
-- Caps at 50 rows ordered by distance, matching the iOS map's render budget.

create or replace function public.nearby_presences(
  p_lat       double precision,
  p_lng       double precision,
  p_radius_m  integer,
  p_caller    uuid
)
returns table (
  id          uuid,
  user_id     uuid,
  username    text,
  bio         text,
  lat         double precision,
  lng         double precision,
  venue_name  text,
  expires_at  timestamptz
)
language sql
stable
as $$
  select
    p.id,
    p.user_id,
    u.username,
    u.bio,
    st_y(p.location::geometry)::double precision as lat,
    st_x(p.location::geometry)::double precision as lng,
    p.venue_name,
    p.expires_at
  from public.presences p
  join public.users u on u.id = p.user_id
  where p.is_active = true
    and p.expires_at > now()
    and p.user_id <> p_caller
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = p_caller and b.blocked_id = p.user_id)
         or (b.blocker_id = p.user_id and b.blocked_id = p_caller)
    )
    and st_dwithin(
      p.location,
      st_makepoint(p_lng, p_lat)::geography,
      p_radius_m
    )
  order by p.location <-> st_makepoint(p_lng, p_lat)::geography
  limit 50;
$$;
