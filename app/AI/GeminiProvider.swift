import Foundation

struct GeminiProvider: AIProvider {
    let kind: AIProviderKind = .gemini

    private let baseURL: String
    private let apiKey: String
    private let model: String
    private let temperature: Double?
    private let session: URLSession

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
        guard let url = URL(string: "\(baseURL)/models/\(model):generateContent") else {
            throw AIProviderError.networkError("Invalid Gemini endpoint URL.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let body = GeminiRequest(
            systemInstruction: GeminiContent(parts: [GeminiPart(text: systemPrompt)]),
            contents: [GeminiContent(parts: [GeminiPart(text: PromptDefaults.userMessage(for: transcript))])],
            generationConfig: temperature.map(GeminiGenerationConfig.init(temperature:))
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

        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = decoded.candidates?.first?.content?.parts?.first?.text?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw AIProviderError.invalidResponse
        }

        return text
    }

    private static func errorMessage(from data: Data) -> String? {
        struct GeminiErrorResponse: Decodable {
            struct ErrorDetail: Decodable {
                let message: String
            }

            let error: ErrorDetail
        }

        return (try? JSONDecoder().decode(GeminiErrorResponse.self, from: data))?.error.message
    }
}

private struct GeminiRequest: Encodable {
    let systemInstruction: GeminiContent
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
}

private struct GeminiContent: Encodable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Encodable {
    let text: String
}

private struct GeminiGenerationConfig: Encodable {
    let temperature: Double
}

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
}

private struct GeminiCandidate: Decodable {
    let content: GeminiResponseContent?
}

private struct GeminiResponseContent: Decodable {
    let parts: [GeminiResponsePart]?
}

private struct GeminiResponsePart: Decodable {
    let text: String?
}
