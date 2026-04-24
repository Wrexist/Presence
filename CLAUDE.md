# PRESENCE — Claude Opus 4.7 Master Context File
> Real-time ambient social layer for the loneliness epidemic
> Read this entire file before touching any code. Every session.

---

## 🧠 WHO YOU ARE IN THIS PROJECT

You are the primary engineer and product architect for **Presence** — a hyper-local ambient social iOS app. You have full autonomy to make architectural decisions. You are not a code assistant. You are a co-founder building a production app.

**Model:** Claude Opus 4.7  
**Key strengths to leverage on this project:**
- Use `xhigh` effort for all UI architecture and matching algorithm work
- Use high-resolution vision for any screenshot/design review tasks (3.75MP native)
- Use extended thinking for complex geolocation + privacy decisions
- 1M context window: keep full codebase context loaded — never summarize away critical logic

---

## 📱 WHAT PRESENCE IS

**One-liner:** Presence shows you who nearby is open to connecting — right now, in real life.

**Core mechanic:**
1. User opts in → they become "Present" at their current location
2. App shows a glass map with glowing dots of nearby Present users
3. Tap a dot → AI generates a single contextual icebreaker based on venue + time + both users' brief bios
4. Both users get the icebreaker notification → optional wave back
5. If both wave → a 10-minute chat window opens, then closes (forcing IRL meetup)
6. Connection is tracked. If they become friends, the mascot (Luma) celebrates.

**What it is NOT:**
- Not a dating app (no romantic framing anywhere — strict enforcement)
- Not a social media feed (no posts, no stories, no likes)
- Not a location tracker (presence is opt-in per session, never persistent)
- Not a chat app (chat window is intentionally limited to 10 minutes)

---

## 🏗️ TECHNICAL STACK

### iOS App
```
Language:       Swift 6.0 (strict concurrency)
UI Framework:   SwiftUI (iOS 26 target — Liquid Glass native)
Min Deployment: iOS 26.0
Architecture:   MVVM + Coordinator pattern
DI:             Swift's native @Environment + custom ServiceContainer
```

### Key iOS 26 APIs in use
```swift
// Liquid Glass — USE THESE, NOT CUSTOM BLUR
.glassEffect()                    // Primary glass material
.glassEffect(.regular, in: ...)  // For cards
GlassEffectContainer { }         // Group morphing glass elements
// Always gate with:
if #available(iOS 26.0, *) { ... } else { /* Material fallback */ }
```

### Backend
```
Runtime:        Node.js 22 (TypeScript)
API:            REST + WebSocket (socket.io for real-time presence)
Database:       Supabase (PostgreSQL + PostGIS for geolocation queries)
Auth:           Supabase Auth (Phone number — no email, reduces friction)
Storage:        Supabase Storage (Luma animation assets)
Edge Functions: Supabase Edge Functions (Deno)
AI:             Anthropic API — claude-opus-4-7 (icebreaker generation)
```

### Third-party SDKs
```
RevenueCat         — subscription management (already familiar from Dynasty Manager)
Lottie iOS         — Luma mascot animations
MapKit             — iOS 26 native maps with Liquid Glass overlays
CoreLocation       — precise location (only when Present)
UserNotifications  — push for wave alerts
PostHog            — analytics (privacy-first)
```

---

## 🗂️ PROJECT FILE STRUCTURE

> Mirrors the Peptide-ai layout (XcodeGen-driven). Flat — no `Core/` wrapper.
> The `.xcodeproj` is **never committed**; it is generated from `project.yml`.
> See `SETUP.md` for the full workflow including Windows-only development.

