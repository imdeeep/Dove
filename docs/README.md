# Dove documentation

Dove is a **free, open-source** macOS menu bar app ([MIT License](../LICENSE)). This folder is the technical reference for contributors, maintainers, and anyone building from source.

---

## Start here

| I want to… | Read |
|------------|------|
| **Use Dove** (download & install) | [README → User setup](../README.md#user-setup) |
| **Build Dove from source** (no signed DMG needed) | [build-from-source.md](./build-from-source.md) |
| **Understand the codebase** | [app-architecture.md](./app-architecture.md) |
| **Contribute code or report bugs** | [README → Contributing](../README.md#contributing) |
| **Ship a signed release** (maintainers) | [release.md](./release.md) |
| **Deploy the website** | [deploy-website.md](./deploy-website.md) |

---

## Documentation index

### Users

- **[README.md](../README.md)** — Product overview, install, permissions, preferences, support

### Developers & contributors

- **[build-from-source.md](./build-from-source.md)** — Clone, build in Xcode, run locally, local test DMG
- **[app-architecture.md](./app-architecture.md)** — Full app reference: flows, every Swift file, dependencies
- **[dogfooding-checklist.md](./dogfooding-checklist.md)** — Manual QA checklist before shipping

### Maintainers

- **[release.md](./release.md)** — Developer ID signing, notarization, `release.sh`, GitHub Releases, website deploy
- **[deploy-website.md](./deploy-website.md)** — Vercel env vars, `/download`, post-release deploy

### Website

- **[website/README.md](../website/README.md)** — Next.js marketing site (local dev)
- **[deploy-website.md](./deploy-website.md)** — Production env and deploy checklist
- **Live site:** [dove.imdeeep.in](https://dove.imdeeep.in)

---

## Open source

Dove is MIT licensed. You may:

- Use, modify, and redistribute the code
- Build and run Dove without paying Apple (Xcode + free Apple ID is enough for local development)
- Fork the project and ship your own builds (follow the license and third-party notices)

**Public `.dmg` distribution** (no Gatekeeper warnings) requires an [Apple Developer Program](https://developer.apple.com/programs/) membership and notarization — see [release.md](./release.md). That cost applies to *distribution*, not to *using or hacking on* the source.

---

## Project layout

```
dove/
├── app/              macOS app (Swift, SwiftUI, AppKit)
├── Dove.xcodeproj    Xcode project
├── website/          Next.js site + /download + version.json
├── docs/             This folder
├── scripts/          release.sh, ExportOptions.plist
├── assets/           Branding
└── LICENSE           MIT
```

---

## Keeping docs up to date

When you change behavior, update the relevant doc in the same PR:

| Change type | Update |
|-------------|--------|
| New Swift file or flow | `app-architecture.md` |
| Release / signing process | `release.md` |
| Build or clone steps | `build-from-source.md`, `README.md` |
| User-facing install or features | `README.md`, website copy |
