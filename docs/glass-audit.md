# Liquid Glass Audit — D8

> Pass over every screen against the rules in `CLAUDE.md` § Design System
> ("Liquid Glass lives on the navigation layer", "Never stack glass",
> "Never put glass on scrollable content"). Run on commit `D7+D8+E1`.

## ✅ Pass

| Screen                          | Notes                                            |
|---------------------------------|--------------------------------------------------|
| `OnboardingView` (root)         | No glass; per-step views are full-bleed.         |
| `OnboardingPhone/OTP/Username/Bio` | `GlassTextField` is the only glass; sibling, not nested. |
| `OnboardingPrivacy`             | Plain text rows; no glass-on-glass.              |
| `OnboardingReady`               | Hero Luma + plain text + CTA; clean.             |
| `HomeView` map background       | Map tiles correctly NOT glass.                   |
| `HomeView` Go-Present CTA       | `GlassPillButton` over map; nav-layer, fine.     |
| `GoPresentView`                 | One CTA + one chip, sibling.                     |
| `WaveComposeView`               | Card + CTA; chips inside cards FIXED in this pass.|
| `WaveReceivedView`              | Card + CTA; clean.                               |
| `ChatView` messages             | Bubbles intentionally NOT glass — scroll content. |
| `ChatView` composer             | Glass field + glass send button on nav layer.    |
| `WavesView`                     | Sectioned cards + chip in section header (sibling, not nested). |
| `CelebrationView`               | Plain hero + chips + CTA; no nested glass.       |
| `PaywallView`                   | Plan tiles use plain rounded rectangles, not glass cards — by design. |
| `ProfileView`                   | Card siblings + edit alerts; clean.              |
| `JourneyView`                   | Stat cards as siblings; activity card had a glass chip that was FIXED. |
| `SettingsView`                  | Sectioned card list; siblings only.              |
| `PrivacyView`                   | Sectioned card list + share sheet; clean.        |
| `SafetySheet`                   | Action rows are GlassCards; sibling.             |

## 🛠 Fixed in this pass

1. **`HomeView.liveChip`** was a `GlassChip` rendered inside the header
   `GlassCard` ("Live" / "..." / "Offline"). Replaced with a plain icon
   + text styled by socket state — same affordance, no nesting.
2. **`JourneyView.activityCard`** had a `GlassChip(text: "last 7 days")`
   inside its `GlassCard`. Replaced with a plain `Text` in the hint
   color.
3. **`WaveComposeView.icebreakerCard`** had a `GlassChip(text: "local")`
   inside its `GlassCard` (shown when the icebreaker came from the
   fallback library). Replaced with plain styled text.

## 🟡 Notes / future audits

- **`Reduce Transparency`**: `glassSurface` already falls back to
  `.regularMaterial` on iOS < 26 and the OS handles the user setting
  inside the iOS-26 `.glassEffect` API. Visual verification on a real
  device with the setting ON is in E1.
- **`GlassChip` in `WavesView` section header**: Sits OUTSIDE the wave-row
  cards (in the section header HStack). Not nested — left as-is.
- **`PaywallView` plan tiles**: Deliberately use plain
  `RoundedRectangle` instead of `GlassCard` because they sit on a
  full-bleed gradient and need higher contrast for the price text.
- **No glass on map tiles**: Confirmed — map uses MapKit native
  `.standard(elevation: .flat, pointsOfInterest: .excludingAll)`.

## How to keep this audit green

- Default: a chip / pill renders glass only when it sits over plain
  background or the map. If it sits inside a `GlassCard`, render the
  same content as plain text or a tinted SF Symbol.
- Never put a `GlassCard` inside another `GlassCard`'s content closure.
- Bubbles, list rows, and other scroll-content items stay non-glass.
