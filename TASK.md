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
- [ ] Create Supabase project, copy URL + anon key into local `.env.development`
- [ ] Run the SQL migrations from `CLAUDE.md` § "Database Schema" in Supabase SQL editor
- [ ] Create RevenueCat account + iOS app, copy SDK key into `.env.development`
- [ ] Push branch and confirm `pr-checks.yml` goes green on macOS runner
- [ ] (Optional, later) Apple Developer Program enrollment for TestFlight

### [TASK-003] Auth Flow
- [ ] Supabase phone auth integration
- [ ] OTP verification screen (glass design)
- [ ] Username + bio setup screen
- [ ] Luma onboarding animation trigger

---

## 📋 BACKLOG (Ordered by Priority)

### Sprint 1 — Core Loop
- [ ] TASK-004: MapView with MapKit + Liquid Glass overlays
- [ ] TASK-005: LocationService (CoreLocation wrapper)
- [ ] TASK-006: PresenceService (toggle on/off, 3h expiry)
- [ ] TASK-007: Supabase PostGIS integration (store/query presences)
- [ ] TASK-008: WebSocket service (real-time dot updates on map)
- [ ] TASK-009: PresenceDotView (glowing marker on map)
- [ ] TASK-010: "Go Present" button (main CTA, glass pill)
- [ ] TASK-011: Luma component + idle animation (Lottie)

### Sprint 2 — Wave System
- [ ] TASK-012: Tap-a-dot → wave preview sheet
- [ ] TASK-013: Claude API icebreaker generation (backend)
- [ ] TASK-014: WaveView — show icebreaker + wave button
- [ ] TASK-015: Wave notification (push, Luma inline)
- [ ] TASK-016: Wave response flow (accept/ignore)
- [ ] TASK-017: 10-minute chat window (ChatView with countdown)
- [ ] TASK-018: Connection recording + Luma celebration

### Sprint 3 — Monetization & Polish
- [ ] TASK-019: RevenueCat integration
- [ ] TASK-020: Paywall screen (Presence+)
- [ ] TASK-021: Free tier enforcement (3 presences/week)
- [ ] TASK-022: Profile screen + connection history
- [ ] TASK-023: Block/report flow
- [ ] TASK-024: Privacy screen + data export
- [ ] TASK-025: Settings screen
- [ ] TASK-026: Luma full state machine + all animations

### Sprint 4 — Beta
- [ ] TASK-027: App Store Connect setup
- [ ] TASK-028: TestFlight distribution
- [ ] TASK-029: Analytics (PostHog)
- [ ] TASK-030: Crash reporting (Sentry)
- [ ] TASK-031: ASO — screenshots, description, keywords
- [ ] TASK-032: Venue partner B2B backend

---

## 🐛 ACTIVE BUGS

*None yet*

---

## 🔖 SESSION NOTES

**Last session (2026-04-24):** Scaffolded the Node.js backend (`Backend/`) — the first piece of the system that runs natively on Windows.

- `src/index.ts` — Express + Socket.io entry, pino logging, graceful shutdown
- `src/config.ts` — Zod-validated env with `featureFlags` for Supabase / Anthropic
- `src/services/matchingService.ts` — Claude icebreaker generation via `@anthropic-ai/sdk`, using `claude-opus-4-7` with `thinking: disabled`, no sampling params (Opus 4.7 removed them), prompt-cache marker on the system prompt (no-op at current length, future-proofs), response validation (20–200 chars, AI-mention filter), and a hand-written fallback library keyed deterministically by venue name
- `src/services/supabase.ts` — server-side client factory using the service-role key
- `src/routes/{health,icebreaker,presence,waves}.ts` — icebreaker endpoint is live + rate-limited (1 req / 30s per sender); presence/waves stubs return 501 with a sprint pointer
- `src/websocket/index.ts` — socket.io scaffold, geohash rooms land in Sprint 1
- `supabase/migrations/0001_initial_schema.sql` — full PostGIS schema from CLAUDE.md (users, presences, waves, connections, blocks, venue_partners) with GIST index, 3h expiry check, RLS with placeholder deny-all-anon policies
- `README.md` — how to run, how to verify, env table, curl example

Also fixed doc debt: CLAUDE.md's Glass hierarchy used to list `.glassEffect(.thin)` — that's not a real iOS 26 API. Updated the hierarchy to show `.regular` + `.clear` only, added a warning note, and cross-linked a LEARNINGS.md entry explaining the CI error pattern.

**Next session start with:** pick a direction — (a) onboarding flow UI (phone → OTP → bio → map, pure SwiftUI, builds on Windows), (b) wire Supabase Auth + presence persistence end-to-end (Sprint 1 core loop, requires a Supabase project), or (c) harden the Backend (unit tests, fallback library expansion, deploy to Railway). The backend is now runnable locally — `cd Backend && npm install && npm run dev`, hit `/health`, then POST to `/api/icebreaker` with or without an `ANTHROPIC_API_KEY`.

---

## 📊 METRICS TO TRACK (post-launch)
- DAU / MAU ratio (target: >40% — Duolingo benchmark)
- Presences per active user per week (target: 2+)
- Wave accept rate (target: >30%)
- Connection-to-friend rate (how many waves become real connections — survey)
- Week 1 retention (target: >50%)
- Week 4 retention (target: >25%)
- Free-to-paid conversion (target: >5%)
