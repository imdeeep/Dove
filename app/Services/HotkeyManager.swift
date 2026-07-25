// Global toggle-to-record via CGEvent tap.
// Press hotkey once to start, press again to stop. Requires Accessibility permission.

import ApplicationServices
import Foundation
import Observation

@MainActor
@Observable
final class HotkeyManager {
    var isAccessibilityTrusted = false
    var isHotkeyActive = false

    private weak var hudController: HUDController?

    var hudState: HUDState {
        hudController?.state ?? .idle
    }

    /// Returns nil when recording started, or a user-facing message explaining why it did not.
    var onRecordingStarted: (() -> String?)?
    var onRecordingStopped: (() -> Void)?
    var onRecordingCancelled: (() -> Void)?

    private var settings: AppSettings?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private enum RecordingPhase {
        case idle
        case starting
        case recording
    }

    private let stateLock = NSLock()
    private var cachedBinding: HotkeyBinding = .default
    private var callbackPhase: RecordingPhase = .idle
    private var suppressReleaseUntil: Date?

    private var phase: RecordingPhase = .idle
    private var pendingStartWorkItem: DispatchWorkItem?
    private var lastToggleAt: Date?

    private static let recordingStartDelay: TimeInterval = 0.12
    private static let toggleDebounce: TimeInterval = 0.25
    private static let releaseSuppression: TimeInterval = 0.5

    func configure(settings: AppSettings, hudController: HUDController) {
        self.settings = settings
        self.hudController = hudController
        syncBindingForCallback()
    }

    private var hotkeyBinding: HotkeyBinding {
        settings?.hotkeyBinding ?? .default
    }

    /// Call on launch and after returning from System Settings.
    func refreshPermissionsAndStart(prompt: Bool = true) {
        syncBindingForCallback()
        isAccessibilityTrusted = PermissionsHelper.requestAccessibility(prompt: prompt)

        guard isAccessibilityTrusted else {
            isHotkeyActive = false
            log("Accessibility permission required - enable Dove in System Settings → Privacy → Accessibility")
            return
        }

        if eventTap == nil {
            installEventTap()
        } else if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
            isHotkeyActive = true
        }

        if isHotkeyActive {
            log("Hotkey active: \(hotkeyBinding.displayString) (toggle)")
        }
    }

    func stop() {
        pendingStartWorkItem?.cancel()
        pendingStartWorkItem = nil

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        eventTap = nil
        self.runLoopSource = nil
        isHotkeyActive = false
        resetRecording()
    }

    func cancelRecording() {
        guard phase == .recording else { return }
        resetRecording()
        onRecordingCancelled?()
        log("recording cancelled")
    }

    private func installEventTap() {
        stop()

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: HotkeyManager.eventTapCallback,
            userInfo: userInfo
        ) else {
            isHotkeyActive = false
            log("Failed to create event tap - check Accessibility permission and restart the app")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isHotkeyActive = true
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, refcon in
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let refcon {
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                DispatchQueue.main.async {
                    if let tap = manager.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                }
            }
            return Unmanaged.passUnretained(event)
        }

        guard let refcon else {
            return Unmanaged.passUnretained(event)
        }

        let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let isAutorepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0

        let snapshot: (HotkeyBinding, RecordingPhase, Date?) = {
            manager.stateLock.lock()
            defer { manager.stateLock.unlock() }
            return (manager.cachedBinding, manager.callbackPhase, manager.suppressReleaseUntil)
        }()

        let consume = shouldConsumeEvent(
            type: type,
            keyCode: keyCode,
            flags: flags,
            isAutorepeat: isAutorepeat,
            binding: snapshot.0,
            phase: snapshot.1,
            suppressReleaseUntil: snapshot.2
        )

        if consume {
            DispatchQueue.main.async {
                manager.processKeyboardEvent(type: type, keyCode: keyCode, flags: flags, isAutorepeat: isAutorepeat)
            }
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private static func shouldConsumeEvent(
        type: CGEventType,
        keyCode: CGKeyCode,
        flags: CGEventFlags,
        isAutorepeat: Bool,
        binding: HotkeyBinding,
        phase: RecordingPhase,
        suppressReleaseUntil: Date?
    ) -> Bool {
        switch type {
        case .keyDown:
            guard keyCode == binding.keyCode else { return false }
            guard !isAutorepeat else { return phase == .recording }
            return binding.matches(keyCode: keyCode, flags: flags)

        case .keyUp, .flagsChanged:
            guard let suppressReleaseUntil, Date() < suppressReleaseUntil else { return false }
            if type == .keyUp {
                return keyCode == binding.keyCode || binding.involvesModifierKeyCode(keyCode)
            }
            return true

        default:
            return false
        }
    }

    private func processKeyboardEvent(
        type: CGEventType,
        keyCode: CGKeyCode,
        flags: CGEventFlags,
        isAutorepeat: Bool
    ) {
        syncBindingForCallback()

        switch type {
        case .keyDown:
            guard hotkeyBinding.matches(keyCode: keyCode, flags: flags) else { return }
            guard !isAutorepeat else { return }
            toggleRecording()

        default:
            break
        }
    }

    private func toggleRecording() {
        if let lastToggleAt,
           Date().timeIntervalSince(lastToggleAt) < Self.toggleDebounce {
            return
        }
        lastToggleAt = Date()
        markReleaseSuppression()

        switch phase {
        case .idle:
            startRecording()
        case .starting:
            cancelPendingStart()
        case .recording:
            finishRecording()
        }
    }

    private func startRecording() {
        guard phase == .idle else { return }

        phase = .starting
        syncPhaseForCallback()

        pendingStartWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.activateRecording()
        }
        pendingStartWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.recordingStartDelay, execute: work)
    }

    private func activateRecording() {
        pendingStartWorkItem = nil
        guard phase == .starting else { return }

        guard let startRecording = onRecordingStarted else {
            resetRecording()
            hudController?.showError(HUDErrorMessage.generic)
            log("recording failed to start - no recorder attached")
            return
        }

        if let failureMessage = startRecording() {
            resetRecording()
            hudController?.showError(failureMessage)
            log("recording failed to start")
            return
        }

        guard phase == .starting else {
            onRecordingCancelled?()
            resetRecording()
            return
        }

        phase = .recording
        hudController?.showListening(startedAt: Date())
        syncPhaseForCallback()
        log("recording started - press \(hotkeyBinding.displayString) again to stop")
    }

    private func cancelPendingStart() {
        pendingStartWorkItem?.cancel()
        pendingStartWorkItem = nil
        resetRecording()
        log("recording start cancelled")
    }

    private func finishRecording() {
        guard phase == .recording else { return }
        pendingStartWorkItem?.cancel()
        pendingStartWorkItem = nil
        phase = .idle
        syncPhaseForCallback()
        log("recording stopped")
        onRecordingStopped?()
    }

    private func resetRecording() {
        pendingStartWorkItem?.cancel()
        pendingStartWorkItem = nil
        phase = .idle
        syncPhaseForCallback()
        hudController?.hide()
    }

    private func markReleaseSuppression() {
        stateLock.lock()
        suppressReleaseUntil = Date().addingTimeInterval(Self.releaseSuppression)
        stateLock.unlock()
    }

    private func syncBindingForCallback() {
        stateLock.lock()
        cachedBinding = hotkeyBinding
        stateLock.unlock()
    }

    private func syncPhaseForCallback() {
        stateLock.lock()
        callbackPhase = phase
        stateLock.unlock()
    }

    private func log(_ message: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date())
        print("[VoicePrompt] \(timestamp) \(message)")
    }
}
