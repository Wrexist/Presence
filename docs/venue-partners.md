# Venue Partner Tier — Design Spec (F.3)

> The B2B side of `CLAUDE.md` § Monetization. Spec only — implementation
> is post-launch (Month 2+) once consumer-side metrics support a sales
> conversation.

---

## The product

Local venues (cafés, gyms, libraries, coworking) pay $49–199/month to
appear as **Presence Hubs** on the map and to receive anonymized
analytics about real connections happening at their location.

Three pricing tiers (mirrors the brief):

| Tier | Monthly | What they get |
|---|---|---|
| **Standard** | $49 | Highlighted ring on the map dot pile in their footprint, custom Luma color for their dot |
| **Hub** | $99 | Standard + weekly "people glowed here" email digest + connection heatmap |
| **Premium** | $199 | Hub + curated event placement ("Open to meet, today 4–7pm") + co-marketing toolkit |

This is intentionally cheap relative to the value. A $99 cafe-of-the-
month subscription that brings even one new regular pays for itself.

## What we already have

The data model from migration `0001` already includes:

```sql
create table public.venue_partners (
  id          uuid primary key,
  name        text not null,
  location    geography(point, 4326),
  tier        text default 'standard'
              check (tier in ('standard','hub','premium')),
  active      boolean default true,
  ...
);
```

The schema is the foundation. What's missing: writes (admin tooling),
reads (the map highlight + analytics queries), and billing (Stripe).

## What's missing

### 1. Admin write path

For MVP we don't need a partner-facing dashboard. Supabase Studio +
SQL is enough to insert a venue. A thin admin endpoint protected by an
admin-only header:

```
POST /api/admin/venues
Header: X-Admin-Token: <env var>
Body:  { name, lat, lng, tier }
```

That's the entire admin surface for the first 50 partners.

### 2. Map highlight on iOS

`HomeView` extends to render a partner ring. Backend adds a
`/api/presence/nearby/venues` endpoint returning active venue partners
within the same radius the dots use. The iOS map renders:

```swift
ForEach(viewModel.partnerVenues) { venue in
    Annotation("", coordinate: venue.coord) {
        Circle()
            .strokeBorder(venue.tierColor, lineWidth: 2.5)
            .frame(width: 56, height: 56)
            .shadow(color: venue.tierColor.opacity(0.5), radius: 12)
    }
    .annotationTitles(.hidden)
}
```

Plus a small overlay label at the bottom of the ring with the venue
name on tap.

### 3. Analytics endpoint

The metric partners actually want is **connections that happened at my
venue**, anonymized.

```
GET /api/venues/:id/analytics
Header: X-Venue-Token: <per-venue token>

→ {
  weekly: [
    { weekStart: "...", connectionCount: 12, presenceCount: 47 },
    ...
  ],
  heatmap: [
    { hourOfWeek: 36, connectionCount: 3 },  // Wed 12:00 = hour 36
    ...
  ]
}
```

Implementation: a SQL view `venue_weekly_stats` that joins
`connections.venue_name = venue_partners.name`. The current
connections row carries `venue_name` already (added in `0001`).

The per-venue token is rotated quarterly. Generated via a small admin
script + delivered manually for the first cohort.

### 4. Billing

Don't roll our own. Use **Stripe** for the partner side specifically
(RevenueCat is the wrong tool — that's for consumer subscriptions on
Apple's APIs).

```
POST /api/admin/venues/:id/checkout
→ Stripe Checkout session URL
```

Send the URL to the venue contact via email. Stripe webhook flips
`venue_partners.active` based on subscription state.

A minimal Stripe wiring:
- `STRIPE_SECRET_KEY` env var
- One product per tier in Stripe dashboard
- One webhook endpoint at `/api/webhooks/stripe`
- Webhook verifies signature, updates `active` and `tier`

## Sales motion

For the first 50 partners, this is door-to-door:

1. Pick 10 venues per neighborhood that already have Presence dot
   activity ≥ 5 weekly. Cross-reference with PostHog `dot_tapped`
   counts grouped by venue name.
2. Walk in with a one-page proposal: "5 connections happened here
   last week, here's what you'd see on a Hub plan." Charge nothing
   for the first month — let them feel it.
3. After month 1, the Stripe Checkout URL in their email.

## Privacy boundaries

The thing partners cannot see:
- Individual user identities
- Specific exact times (only weekly + day-of-week buckets)
- Any chat content, ever
- Bios

The only personal data that touches the partner side is the venue
name itself, which is non-personal.

## Sequencing

Realistic post-launch path:

1. (Month 2) Admin endpoint + manual venue inserts. (1 day)
2. (Month 2) Map highlight rendering. (2 days)
3. (Month 2) Stripe wiring + tier-flag webhook. (2 days)
4. (Month 2-3) Analytics endpoint + SQL view. (1 day)
5. (Month 3) Door-to-door pilot with 10 venues. (real time = 2 weeks)
6. (Month 4) Email digest cron (weekly summaries to venue contacts). (1 day)

## Defer past v1

- Self-serve partner sign-up
- Partner-facing web dashboard
- Custom Luma skin per venue
- Cross-venue leaderboards (privacy risk)
- API for venue partners to read realtime foot traffic (huge privacy
  rethink before this exists)
