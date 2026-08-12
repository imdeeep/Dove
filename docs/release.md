# Releasing Dove

Guide for **maintainers** building a signed, notarized `.dmg` and shipping it to users via direct download (website + GitHub Releases). This is the distribution path Dove uses today — not the Mac App Store.

For building and running locally without a paid developer account, see **[build-from-source.md](./build-from-source.md)**. Documentation index: **[docs/README.md](./README.md)**.

---

## What you need

| Requirement | Notes |
|-------------|--------|
| **Apple Developer Program** | Paid membership ($99/year), individual or organization |
| **Developer ID Application certificate** | Signs apps distributed outside the App Store |
| **Team ID** | e.g. `9UX5L32DZM` — shown in Xcode → Settings → Accounts |
| **Xcode** | Latest stable recommended |
| **notarytool credentials** | App-specific password stored in Keychain (one-time setup) |

Dove’s Xcode project is configured for team **Communittii Platform Solutions Private Limited** (`9UX5L32DZM`) and bundle ID **`com.mandeep.Dove`**.

---

## Direct download vs Mac App Store

| | Direct download (this guide) | Mac App Store |
|---|-------------------------------|---------------|
| Certificate | **Developer ID Application** | Apple Distribution |
| Output | Notarized `.dmg` | App Store Connect upload |
| Review | None | Apple App Review |
| Hosting | You (website, GitHub) | Apple |
| Dove support today | ✅ | ❌ Not configured |

---

## Organization accounts: who can create what

On **organization** Developer accounts, permissions matter:

| Action | Account Holder | Admin / Developer |
|--------|----------------|-------------------|
| Create **Developer ID Application** cert on developer.apple.com | ✅ | ❌ Often blocked — message: *"This operation can only be performed by the Account Holder"* |
| Create **Apple Development** cert in Xcode | ✅ | ✅ |
| Upload CSR (browser only) | ✅ | ✅ if given access |
| Sign & notarize on a Mac with the cert installed | ✅ | ✅ once cert is in Keychain |

**Typical team setup:** one person is Account Holder; the developer is Admin or Developer on App Store Connect.

---

## Certificate setup (organization + Account Holder without a Mac)

When the Account Holder cannot use a Mac, the developer machine holds the private key:

### 1. Developer Mac — create a CSR

**Option A — Keychain Access**

1. Keychain Access → **login** keychain  
2. Menu bar: **Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority…**  
3. Email: your developer Apple ID  
4. Common Name: e.g. `Dove Developer ID`  
5. **Saved to disk** → save `.certSigningRequest`  
6. **Keep the private key on this Mac** — it stays in the login keychain automatically

**Option B — Terminal (OpenSSL)**

```bash
openssl genrsa -out ~/Desktop/DoveDeveloperID.key 2048

openssl req -new -key ~/Desktop/DoveDeveloperID.key \
  -out ~/Desktop/DoveDeveloperID.certSigningRequest \
  -subj "/emailAddress=YOUR_APPLE_ID@example.com/CN=Dove Developer ID/C=IN"
```

Send **only** the `.certSigningRequest` to the Account Holder. **Never** send the `.key` file.

### 2. Account Holder — approve on developer.apple.com

