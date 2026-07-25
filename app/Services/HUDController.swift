import AppKit
import Observation
import SwiftUI

@Observable
@MainActor
final class HUDController {
    private(set) var state: HUDState = .idle

    private var panel: NSPanel?
    private var hostingView: NSHostingView<HUDPanelView>?
    private var dismissTask: Task<Void, Never>?
    private var watchdogTask: Task<Void, Never>?
    private weak var audioRecorder: AudioRecorder?
    private weak var settings: AppSettings?
    private var isPanelVisible = false
    private var screenParametersObserver: NSObjectProtocol?

    private static let panelWidth: CGFloat = 320
    private static let panelHeight: CGFloat = 48

    func install(audioRecorder: AudioRecorder, settings: AppSettings) {
        guard panel == nil else { return }
        self.audioRecorder = audioRecorder
        self.settings = settings

        let rootView = HUDPanelView(controller: self, audioRecorder: audioRecorder)
        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        hosting.layer?.isOpaque = false

        let panel = NSPanel(
            contentRect: hosting.frame,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.contentView = hosting
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView?.layer?.isOpaque = false

        self.panel = panel
        self.hostingView = hosting

        screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.state != .idle else { return }
                self.repositionPanel()
            }
        }
    }

    func showListening(startedAt: Date = Date()) {
        cancelDismiss()
        cancelWatchdog()
        state = .listening(startedAt: startedAt)
        presentPanel()
    }

    func showProcessing(_ step: ProcessingStep) {
        cancelDismiss()
        state = .processing(step)
        presentPanel()
        startWatchdog(for: step)
    }

    func showSuccess() {
        cancelDismiss()
        cancelWatchdog()
        state = .success
        presentPanel()
        scheduleDismiss(after: 1.0)
    }

    func showError(_ message: String) {
        cancelDismiss()
        cancelWatchdog()
        state = .error(message.isEmpty ? HUDErrorMessage.generic : message)
        presentPanel()
        scheduleDismiss(after: 2.5)
    }

    func dismissEarly() {
        hide()
    }

    func hide() {
        let shouldPlayDismiss = isPanelVisible
        cancelDismiss()
        cancelWatchdog()
        state = .idle
        panel?.orderOut(nil)
        isPanelVisible = false
        if shouldPlayDismiss {
            SoundEffects.playHUDDismiss(enabled: settings?.soundEffectsEnabled ?? true)
        }
    }

    private func presentPanel() {
        guard let panel else { return }
        let shouldPlayAppear = !isPanelVisible
        resizePanelToFit()
        repositionPanel()
        panel.orderFrontRegardless()
        isPanelVisible = true
        if shouldPlayAppear {
            SoundEffects.playHUDAppear(enabled: settings?.soundEffectsEnabled ?? true)
        }
    }

    private func resizePanelToFit() {
        guard let hostingView, let panel else { return }
        hostingView.frame = NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight)
        panel.setContentSize(NSSize(width: Self.panelWidth, height: Self.panelHeight))
    }

    private func repositionPanel() {
        guard let panel, let screen = HUDPlacement.targetScreen() else { return }
        let origin = HUDPlacement.bottomCenterOrigin(
            panelSize: panel.frame.size,
            on: screen
        )
        panel.setFrameOrigin(origin)
    }

    private func scheduleDismiss(after seconds: TimeInterval) {
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            hide()
        }
    }

    private func cancelDismiss() {
        dismissTask?.cancel()
        dismissTask = nil
    }

    /// A stage that never reports back - a killed task, a wedged model load - would
    /// otherwise leave the HUD spinning forever. The watchdog always lands it.
    private func startWatchdog(for step: ProcessingStep) {
        watchdogTask?.cancel()
        let timeout = Self.watchdogTimeout(for: step)

        watchdogTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(timeout))
            guard !Task.isCancelled, let self else { return }
            guard case .processing(let current) = state, current == step else { return }

            ErrorReporter.report("HUD \(step)", reason: "no result after \(Int(timeout))s")
            showError(HUDErrorMessage.generic)
        }
    }

    private func cancelWatchdog() {
        watchdogTask?.cancel()
        watchdogTask = nil
    }

    /// Transcribing can include a first-run model download, so it gets far more room.
    private static func watchdogTimeout(for step: ProcessingStep) -> TimeInterval {
        switch step {
        case .transcribing: return 300
        case .polishing: return 60
        case .inserting: return 120
        }
    }
}
