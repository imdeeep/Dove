# Dogfooding Checklist

Run through this before each public release. Check every box.

## Setup

- [ ] Fresh install from `.dmg` on macOS 14+
- [ ] Welcome window appears on first launch
- [ ] Microphone permission granted
- [ ] Accessibility permission granted
- [ ] Whisper model downloads (Speech preferences)
- [ ] API key saved (AI Provider preferences)

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

- [ ] dove.duckdns.org loads
- [ ] Download button reaches GitHub Release
- [ ] `/version.json` matches app version after release



## Sign-off

- Tester: _______________
- Version: _______________
- Date: _______________
- Blockers: _______________

