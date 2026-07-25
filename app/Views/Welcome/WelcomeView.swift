import AppKit
import SwiftUI

enum WelcomeWindow {
    static let id = "dove.welcome"

    /// Dove is an accessory app, so the window needs an explicit activation to come forward.
    @MainActor
    static func present(using openWindow: OpenWindowAction) {
        openWindow(id: id)
        NSApp.activate()
    }
}

/// First-run window: introduces Dove and walks through the two permissions it needs.
struct WelcomeView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(HotkeyManager.self) private var hotkeyManager
    @Environment(\.audioRecorder) private var audioRecorder
    @Environment(\.dismiss) private var dismiss

    @State private var microphoneGranted = PermissionsHelper.microphoneStatus == .authorized
    @State private var accessibilityGranted = PermissionsHelper.isAccessibilityTrusted

    private let pollTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        @Bindable var settings = settings

        VStack(spacing: 24) {
            header
            steps
                .animation(.easeOut(duration: 0.18), value: microphoneGranted)
                .animation(.easeOut(duration: 0.18), value: accessibilityGranted)
            footer(showAtLaunch: $settings.showWelcomeAtLaunch)
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 20)
        .frame(width: 460)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            settings.hasCompletedWelcome = true
            refreshPermissions()
        }
        .onReceive(pollTimer) { _ in refreshPermissions() }
    }

    private var header: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 84, height: 84)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Welcome to Dove")
                    .font(.system(size: 22, weight: .semibold))

                Text("Speak your thought and Dove turns it into a clean, polished prompt - typed right where you are working.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var steps: some View {
        VStack(spacing: 0) {
            WelcomeStepRow(
                systemImage: "mic.fill",
                title: "Microphone",
                detail: "Needed to hear you while you hold the shortcut.",
                isComplete: microphoneGranted,
                actionTitle: "Allow",
                action: requestMicrophone
            )

            Divider().padding(.leading, 54)

            WelcomeStepRow(
                systemImage: "accessibility",
                title: "Accessibility",
                detail: "Lets Dove listen for the shortcut and type into other apps.",
                isComplete: accessibilityGranted,
                actionTitle: "Open Settings",
                action: requestAccessibility
            )

            Divider().padding(.leading, 54)

            WelcomeStepRow(
                systemImage: "command",
                title: "Press \(settings.hotkeyBinding.displayString)",
                detail: "Tap once to start recording, tap again to stop. Everything else is automatic.",
                isComplete: nil,
                actionTitle: nil,
                action: nil
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
    }

    private func footer(showAtLaunch: Binding<Bool>) -> some View {
        VStack(spacing: 12) {
            Button("Get Started") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Toggle("Show this window at launch", isOn: showAtLaunch)
                .toggleStyle(.checkbox)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func refreshPermissions() {
        let mic = PermissionsHelper.microphoneStatus == .authorized
        let accessibility = PermissionsHelper.isAccessibilityTrusted

        if mic != microphoneGranted { microphoneGranted = mic }
        if accessibility != accessibilityGranted {
            accessibilityGranted = accessibility
            if accessibility && !hotkeyManager.isHotkeyActive {
                hotkeyManager.refreshPermissionsAndStart(prompt: false)
            }
        }
    }

    private func requestMicrophone() {
        Task { @MainActor in
            let granted = await PermissionsHelper.requestMicrophoneAccess()
            if granted {
                await audioRecorder?.prepareIfNeeded()
            } else {
                PermissionsHelper.openMicrophoneSettings()
            }
            refreshPermissions()
        }
    }

    private func requestAccessibility() {
        _ = PermissionsHelper.requestAccessibility(prompt: true)
        PermissionsHelper.openAccessibilitySettings()
    }
}

private struct WelcomeStepRow: View {
    let systemImage: String
    let title: String
    let detail: String
    /// `nil` for informational rows that have nothing to complete.
    let isComplete: Bool?
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 22, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            trailing
                .padding(.top, 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var trailing: some View {
        if isComplete == true {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.green)
                .transition(.opacity)
                .accessibilityLabel("Granted")
        } else if let actionTitle, let action {
            Button(actionTitle, action: action)
                .controlSize(.small)
        }
    }
}

#Preview("Welcome") {
    WelcomeView()
        .environment(AppSettings())
        .environment(HotkeyManager())
}