```
.
├── project.yml                    # XcodeGen — source of truth for the Xcode project
├── .swiftlint.yml                 # Lint config
├── .gitignore                     # Ignores *.xcodeproj, .env*, DerivedData, etc.
├── .env.example                   # Copy → .env.development
├── SETUP.md                       # Bootstrap — including Windows + cloud-Mac path
├── TESTFLIGHT_SETUP.md            # How to wire automated TestFlight deploys
├── CLAUDE.md / PRD.md / ROADMAP.md / TASK.md / LEARNINGS.md / LUMA_BRIEF.md
│
├── .github/workflows/
│   └── pr-checks.yml              # macOS CI: xcodegen → swiftlint → build → test
│
├── Presence/                      # ← App target source
│   ├── App/
│   │   ├── PresenceApp.swift      # @main entry point
│   │   ├── AppCoordinator.swift   # Root navigation state (@Observable)
│   │   └── ServiceContainer.swift # DI container — @Environment-injected
│   ├── DesignSystem/
│   │   ├── GlassTokens.swift      # Radius/Padding/Opacity/Motion enums
│   │   ├── PresenceColors.swift   # Aurora palette + Color(hex:) + dotColor(for:)
│   │   ├── Typography.swift       # SF Pro Rounded scale
│   │   ├── GlassComponents.swift  # GlassCard/PillButton/IconButton/BottomSheet/Chip
│   │   └── Luma/                  # LumaView, LumaState, LumaAnimations
│   ├── Features/
│   │   ├── Onboarding/            # OnboardingView, BioSetupView, OnboardingVM
│   │   ├── Map/                   # MapView, PresenceDotView, VenueCardView, MapViewModel
│   │   ├── Wave/                  # WaveView, ChatView, WaveViewModel
│   │   ├── Profile/               # ProfileView, PresenceHistoryView
│   │   └── Settings/              # SettingsView, PrivacyView
│   ├── Models/                    # User, PresentUser, Wave, Venue (plain data types)
│   ├── Services/                  # PresenceService, LocationService, MatchingService,
│   │                              # SocketService, NotificationService (actors / @MainActor)
│   ├── Data/                      # Repositories, Supabase clients, caches
│   ├── Resources/
│   │   ├── Info.plist             # Generated by xcodegen from project.yml
│   │   └── Assets.xcassets/       # AppIcon, AccentColor
│   └── Presence.entitlements
│
├── Shared/                        # Code shared with future extensions (widgets, intents)
├── PresenceTests/                 # Swift Testing unit tests
├── PresenceUITests/               # XCUITest smoke tests
│
└── Backend/                       # Node.js backend (separate runtime, fully Windows-friendly)
    ├── src/
    │   ├── routes/
    │   ├── services/              # presenceService, matchingService (Claude API), geolocationService
    │   └── websocket/
    └── supabase/
        ├── migrations/
        └── edge-functions/
```

### XcodeGen workflow (critical — read before editing the project)
- **Never commit `Presence.xcodeproj`** — it's regenerated from `project.yml`.
- After adding a new Swift file or changing a dependency, run `xcodegen generate` (or push and let CI regenerate).
- On Windows, you don't run xcodegen locally — push to a branch and let `pr-checks.yml` validate.
- Swift Package dependencies are declared in `project.yml` under `packages:`, not via Xcode UI.

---

## 🎨 DESIGN SYSTEM — LIQUID GLASS RULES

### The Golden Rule
> Liquid Glass lives on the **navigation layer** — it floats ABOVE content.  
> Content (user dots, map, text) lives BELOW glass.  
> Never stack glass on glass. Never put glass on scrollable content.

### GlassTokens — ALWAYS USE THESE (never hardcode values)

```swift
// GlassTokens.swift — source of truth
enum GlassTokens {
    enum Radius {
        static let card: CGFloat = 28
        static let pill: CGFloat = 999
        static let sheet: CGFloat = 34
        static let dot: CGFloat = 22
        static let icon: CGFloat = 16
    }
    enum Padding {
        static let card = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        static let pill = EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)
        static let iconButton = EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        static let sheet = EdgeInsets(top: 28, leading: 24, bottom: 28, trailing: 24)
    }
    enum Opacity {
        static let primary: Double = 1.0
        static let secondary: Double = 0.7
        static let hint: Double = 0.45
    }
}
```

