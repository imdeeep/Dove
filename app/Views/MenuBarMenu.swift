import AppKit
import SwiftUI

struct MenuBarMenu: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    @Environment(\.audioRecorder) private var audioRecorder
    @Environment(AppSettings.self) private var settings
    @Environment(HotkeyManager.self) private var hotkeyManager

    var body: some View {
        Text("Dove is running")
            .disabled(true)

        if hotkeyManager.isHotkeyActive {
            Text("Hotkey: \(settings.hotkeyBinding.displayString) - tap to record")
                .font(.caption)
                .disabled(true)

            if hotkeyManager.hudState.isListening {
                Text("Recording… tap hotkey again to stop")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .disabled(true)
            }

            if hotkeyManager.hudState.isProcessing {
                Text("Transcribing…")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .disabled(true)
            }

            if PermissionsHelper.microphoneStatus != .authorized {
                Text("Microphone access required for recording")
                    .font(.caption)
                    .disabled(true)

                Button("Allow Microphone Access…") {
                    Task { @MainActor in
                        let granted = await PermissionsHelper.requestMicrophoneAccess()
                        if granted {
                            await audioRecorder?.prepareIfNeeded()
                        } else {
                            PermissionsHelper.openMicrophoneSettings()
                        }
                    }
                }
            }
        } else if !hotkeyManager.isAccessibilityTrusted {
            Text("Accessibility required for hotkey")
                .font(.caption)
                .disabled(true)

            Button("Open Accessibility Settings…") {
                PermissionsHelper.openAccessibilitySettings()
            }

            Button("Retry After Enabling") {
                hotkeyManager.refreshPermissionsAndStart(prompt: false)
            }

            Button("Quit Dove") {
                NSApplication.shared.terminate(nil)
            }
        } else {
            Text("Hotkey failed to start - retry")
                .font(.caption)
                .disabled(true)

            Button("Retry Hotkey") {
                hotkeyManager.refreshPermissionsAndStart(prompt: false)
            }
        }

        Divider()

        Button("Welcome to Dove…") {
            WelcomeWindow.present(using: openWindow)
        }

        Button("Preferences…") {
            openSettings()
        }

        Button("Check for Updates…") {
            Task { @MainActor in
                let result = await UpdateChecker.checkForUpdates()
                UpdateChecker.presentResult(result)
            }
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
