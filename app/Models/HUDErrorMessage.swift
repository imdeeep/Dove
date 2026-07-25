import Foundation

/// Every user-facing failure string in Dove. Short, calm, and actionable -
/// with a generic fallback so an unexpected error is never shown raw.
enum HUDErrorMessage {
    static let generic = "An error occurred. Please try again."
    static let transcriptionFailed = "Transcription failed. Try again."
    static let nothingHeard = "Nothing heard. Try again."
    static let microphoneUnavailable = "Microphone unavailable."
    static let microphoneDenied = "Microphone access is off. Enable it in System Settings."
    static let accessibilityRequired = "Enable Accessibility in System Settings."
    static let accessibilityCopied = "Accessibility is off. Copied to clipboard."
    static let noConnection = "No connection. Check your network."
    static let invalidAPIKey = "Invalid API key. Check Preferences."
    static let requestTimedOut = "Request timed out. Try again."
    static let copiedToClipboard = "Copied to clipboard. Paste with ⌘V."
    static let speechModelUnavailable = "Speech model unavailable. Open Preferences → Speech."
    static let speechModelFailed = "Could not load the speech model. Check your connection and try again."
    static let diskFull = "Not enough disk space."
    static let keychainUnavailable = "Keychain is unavailable."

    /// Map any error to a friendly message. Unknown errors fall back to `generic`
    /// so nothing technical ever reaches the HUD.
    static func from(_ error: Error) -> String {
        switch error {
        case let providerError as AIProviderError:
            return from(providerError)
        case let transcriptionError as TranscriptionError:
            return from(transcriptionError)
        case let inserterError as TextInserterError:
            return from(inserterError)
        case let recorderError as AudioRecorderError:
            return from(recorderError)
        case is KeychainError:
            return keychainUnavailable
        case let urlError as URLError:
            return from(urlError)
        case let cocoaError as CocoaError:
            return cocoaError.code == .fileWriteOutOfSpace ? diskFull : generic
        default:
            return generic
        }
    }

    static func from(_ error: AIProviderError) -> String {
        switch error {
        case .unauthorized:
            return invalidAPIKey
        case .rateLimited:
            return "Rate limit reached. Try again in a moment."
        case .networkError(let message):
            if message.localizedCaseInsensitiveContains("timed out")
                || message.localizedCaseInsensitiveContains("timeout") {
                return requestTimedOut
            }
            return noConnection
        case .invalidResponse, .apiError:
            return generic
        }
    }

    static func from(_ error: TranscriptionError) -> String {
        switch error {
        case .modelNotLoaded:
            return speechModelUnavailable
        case .emptyTranscript:
            return nothingHeard
        case .whisperKitFailed:
            return transcriptionFailed
        }
    }

    static func from(_ error: TextInserterError) -> String {
        switch error {
        case .accessibilityNotTrusted:
            return accessibilityRequired
        case .noFocusedElement, .insertionFailed:
            return copiedToClipboard
        }
    }

    static func from(_ error: AudioRecorderError) -> String {
        switch error {
        case .permissionDenied:
            return microphoneDenied
        case .notPrepared, .failedToStart:
            return microphoneUnavailable
        }
    }

    static func from(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
            return noConnection
        case .timedOut:
            return requestTimedOut
        default:
            return generic
        }
    }
}