### Glass Component Hierarchy
```
GlassEffectContainer (morphing group)
    └── .glassEffect()              → Primary: nav bars, main CTAs
    └── .glassEffect(.regular)     → Secondary: cards, bottom sheets  
    └── .glassEffect(.thin)        → Tertiary: subtle overlays, status
    └── Material (fallback)        → iOS < 26 only
```

### What MUST use Liquid Glass
- Tab bar
- Navigation bar
- All CTAs (primary buttons)
- Bottom sheets / modals
- The "Present" toggle button
- Wave notification cards
- Venue info overlays

### What must NOT use Liquid Glass
- Map tiles
- Presence dot markers (use glowing fill instead)
- Text content areas
- List rows
- Full-screen background

---

## 🎭 LUMA — THE MASCOT (Critical Context)

**Luma is a small bioluminescent deep-sea creature** — somewhere between a lanternfish and a water droplet with eyes. Bioluminescent. Floats. Glows softly in Presence's signature aurora colors.

**Why this design:**
- Connects to the app's core metaphor (presence = light in darkness, loneliness = the dark)
- Non-threatening (no sharp edges, no aggressive traits)
- Non-gendered (intentionally inclusive)
- Bioluminescence = the literal act of being "present" → glowing to attract others
- Deep-sea creature = finds connection in the darkest, most unlikely places (perfectly on-brand)
- "Kawaii" adjacent without being childish — works for adults

**Luma's personality:**
- Shy but warm (mirrors the user who is nervous to connect)
- Celebrates quietly — not obnoxious about wins
- Gets sad but never guilt-trips (anti-Duolingo aggressive notification pattern)
- Communicates mostly through glow color and body language, not text

**Luma's states (map to LumaState enum):**
```swift
enum LumaState {
    case idle           // Gentle floating, soft white glow
    case excited        // Rapid floating, golden glow — someone nearby is Present
    case waving         // Wiggling tentacles — wave sent/received
    case connecting     // Spiraling animation — icebreaker loading
    case celebrating    // Burst of light — successful connection made
    case sleepy         // Dim glow, slow breathing — no one nearby
    case gentle         // Eyes closed, pulsing — used during quiet moments
}
```

**Luma's visual spec for design handoff:**
- Base shape: ~60px circle with 3-4 small trailing wisps/tentacles
- Eyes: Large, simple, expressive (2 dots with subtle glow)
- Glow: Soft gaussian blur halo, color-shifts by state
- Colors by state: idle=white/pearl, excited=amber/gold, waving=cyan, 
  connecting=violet, celebrating=full spectrum aurora, sleepy=dim blue
- Animation: Always floating (never static), 3-4 second idle loop
- Format: Lottie JSON (vector, scalable, lightweight)
- Sizes needed: 32pt (notification), 64pt (inline), 128pt (hero), 256pt (onboarding)

**Where Luma appears:**
1. Onboarding screens (hero, guides user through setup)
2. Map screen (small, bottom-left corner — reacts to nearby presence)
3. Empty states ("No one nearby — be the first to glow")
4. Wave notifications (inline, small)
5. Celebration moments (fullscreen burst animation)
6. Push notification icon

**Luma does NOT appear on:**
- Settings screens
- Chat windows (this is human-to-human space)
- Error states (keep it clinical/simple there)

---

## 🤖 AI / CLAUDE API INTEGRATION

### Icebreaker Generation — the core AI feature

**Model:** `claude-opus-4-7`  
**Effort:** `high` (not xhigh — this is a creative, short task)  
**Max tokens:** 200 (icebreakers must be SHORT)

**System prompt (production-ready):**
```
You are the icebreaker engine for Presence, an app that connects strangers in real life.
Generate ONE perfect conversation starter for two people who are about to meet.

Rules:
- Maximum 2 sentences
- Warm, not creepy — like something a mutual friend would say
- Specific to the context provided (venue, time, user bios)
- Never romantic or flirtatious
- Never reference the app or AI
- Should feel like it came from local knowledge, not an algorithm
- End with an open question when possible

Output: Only the icebreaker text. Nothing else.
```

