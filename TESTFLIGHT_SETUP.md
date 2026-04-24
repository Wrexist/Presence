# TESTFLIGHT_SETUP — Presence

> How to wire up automated TestFlight deploys from GitHub Actions.
> **Not active yet.** Activate when you have an Apple Developer account ($99/yr) and a real device to test on.

---

## What you need first

1. Apple Developer Program membership ($99/yr)
2. App Store Connect access
3. The bundle ID `com.presenceapp.ios` registered in the Developer Portal
4. A distribution certificate (`.p12`)
5. An App Store Connect API key (`.p8` issued by Apple)

---

## Required GitHub secrets

Add these in **Settings → Secrets and variables → Actions** of the repo:

| Secret | What it is |
|--------|-----------|
| `APPLE_TEAM_ID` | 10-char alphanumeric, found in Developer Portal → Membership |
| `APPLE_DIST_CERT_P12_BASE64` | Distribution `.p12` certificate, base64-encoded |
| `APPLE_DIST_CERT_PASSWORD` | The password you set when exporting the `.p12` |
| `APP_STORE_CONNECT_KEY_ID` | API key ID (10 chars) |
| `APP_STORE_CONNECT_ISSUER_ID` | UUID from App Store Connect → Users and Access → Keys |
| `APP_STORE_CONNECT_API_KEY_P8_BASE64` | The `.p8` key contents, base64-encoded |

To base64-encode on macOS: `base64 -i AuthKey_XXXX.p8 | pbcopy`
On Windows: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXX.p8"))` in PowerShell.

---

## Activating the workflow

When you're ready, copy `.github/workflows/pr-checks.yml` as a template and create a new `.github/workflows/ios-testflight.yml` that:

1. Triggers on `workflow_dispatch` (manual) and tag pushes (`v*`)
2. Imports the distribution cert into a temporary keychain
3. Writes the `.p8` API key to disk for `xcodebuild`
4. Runs `xcodegen generate`
5. Runs `xcodebuild archive` with automatic provisioning + your `APPLE_TEAM_ID`
6. Runs `xcodebuild -exportArchive` with an `ExportOptions.plist` that sets `method` to `app-store`
7. Uploads the resulting `.ipa` via `xcrun altool` or the `apple-actions/upload-testflight-build` action
8. Deletes the temporary keychain in the cleanup step

A reference workflow lives in [Wrexist/Peptide-ai → ios-testflight.yml](https://github.com/Wrexist/Peptide-ai/blob/main/.github/workflows/ios-testflight.yml) — adapt names, bundle IDs, and capabilities.

---

## Important: capabilities

For the App Store Connect API to push a build, the bundle ID `com.presenceapp.ios` must have the following enabled in the Developer Portal:

- Push Notifications
- (Future: Sign in with Apple, App Groups for widget extension)

---

## First manual upload

For your very first TestFlight build, do it manually from Xcode:
- Open `Presence.xcodeproj`
- Product → Archive
- Distribute App → App Store Connect → Upload

This validates that all signing + capability configuration is correct before automating it.
