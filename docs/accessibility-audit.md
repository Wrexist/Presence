# Accessibility Audit — E1

> First pass against `ROADMAP.md` Phase 4 Day 55-57 + the rules in
> `CLAUDE.md` § Known Pitfalls #3 ("Liquid Glass + Reduce Transparency
> — always test with this setting ON in Accessibility").
>
> Verified-on-device pass goes in the TestFlight session (E6). This doc
> tracks code-side state; the ✅ / ❌ on real-device verification will
> get filled in during beta.

## VoiceOver labels

| Surface                          | Label                                 | Status |
|----------------------------------|---------------------------------------|--------|
| Tab bar items                    | "Nearby" / "Waves" / "Journey" / "You"| ✅ in `GlassTabBar` |
| Tab bar center "Go Present"      | "Go Present"                          | ✅ in `GlassTabBar` |
| Map presence dots                | "Glowing user, {username}, {bio}" + hint "Double tap to start a wave" | ✅ in `HomeView` (this pass) |
| Map compass / user-location btn  | System-default                        | ✅ free |
| Wave compose top bar dismiss     | "Dismiss"                             | ✅ |
| Wave compose flag                | "Block or report"                     | ✅ |
| Wave received flag               | "Block or report"                     | ✅ |
| Chat dismiss                     | "Close chat"                          | ✅ |
| Chat send                        | "Send"                                | ✅ |
| Chat flag                        | "Block or report"                     | ✅ |
| Settings close                   | "Close"                               | ✅ |
| Privacy close                    | "Close"                               | ✅ |
| Paywall close                    | "Close"                               | ✅ |
| Glass-icon-button generic        | per-call `accessibilityLabel:` arg    | ✅ |

**Outstanding:** verify on-device that VoiceOver reads the dot label
correctly when the user pans / zooms the map. MapKit's annotation
focus order can be surprising.

## Reduce Motion

| Element                         | Behavior under Reduce Motion ON       |
|---------------------------------|---------------------------------------|
| `LumaView` (Lottie path)        | `.animation(reduceMotion ? nil : ...)` — instant state crossfade. ✅ |
| `LumaPureView` (fallback)       | `startAnimating()` no-ops under Reduce Motion (this pass). ✅ |
| Tab switch transitions          | SwiftUI default — Reduce Motion replaces the default `.opacity` transition with no animation; honored automatically. ✅ |
| Modal sheet swap                | iOS-system-driven; respects user setting. ✅ |
| Onboarding step-to-step move    | Uses `withAnimation(.spring)` — system honors Reduce Motion globally on `withAnimation`. 🟡 verify |

## Reduce Transparency

| Element                         | Behavior                              |
|---------------------------------|---------------------------------------|
| `glassSurface()` modifier       | `.glassEffect(.regular, in:)` on iOS 26+ — system handles Reduce Transparency. ✅ |
| iOS < 26 fallback               | `.regularMaterial` — system handles Reduce Transparency. ✅ |
| `GlassTabBar.glassBar`          | Same — system handled. ✅ |
| Custom blurs (Luma halo, paywall radial glow) | NOT system-managed; static gaussian blur. 🟡 acceptable since they're decorative + accessibility-hidden. |

## Dynamic Type

| Element                         | Behavior                              |
|---------------------------------|---------------------------------------|
| `Typography.*` font scale       | All system font scales (`.body`, `.headline`, `.callout`, `.caption`, `.footnote`, `.title`, `.display`) — auto-scales. ✅ |
| Hand-rolled `font(.system(size:))` (icon labels, etc.) | Most are system glyph weights — won't scale text. 🟡 fine because they're chrome, not content. |
| Wave row icebreaker `lineLimit(2)` | Lines clip on xxxLarge — copy gets cut. 🟡 acceptable; the full line is on `WaveReceivedView`. |

## What still needs on-device verification (E6)

- VoiceOver order through map annotations under pinch/zoom
- Reduce Transparency at 100% (specific glass affordances may need
  overlay tints)
- xxxLarge Dynamic Type on every screen — content must not clip
- `withAnimation` honor of Reduce Motion across the onboarding springs
- Color-contrast on aurora-on-deep-night text combos (the hint-opacity
  text at 0.45 may fail WCAG AA at small sizes)

## Where Luma is correctly hidden from VO

`LumaView` and `LumaPureView` set `.accessibilityHidden(true)`. This is
correct — Luma is decorative; the meaningful state ("Someone waved at
you", "Time's up") lives in the surrounding text which VoiceOver reads.

## Action items deferred to E6 (TestFlight)

- Color-contrast pass at xxxLarge on all surfaces
- Switch Control + AssistiveTouch sweep
- Bold Text setting verification
- Differentiate Without Color (the dot palette uses color-only signal —
  a shape variant for partner venues lands later)
