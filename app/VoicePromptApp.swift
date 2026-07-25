import SwiftUI

private struct AudioRecorderEnvironmentKey: EnvironmentKey {
    static let defaultValue: AudioRecorder? = nil
}

private struct HUDControllerEnvironmentKey: EnvironmentKey {
    static let defaultValue: HUDController? = nil
}

private struct TranscriptionServiceEnvironmentKey: EnvironmentKey {
    static let defaultValue: TranscriptionService? = nil
}

extension EnvironmentValues {
    var audioRecorder: AudioRecorder? {
        get { self[AudioRecorderEnvironmentKey.self] }
        set { self[AudioRecorderEnvironmentKey.self] = newValue }
    }

    var hudController: HUDController? {
        get { self[HUDControllerEnvironmentKey.self] }
        set { self[HUDControllerEnvironmentKey.self] = newValue }
    }

    var transcriptionService: TranscriptionService? {
        get { self[TranscriptionServiceEnvironmentKey.self] }
        set { self[TranscriptionServiceEnvironmentKey.self] = newValue }
    }
}

@main
struct VoicePromptApp: App {
    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(DoveAppDelegate.self) private var appDelegate
    @State private var settings = AppSettings()
    @State private var hotkeyManager = HotkeyManager()
    @State private var audioRecorder = AudioRecorder()
    @State private var transcriptionService = TranscriptionService()
    @State private var hudController = HUDController()
    @State private var pipelineCoordinator: PipelineCoordinator?
    @State private var didBootstrap = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu()
                .environment(settings)
                .environment(hotkeyManager)
                .environment(hudController)
                .environment(\.audioRecorder, audioRecorder)
                .environment(\.transcriptionService, transcriptionService)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    if !hotkeyManager.isHotkeyActive {
                        hotkeyManager.refreshPermissionsAndStart(prompt: false)
                    }
                    Task { await audioRecorder.prepareIfNeeded() }
                }
        } label: {
            // The menu content is built lazily on first open, so bootstrap from the
            // status item label - it is the only part rendered at launch.
            Image("MenuBarIcon")
                .accessibilityLabel("Dove")
                .onAppear(perform: bootstrap)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            PreferencesView()
                .environment(settings)
                .environment(\.transcriptionService, transcriptionService)
        }

        Window("Welcome to Dove", id: WelcomeWindow.id) {
            WelcomeView()
                .environment(settings)
                .environment(hotkeyManager)
                .environment(\.audioRecorder, audioRecorder)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commandsRemoved()
    }

    private func bootstrap() {
        guard !didBootstrap else { return }
        didBootstrap = true

        let showWelcome = settings.shouldShowWelcomeOnLaunch
        DiagnosticLog.beginSession()
        registerShutdown()
        RecordingCleanup.cleanupStaleRecordings()
        LaunchAtLoginService.sync(enabled: settings.launchAtLogin)
        hudController.install(audioRecorder: audioRecorder, settings: settings)
        configurePipeline()
        // The welcome window walks through permissions, so skip the bare system prompt.
        hotkeyManager.refreshPermissionsAndStart(prompt: !showWelcome)
        // Warm-ups stay off the launch path so the menu bar responds immediately.
        Task { await audioRecorder.prepareIfNeeded() }
        Task { await transcriptionService.prepareModelIfNeeded(settings: settings) }
        if showWelcome {
            WelcomeWindow.present(using: openWindow)
        }
    }

    private func registerShutdown() {
        AppTermination.shared.onTerminate {
            await AppShutdown.perform(
                hotkeyManager: hotkeyManager,
                audioRecorder: audioRecorder,
                hudController: hudController,
                pipeline: pipelineCoordinator
            )
        }
    }

    private func configurePipeline() {
        let coordinator = PipelineCoordinator(
            transcriptionService: transcriptionService,
            settings: settings,
            hudController: hudController
        )
        pipelineCoordinator = coordinator

        hotkeyManager.configure(settings: settings, hudController: hudController)

        hotkeyManager.onRecordingStarted = {
            do {
                try audioRecorder.startRecording()
                return nil
            } catch {
                let message = ErrorReporter.report(error, context: "Start recording")
                // Only send the user to System Settings when permission is the actual blocker.
                switch PermissionsHelper.microphoneStatus {
                case .denied, .restricted:
                    PermissionsHelper.openMicrophoneSettings()
                case .authorized, .notDetermined:
                    break
                }
                return message
            }
        }

        hotkeyManager.onRecordingStopped = {
            guard let url = audioRecorder.stopRecording() else {
                hudController.showError(
                    ErrorReporter.report(
                        "Stop recording",
                        reason: "no audio captured",
                        message: HUDErrorMessage.nothingHeard,
                        origin: .expected
                    )
                )
                return
            }

            guard let pipelineCoordinator else {
                RecordingCleanup.deleteRecording(at: url)
                hudController.showError(
                    ErrorReporter.report("Pipeline", reason: "coordinator unavailable")
                )
                return
            }

            let insertionTarget = InsertionTarget.captureFrontmost()

            Task { @MainActor in
                if let result = await pipelineCoordinator.processRecording(
                    at: url,
                    insertionTarget: insertionTarget
                ) {
                    print("[VoicePrompt] Pipeline complete (\(result.count) characters)")
                }
            }
        }

        hotkeyManager.onRecordingCancelled = {
            audioRecorder.cancelRecording()
        }
    }
}
