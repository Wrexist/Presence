# TASK.md — Current Work State
> Update this at the end of every session. Read at the start of every session.

---

## 🎯 CURRENT SPRINT: Sprint 0 — Foundation
**Goal:** Working skeleton: auth, map, presence toggle, Luma idle state  
**Sprint end:** 2 weeks from project start

---

## ✅ COMPLETED TASKS

### [TASK-001] Project Setup
- [x] **XcodeGen-driven project structure** mirroring Peptide-ai (`project.yml` is the source of truth, `.xcodeproj` is gitignored — fully Windows-friendly)
- [x] Repo restructured to `Presence/{App,DesignSystem,Features,Models,Services,Data,Resources}` + `Shared/`, `PresenceTests/`, `PresenceUITests/`, `Backend/`
- [x] iOS 26 deployment target, Swift 6.0 strict concurrency, all SPM deps declared (Lottie, RevenueCat, Supabase, SocketIO)
- [x] `Presence/App/PresenceApp.swift` — `@main` entry with environment wiring
- [x] `Presence/App/AppCoordinator.swift` — `@Observable` route state
- [x] `Presence/App/ServiceContainer.swift` — DI container scaffold (live/preview)
- [x] `Presence/Presence.entitlements` (push only — minimal)
- [x] `Presence/Resources/Assets.xcassets` (AppIcon stub + AccentColor = aurora blue)
- [x] `Info.plist` properties defined in `project.yml` (location + push usage strings)
- [x] `.swiftlint.yml`, `.gitignore`, `.env.example`
- [x] `.github/workflows/pr-checks.yml` — macOS CI: xcodegen → swiftlint → build → unit tests
- [x] `SETUP.md` — bootstrap guide including Windows-only workflow
- [x] `TESTFLIGHT_SETUP.md` — guide for activating signed deploys later
- [x] Supabase + RevenueCat *dashboards* still need to be created manually (browser tasks)

### [TASK-002] Design System — Liquid Glass Foundation (code-only portion)
- [x] GlassTokens enum complete (`Presence/DesignSystem/GlassTokens.swift`)
- [x] GlassCard component
- [x] GlassPillButton component
- [x] GlassIconButton component
- [x] GlassBottomSheet component
- [x] GlassChip component (bonus — needed for countdowns/status)
- [x] Fallback Material components for iOS < 26 (centralized in `glassSurface(in:thin:)`)
- [x] Preview all components in light + dark mode + Reduce Transparency
- [x] PresenceColors.swift — aurora palette + `Color(hex:)` + deterministic `dotColor(for:)`
- [x] Typography.swift — SF Pro Rounded scale

---

## 🔨 IN PROGRESS

### Operational chores (browser/dashboard work — not code)
- [ ] Create Supabase project — **walkthrough now in `docs/supabase-setup.md`**
- [ ] Run `Backend/supabase/migrations/0001_initial_schema.sql` in Supabase SQL editor
- [ ] Create RevenueCat account + iOS app, copy SDK key into `.env.development`
- [ ] Provision Railway project for backend — **decision + steps in `docs/backend-hosting.md`**
- [ ] Add `RAILWAY_TOKEN` repo secret + `BACKEND_URL` repo variable for `.github/workflows/backend-deploy.yml`
- [ ] Push branch and confirm `pr-checks.yml` goes green on macOS runner
- [ ] (Optional, later) Apple Developer Program enrollment for TestFlight

### [TASK-003] Auth Flow
- [x] Supabase phone auth integration — `AuthService` now backed by `supabase-swift`
- [x] OTP verification screen (glass design)
- [x] Username + bio setup screen
- [x] Luma onboarding animation trigger
- [x] Seven-step onboarding: Welcome → Phone → OTP → Username → Bio → Privacy → Ready
- [x] `GlassTextField` glass-styled input
- [x] `OnboardingCoordinator` with async auth calls + error surfacing
- [x] `AppCoordinator` boots via `AuthService.restoreSession()`, routes to onboarding on no session
- [x] Keychain-backed session storage (`SupabaseSessionStorage` + `KeychainStore`)

---

## 📋 BACKLOG (Ordered by Priority)

### Sprint 1 — Core Loop
- [ ] TASK-004: MapView with MapKit + Liquid Glass overlays (partial — real `Map{}` + annotations done; Liquid Glass on controls inherits from system)
- [x] TASK-005: LocationService (CoreLocation wrapper) — `Services/LocationService.swift`
- [x] TASK-005a: BackendClient (URLSession actor with retries + typed errors) — `Data/BackendClient.swift`
- [x] TASK-006: PresenceService (toggle on/off, 3h expiry) — `Services/PresenceService.swift`
- [x] TASK-007: Supabase PostGIS integration (store/query presences) — `Backend/src/routes/presence.ts` + `0002_nearby_presences_function.sql`
- [x] TASK-008: WebSocket service (real-time dot updates on map) — backend geohash rooms + JWT handshake auth (B5); iOS `SocketService` + `MapViewModel` merging REST hydrate with socket events (B6)
- [x] TASK-009: PresenceDotView (glowing marker on map)
- [x] TASK-010: "Go Present" button (main CTA, glass pill) — wired to `PresenceService.activate/deactivate` + 3h countdown chip
- [x] TASK-011: Luma component + idle animation — `LumaView` is now Lottie-first with pure-SwiftUI fallback (`LumaPureView`); designer assets land under `Presence/Resources/Luma/` per the README spec

