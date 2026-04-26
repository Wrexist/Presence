# Group Presence — Design Spec (F.1)

> Lets up to 4 friends form a group at one venue, share a single dot on
> the map, and receive a single icebreaker addressed to the whole table.
> Targets Month 3-4 from `ROADMAP.md`. **This is a design doc, not an
> implementation.** Implementation is gated on solo Presence shipping
> cleanly to public beta and on the open-design-questions below being
> resolved with user research.

---

## Why

Groups are how most public space is occupied. A solo dot on the map at a
crowded coffee shop misrepresents reality (there are 4 of you, but only
1 dot), and it strips the affordance that the most common open-to-meet
moment is *"we have an extra chair, come join."*

Solo Presence remains the canonical loop. Group Presence is additive —
never a replacement.

## Non-goals

- Public groups with persistent membership (not a Discord)
- Group chat outside the 10-minute mutual-wave window (still the same
  forcing function)
- Groups larger than 4 (a chair-count cap; bigger groups are events)
- Inviting strangers into a group (groups are formed by people who are
  already together)

## User flow

```
1. User A taps Go Present and starts glowing solo.
2. User A taps "Make this a group" on the post-activate sheet.
   → A 6-character invite code appears (e.g. "L7-9PQ").
3. User A reads the code aloud / shows it to friend B.
4. B taps Go Present → "Join a group" → enters L7-9PQ.
5. B's solo glow snaps to A's location and the dots merge into one.
6. Repeat up to 4 members.
7. Map shows ONE group dot. Tapping the dot:
   - Renders the group composite ("Maya, Theo, Jin, +1")
   - Generates ONE icebreaker addressed to the table
   - Sends ONE wave that lands in ALL members' inboxes
8. ANY member can wave back to lock in the mutual.
9. Mutual creates ONE chat room. All four members can post.
10. Group dissolves when:
    - Any member taps "Leave group" (others stay grouped)
    - The host's Presence expires (3h)
    - Last member leaves
```

## Data model

### `presence_groups` (new)
```sql
create table public.presence_groups (
  id          uuid primary key default gen_random_uuid(),
  host_id     uuid not null references public.users(id) on delete cascade,
  invite_code text not null unique,                       -- "L7-9PQ"
  venue_name  text,
  venue_type  text,
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null,                       -- inherits host's
  is_active   boolean not null default true,
  check (expires_at <= created_at + interval '3 hours')
);

create index presence_groups_invite_idx on public.presence_groups(invite_code) where is_active;
```

### `presence_group_members` (new)
```sql
create table public.presence_group_members (
  group_id   uuid not null references public.presence_groups(id) on delete cascade,
  user_id    uuid not null references public.users(id) on delete cascade,
  joined_at  timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- Server-enforced cap: max 4 members per group.
create or replace function public.enforce_group_cap()
returns trigger language plpgsql as $$
begin
  if (select count(*) from public.presence_group_members where group_id = new.group_id) >= 4 then
    raise exception 'group_full';
  end if;
  return new;
end;
$$;
create trigger presence_group_cap
  before insert on public.presence_group_members
  for each row execute function public.enforce_group_cap();
```

### Existing `presences` table change
- Add `group_id uuid references presence_groups(id)`. When a presence
  joins a group, its row's `group_id` is set.
- The `nearby_presences` RPC collapses by `group_id` — for any presence
  with a non-null group, only emit the group's host row, but include a
  member-count column.

## API surface

| Method | Path | Behavior |
|---|---|---|
| `POST` | `/api/presence/groups` | host creates group; body: `{ venueName?, venueType? }`. Returns `{ id, inviteCode }`. |
| `POST` | `/api/presence/groups/:id/join` | body: `{ inviteCode }`. 403 on wrong code, 409 on full. |
| `DELETE` | `/api/presence/groups/:id/members/me` | leave group. |
| `GET` | `/api/presence/groups/:id` | fetch members + venue + expiry. |

