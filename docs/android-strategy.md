# Android Strategy — Tradeoff Doc (F.4)

> One-page comparison for picking the path to Android. Targets Month
> 6+. **Spec only.**
>
> The premise: iOS-only is leaving ~70% of US smartphones on the table.
> But the team is small (2 people, both Swift-native), and the iOS
> product depends on Liquid Glass — an Android-equivalent doesn't
> exist. The risk of porting badly is bigger than the risk of porting
> late.

## Recommendation

**Native Kotlin, after iOS hits 50k MAU.** Reasoning at the bottom.

## Options

### Option A — React Native port

| | |
|---|---|
| Effort to feature parity | ~12 weeks |
| Reuses backend? | Yes (the Node + Supabase backend is fully agnostic) |
| Reuses UI code? | None — no React Native code today |
| Reuses business logic? | Some — viewmodels would need to be ported to TS, but the shapes align |
| Design-system parity | Bad — Liquid Glass has no Android equivalent. Material You is the closest, but the metaphor is fundamentally different (tonal surfaces vs. translucent depth) |
| Team skill match | Low — neither founder is a JS native; we'd be hiring or learning |
| Time-to-parity | 12-14 weeks |
| Long-term cost | Medium-high — RN boundaries cause real bugs, and every iOS feature (Live Activities, App Intents, etc.) needs a wrapper |
| Best when | A team is JS-native and wants one codebase |

### Option B — Compose Multiplatform (KMP + Compose)

| | |
|---|---|
| Effort to feature parity | ~14 weeks |
| Reuses backend? | Yes |
| Reuses UI code? | None today |
| Reuses business logic? | Yes — KMP shared business logic in Kotlin |
| Design-system parity | Bad — same as RN, plus Compose's own iOS rendering on iOS isn't quite native |
| Team skill match | Low — same hiring story as RN |
| Time-to-parity | 14-16 weeks |
| Long-term cost | Medium — KMP is genuinely getting better, but iOS-first products still feel "ported" |
| Best when | A team has Kotlin chops AND a stable Compose iOS story |

### Option C — Native Kotlin + Material You

| | |
|---|---|
| Effort to feature parity | ~10 weeks |
| Reuses backend? | Yes |
| Reuses UI code? | None |
| Reuses business logic? | None directly — but the architectural shapes (MVVM, actor-flavored services) translate to Kotlin coroutines + flows almost 1:1 |
| Design-system parity | The right answer is *not* parity — re-imagine the Presence aesthetic in Material You. Aurora colors translate. Luma stays Lottie. Glass becomes Material 3 surface tonal elevation |
| Team skill match | Low initially — but Kotlin Compose is the closest mental model to SwiftUI on the market, and the iOS founder will pick it up faster than learning RN |
| Time-to-parity | 10-12 weeks |
| Long-term cost | Lowest — every Android feature is a first-class API call, no bridges |
| Best when | iOS is the lead platform AND the team values design fidelity over codebase consolidation |

### Option D — Web-first PWA (defer Android entirely)

| | |
|---|---|
| Effort to feature parity | ~6 weeks for a stripped subset |
| Reuses backend? | Yes |
| Design-system parity | Glass via CSS `backdrop-filter`; reasonable in modern Chrome/Safari |
| Time-to-parity | 6 weeks for ~70% of features |
| Cost | Lowest |
| Why it might still be wrong | Push notifications on Android Chrome are second-class, Mobile Safari offers no PWA-quality push at all. Presence's wave loop is push-driven — if push is bad, the loop is bad. |
| Best when | The product can degrade gracefully to no-push (Presence cannot) |

## Why native Kotlin wins for Presence

Three reasons in priority order:

1. **The product's emotional surface is the design**. Luma + Liquid
   Glass are most of why early users stick. A Material You re-imagining
   that *belongs* on Android beats a Glass simulacrum that feels
   off-platform on every screen. Compose Multiplatform and React
   Native both push toward "looks similar everywhere," which is the
   wrong goal.
2. **The backend doesn't care.** It's already platform-agnostic. We
   don't gain anything from JS or KMP on the data side — they save
   time only on the UI/state layer, and that's the layer we want to
   *not* compromise on.
3. **Kotlin Compose is the closest mental model to SwiftUI we'll find
   anywhere**. State machines are state machines. The 8 sessions of
   iOS engineering documented in this repo translate to Kotlin in a
   way they don't to React Native.

## When to start

Not until iOS hits **50k MAU** (per the post-launch metrics in
`ROADMAP.md`). Reasons:

- Below 50k, every engineering hour is better spent on the consumer
  side of iOS (group presence, widgets, retention).
- Above 50k, the venue-partner pipeline (F.3) generates revenue we
  can hire against. Hire one Android engineer and run two-platform
  feature work in parallel.
- The Anthropic icebreaker logic, presence routes, wave routes, and
  privacy guarantees are all stable by then — Android implements
  against a frozen contract, not a moving one.

## Migration risks

- **iOS-first features stranded on iOS**: Live Activities, App Intents,
  StandBy. Mitigation: every backend route stays platform-agnostic, so
  Android can ignore those without missing the core loop.
- **Two design systems forever**: We commit to "the same product,
  expressed natively on each platform." A CTA button on iOS is glass;
  on Android it's tonal elevation. That's a feature, not a bug.
- **Two backend deploys per release**: The deploy workflow stays
  shared (Backend/** unchanged), so this is mostly a coordination cost
  for App Store + Play Store submission timing.

## What we should NOT do

- Don't start a "thin Android" port that does 50% of the iOS feature
  set. Group Presence is binary — either both platforms have it or
  neither.
- Don't promise iOS↔Android cross-talk for v1 (mutual waves between
  iPhone + Android). It works automatically on the backend, but the
  push-notification UX between the two is a quality minefield.
- Don't ship an Android app without the same privacy non-negotiables
  in the product. Location-only-when-Present, ~50m jitter, and 3h
  expiry are universal contracts, not iOS implementation details.

## Decision

Revisit at 50k MAU. Hire one Android engineer. Native Kotlin +
Material You + Compose. ~10 weeks to v1 parity. Skip
PWA/RN/Compose-Multiplatform.