### Sprint 2 — Wave System
- [x] TASK-012: Tap-a-dot → wave preview sheet — `WaveComposeView` (sender side), wired off `HomeView` dot annotations
- [x] TASK-013: Claude API icebreaker generation — backend route + iOS request flow (`/api/icebreaker` now JWT-authed)
- [x] TASK-014: WaveView — `WaveReceivedView` now driven by the live `Wave` model + `WavesViewModel`
- [x] TASK-015: Wave notification — backend push stub + iOS `NotificationService` + `AppDelegate` deep-link routing (real APNs send deferred to E6)
- [x] TASK-016: Wave response flow (accept/decline) — backend `POST /api/waves/:id/respond` with mutual detection + connection insert
- [x] TASK-017: 10-minute chat window — `ChatView` + `ChatViewModel` + `chat_rooms` / `chat_messages` migration; server enforces ends_at
- [x] TASK-018: Connection recording + Luma celebration — `CelebrationView` triggered globally on `wave_mutual`; milestone copy at 1/5/10/25

### Sprint 3 — Monetization & Polish
- [x] TASK-019: RevenueCat integration — `SubscriptionService` (D1)
- [x] TASK-020: Paywall screen (Presence+) — `Features/Paywall/PaywallView` (D2)
- [x] TASK-021: Free tier enforcement (3 presences/week) — server-side ISO-week count returns 402; client routes to paywall (D3)
- [x] TASK-022: Profile screen + connection history — `ProfileViewModel`, edit username/bio, weekly chip for free users, journey 7-day chart wired to `/api/users/me/journey` (D4)
- [x] TASK-023: Block/report flow — `/api/blocks` + `/api/reports` + `SafetySheet` reachable from compose / received / chat in ≤2 taps (D6)
- [x] TASK-024: Privacy screen + data export — `PrivacyView` with blocked-user list + JSON share-sheet export of `/api/users/me/export` (D5)
- [x] TASK-025: Settings screen — `SettingsView` with subscription status, sign-out + delete-account confirms (D5)
- [x] TASK-026: Luma full state machine — `LumaCoordinator` (D7) drives the ambient Luma corner on `HomeView`; explicit-state Lumas (onboarding, paywall, celebration, chat) stay inline

### Sprint 4 — Beta
- [ ] TASK-027: App Store Connect setup
- [ ] TASK-028: TestFlight distribution
- [x] TASK-029: Analytics (PostHog) — `AnalyticsService` actor with typed events; identify on `.main`, reset on `.onboarding`; events fire from onboarding/presence/wave/paywall surfaces (E2)
- [x] TASK-030: Crash reporting (Sentry) — iOS `CrashReportingService` (no screenshots/view-hierarchy/IP); Node `sentry.ts` with PII scrubbing + `/debug-sentry` (E3)
- [ ] TASK-031: ASO — screenshots, description, keywords
- [ ] TASK-032: Venue partner B2B backend

---

## 🐛 ACTIVE BUGS

*None yet*

---

## 🔖 SESSION NOTES

**Last session (2026-04-24, MapKit + LocationService):** Stacked on top of onboarding-flow. Real SwiftUI `Map{}` replaces the stylized canvas, and the first-tap location-permission flow is now wired end-to-end.

- `Services/LocationService.swift` — `@MainActor @Observable` NSObject wrapping `CLLocationManager`. `requestWhenInUseAuthorization()` is async (bridges the delegate callback via `CheckedContinuation`). `privacyReducedLocation()` jitters the coord by ~±50m with longitude scaled by `cos(lat)` so the radius stays roughly constant. Delegate uses `@preconcurrency` to keep Swift 6 strict concurrency happy. Rejects fixes with accuracy > 200m or staler than 15s.
- `Features/Map/HomeView.swift` — rewritten to use real `Map(position:)` with `Annotation` overlays for preview presence dots, floating Lumas (scattered on the map, per Design_2), and the user's own dot (only rendered when CoreLocation has a fix). `MapCompass` + `MapUserLocationButton` controls, POIs excluded, flat elevation. Camera defaults to a San-Francisco region; panning is free.
- `Features/Map/GoPresentView.swift` — first Go Present tap calls `services.location.requestWhenInUseAuthorization()`. Authorized: starts updates, flips to glowing state. Denied/restricted: surfaces an alert with an "Open Settings" deep link. Added a "Stop glowing" toggle on subsequent taps that calls `stopUpdating()`.
- `App/ServiceContainer.swift` — now holds `LocationService`. `.live()` and `.preview()` both instantiate a real service (permission prompts are inert in previews).

