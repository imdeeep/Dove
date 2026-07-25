import Foundation

/// Serves every provider that speaks OpenAI Chat Completions - OpenAI, Groq,
/// OpenRouter, DeepSeek, Kimi, GLM, xAI, Mistral, and Custom endpoints.
struct OpenAICompatibleProvider: AIProvider {
    let kind: AIProviderKind

    private let baseURL: String
    private let apiKey: String
    private let model: String
    private let temperature: Double?
    private let session: URLSession

    init(
        kind: AIProviderKind,
        baseURL: String,
        apiKey: String,
        model: String,
        temperature: Double?,
        session: URLSession = .shared
    ) {
        self.kind = kind
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.temperature = temperature
        self.session = session
    }

    func polish(transcript: String, systemPrompt: String) async throws -> String {
        let messages = [
            ChatMessage(role: "system", content: systemPrompt),
            ChatMessage(role: "user", content: PromptDefaults.userMessage(for: transcript)),
        ]

        do {
            return try await send(messages: messages, temperature: temperature)
        } catch AIProviderError.apiError(let message) where temperature != nil && Self.rejectsTemperature(message) {
            return try await send(messages: messages, temperature: nil)
        }
    }

    private func send(messages: [ChatMessage], temperature: Double?) async throws -> String {
        guard !baseURL.isEmpty, let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIProviderError.networkError("Invalid endpoint URL for \(kind.displayName).")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        if kind == .openRouter {
            request.setValue("https://github.com/mandeep/dove", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("Dove", forHTTPHeaderField: "X-Title")
        }

        let body = ChatRequest(model: model, messages: messages, temperature: temperature)
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIProviderError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        switch http.statusCode {
        case 200:
            break
        case 401, 403:
            throw AIProviderError.unauthorized
        case 429:
            throw AIProviderError.rateLimited
        default:
            let message = Self.errorMessage(from: data) ?? "HTTP \(http.statusCode)"
            throw AIProviderError.apiError(message)
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let text = decoded.choices.first?.message.content?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw AIProviderError.invalidResponse
        }

        return text
    }

    /// Reasoning models reply with a 400 naming the offending parameter; retry without it.
    private static func rejectsTemperature(_ message: String) -> Bool {
        let lowered = message.lowercased()
        return lowered.contains("temperature")
            && (lowered.contains("unsupported")
                || lowered.contains("not support")
                || lowered.contains("unknown")
                || lowered.contains("invalid"))
    }

    private static func errorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            struct Detail: Decodable {
                let message: String
            }

            let error: Detail
        }

        return (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.error.message
    }
}

private struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double?
}

private struct ChatMessage: Encodable {
    let role: String
    let content: String
}

private struct ChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String?
    }
}
