import Foundation

/// Single source of truth for provider endpoints and metadata.
enum ProviderRegistry {
    static let all: [ProviderSpec] = [
        ProviderSpec(
            kind: .openai,
            displayName: "OpenAI",
            wireFormat: .openAICompatible,
            baseURL: "https://api.openai.com/v1",
            keyPlaceholder: "sk-…",
            consoleURL: "https://platform.openai.com/api-keys",
            defaultModel: "gpt-5.6-luna"
        ),
        ProviderSpec(
            kind: .anthropic,
            displayName: "Anthropic",
            wireFormat: .anthropic,
            baseURL: "https://api.anthropic.com/v1",
            keyPlaceholder: "sk-ant-…",
            consoleURL: "https://console.anthropic.com/settings/keys",
            defaultModel: "claude-haiku-4-5"
        ),
        ProviderSpec(
            kind: .gemini,
            displayName: "Google Gemini",
            wireFormat: .gemini,
            baseURL: "https://generativelanguage.googleapis.com/v1beta",
            keyPlaceholder: "AIza…",
            consoleURL: "https://aistudio.google.com/apikey",
            defaultModel: "gemini-flash-lite-latest"
        ),
        ProviderSpec(
            kind: .groq,
            displayName: "Groq",
            wireFormat: .openAICompatible,
            baseURL: "https://api.groq.com/openai/v1",
            keyPlaceholder: "gsk_…",
            consoleURL: "https://console.groq.com/keys",
            defaultModel: "openai/gpt-oss-20b"
        ),
        ProviderSpec(
            kind: .openRouter,
            displayName: "OpenRouter",
            wireFormat: .openAICompatible,
            baseURL: "https://openrouter.ai/api/v1",
            keyPlaceholder: "sk-or-…",
            consoleURL: "https://openrouter.ai/keys",
            defaultModel: "openai/gpt-5.6-luna"
        ),
        ProviderSpec(
            kind: .deepseek,
            displayName: "DeepSeek",
            wireFormat: .openAICompatible,
            baseURL: "https://api.deepseek.com/v1",
            keyPlaceholder: "sk-…",
            consoleURL: "https://platform.deepseek.com/api_keys",
            defaultModel: "deepseek-v4-flash"
        ),
        ProviderSpec(
            kind: .kimi,
            displayName: "Kimi (Moonshot)",
            wireFormat: .openAICompatible,
            baseURL: "https://api.moonshot.ai/v1",
            keyPlaceholder: "sk-…",
            consoleURL: "https://platform.moonshot.ai/console/api-keys",
            defaultModel: "kimi-k2.6"
        ),
        ProviderSpec(
            kind: .glm,
            displayName: "GLM (Zhipu)",
            wireFormat: .openAICompatible,
            baseURL: "https://open.bigmodel.cn/api/paas/v4",
            keyPlaceholder: "your-api-key",
            consoleURL: "https://open.bigmodel.cn/usercenter/apikeys",
            defaultModel: "glm-5-turbo"
        ),
        ProviderSpec(
            kind: .xai,
            displayName: "xAI (Grok)",
            wireFormat: .openAICompatible,
            baseURL: "https://api.x.ai/v1",
            keyPlaceholder: "xai-…",
            consoleURL: "https://console.x.ai",
            defaultModel: "grok-4.5"
        ),
        ProviderSpec(
            kind: .mistral,
            displayName: "Mistral",
            wireFormat: .openAICompatible,
            baseURL: "https://api.mistral.ai/v1",
            keyPlaceholder: "your-api-key",
            consoleURL: "https://console.mistral.ai/api-keys",
            defaultModel: "mistral-small-latest"
        ),
        ProviderSpec(
            kind: .custom,
            displayName: "Custom (OpenAI-compatible)",
            wireFormat: .openAICompatible,
            baseURL: "",
            keyPlaceholder: "optional for local servers",
            consoleURL: "https://github.com/ollama/ollama/blob/main/docs/openai.md",
            defaultModel: "",
            isEditableBaseURL: true
        ),
    ]

    static func spec(for kind: AIProviderKind) -> ProviderSpec {
        all.first { $0.kind == kind } ?? all[0]
    }
}
