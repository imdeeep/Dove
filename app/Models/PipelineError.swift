import Foundation

enum PipelineError: LocalizedError {
    case transcriptionFailed(String)
    case polishFailed(String)
    case insertionFailed(String)

    var errorDescription: String? {
        switch self {
        case .transcriptionFailed(let message):
            return message
        case .polishFailed(let message):
            return message
        case .insertionFailed(let message):
            return message
        }
    }
}
