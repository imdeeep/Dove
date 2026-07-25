import Foundation

/// HTTP request/response shape a provider speaks.
enum ProviderWireFormat {
    case openAICompatible
    case anthropic
    case gemini
}

/// Static description of a provider: where to reach it and how to talk to it.
struct ProviderSpec {
    let kind: AIProviderKind
    let displayName: String
    let wireFormat: ProviderWireFormat
    /// Empty for `.custom` - the user supplies it in preferences.
    let baseURL: String
    let keyPlaceholder: String
    let consoleURL: String
    /// Path appended to `baseURL` to list models. Nil disables live refresh.
    let modelsPath: String?
    let defaultModel: String
    let isEditableBaseURL: Bool

    init(
        kind: AIProviderKind,
        displayName: String,
        wireFormat: ProviderWireFormat,
        baseURL: String,
        keyPlaceholder: String,
        consoleURL: String,
        modelsPath: String? = "/models",
        defaultModel: String,
        isEditableBaseURL: Bool = false
    ) {
        self.kind = kind
        self.displayName = displayName
        self.wireFormat = wireFormat
        self.baseURL = baseURL
        self.keyPlaceholder = keyPlaceholder
        self.consoleURL = consoleURL
        self.modelsPath = modelsPath
        self.defaultModel = defaultModel
        self.isEditableBaseURL = isEditableBaseURL
    }

    /// Resolved base URL, preferring the user's custom value when the spec allows it.
    func resolvedBaseURL(customBaseURL: String) -> String {
        let trimmedCustom = customBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        var source = isEditableBaseURL ? trimmedCustom : baseURL
        while source.hasSuffix("/") {
            source.removeLast()
        }
        return source
    }
}