1. [Certificates list](https://developer.apple.com/account/resources/certificates/list) (logged in as Account Holder)  
2. **+** → **Developer ID Application**  
3. **G2 Sub-CA (Xcode 11.4.1 or later)**  
4. Upload the `.certSigningRequest` → download `.cer`  
5. Send the `.cer` back to the developer

No Mac required — a web browser on any OS is enough for this step.

### 3. Developer Mac — install the certificate

**If CSR was created in Keychain Access:** double-click the `.cer` → add to **login** keychain.

**If CSR was created with OpenSSL:**

```bash
security import ~/Desktop/DoveDeveloperID.key \
  -k ~/Library/Keychains/login.keychain-db \
  -T /usr/bin/codesign -T /usr/bin/security

security import ~/Desktop/DoveDeveloperID.cer \
  -k ~/Library/Keychains/login.keychain-db \
  -T /usr/bin/codesign -T /usr/bin/security
```

### 4. Alternative — export `.p12` from the Mac that has the cert

If the CSR was created on the Account Holder’s Mac instead:

1. Keychain Access → **login** → **My Certificates**  
2. Expand **Developer ID Application: …** — confirm a **private key** is nested under ▶  
3. Right-click the certificate → **Export…** → **Personal Information Exchange (.p12)**  
4. Transfer the `.p12` securely to the build Mac; install with a **one-time export password** (share password separately, never commit to git)

### 5. Verify

```bash
security find-identity -v -p codesigning | grep "Developer ID Application"
```

Expected: a line containing **Developer ID Application** and your team name.

---

## Xcode signing

1. Open `Dove.xcodeproj`  
2. Target **Dove** → **Signing & Capabilities**  
3. **Team** → your organization team  
4. **Automatically manage signing** → ON  
5. **Product → Archive** — must succeed before running the release script

When macOS prompts *"codesign wants to access key … in your keychain"*, enter your **Mac login password** (not Apple ID or `.p12` password). Choose **Always Allow**.

---

## Notarization (one-time)

1. Create an [app-specific password](https://appleid.apple.com) for your Apple ID  
2. Store credentials in Keychain:

```bash
xcrun notarytool store-credentials "Dove-Notary" \
  --apple-id YOUR_APPLE_ID@example.com \
  --team-id YOUR_TEAM_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

Verify:

```bash
xcrun notarytool history --keychain-profile "Dove-Notary"
```

Use a profile name that matches `NOTARY_PROFILE` in the release script (default example: `Dove-Notary`).

**Never** commit app-specific passwords, `.p12` files, or `.key` files to the repository.

---

## Build a public release

From the repo root:

```bash
DEVELOPMENT_TEAM=YOUR_TEAM_ID NOTARY_PROFILE=Dove-Notary ./scripts/release.sh 1.0.0
```

Optional build number:

```bash
./scripts/release.sh 1.0.0 2
```

### What the script does

1. Bumps version in `app/Info.plist`, `website/public/version.json`, and `website/lib/site-config.ts`  
2. Archives with **Release** configuration  
3. Exports with **Developer ID** (`scripts/ExportOptions.plist`)  
4. Creates `build/Dove-VERSION.dmg`  
5. Notarizes and staples (when `NOTARY_PROFILE` is set)

Output: **`build/Dove-1.0.0.dmg`**

### Local test build (no Developer ID)

For testing on your Mac only — not for public distribution:

```bash
./scripts/release.sh 1.0.0 --local
```

Uses an Apple Development certificate; users will see Gatekeeper warnings.

---

## Publish

### 1. Dogfood

Run through [dogfooding-checklist.md](./dogfooding-checklist.md) on a fresh install from the `.dmg`.

### 2. GitHub Release

```bash
git tag v1.0.0
git push origin v1.0.0
gh release create v1.0.0 build/Dove-1.0.0.dmg --title "Dove 1.0.0"
```

### 3. Website

Deploy so:

- `https://dove.imdeeep.in/version.json` matches the new version and build  
- `/download` serves the latest `.dmg`

Confirm in the app: **Check for Updates** finds the new version.

---

## Troubleshooting

### `release.sh` exits immediately with no output

Fixed in repo: a `set -e` interaction with the old `DMG_PATH` line caused silent exit on public builds. Update to the latest `scripts/release.sh`.

### `hdiutil: create failed - No such file or directory`

Export produced a different app name than `Dove.app` (e.g. a `PRODUCT_NAME` typo in Xcode). The script now falls back to any `.app` in the export folder; ensure **PRODUCT_NAME** is `Dove` in the Xcode target.

### Developer ID not in Xcode **Manage Certificates** menu

Normal on some accounts. Create the cert on [developer.apple.com](https://developer.apple.com/account/resources/certificates/list) instead, or export via **Organizer → Distribute App → Direct Distribution**.

### *"This operation can only be performed by the Account Holder"*

Only the Account Holder can create **Developer ID Application** on organization accounts. Use the CSR handoff workflow above.

### *"certificate is not trusted"* in Keychain

Usually means the cert is under **Certificates** without a paired private key. Check **My Certificates** for cert + key together, or reinstall `.cer` on the Mac that created the CSR.

### Notary submission fails

- Confirm `--team-id` matches the team that signed the app  
- Use an app-specific password, not your Apple ID password  
- Ensure the app was signed with **Developer ID Application**, not Apple Development

### Keychain password prompt during build

Enter your **Mac user account password**. Click **Always Allow**.

---

## Security checklist

- [ ] `.p12`, `.key`, and app-specific passwords are in `.gitignore` or never added to git  
- [ ] Diagnostic logs and support exports redact paths and secrets (built into `DiagnosticLog`)  
- [ ] Rotate or revoke certificates if a `.p12` is exposed  
- [ ] Limit who has Account Holder access on the Developer team

---

## Related docs

- [dogfooding-checklist.md](./dogfooding-checklist.md) — pre-release QA  
- [app-architecture.md](./app-architecture.md) — codebase reference  
- [README.md](../README.md) — project overview
