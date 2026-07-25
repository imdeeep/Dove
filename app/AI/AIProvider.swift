import Foundation

protocol AIProvider {
    var kind: AIProviderKind { get }

    func polish(transcript: String, systemPrompt: String) async throws -> String
}

enum AIProviderError: LocalizedError {
    case invalidResponse
    case unauthorized
    case rateLimited
    case networkError(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The AI provider returned an unexpected response."
        case .unauthorized:
            return "Invalid API key. Check Preferences → AI Provider."
        case .rateLimited:
            return "Rate limit reached. Try again in a moment."
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return message
        }
    }
}

enum AIProviderFactory {
    static func makeProvider(settings: AppSettings) -> (any AIProvider)? {
        let kind = settings.selectedProvider
        let spec = ProviderRegistry.spec(for: kind)
        let storedKey = (try? KeychainService.load(forKey: kind.keychainAccount)) ?? nil
        let apiKey = storedKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Custom endpoints (local Ollama, LM Studio) commonly need no key.
        guard !apiKey.isEmpty || kind == .custom else { return nil }

        let baseURL = spec.resolvedBaseURL(customBaseURL: settings.customBaseURL)
        let model = settings.model(for: kind)
        guard !baseURL.isEmpty, !model.isEmpty else { return nil }

        let temperature = ModelCatalog.supportsTemperature(modelID: model, for: kind)
            ? settings.temperature
            : nil

        switch spec.wireFormat {
        case .openAICompatible:
            return OpenAICompatibleProvider(
                kind: kind,
                baseURL: baseURL,
                apiKey: apiKey,
                model: model,
                temperature: temperature
            )
        case .anthropic:
            return AnthropicProvider(
                baseURL: baseURL,
                apiKey: apiKey,
                model: model,
                temperature: temperature
            )
        case .gemini:
            return GeminiProvider(
                baseURL: baseURL,
                apiKey: apiKey,
                model: model,
                temperature: temperature
            )
        }
    }
}
