# Building Dove from source

Dove is open source under the [MIT License](../LICENSE). You can clone, build, and run it on your Mac without a paid Apple Developer account or a notarized `.dmg`.

---

## Requirements

| | |
|---|---|
| **macOS** | 14 (Sonoma) or later |
| **Xcode** | 15 or later |
| **Apple ID** | Free account for Xcode signing (Personal Team) |
| **Hardware** | Apple Silicon recommended for Whisper performance |

---

## Clone and open

```bash
git clone https://github.com/mandeep7yadav/dove.git
cd dove
open Dove.xcodeproj
```

---

## Signing (first time)

1. Xcode → **Settings → Accounts** → add your Apple ID  
2. Select the **Dove** target → **Signing & Capabilities**  
3. **Team** → your **Personal Team** (or your org team if you have one)  
4. **Automatically manage signing** → ON  

Xcode may change the bundle identifier for Personal Team builds. That is fine for local development.

---

## Run from Xcode

1. Scheme: **Dove**  
2. Destination: **My Mac**  
3. Press **⌘R**

Grant **Microphone** and **Accessibility** when prompted.

If Accessibility was enabled before a rebuild, remove Dove from **System Settings → Privacy & Security → Accessibility**, quit Dove, rebuild, and re-enable.

---

## Speech model (first run)

1. Menu bar → **Preferences → Speech**  
2. Choose a model (e.g. **Small (English)**)  
3. Click **Download Now** or **Load Model**  

Models are stored in `~/Documents/huggingface/` and work offline after download.

---

## Local test DMG (optional)

Creates an unsigned `.dmg` for testing on your Mac only — **not** for public distribution:

```bash
./scripts/release.sh 1.0.0 --local
```

Output: `build/Dove-1.0.0-local.dmg`

Users who open unsigned builds may need **right-click → Open** the first time (Gatekeeper).

---

## Public release (maintainers)

Signed, notarized builds for [dove.imdeeep.in](https://dove.imdeeep.in) and GitHub Releases require:

- Apple Developer Program membership  
- **Developer ID Application** certificate  
- Notarization via `notarytool`  

See **[release.md](./release.md)** for the full process.

---

## Website (optional)

```bash
cd website
npm install
cp .env.example .env.local   # edit URLs if needed
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

---

## Troubleshooting

### Speech model shows “Already downloaded” but won’t load

The on-disk model may be incomplete. In Preferences → Speech, use **Repair Model** / **Download Now** to re-fetch. See `WhisperModelCache` validation in the codebase.

### Hotkey does not fire

Check **Accessibility** permission and that no other app uses the same shortcut.

### Build errors after pulling

**Product → Clean Build Folder** (⇧⌘K), then rebuild. Resolve Swift Package dependencies via **File → Packages → Reset Package Caches** if needed.

---

## Next steps

- **[app-architecture.md](./app-architecture.md)** — How the app is structured  
- **[README.md → Contributing](../README.md#contributing)** — Pull request guidelines  
- **[docs/README.md](./README.md)** — Full documentation index