**Input format:**
```typescript
interface IcebreakerRequest {
  venue: {
    name: string;
    type: 'cafe' | 'park' | 'gym' | 'library' | 'bar' | 'coworking' | 'other';
    vibe: 'quiet' | 'social' | 'working' | 'active';
  };
  timeContext: {
    hour: number;        // 0-23
    dayOfWeek: string;   // 'monday' etc
    isWeekend: boolean;
  };
  userA: {
    bio: string;         // Max 3 words — "loves coffee mornings"
    connectionCount: number; // How many connections made via app
  };
  userB: {
    bio: string;
    connectionCount: number;
  };
}
```

**Example output:**
> "This place has the best oat milk for miles — have you tried their afternoon special yet?"

### Privacy architecture for AI calls
- NEVER send user IDs or names to Claude API
- Bios are anonymized before sending (no PII)
- All AI calls routed through backend Edge Function (not client-side)
- API key never in client bundle

---

## 🔒 PRIVACY — NON-NEGOTIABLE RULES

These are product constraints, not suggestions. Break any of these and the app fails its core promise.

1. **Location is ONLY collected when user is actively Present** — not in background
2. **Location precision is reduced by ~50m radius** before storing in DB (prevents exact pinpointing)
3. **Presence expires automatically** — max 3 hours, user must re-opt-in
4. **No location history stored** — only current presence, deleted on timeout
5. **Username is displayed to nearby users, not real name** — chosen at onboarding
6. **Profile photo is optional** — Luma avatar is default and always valid
7. **Block/report is always one tap** — never more than 2 taps away
8. **GDPR/CCPA compliant** — full data export + delete in settings

---

## 💰 MONETIZATION

### Freemium Model
```
FREE:
- 3 Presences per week
- Standard icebreakers
- Luma in idle/excited states only

PRESENCE+ ($6.99/month or $49.99/year):
- Unlimited Presences
- Enhanced icebreakers (more contextual)
- See how many people are Present in an area before activating
- Luma full emotion spectrum + exclusive seasonal skins
- "Quiet Hours" — set a schedule for auto-Presence

VENUE PARTNER (B2B, $49-199/month):
- Venue appears as "Presence Hub" on map (highlighted)
- Analytics: how many Presence connections happen at their venue
- Custom Luma color for their venue dot
```

### RevenueCat Integration
- Products: `presence_plus_monthly`, `presence_plus_annual`
- Entitlement: `presence_plus`
- Paywall: Show after 3rd weekly Presence attempt, never during onboarding

---

## 🗄️ DATABASE SCHEMA (Supabase/PostGIS)

```sql
-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  bio TEXT, -- max 50 chars, 3-word style
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  -- No email stored, phone auth via Supabase
);

-- Active Presences (ephemeral)
CREATE TABLE presences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  location GEOGRAPHY(POINT, 4326) NOT NULL, -- PostGIS
  venue_name TEXT,
  venue_type TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL, -- max 3h from start
  is_active BOOLEAN DEFAULT TRUE,
  -- No location stored after expires_at — trigger deletes
);
CREATE INDEX presences_location_idx ON presences USING GIST(location);
CREATE INDEX presences_active_idx ON presences(is_active, expires_at);

-- Waves
CREATE TABLE waves (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES users(id),
  receiver_id UUID REFERENCES users(id),
  icebreaker TEXT NOT NULL,
  status TEXT DEFAULT 'sent', -- sent, waved_back, expired, blocked
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL, -- 2h to respond
);

-- Connections (successful waves)
CREATE TABLE connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a UUID REFERENCES users(id),
  user_b UUID REFERENCES users(id),
  venue_name TEXT,
  connected_at TIMESTAMPTZ DEFAULT NOW(),
  -- Soft data only, for user's "connections made" count
);

-- Venue Partners (B2B)
CREATE TABLE venue_partners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  location GEOGRAPHY(POINT, 4326),
  tier TEXT DEFAULT 'standard',
  active BOOLEAN DEFAULT TRUE,
);

-- Cleanup trigger: auto-delete expired presences
CREATE OR REPLACE FUNCTION expire_presences()
RETURNS void AS $$
  UPDATE presences SET is_active = FALSE 
  WHERE expires_at < NOW() AND is_active = TRUE;
$$ LANGUAGE SQL;
```