**Privacy model checkpoint:** the system `CLLocationManager` prompt fires ONLY on first Go Present tap, not during onboarding. Matches CLAUDE.md § Privacy Rules ("Location ONLY when Present") and the LEARNINGS note that explanation-before-ask yields ~40% better grant rates.

**Scope deferred for follow-up slices:**
- `PresenceService` that activates via the backend and schedules the 3h expiry (TODO marker already in `handleGoPresent`)
- `BackendClient` for HTTP calls
- `SocketService` + realtime dot updates
- Sprint 1 backend routes (`/api/presence`) which currently return 501

**Last session (2026-04-24, onboarding):** Built the full seven-step onboarding flow in pure SwiftUI. Windows-buildable, CI-verified on commit.

- New SwiftUI screens under `Features/Onboarding/`: `OnboardingView` (root with progress capsules), `OnboardingWelcomeView` (Luma hero + staggered text fade-in + "You're not alone in feeling alone."), `OnboardingPhoneView`, `OnboardingOTPView` (auto-submits on 6 digits, "Change number" link), `OnboardingUsernameView` (lowercase lock, 3–24 char regex validation), `OnboardingBioView` (live 0/3-word counter), `OnboardingPrivacyView` (three glass privacy rows + shielded Luma), `OnboardingReadyView` (celebrating Luma → hands off to map)
- `OnboardingCoordinator` — `@MainActor @Observable`, holds form state, dispatches to the stubbed `AuthService`, surfaces `isSubmitting` and `errorMessage` to views, advances `step: OnboardingStep`
- `Services/AuthService.swift` — actor stub with `sendOTP`, `verifyOTP`, `claimUsername`. Clear `TODO(sprint-1)` markers for Supabase Auth wiring. Validators (`isValidE164`, `isValidUsername`) exposed as statics for UI pre-checks
- `Models/User.swift` — plain Sendable/Codable value type mirroring the DB schema
- `DesignSystem/GlassTextField.swift` — new reusable glass-styled input with focus ring, optional prefix/icon, max-length enforcement
- `AppCoordinator` now starts in `.onboarding` on first launch, persists completion in UserDefaults (`presence.onboarding.complete.v1`), and stores `currentUser: User?`. `completeOnboarding(with:)` takes the User from `AuthService.claimUsername`. `resetToOnboarding()` clears everything (useful for dev reset / sign-out later)
- Deliberate design call: the onboarding flow does NOT request `CLLocationManager` permission. The privacy screen *explains* location, and the real permission prompt fires on first "Go Present" tap — matches the "location only when Present" privacy model (CLAUDE.md § Privacy Rules) and the ~40%-better-grant-rate pattern from LEARNINGS.md

- `src/index.ts` — Express + Socket.io entry, pino logging, graceful shutdown
- `src/config.ts` — Zod-validated env with `featureFlags` for Supabase / Anthropic
- `src/services/matchingService.ts` — Claude icebreaker generation via `@anthropic-ai/sdk`, using `claude-opus-4-7` with `thinking: disabled`, no sampling params (Opus 4.7 removed them), prompt-cache marker on the system prompt (no-op at current length, future-proofs), response validation (20–200 chars, AI-mention filter), and a hand-written fallback library keyed deterministically by venue name
- `src/services/supabase.ts` — server-side client factory using the service-role key
- `src/routes/{health,icebreaker,presence,waves}.ts` — icebreaker endpoint is live + rate-limited (1 req / 30s per sender); presence/waves stubs return 501 with a sprint pointer
- `src/websocket/index.ts` — socket.io scaffold, geohash rooms land in Sprint 1
- `supabase/migrations/0001_initial_schema.sql` — full PostGIS schema from CLAUDE.md (users, presences, waves, connections, blocks, venue_partners) with GIST index, 3h expiry check, RLS with placeholder deny-all-anon policies
- `README.md` — how to run, how to verify, env table, curl example

Also fixed doc debt: CLAUDE.md's Glass hierarchy used to list `.glassEffect(.thin)` — that's not a real iOS 26 API. Updated the hierarchy to show `.regular` + `.clear` only, added a warning note, and cross-linked a LEARNINGS.md entry explaining the CI error pattern.

**Next session start with:** with LocationService + real MapKit in, the next cohesive Sprint 1 slice is the backend wiring — a `BackendClient` (URLSession) + `PresenceService` that hits `/api/presence` for activate/nearby/deactivate. Then swap `HomeView`'s preview-dots array for a real query. That slice depends on (a) the Sprint 1 backend routes being implemented (currently 501) and ideally (b) a Supabase project existing so the backend can actually persist.

---

## 📊 METRICS TO TRACK (post-launch)
- DAU / MAU ratio (target: >40% — Duolingo benchmark)
- Presences per active user per week (target: 2+)
- Wave accept rate (target: >30%)
- Connection-to-friend rate (how many waves become real connections — survey)
- Week 1 retention (target: >50%)
- Week 4 retention (target: >25%)
- Free-to-paid conversion (target: >5%)
