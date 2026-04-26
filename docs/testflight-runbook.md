# TestFlight + Beta Runbook — E6

> What to do, in order, when you decide it's time for the first signed
> build. This complements `TESTFLIGHT_SETUP.md` (which covers the
> one-time Apple Developer + cert setup). This file is the *operating*
> playbook: weekly cadence, monitoring rituals, kill-switch process.

## Pre-flight checklist (first signed build)

Before kicking off the workflow:

- [ ] Apple Developer Program enrollment is complete
- [ ] App Store Connect record created (bundle id `app.presence.ios`)
- [ ] `RAILWAY_TOKEN` repo secret + `BACKEND_URL` repo variable set
      (per `docs/backend-hosting.md`)
- [ ] All migrations applied to the production Supabase project (0001
      through 0006)
- [ ] RevenueCat dashboard products live: `presence_plus_monthly` /
      `presence_plus_annual` + entitlement `presence_plus`
- [ ] PostHog project created, API key in build env
- [ ] Sentry projects created (one for iOS, one for Node), DSNs in env
- [ ] Privacy Policy URL live (deploy `legal/privacy.md`)
- [ ] Terms of Service URL live (deploy `legal/terms.md`)
- [ ] Twilio Messaging Service has at least one number attached and is
      reachable from your test phone
- [ ] In Settings → Schemes → Edit Scheme → Run, confirm the env vars
      `SUPABASE_URL` / `SUPABASE_ANON_KEY` / `BACKEND_URL` /
      `REVENUECAT_API_KEY` / `POSTHOG_API_KEY` / `SENTRY_DSN` are
      populated for the Release configuration too (otherwise the
      TestFlight build crashes on `Config` access)

## Running the first build

The signed-build workflow is `.github/workflows/ios-testflight.yml`
(already present in the repo). It runs `xcodegen generate`, archives
with the release scheme, and uploads via `fastlane pilot upload`.

1. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in
   `project.yml` if needed (semantic versioning; build number must
   strictly increase).
2. Open a PR with the bump.
3. Wait for `pr-checks.yml` to go green on macOS.
4. Merge to `main`.
5. Manually trigger `ios-testflight.yml` from the Actions tab —
   keeps you in control of when builds ship even though main has new
   commits.
6. ~25 minutes later, the build appears in App Store Connect →
   TestFlight. Apple's automated review of TestFlight builds typically
   resolves in under an hour for non-substantial changes.

## Inviting internal testers

Goal: 15 trusted people in the launch city before the public beta.

1. App Store Connect → Users and Access → invite each tester (they
   need an Apple ID; that's it).
2. App Store Connect → TestFlight → Internal Testing → add tester to
   the "Internal Beta" group.
3. Send a one-line invite via DM (don't email — most go to spam):
   > "Trying a thing — small social app for finding people who are
   > also at coffee shops. Want to test? Will text the link."
4. Once they accept, give them the elevator pitch (under 30 seconds,
   no demo) and let them poke around.

## Distributing QR codes to seed venues

Coffee shops in the launch city are the primary acquisition channel
for the first 1000 users. They need to see at least 3 dots on the map
when they open the app or they bounce.

1. Pick 5 venues with reliable Tuesday–Saturday morning traffic.
2. Print a 4×6 card per venue with:
   - Headline: "See who's here, right now."
   - QR code linking to the App Store listing
   - Footer: "@app.presence.ios"
3. Walk in, ask for the manager, give them 10 cards. Don't ask
   permission to put them out — ask if they'd like to put them out.
4. Track redemptions via the `?utm_source=qr-{venue}` UTM in the App
   Store URL (PostHog reads UTM on first launch).

## Daily monitoring (first 72 hours after each release)

| Time | Action | Tool |
|---|---|---|
| Morning | Sentry: any iOS crashes overnight? | Sentry inbox |
| Morning | Sentry: any backend 5xx events? | Sentry inbox |
| Morning | Crash-free rate ≥ 99.5%? | Sentry releases |
| Morning | Wave-accept rate this week? | PostHog dashboard |
| Anytime | Manually generate a test wave + chat as your alt account | Real device |
| Evening | Sample 10 random icebreakers from logs — any AI weirdness? | Anthropic console + Supabase Studio |
| Evening | Reports queue: any unresolved? | Supabase Studio → reports table |

Set up a single Slack channel `#presence-ops` with two webhooks:
- Sentry: any new issue at level error+
- PostHog: weekly summary

## Beta-feedback loop (weeks 13–14)

At 100 testers, run a structured retro:

1. **Quantitative** (PostHog):
   - Activation: % of testers who completed at least one Presence
   - Engagement: presences per active tester per week (target ≥ 2)
   - Retention: D7 / D30 by cohort
   - Wave-accept rate (target ≥ 30%)
   - Connection-to-friend rate via in-app survey at 7 days post-connection
2. **Qualitative**: short text interview with 10 testers via DM:
   - What made you open the app the second time?
   - What part of the flow was confusing?
   - What did Luma feel like?
3. Triage P0/P1 bugs from beta into a list. P0 = unsafe content +
   crashes; P1 = anything that breaks the core wave loop.

## Kill-switch process (P0 surfaces)

If a P0 lands (active harassment, exploited safety hole, exposed
PII), in this order:

1. **Open Sentry** — confirm scope (one user, many users, all users).
2. **Throttle the affected route** — Railway → Settings →
   Variables → set `RATE_LIMIT_MS` to a high number for the affected
   path. Redeploy. (~2 min.)
3. **If user-data exposure**: rotate `SUPABASE_SERVICE_ROLE_KEY` in
   Supabase dashboard → Project Settings → API → Reset. Redeploy.
   This invalidates every server-side cache.
4. **Communicate** — post in `#presence-ops` and email the affected
   testers within 4 hours with what happened, what we did, what they
   should do.
5. **Post-mortem within 48 hours** — short doc in `docs/postmortems/`
   describing the timeline, the root cause, and what blocks it from
   recurring.

## Final sub-checklist for "ready for public beta"

- [ ] Crash-free rate ≥ 99.5% over the last 7 days
- [ ] Wave-accept rate ≥ 30% over the last 7 days
- [ ] At least 5 real connections (per the in-app survey)
- [ ] Reports queue empty or all triaged
- [ ] Privacy + Terms URLs live and reviewed by counsel
- [ ] Real APNs send working (not the stub from C3) — this is the
      moment to revisit `Backend/src/services/pushService.ts` and
      remove the TODO with a real implementation
- [ ] Open the App Store Connect submission per `docs/app-store.md`
