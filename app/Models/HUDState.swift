import Foundation

enum ProcessingStep: Equatable {
    case transcribing
    case polishing
    case inserting
}

enum HUDState: Equatable {
    case idle
    case listening(startedAt: Date)
    case processing(ProcessingStep)
    case success
    case error(String)

    var isListening: Bool {
        if case .listening = self { return true }
        return false
    }

    var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }
}
