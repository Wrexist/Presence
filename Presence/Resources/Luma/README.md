# Luma — Lottie Asset Spec

> Drop the `.json` (or `.lottie`) files produced from the designer's
> After Effects export into this directory. `LumaView` looks each one up
> via `LottieAnimation.named(_:)` at render time. If a file is missing,
> the view silently falls back to the pure-SwiftUI render in
> `LumaPureView.swift`, so the app keeps working through the asset
> handoff process.

## Required filenames

`LumaState.animationName` is the source of truth — these names must match
exactly (no extension):

| State          | Filename                | Used in                             |
|----------------|-------------------------|-------------------------------------|
| `.idle`        | `luma_idle.json`        | Map corner default, onboarding hero |
| `.excited`     | `luma_excited.json`     | Map corner when nearby presences    |
| `.waving`      | `luma_waving.json`      | After wave sent / received          |
| `.connecting`  | `luma_connecting.json`  | Icebreaker loading                  |
| `.celebrating` | `luma_celebrating.json` | Mutual wave / connection burst      |
| `.sleepy`      | `luma_sleepy.json`      | No one nearby for 5+ min            |
| `.gentle`      | `luma_gentle.json`      | Quiet moments (waves empty state)   |

## Sizes (vector — single master per state)

Lottie is vector, so one master file per state covers every render size.
**Don't ship per-size files.** Use these target sizes when verifying that
the master reads cleanly at small dimensions:

| Render size | Where it appears                                                     |
|-------------|----------------------------------------------------------------------|
| **32 pt**   | Push notification icon (simplified silhouette)                       |
| **64 pt**   | Inline (map corner, wave row)                                        |
| **128 pt**  | Hero (paywall, celebration)                                          |
| **256 pt**  | Onboarding welcome screen                                            |

Verify legibility of the eyes + glow at 32 pt — that's the worst case.

## Animation rules

- **Loop:** all states loop infinitely (`loopMode: .loop` in `LumaView`).
- **Tempo:** `LumaState.lottieSpeed` is multiplied into the playback rate
  to keep visual cadence consistent across states. Defaults to 1.0; use
  the table in `LumaState.swift` as the source of truth.
- **Duration:** target a **3–4 second** master loop for idle/gentle/sleepy.
  Faster tempos (excited, celebrating) can be 1.5–2 seconds.
- **Color:** keep the file color-tinted internally (no SwiftUI tinting).
  `LumaState.bodyColor` and `glowColor` are used **only** by the pure-SwiftUI
  fallback; the Lottie file controls its own colors.

## Format

- `.lottie` (newer dotLottie format) is preferred for smaller bundle size.
  `LottieAnimation.named(_:)` resolves both `.json` and `.lottie` from the
  same name.
- Strip unused layers and rasterized PNG sequences before export — vector
  paths only.
- Aim for **< 30 KB** per state.

## Where Luma must NOT appear

Cross-reference `CLAUDE.md` § "Where Luma appears":
- ❌ Settings screens
- ❌ Chat windows (human-to-human space)
- ❌ Error states (keep clinical)

If you find a `LumaView` in any of those places, that's a bug — file it
and remove the call site.

## Verifying the asset is bundled

After dropping files into this directory, run `xcodegen generate` (or
let CI regenerate) and rebuild. In a debug build, you can confirm a
specific state is rendering Lottie (not the fallback) by setting a
breakpoint on `LumaView.rendered` and inspecting the `if let animation`
branch.