The wave + chat routes don't change shape — they just need to recognize
`receiverId` referring to a group host and broadcast to all members.

## Wave + chat semantics

- Sending a wave to a grouped dot → wave row's `receiver_id` is the
  group's HOST. Broadcast `wave_received` to every member's inbox room.
  Push-notify all members.
- Any member responds → flips wave to `waved_back`, creates connection
  pairs sender↔each member, opens ONE chat room with all members in it.
- Chat room schema gains `participants uuid[]` (or a join table) — the
  current `(user_a, user_b)` shape needs to become n-ary.

## iOS UX

### Map
- A group dot looks like the solo dot but with a 2px aurora ring + a
  small badge "+3" at the top-right.
- Tapping a group dot opens a `WaveComposeView` variant that lists the
  members ("Maya, Theo, Jin, +1") and shows a single icebreaker.
- The user's own group dot pulses subtly so they know they're glowing
  as a group, not solo.

### Compose for the host
- After Go Present succeeds, the post-activate sheet adds a "Make this
  a group" tile (Plus only? See open question).
- The invite code appears on a 60pt glass chip, copyable + shareable.
- Member count chip appears below as friends join.

## Privacy

The privacy non-negotiables don't change:
- Each member's location is still ~50m-jittered before storage. The
  group dot's coordinate is the host's jittered coord.
- Any member can leave at any time; their row reverts to solo or stops.
- Bios shared with the icebreaker engine are anonymized as before; we
  send up to 4 "userN" entries instead of 2.

## Edge cases

| Case | Resolution |
|---|---|
| Host's Presence expires while members are still there | Auto-promote oldest joined member to host. Emit `group_host_changed`. |
| Member leaves mid-wave | Wave still sees the remaining members; mutual still works. |
| Two members try to wave back nearly simultaneously | First write wins (unique pair index); second member sees mutual already active. |
| Member is blocked by the wave sender | Member is silently filtered from the recipient list — wave still goes to others. |
| Member of group A tries to also be in group B | Refuse — one active group per user. |
| Group host is reported by a wave recipient | Auto-block applies between reporter and host only. Other members unaffected. |

## Icebreaker prompt (group variant)

The system prompt grows one line:

> "If the user provides multiple Person B entries, address the
> icebreaker to the group as a whole, not a specific member. Use 'you
> all' or 'this group' rather than singling someone out."

`buildUserPrompt` becomes variadic:

```
Person A: "loves coffee mornings" (3 prior connections)
Group of 3:
  - "runs at golden hour"
  - "asks the best questions"
  - "knows every cafe in town"
```

Output remains 1-2 sentences max.

## Pricing

The original brief (`CLAUDE.md` § Monetization) lists Group Presence as
a Plus feature in spirit but not explicitly. Recommendation:

- **Free**: can JOIN any group via invite code (zero friction for the
  invited friend).
- **Plus only**: can CREATE a group.

This matches "Plus subscribers throw the party; everyone can come."

## Open questions

1. **Discoverability**: do we show group dots differently (the +3 badge)
   to the wave-sender, or hide membership until tap? Lean: hide.
2. **Splitting**: if 2 of 4 leave the table, do they auto-fork into a
   new pair-group? Lean: no, they each go solo.
3. **Plus gate strength**: A/B test free-creates-up-to-2 vs. Plus-only.
4. **Chat moderation**: with up to 4 in chat, the 10-minute window may
   feel tight for genuine handoff. Test extending to 15m for groups.

## Sequencing

A reasonable implementation cut after solo is healthy:

1. Backend: migrations + group routes + RPC update (~2 days)
2. Wave + chat routes: n-ary refactor (~2 days; this is the gnarly part)
3. iOS: group dot + invite-code UX (~2 days)
4. iOS: compose / wave / chat n-ary surfaces (~3 days)
5. Internal beta with 3 friend groups (~1 week)
6. Public ship behind a feature flag (~1 day)

Total: ~2 weeks of focused work. Realistic to land in Month 3.
