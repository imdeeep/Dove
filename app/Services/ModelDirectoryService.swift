import Foundation

/// Fetches each provider's live model list and caches it in UserDefaults, so a
/// build shipped with a stale catalog still surfaces new models after one refresh.
enum ModelDirectoryService {
    struct CachedDirectory: Codable {
        let models: [CachedModel]
        let fetchedAt: Date
    }

    struct CachedModel: Codable {
        let id: String
        let displayName: String
    }

    // MARK: - Cache

    static func cachedModels(for kind: AIProviderKind) -> [AIModel] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey(for: kind)),
              let cached = try? JSONDecoder().decode(CachedDirectory.self, from: data) else {
            return []
        }
        return cached.models.map { AIModel($0.id, $0.displayName) }
    }

    static func lastFetchDate(for kind: AIProviderKind) -> Date? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey(for: kind)),
              let cached = try? JSONDecoder().decode(CachedDirectory.self, from: data) else {
            return nil
        }
        return cached.fetchedAt
    }

    /// Curated entries first (they carry hand-written names and temperature support),
    /// then any live model the catalog does not know about.
    static func mergedModels(for kind: AIProviderKind) -> [AIModel] {
        let curated = ModelCatalog.models(for: kind)
        let curatedIDs = Set(curated.map(\.id))
        let extra = cachedModels(for: kind).filter { !curatedIDs.contains($0.id) }
        return curated + extra.sorted { $0.id < $1.id }
    }

    // MARK: - Live fetch

    static func refresh(
        spec: ProviderSpec,
        apiKey: String,
        customBaseURL: String,
        session: URLSession = .shared
    ) async throws -> [AIModel] {
        guard let modelsPath = spec.modelsPath else {
            throw AIProviderError.apiError("\(spec.displayName) does not publish a model list.")
        }

        let baseURL = spec.resolvedBaseURL(customBaseURL: customBaseURL)
        guard !baseURL.isEmpty, let url = URL(string: baseURL + modelsPath) else {
            throw AIProviderError.networkError("Invalid endpoint URL for \(spec.displayName).")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        switch spec.wireFormat {
        case .openAICompatible:
            if !apiKey.isEmpty {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
        case .anthropic:
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        case .gemini:
            request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        }

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
            throw AIProviderError.apiError("HTTP \(http.statusCode)")
        }

        let models = try parse(data: data, wireFormat: spec.wireFormat)
        guard !models.isEmpty else {
            throw AIProviderError.invalidResponse
        }

        store(models, for: spec.kind)
        return models
    }

    private static func parse(data: Data, wireFormat: ProviderWireFormat) throws -> [AIModel] {
        let decoder = JSONDecoder()
        switch wireFormat {
        case .openAICompatible, .anthropic:
            guard let decoded = try? decoder.decode(ListResponse.self, from: data) else {
                throw AIProviderError.invalidResponse
            }
            return decoded.data.map { AIModel($0.id, $0.display_name ?? $0.id) }
        case .gemini:
            guard let decoded = try? decoder.decode(GeminiListResponse.self, from: data) else {
                throw AIProviderError.invalidResponse
            }
            return decoded.models
                .filter { $0.supportedGenerationMethods?.contains("generateContent") ?? true }
                .map { entry in
                    // Gemini returns fully qualified names like "models/gemini-3.5-flash".
                    let id = entry.name.hasPrefix("models/")
                        ? String(entry.name.dropFirst("models/".count))
                        : entry.name
                    return AIModel(id, entry.displayName ?? id)
                }
        }
    }

    private static func store(_ models: [AIModel], for kind: AIProviderKind) {
        let cached = CachedDirectory(
            models: models.map { CachedModel(id: $0.id, displayName: $0.displayName) },
            fetchedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(cached) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey(for: kind))
    }

    private static func cacheKey(for kind: AIProviderKind) -> String {
        "modelDirectory.\(kind.rawValue)"
    }
}

private struct ListResponse: Decodable {
    let data: [Entry]

    struct Entry: Decodable {
        let id: String
        let display_name: String?
    }
}

private struct GeminiListResponse: Decodable {
    let models: [Entry]

    struct Entry: Decodable {
        let name: String
        let displayName: String?
        let supportedGenerationMethods: [String]?
    }
}
