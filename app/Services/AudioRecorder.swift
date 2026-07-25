import AVFoundation
import Foundation

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case notPrepared
    case failedToStart

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone access was denied."
        case .notPrepared:
            return "The microphone is not ready yet."
        case .failedToStart:
            return "The microphone could not start recording."
        }
    }
}

@MainActor
final class AudioRecorder {
    private var recorder: AVAudioRecorder?
    private(set) var currentFileURL: URL?
    private var isPrepared = false

    private static let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 16_000.0,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
    ]

    /// Request mic access and prime the input device once at launch.
    func prepareIfNeeded() async {
        guard !isPrepared else { return }

        let granted = await PermissionsHelper.requestMicrophoneAccess()
        guard granted else {
            print("[VoicePrompt] Microphone permission denied (status: \(PermissionsHelper.microphoneStatus))")
            return
        }

        if let device = AVCaptureDevice.default(for: .audio) {
            print("[VoicePrompt] Microphone ready: \(device.localizedName)")
        }

        // Prime the built-in mic so the first hotkey press doesn't hit "reconfig pending".
        let warmupURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("voiceprompt-warmup.wav")
        defer { try? FileManager.default.removeItem(at: warmupURL) }

        if let warmup = try? AVAudioRecorder(url: warmupURL, settings: Self.recordingSettings) {
            warmup.prepareToRecord()
        }

        isPrepared = true
        print("[VoicePrompt] Audio recorder prepared")
    }

    /// Synchronous start - call only after `prepareIfNeeded()` and while the hotkey is held.
    func startRecording() throws {
        switch PermissionsHelper.microphoneStatus {
        case .denied, .restricted:
            throw AudioRecorderError.permissionDenied
        case .authorized, .notDetermined:
            break
        }

        guard isPrepared else {
            throw AudioRecorderError.notPrepared
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voiceprompt-\(UUID().uuidString).wav")

        recorder = try AVAudioRecorder(url: url, settings: Self.recordingSettings)
        recorder?.isMeteringEnabled = true
        recorder?.prepareToRecord()

        guard recorder?.record() == true else {
            recorder = nil
            throw AudioRecorderError.failedToStart
        }

        currentFileURL = url
        print("[VoicePrompt] Recording to: \(url.path)")
    }

    var isRecording: Bool { recorder != nil }

    /// Normalized input level 0…1 while recording; 0 when idle.
    func currentLevel() -> CGFloat {
        guard let recorder else { return 0 }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalized = (power + 50) / 50
        return CGFloat(max(0, min(1, normalized)))
    }

    func stopRecording() -> URL? {
        guard let activeRecorder = recorder else { return nil }

        activeRecorder.updateMeters()
        let peak = activeRecorder.peakPower(forChannel: 0)
        activeRecorder.stop()
        recorder = nil

        guard let url = currentFileURL else { return nil }
        currentFileURL = nil

        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        print("[VoicePrompt] Recording saved: \(url.path) (\(size) bytes, peak \(String(format: "%.1f", peak)) dB)")
        if size < 1_000 || peak < -50 {
            print("[VoicePrompt] Warning: recording looks silent - hold ⌃⇧Space longer and speak closer to the mic")
        }
        return url
    }

    func cancelRecording() {
        recorder?.stop()
        recorder = nil
        if let url = currentFileURL {
            RecordingCleanup.deleteRecording(at: url)
        }
        currentFileURL = nil
    }
}
