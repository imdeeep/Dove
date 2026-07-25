# Dove

**Speak it. Dove writes it.**

Dove is a free, open-source macOS menu bar app that turns speech into polished prompts and inserts them exactly where your cursor is — in any app.

**[Download for Mac](https://dove.duckdns.org/)** · [Website](https://dove.duckdns.org) · [Releases](https://github.com/mandeep7yadav/dove/releases)

Built by [Mandeep](https://www.linkedin.com/in/mandeep7yadav).

---

## What Dove offers

- **Local speech recognition** — WhisperKit runs on your Mac. After the first model download, transcription works offline.
- **AI polishing** — Clean up fillers, fix grammar, and format technical terms using your choice of 11 cloud providers (OpenAI, Anthropic, Gemini, Groq, OpenRouter, DeepSeek, Kimi, GLM, xAI, Mistral, or a custom OpenAI-compatible endpoint).
- **Smart insertion** — Types the result at your cursor. Word-by-word mode makes it feel like natural typing; focus tracking stops mid-stream if you switch apps.
- **Menu bar native** — Lives in the status bar. No Dock icon, no account, no analytics.
- **Privacy by design** — Audio stays local for transcription. API keys live in macOS Keychain. Diagnostics log errors only — never your speech or prompts.
- **Graceful fallbacks** — No API key? You still get the raw transcript. Polish fails? Raw transcript. Insertion fails? Copied to clipboard.

---

## How it works

1. **Press your shortcut once** to start recording (default: **⌃⇧Space**).
2. **Speak naturally** — um, like, whatever you actually mean to say.
3. **Press the shortcut again** to stop.
4. Dove transcribes locally with Whisper, optionally polishes with your AI provider, and inserts the result where your cursor was.

```
Hotkey → Record → Whisper (local) → AI polish (optional) → Insert at cursor
```

A small HUD at the bottom of the screen shows listening, transcribing, polishing, and success states.

**Without an API key**, Dove skips the polish step and inserts the raw Whisper transcript — still useful on its own.

---

## Requirements

| | |
|---|---|
| **macOS** | 14 (Sonoma) or later |
| **Hardware** | Apple Silicon recommended |
| **Permissions** | Microphone (recording) and Accessibility (global hotkey + text insertion) |
| **Network** | Required once to download a Whisper model; optional for AI polish |

---

## User setup

### Install

1. Download the latest `.dmg` from [dove.duckdns.org/download](https://dove.duckdns.org/download) or [GitHub Releases](https://github.com/mandeep7yadav/dove/releases).
2. Open the DMG and drag **Dove** to Applications.
3. Launch Dove from Applications. It appears in the menu bar.

On first launch, the **Welcome** window walks you through microphone and Accessibility permissions.

### Configure (optional but recommended)

Open **Preferences** from the menu bar:

| Pane | What to set |
|------|-------------|
| **General** | Launch at login, word-by-word typing, sound effects |
| **Speech** | Whisper model size and language |
| **Hotkey** | Recording shortcut |
| **AI Provider** | Provider, API key, model, temperature |
| **Contact** | Support email and diagnostic logs |

Without an API key, Dove uses the raw transcript. With a key, Dove sends only the transcript text to your chosen provider for cleanup — not your audio.

### Check for updates

Menu bar → **Check for Updates**. Dove compares against [version.json](https://dove.duckdns.org/version.json) on the website.

---

## Development setup

### Prerequisites

- macOS 14+
- Xcode 15+
- Node.js 20+ (for the website only)

### Build the app

```bash
git clone https://github.com/mandeep7yadav/dove.git
cd dove
open Dove.xcodeproj
```

Select the **Dove** scheme and press **⌘R**.

Grant **Microphone** and **Accessibility** when prompted. If Accessibility was enabled before a rebuild, remove Dove from System Settings → Privacy → Accessibility, quit, rebuild, and re-enable.

### Run the website locally

```bash
cd website
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000). Copy `website/.env.example` to `.env.local` and fill in URLs if needed.

### Release a version

```bash
./scripts/release.sh 1.0.0
```

This bumps `app/Info.plist`, `website/public/version.json`, and `website/lib/site-config.ts`, then archives and exports a signed `.dmg`. See [scripts/release.sh](scripts/release.sh) and [docs/deploy-website.md](docs/deploy-website.md) for notarization and deployment details.

---

## Project structure

```
dove/
├── app/                  macOS app source (Swift)
├── Dove.xcodeproj        Xcode project
├── website/              Next.js marketing site
├── docs/                 Architecture, deployment, and QA docs
├── assets/               Shared branding (dove.png)
└── scripts/              Release and export helpers
```

---

## Contributing

Contributions are welcome. Dove is [MIT licensed](LICENSE) — you can use, modify, and distribute it freely.

### Ways to contribute

- **Report bugs** — [Open an issue](https://github.com/mandeep7yadav/dove/issues) with steps to reproduce, macOS version, and an exported diagnostic report (Preferences → Contact → Export Report).
- **Suggest features** — Open an issue describing the problem you want solved, not just the solution.
- **Submit code** — Fork the repo, create a branch, and open a pull request.

### Pull request guidelines

1. **One concern per PR** — A bug fix, a feature, or a doc update. Not all three.
2. **Match existing style** — Read surrounding Swift or TypeScript before editing. No drive-by refactors.
3. **Test on macOS** — Build with Xcode and verify the hotkey → record → transcribe → insert flow.
4. **Keep secrets out** — Never commit API keys, `.env.local`, or credentials.
5. **Update docs** — If you change behavior, update the relevant doc (especially `docs/app-architecture.md` for app changes).

### Development notes

- Default hotkey is **⌃⇧Space** (Control+Shift+Space), defined in `app/Models/HotkeyBinding.swift`.
- Whisper models download to `~/Documents/huggingface/` on first use.
- The master polish prompt lives in `app/Models/PromptDefaults.swift` and is not user-editable by design.

---

## Support

- **Email:** [mandeep7yadav@gmail.com](mailto:mandeep7yadav@gmail.com)
- **Issues:** [GitHub Issues](https://github.com/mandeep7yadav/dove/issues)
- **Diagnostics:** Preferences → Contact → Export Report (errors only, no speech or prompts)

---

## License

Dove is open-source software released under the **[MIT License](LICENSE)**.

You are free to use, copy, modify, merge, publish, distribute, sublicense, and sell copies of Dove, subject to including the copyright notice and license text in any distribution.

```
Copyright (c) 2026 Mandeep
SPDX-License-Identifier: MIT
```

Third-party dependencies (including [WhisperKit](https://github.com/argmaxinc/WhisperKit)) are subject to their own licenses.
