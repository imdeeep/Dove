import Foundation

/// Anthropic Messages API: system prompt is a top-level field and `max_tokens` is required.
struct AnthropicProvider: AIProvider {
    let kind: AIProviderKind = .anthropic

    private let baseURL: String
    private let apiKey: String
    private let model: String
    private let temperature: Double?
    private let session: URLSession

    private static let apiVersion = "2023-06-01"
    private static let maxTokens = 2048

    init(
        baseURL: String,
        apiKey: String,
        model: String,
        temperature: Double?,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.temperature = temperature
        self.session = session
    }

    func polish(transcript: String, systemPrompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/messages") else {
            throw AIProviderError.networkError("Invalid Anthropic endpoint URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")

        let body = MessagesRequest(
            model: model,
            maxTokens: Self.maxTokens,
            system: systemPrompt,
            temperature: temperature,
            messages: [
                MessagesRequest.Message(
                    role: "user",
                    content: PromptDefaults.userMessage(for: transcript)
                )
            ]
        )
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

        let decoded = try JSONDecoder().decode(MessagesResponse.self, from: data)
        let text = decoded.content
            .compactMap(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw AIProviderError.invalidResponse
        }

        return text
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

private struct MessagesRequest: Encodable {
    let model: String
    let maxTokens: Int
    let system: String
    let temperature: Double?
    let messages: [Message]

    struct Message: Encodable {
        let role: String
        let content: String
    }

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case temperature
        case messages
    }
}

private struct MessagesResponse: Decodable {
    let content: [Block]

    struct Block: Decodable {
        let type: String
        let text: String?
    }
}
