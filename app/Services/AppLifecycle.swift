import AppKit
import Foundation

/// Bridge between AppKit's termination callback and the SwiftUI-owned services.
/// The App registers a handler at launch; the delegate runs it before quitting.
@MainActor
final class AppTermination {
    static let shared = AppTermination()

    private var handler: (() async -> Void)?
    private var isShuttingDown = false

    private init() {}

    func onTerminate(_ handler: @escaping () async -> Void) {
        self.handler = handler
    }

    /// Returns whether AppKit should wait for us to finish.
    func beginShutdown() -> Bool {
        guard !isShuttingDown, let handler else { return false }
        isShuttingDown = true

        Task { @MainActor in
            await handler()
            NSApp.reply(toApplicationShouldTerminate: true)
        }

        return true
    }
}

@MainActor
final class DoveAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        AppTermination.shared.beginShutdown() ? .terminateLater : .terminateNow
    }
}

/// Winds Dove down in order instead of vanishing mid-task: stop listening, settle
/// any work already in flight, then release the microphone and the HUD.
///
/// Every step is bounded, so quitting is never held up for longer than `gracePeriod`.
@MainActor
enum AppShutdown {
    static func perform(
        hotkeyManager: HotkeyManager,
        audioRecorder: AudioRecorder,
        hudController: HUDController,
        pipeline: PipelineCoordinator?
    ) async {
        // Release the hotkey first so nothing new can start while we are closing.
        hotkeyManager.stop()

        if audioRecorder.isRecording {
            audioRecorder.cancelRecording()
            DiagnosticLog.recordNote("Shutdown discarded an in-progress recording")
        }

        if let pipeline, pipeline.isProcessing {
            let finished = await waitForPipeline(pipeline)
            if !finished {
                pipeline.salvagePendingText()
                DiagnosticLog.recordNote("Shutdown interrupted the pipeline; prompt left on the clipboard")
            }
        }

        hudController.hide()
        RecordingCleanup.cleanupStaleRecordings()
        DiagnosticLog.endSession()
    }

    /// Gives in-flight work a moment to land. Returns false if it outlasts the grace period.
    private static func waitForPipeline(_ pipeline: PipelineCoordinator) async -> Bool {
        let deadline = Date().addingTimeInterval(gracePeriod)

        while pipeline.isProcessing, Date() < deadline {
            try? await Task.sleep(for: .milliseconds(pollInterval))
        }

        return !pipeline.isProcessing
    }

    private static let gracePeriod: TimeInterval = 2.0
    private static let pollInterval = 50
}
