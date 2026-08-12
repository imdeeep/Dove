# Dogfooding Checklist

Run through this before each public release. See also **[release.md](./release.md)** and **[docs/README.md](./README.md)**.

Check every box.

## Release artifact

Verify the build before installing it. Commands in [release.md → Verify the published download](./release.md#4-verify-the-published-download).

- [ ] `.dmg` downloaded through `dove.imdeeep.in/download`, not the local `build/` copy
- [ ] SHA-256 matches the GitHub release asset digest
- [ ] `xcrun stapler validate` passes on the `.dmg`
- [ ] `spctl` reports `accepted` / `source=Notarized Developer ID` for the `.dmg`
- [ ] `spctl` reports the same for `Dove.app` **inside** the mounted image
- [ ] DMG window opens styled: large icons, Dove left, Applications right
- [ ] `version.json` on the live site matches the version, build, and `dmgSizeBytes`

## Setup

- [ ] Fresh install from `.dmg` on macOS 14+
- [ ] Dragged to `/Applications` and the disk ejected (never run from the DMG)
- [ ] No Gatekeeper warning on first launch
- [ ] Welcome window appears on first launch
- [ ] Microphone permission granted
- [ ] Accessibility permission granted
- [ ] Accessibility row turns green on its own after toggling, without relaunching
- [ ] Whisper model downloads (Speech preferences)
- [ ] API key saved (AI Provider preferences)

If the Accessibility row stays incomplete while System Settings shows it enabled, an older build left a stale record — see [release.md → Accessibility toggle is on but the app says permission is missing](./release.md#accessibility-toggle-is-on-but-the-app-says-permission-is-missing). Test on a Mac that has **never** run a development build to catch this the way a real user would.

## Core pipeline

- [ ] Hotkey starts recording (HUD + waveform)
- [ ] Hotkey stops recording
- [ ] Transcription completes (check Xcode console)
- [ ] Polish completes with valid API key
- [ ] Raw transcript inserts when no API key
- [ ] Success HUD appears and dismisses
- [ ] Sound effects play (if enabled)



## Smart typing

- [ ] Word-by-word insertion enabled in Preferences
- [ ] Text types gradually into target field
- [ ] Switch apps mid-typing — remainder lands correctly or on clipboard



## Target apps


| App               | Insert works | Notes            |
| ----------------- | ------------ | ---------------- |
| Cursor (chat)     | ☐            | Primary target   |
| Cursor (editor)   | ☐            |                  |
| VS Code           | ☐            |                  |
| TextEdit          | ☐            | Baseline         |
| Chrome (textarea) | ☐            | e.g. ChatGPT web |
| Safari (textarea) | ☐            |                  |




## Error handling

- [ ] Deny mic — friendly HUD message
- [ ] No Accessibility — clipboard fallback message
- [ ] Invalid API key — polish falls back to raw transcript
- [ ] Empty recording — "nothing heard" message
- [ ] HUD never stuck spinning (watchdog fires after timeout)



## Updates & lifecycle

- [ ] **Check for Updates** — up to date message on current version
- [ ] **Check for Updates** — opens download when `version.json` is newer
- [ ] Quit during processing — graceful shutdown, prompt on clipboard if needed
- [ ] Relaunch — Whisper loads from cache (no re-download)



## Preferences

- [ ] Hotkey rebinding works
- [ ] Provider switch + model refresh
- [ ] Launch at login toggle
- [ ] Diagnostic export creates readable report
- [ ] Delete logs clears stored diagnostics



## Website

- [ ] dove.imdeeep.in loads
- [ ] Download button reaches GitHub Release
- [ ] `/version.json` matches app version after release
- [ ] `/download` returns the full file — compare `size_download` against the release asset size

## Sign-off

- Tester: _______________
- Version: _______________
- Date: _______________
- Blockers: _______________

