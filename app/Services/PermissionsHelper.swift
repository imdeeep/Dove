import AppKit
import ApplicationServices
import AVFoundation
import Foundation

enum PermissionsHelper {
    enum MicrophoneStatus {
        case authorized
        case notDetermined
        case denied
        case restricted
    }

    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    static var microphoneStatus: MicrophoneStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return .authorized
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }

    static func requestAccessibility(prompt: Bool) -> Bool {
        let trusted: Bool
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            trusted = AXIsProcessTrustedWithOptions(options)
        } else {
            trusted = AXIsProcessTrusted()
        }

        #if DEBUG
        if !trusted {
            let path = Bundle.main.bundlePath
            print("[VoicePrompt] Accessibility not granted for process at: \(path)")
            print("[VoicePrompt] If already enabled in Settings, remove Dove from the list, quit the app, rebuild, and enable again.")
        }
        #endif

        return trusted
    }

    @MainActor
    static func requestMicrophoneAccess() async -> Bool {
        switch microphoneStatus {
        case .authorized:
            return true
        case .notDetermined:
            NSApp.activate(ignoringOtherApps: true)
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    DispatchQueue.main.async {
                        continuation.resume(returning: granted)
                    }
                }
            }
        case .denied, .restricted:
            return false
        }
    }

    static func openAccessibilitySettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        ]
        openFirstAvailableSettingsURL(urls)
    }

    static func openMicrophoneSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone",
        ]
        openFirstAvailableSettingsURL(urls)
    }

    private static func openFirstAvailableSettingsURL(_ urlStrings: [String]) {
        for urlString in urlStrings {
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
                return
            }
        }
    }
}
