import Foundation

/// Supported cloud polish providers. Add cases here as new providers ship.
enum AIProviderKind: String, Codable, CaseIterable, Identifiable {
    case openai
    case anthropic
    case gemini
    case groq
    case openRouter
    case deepseek
    case kimi
    case glm
    case xai
    case mistral
    case custom

    var id: String { rawValue }

    var displayName: String {
        ProviderRegistry.spec(for: self).displayName
    }

    var keychainAccount: String {
        "apiKey.\(rawValue)"
    }
}
