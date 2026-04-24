# TESTFLIGHT_SETUP — Presence

> One-click TestFlight deploys from GitHub Actions.
> Once the secrets below are set, shipping a new build is: **Actions tab → "iOS TestFlight Deploy" → Run workflow**.

---

## What you need first

1. Apple Developer Program membership ($99/yr)
2. App Store Connect access for this Apple ID
3. A Mac **once**, to export the distribution certificate (or ask someone with a Mac)
4. An App Record in App Store Connect for bundle ID `com.presenceapp.ios`

Everything else runs from GitHub Actions — no Mac required for subsequent builds.

---

## Step 1: Register the App ID

In the [Developer Portal → Identifiers](https://developer.apple.com/account/resources/identifiers/list):

1. Click **+** → **App IDs** → **App** → **Continue**
2. Description: `Presence`
3. Bundle ID (explicit): `com.presenceapp.ios`
4. Under **Capabilities**, tick **Push Notifications**
5. **Continue** → **Register**

> The preflight step in the workflow verifies this and fails fast with a clear message if the App ID or Push Notifications capability is missing.

---

## Step 2: Create the App Store Connect record

In [App Store Connect → My Apps](https://appstoreconnect.apple.com/apps):

1. Click **+** → **New App**
2. Platform: **iOS**
3. Name: `Presence`
4. Primary language: English (U.S.)
5. Bundle ID: pick `com.presenceapp.ios` from the dropdown
6. SKU: `presence-ios` (anything unique to you)
7. User access: Full Access

---

## Step 3: Export the distribution certificate (one-time, needs a Mac)

1. Open **Keychain Access** on the Mac
2. Request a certificate: **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority**
   - Email: your Apple ID
   - Common Name: `Presence Distribution`
   - Saved to disk → `CertificateSigningRequest.certSigningRequest`
3. In the [Developer Portal → Certificates](https://developer.apple.com/account/resources/certificates/list):
   - **+** → **Apple Distribution** → upload the CSR → download the `.cer`
4. Double-click the `.cer` to import into Keychain
5. In Keychain, find the cert → expand it → right-click the private key → **Export**
   - Save as `PresenceDistribution.p12`
   - Set a password (remember this — it becomes `APPLE_CERTIFICATE_PASSWORD`)
6. Base64-encode it:
   ```bash
   base64 -i PresenceDistribution.p12 | pbcopy
   ```
   That's `APPLE_CERTIFICATE_BASE64`.

---

## Step 4: Create the App Store Connect API key

In [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api):

1. Click **+** (Generate API Key)
2. Name: `Presence CI`
3. Access: **App Manager** (required to upload builds)
4. **Generate**
5. Download the `AuthKey_XXXXXXXXXX.p8` **immediately** — Apple only lets you download it once
6. Note the **Key ID** (10 chars, visible in the table) → `APPLE_CONNECT_KEY_ID`
7. Note the **Issuer ID** (UUID at the top of the page) → `APPLE_CONNECT_ISSUER_ID`
8. Get the key contents for the secret:
   ```bash
   cat AuthKey_XXXXXXXXXX.p8 | pbcopy
   ```
   Paste the full multi-line PEM (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines) into `APPLE_CONNECT_PRIVATE_KEY`. GitHub preserves newlines.

---

## Step 5: Find your Team ID

[Developer Portal → Membership](https://developer.apple.com/account/#/membership) → **Team ID** (10 alphanumeric chars) → `APPLE_TEAM_ID`.

---

## Step 6: Add the GitHub secrets

Repo → **Settings → Secrets and variables → Actions → New repository secret**. Add all six:

| Secret | What it is |
|--------|-----------|
| `APPLE_TEAM_ID` | 10-char team ID from Step 5 |
| `APPLE_CERTIFICATE_BASE64` | Base64 of the `.p12` from Step 3 |
| `APPLE_CERTIFICATE_PASSWORD` | Password you set when exporting the `.p12` |
| `APPLE_CONNECT_KEY_ID` | 10-char key ID from Step 4 |
| `APPLE_CONNECT_ISSUER_ID` | UUID issuer ID from Step 4 |
| `APPLE_CONNECT_PRIVATE_KEY` | Full contents of the `.p8` file (PEM-formatted) |

---

## Step 7: Ship

1. Go to the repo → **Actions** tab
2. Pick **iOS TestFlight Deploy** in the left sidebar
3. Click **Run workflow** → **Run workflow**
4. Watch the run. First time through, the preflight step will tell you in plain English if any Developer Portal setup is wrong.
5. When it finishes (15–20 min), open the **TestFlight app** on your iPhone — your build appears within 15–30 min of the upload completing, after Apple processes it.

Build numbers are stamped automatically from `github.run_number`, so every run gets a unique, monotonically increasing build number — no manual version bumps needed.

---

## How to increment the marketing version

The app version (what users see: 1.0.0, 1.1.0, etc.) lives in `project.yml` under `MARKETING_VERSION`. Bump it when you want a new user-facing version, push, then run the workflow.

```yaml
# project.yml
settings:
  base:
    MARKETING_VERSION: "1.1.0"  # <- bump this
```

The build number (`CFBundleVersion`) is set automatically by the workflow to `${{ github.run_number }}`, so you never touch it.

---

## Troubleshooting

**Preflight fails: "App ID not registered"** → Go back to Step 1.

**Preflight fails: "missing capability PUSH_NOTIFICATIONS"** → In the Developer Portal, click the `com.presenceapp.ios` App ID, tick **Push Notifications**, Save.

**Archive fails: "doesn't match the entitlements file's value"** → Same fix as above. The workflow dumps the fetched provisioning profiles on failure so you can see exactly what Apple returned.

**Upload fails: "Invalid Provisioning Profile"** → Almost always means the bundle ID in App Store Connect (Step 2) doesn't match `com.presenceapp.ios`. Check the app record.

**Build uploads but doesn't appear in TestFlight** → Wait 15–30 min for Apple's processing. If still missing after an hour, check the sender email account used for the API key — Apple emails processing errors there.

**"No account for team" errors** → `APPLE_TEAM_ID` is wrong. Double-check it in the Developer Portal membership page.

---

## Local verification (optional, macOS only)

If you have a Mac and want to test the archive step locally before running CI:

```bash
xcodegen generate
xcodebuild archive \
  -project Presence.xcodeproj \
  -scheme Presence \
  -archivePath /tmp/Presence.xcarchive \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=YOUR_TEAM_ID
```

If this succeeds, the CI workflow will too.
