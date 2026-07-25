import Foundation
import Observation
import WhisperKit

enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case emptyTranscript
    case whisperKitFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Whisper model is not loaded yet. Open Preferences → Speech to download it."
        case .emptyTranscript:
            return "No speech detected in the recording."
        case .whisperKitFailed(let message):
            return message
        }
    }
}

@Observable
@MainActor
final class TranscriptionService {
    private(set) var downloadProgress: Double = 0
    private(set) var isDownloading = false
    private(set) var isModelReady = false
    private(set) var loadedVariant: String?
    private(set) var lastError: String?

    private var whisperKit: WhisperKit?
    private var prepareTask: Task<Void, Never>?

    private var downloadBase: URL {
        WhisperModelCache.downloadBase
    }

    func isModelInstalled(_ variant: String) -> Bool {
        if loadedVariant == variant, isModelReady { return true }
        return WhisperModelCache.isDownloaded(variant)
    }

    /// Forces the next disk lookup to rescan, in case models were added or removed
    /// outside the app.
    func revalidateInstalledModels() {
        WhisperModelCache.invalidate()
    }

    func invalidateLoadedModel() {
        whisperKit = nil
        loadedVariant = nil
        isModelReady = false
        lastError = nil
    }

    func prepareModelIfNeeded(settings: AppSettings) async {
        if isModelReady, loadedVariant == settings.whisperModelVariant { return }

        if let prepareTask {
            await prepareTask.value
            return
        }

        let task = Task { @MainActor in
            await loadModel(variant: settings.whisperModelVariant)
        }
        prepareTask = task
        await task.value
        prepareTask = nil
    }

    func transcribe(audioURL: URL, settings: AppSettings) async throws -> String {
        if !isModelReady || loadedVariant != settings.whisperModelVariant {
            await prepareModelIfNeeded(settings: settings)
        }

        guard let whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        print("[Dove] Transcribing: \(audioURL.lastPathComponent)")

        let language = Self.resolvedLanguage(
            settings.transcriptionLanguage,
            variant: settings.whisperModelVariant
        )
        let decodeOptions = DecodingOptions(language: language)
        let results: [TranscriptionResult]
        do {
            results = try await whisperKit.transcribe(
                audioPath: audioURL.path,
                decodeOptions: decodeOptions
            )
        } catch {
            throw TranscriptionError.whisperKitFailed(error.localizedDescription)
        }

        let transcript = results
            .map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !transcript.isEmpty else {
            throw TranscriptionError.emptyTranscript
        }

        return transcript
    }

    private func loadModel(variant: String) async {
        if isModelReady, loadedVariant == variant { return }

        invalidateLoadedModel()
        lastError = nil

        do {
            let modelFolder = try await resolveModelFolder(variant: variant)

            print("[Dove] Loading Core ML models from: \(modelFolder.path)")

            let config = WhisperKitConfig(
                downloadBase: downloadBase,
                modelFolder: modelFolder.path,
                verbose: true,
                logLevel: .info,
                load: true,
                download: false
            )

            whisperKit = try await WhisperKit(config)
            loadedVariant = variant
            isModelReady = true
            WhisperModelCache.remember(modelFolder, for: variant)
            print("[Dove] WhisperKit ready (\(variant))")
        } catch {
            let mapped = ErrorReporter.report(error, context: "Load speech model \(variant)")
            lastError = mapped == HUDErrorMessage.generic ? HUDErrorMessage.speechModelFailed : mapped
        }

        isDownloading = false
    }

    /// Cached models load straight from disk. Only a missing model pays for the
    /// network round trip and download.
    private func resolveModelFolder(variant: String) async throws -> URL {
        if let cached = WhisperModelCache.resolvedFolder(for: variant) {
            print("[Dove] Using cached model (\(variant))")
            return cached
        }

        isDownloading = true
        downloadProgress = 0
        print("[Dove] Downloading WhisperKit model (\(variant))…")

        let modelFolder = try await WhisperKit.download(
            variant: variant,
            downloadBase: downloadBase,
            progressCallback: { progress in
                Task { @MainActor in
                    self.downloadProgress = progress.fractionCompleted
                    let percent = Int(progress.fractionCompleted * 100)
                    if percent == 0 || percent % 10 == 0 || progress.completedUnitCount == progress.totalUnitCount {
                        print("[Dove] Download progress: \(percent)%")
                    }
                }
            }
        )

        isDownloading = false
        print("[Dove] Model files ready at: \(modelFolder.path)")
        return modelFolder
    }

    private static func resolvedLanguage(_ language: String, variant: String) -> String {
        if WhisperModelCatalog.model(id: variant)?.isEnglishOnly == true || variant.hasSuffix(".en") {
            return "en"
        }
        return language == "auto" ? "auto" : language
    }
}
