import Foundation

/// One selectable model.
struct AIModel: Identifiable, Hashable {
    let id: String
    let displayName: String
    /// Reasoning-first models reject a `temperature` field; we omit it for those.
    let supportsTemperature: Bool

    init(_ id: String, _ displayName: String, supportsTemperature: Bool = true) {
        self.id = id
        self.displayName = displayName
        self.supportsTemperature = supportsTemperature
    }
}

/// Curated per-provider model lists, verified against provider docs on 2026-07-25.
/// `ModelDirectoryService` merges live results over these so a stale build still
/// surfaces new models after one refresh.
enum ModelCatalog {
    static func models(for kind: AIProviderKind) -> [AIModel] {
        switch kind {
        case .openai:
            return [
                AIModel("gpt-5.6-luna", "GPT-5.6 Luna"),
                AIModel("gpt-5.6-sol", "GPT-5.6 Sol"),
                AIModel("gpt-5.6-terra", "GPT-5.6 Terra"),
                AIModel("gpt-5.5", "GPT-5.5"),
                AIModel("gpt-5.4-mini", "GPT-5.4 mini"),
                AIModel("gpt-5.4-nano", "GPT-5.4 nano"),
                AIModel("gpt-4.1-mini", "GPT-4.1 mini"),
            ]
        case .anthropic:
            return [
                AIModel("claude-haiku-4-5", "Claude Haiku 4.5"),
                AIModel("claude-sonnet-5", "Claude Sonnet 5"),
                AIModel("claude-opus-5", "Claude Opus 5"),
                AIModel("claude-fable-5", "Claude Fable 5"),
                AIModel("claude-sonnet-4-6", "Claude Sonnet 4.6"),
            ]
        case .gemini:
            return [
                AIModel("gemini-flash-lite-latest", "Gemini Flash Lite (latest)"),
                AIModel("gemini-flash-latest", "Gemini Flash (latest)"),
                AIModel("gemini-pro-latest", "Gemini Pro (latest)"),
                AIModel("gemini-3.6-flash", "Gemini 3.6 Flash"),
                AIModel("gemini-3.5-flash", "Gemini 3.5 Flash"),
                AIModel("gemini-3.1-flash-lite", "Gemini 3.1 Flash Lite"),
                AIModel("gemini-2.5-flash", "Gemini 2.5 Flash"),
            ]
        case .groq:
            return [
                AIModel("openai/gpt-oss-20b", "GPT-OSS 20B"),
                AIModel("openai/gpt-oss-120b", "GPT-OSS 120B"),
                AIModel("qwen/qwen3.6-27b", "Qwen 3.6 27B"),
            ]
        case .openRouter:
            return [
                AIModel("openai/gpt-5.6-luna", "GPT-5.6 Luna"),
                AIModel("anthropic/claude-haiku-4-5", "Claude Haiku 4.5"),
                AIModel("x-ai/grok-4.5", "Grok 4.5"),
                AIModel("google/gemini-3.5-flash", "Gemini 3.5 Flash"),
                AIModel("deepseek/deepseek-v4-flash", "DeepSeek V4 Flash"),
            ]
        case .deepseek:
            return [
                AIModel("deepseek-v4-flash", "DeepSeek V4 Flash"),
                AIModel("deepseek-v4-pro", "DeepSeek V4 Pro"),
                AIModel("deepseek-chat", "DeepSeek Chat"),
                AIModel("deepseek-reasoner", "DeepSeek Reasoner", supportsTemperature: false),
            ]
        case .kimi:
            return [
                AIModel("kimi-k2.6", "Kimi K2.6"),
                AIModel("kimi-k2.7-code", "Kimi K2.7 Code"),
                AIModel("kimi-k2.5", "Kimi K2.5"),
                AIModel("moonshot-v1-128k", "Moonshot v1 128K"),
            ]
        case .glm:
            return [
                AIModel("glm-5-turbo", "GLM-5 Turbo"),
                AIModel("glm-5.2", "GLM-5.2"),
                AIModel("glm-5.1", "GLM-5.1"),
                AIModel("glm-4.5-air", "GLM-4.5 Air"),
            ]
        case .xai:
            return [
                AIModel("grok-4.5", "Grok 4.5"),
                AIModel("grok-4.3", "Grok 4.3"),
            ]
        case .mistral:
            return [
                AIModel("mistral-small-latest", "Mistral Small"),
                AIModel("mistral-medium-latest", "Mistral Medium"),
                AIModel("mistral-large-latest", "Mistral Large"),
            ]
        case .custom:
            return []
        }
    }

    static func model(id: String, for kind: AIProviderKind) -> AIModel? {
        models(for: kind).first { $0.id == id }
    }

    /// Unknown IDs (custom endpoints, freshly fetched models) default to allowing temperature.
    static func supportsTemperature(modelID: String, for kind: AIProviderKind) -> Bool {
        model(id: modelID, for: kind)?.supportsTemperature ?? true
    }
}
