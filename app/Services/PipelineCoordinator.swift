import AppKit
import Foundation

@MainActor
final class PipelineCoordinator {
    private let transcriptionService: TranscriptionService
    private let settings: AppSettings
    private let hudController: HUDController

    /// True from the moment a recording enters the pipeline until it leaves it.
    private(set) var isProcessing = false

    /// The finished prompt while it is being inserted. Kept so a quit mid-insertion
    /// can still hand the user their words.
    private(set) var pendingInsertionText: String?

    init(
        transcriptionService: TranscriptionService,
        settings: AppSettings,
        hudController: HUDController
    ) {
        self.transcriptionService = transcriptionService
        self.settings = settings
        self.hudController = hudController
    }

    /// Transcribe audio, optionally polish with the configured AI provider, insert at cursor, and return final text.
    /// Falls back to the raw transcript when no API key is configured or polish fails.
    func processRecording(at audioURL: URL, insertionTarget: InsertionTarget? = nil) async -> String? {
        let pipelineStartedAt = Date()
        isProcessing = true
        defer {
            isProcessing = false
            pendingInsertionText = nil
            RecordingCleanup.deleteRecording(at: audioURL)
        }

        hudController.showProcessing(.transcribing)

        let transcript: String
        do {
            transcript = try await transcriptionService.transcribe(audioURL: audioURL, settings: settings)
            print("[VoicePrompt] Transcript: \(transcript)")
        } catch {
            guard !ErrorReporter.isCancellation(error) else {
                hudController.hide()
                return nil
            }
            hudController.showError(ErrorReporter.report(error, context: "Transcription"))
            return nil
        }

        let finalText = await resolveFinalText(from: transcript)

        let trimmed = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            ErrorReporter.report("Insertion", reason: "empty transcript", origin: .expected)
            hudController.showError(HUDErrorMessage.nothingHeard)
            return nil
        }

        if settings.typeWordByWord {
            hudController.showProcessing(.inserting)
        }

        pendingInsertionText = trimmed

        if let failureMessage = await insertFinalText(trimmed, target: insertionTarget) {
            hudController.showError(failureMessage)
        } else {
            hudController.showSuccess()
        }

        let elapsedMs = Date().timeIntervalSince(pipelineStartedAt) * 1000
        print("[Dove] Pipeline completed in \(String(format: "%.0f", elapsedMs))ms")

        return finalText
    }

    private func resolveFinalText(from transcript: String) async -> String {
        guard let provider = AIProviderFactory.makeProvider(settings: settings) else {
            print("[VoicePrompt] No API key configured - using raw transcript")
            return transcript
        }

        hudController.showProcessing(.polishing)
        print("[VoicePrompt] Polishing with \(provider.kind.displayName)…")

        do {
            let polished = try await provider.polish(
                transcript: transcript,
                systemPrompt: settings.systemPrompt
            )

            if Self.looksLikeInstructionEcho(polished: polished, transcript: transcript) {
                print("[VoicePrompt] Polish returned instructions instead of output - using raw transcript")
                return transcript
            }

            print("[VoicePrompt] Polished prompt: \(polished)")
            return polished
        } catch {
            // Polish is best-effort: fall back to the raw transcript rather than failing
            // the whole recording, so the user still gets their words.
            ErrorReporter.report(error, context: "Polish", origin: .expected)
            return transcript
        }
    }

    /// Returns nil on success, or the message to show when the prompt could not be inserted.
    /// The prompt is always left on the clipboard so the user never loses their words.
    private func insertFinalText(_ text: String, target: InsertionTarget?) async -> String? {
        do {
            if settings.typeWordByWord {
                try await TextInserter.insertByTyping(text, target: target)
            } else {
                try TextInserter.insert(text, target: target)
            }
            print("[VoicePrompt] Inserted prompt at cursor")
            return nil
        } catch TextInserterError.accessibilityNotTrusted {
            ErrorReporter.report("Insertion", reason: "Accessibility not trusted", origin: .expected)
            copyToClipboard(text)
            return HUDErrorMessage.accessibilityCopied
        } catch {
            ErrorReporter.report(error, context: "Insertion")
            copyToClipboard(text)
            return HUDErrorMessage.copiedToClipboard
        }
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("[VoicePrompt] Prompt copied to clipboard - paste manually with ⌘V")
    }

    /// Called during shutdown: if a prompt was still being inserted, leave it on the
    /// clipboard so quitting never costs the user their words.
    func salvagePendingText() {
        guard let pendingInsertionText else { return }
        copyToClipboard(pendingInsertionText)
        self.pendingInsertionText = nil
    }

    /// Detect when the model paraphrases the system prompt instead of polishing the transcript.
    private static func looksLikeInstructionEcho(polished: String, transcript: String) -> Bool {
        let lower = polished.lowercased()
        let instructionPhrases = [
            "transcription refiner",
            "fillers and hesitations",
            "you are not the assistant",
            "rewritten message",
            "the dictation between the markers",
            "<<<transcript",
        ]
        if instructionPhrases.contains(where: { lower.contains($0) }) {
            return true
        }

        let transcriptWords = wordSet(from: transcript)
        let polishedWords = wordSet(from: polished)
        return transcriptWords.count >= 3 && transcriptWords.intersection(polishedWords).isEmpty
    }

    private static func wordSet(from text: String) -> Set<String> {
        Set(
            text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 2 }
        )
    }
}