---

## 🚨 KNOWN PITFALLS — AVOID THESE

1. **Never use UIVisualEffectView manually** for glass — use `.glassEffect()` API only
2. **Never stack glass** — test every screen: if you see glass-on-glass, fix it
3. **Liquid Glass + Reduce Transparency** — always test with this setting ON in Accessibility
4. **Location permissions** — request `whenInUse` only, never `always`. Explain why before requesting.
5. **WebSocket reconnection** — handle network drops gracefully; presence must persist across brief disconnects
6. **Map performance** — cap at 50 visible presence dots maximum; use clustering beyond that
7. **The 10-minute chat timer** — this is sacred. Never let it be disabled in UI. It's the product's core forcing function.
8. **Luma in notifications** — use 32pt version only, ensure it renders on all notification banner sizes
9. **Icebreaker API latency** — show Luma's `connecting` animation while waiting (never a spinner)
10. **RevenueCat + iOS 26** — verify receipt validation works on new SDK; see LEARNINGS.md for any discovered issues

---

## 🔄 SESSION CONTINUITY PROTOCOL

At the START of every Claude Code session:
1. Read CLAUDE.md (this file) — fully
2. Read TASK.md — what's being worked on right now
3. Read LEARNINGS.md — what has been discovered/fixed
4. Read SETUP.md if you haven't — especially the Windows section, since most dev happens on Windows
5. Check git status — understand current branch and uncommitted state
6. Do NOT begin coding until you understand the context

### Reminder: this project is developed primarily from Windows
- All Swift source lives under `Presence/` and is editable in any text editor (VS Code / Cursor recommended).
- The Xcode project is generated by XcodeGen from `project.yml` — never commit `Presence.xcodeproj`.
- Compile / lint / test verification happens in GitHub Actions (`pr-checks.yml`) on macOS runners.
- A real Mac is only required for: running the simulator, running on-device, and submitting to App Store / TestFlight.

At the END of every Claude Code session:
1. Update TASK.md with current state
2. Update LEARNINGS.md with anything new discovered
3. Commit all changes with a clear message
4. Note any TODOs for next session

---

## 📐 CODE STANDARDS

```swift
// MARK: - Style rules

// 1. All async operations use Swift concurrency (async/await)
// 2. @MainActor on all ViewModels
// 3. Actors for shared mutable state (LocationService, SocketService)
// 4. No force unwraps (!) anywhere
// 5. Errors are typed — no catching generic Error where avoidable
// 6. Preview providers for every SwiftUI view
// 7. GlassTokens for every glass value — no magic numbers

// MARK: - Naming
// ViewModels: MapViewModel, WaveViewModel (not MapVM)
// Views: MapView, WaveView (not MapScreen)
// Services: LocationService, MatchingService (not LocationManager)

// MARK: - File header template
//  PresenceApp
//  [FileName].swift
//  Created: [Date]
//  Purpose: [One line]
```

---

## 🌐 ENVIRONMENT CONFIG

```swift
// Config.swift
enum Config {
    static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"]!
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]!
    static let backendURL = ProcessInfo.processInfo.environment["BACKEND_URL"]!
    // Claude API key is NEVER in client — backend only
}
```

`.env.development`:
```
SUPABASE_URL=https://[project].supabase.co
SUPABASE_ANON_KEY=[anon key]
BACKEND_URL=http://localhost:3000
ANTHROPIC_API_KEY=[key — backend use only]
REVENUECAT_API_KEY=[key]
```

---

*Last updated: Session init. Maintain this file as the project evolves.*
