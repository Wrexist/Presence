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

**Last session (2026-04-24):** Pivoted to XcodeGen so the project is fully developable from Windows (mirrors the Peptide-ai layout). Restructured repo: source moved into `Presence/{App,DesignSystem,...}`, `Backend/` skeleton, `Shared/`, `PresenceTests/`, `PresenceUITests/` created. Wrote `project.yml` (iOS 26, Swift 6, all SPM deps), `.swiftlint.yml`, `.gitignore` (excludes `*.xcodeproj`), `.env.example`, `SETUP.md`, `TESTFLIGHT_SETUP.md`, and `.github/workflows/pr-checks.yml` (macOS runner: xcodegen → swiftlint → build → unit tests). App shell scaffolded: `PresenceApp.swift` (env-injected coordinator + service container), `AppCoordinator.swift` (`@Observable` route enum), `ServiceContainer.swift` (DI shell), `Presence.entitlements`, `Assets.xcassets` with aurora-blue AccentColor. Updated `CLAUDE.md` file structure section + added Windows-development note.

**Next session start with:** Push branch → wait for `pr-checks.yml` to go green on the macOS runner. If it fails, read the xcresult artifact and fix. Once green, start Sprint 1: build `LocationService` + `PresenceService` + `MapView` (TASK-004 → TASK-010). Also handle the dashboard chores (Supabase project + SQL migrations, RevenueCat account).

---

## 📊 METRICS TO TRACK (post-launch)
- DAU / MAU ratio (target: >40% — Duolingo benchmark)
- Presences per active user per week (target: 2+)
- Wave accept rate (target: >30%)
- Connection-to-friend rate (how many waves become real connections — survey)
- Week 1 retention (target: >50%)
- Week 4 retention (target: >25%)
- Free-to-paid conversion (target: >5%)
