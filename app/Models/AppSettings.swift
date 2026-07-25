import Foundation
import Observation

@Observable
final class AppSettings {
    var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            LaunchAtLoginService.sync(enabled: launchAtLogin)
        }
    }

    var soundEffectsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEffectsEnabled, forKey: Keys.soundEffectsEnabled) }
    }

    var typeWordByWord: Bool {
        didSet { UserDefaults.standard.set(typeWordByWord, forKey: Keys.typeWordByWord) }
    }

    var showWelcomeAtLaunch: Bool {
        didSet { UserDefaults.standard.set(showWelcomeAtLaunch, forKey: Keys.showWelcomeAtLaunch) }
    }

    /// Set once the welcome window has been shown, so it only appears unprompted on first run.
    var hasCompletedWelcome: Bool {
        didSet { UserDefaults.standard.set(hasCompletedWelcome, forKey: Keys.hasCompletedWelcome) }
    }

    var shouldShowWelcomeOnLaunch: Bool {
        !hasCompletedWelcome || showWelcomeAtLaunch
    }

    var hotkeyBinding: HotkeyBinding {
        didSet {
            if let data = try? JSONEncoder().encode(hotkeyBinding) {
                UserDefaults.standard.set(data, forKey: Keys.hotkeyBinding)
            }
        }
    }

    var selectedProvider: AIProviderKind {
        didSet { UserDefaults.standard.set(selectedProvider.rawValue, forKey: Keys.selectedProvider) }
    }

    /// Model ID chosen per provider, keyed by `AIProviderKind.rawValue`.
    private var modelByProvider: [String: String] {
        didSet { UserDefaults.standard.set(modelByProvider, forKey: Keys.modelByProvider) }
    }

    var customBaseURL: String {
        didSet { UserDefaults.standard.set(customBaseURL, forKey: Keys.customBaseURL) }
    }

    var temperature: Double {
        didSet { UserDefaults.standard.set(temperature, forKey: Keys.temperature) }
    }

    var whisperModelVariant: String {
        didSet { UserDefaults.standard.set(whisperModelVariant, forKey: Keys.whisperModelVariant) }
    }

    var transcriptionLanguage: String {
        didSet { UserDefaults.standard.set(transcriptionLanguage, forKey: Keys.transcriptionLanguage) }
    }

    /// Developer-controlled prompt - not exposed in preferences UI.
    var systemPrompt: String { PromptDefaults.systemPrompt }

    func model(for kind: AIProviderKind) -> String {
        modelByProvider[kind.rawValue] ?? ProviderRegistry.spec(for: kind).defaultModel
    }

    func setModel(_ model: String, for kind: AIProviderKind) {
        modelByProvider[kind.rawValue] = model
    }

    var selectedModel: String {
        get { model(for: selectedProvider) }
        set { setModel(newValue, for: selectedProvider) }
    }

    init() {
        let defaults = UserDefaults.standard
        launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        soundEffectsEnabled = defaults.object(forKey: Keys.soundEffectsEnabled) as? Bool ?? true
        typeWordByWord = defaults.object(forKey: Keys.typeWordByWord) as? Bool ?? true
        showWelcomeAtLaunch = defaults.object(forKey: Keys.showWelcomeAtLaunch) as? Bool ?? false
        hasCompletedWelcome = defaults.object(forKey: Keys.hasCompletedWelcome) as? Bool ?? false

        if let data = defaults.data(forKey: Keys.hotkeyBinding),
           let saved = try? JSONDecoder().decode(HotkeyBinding.self, from: data) {
            if saved.isLegacyOptionSpace {
                hotkeyBinding = .default
            } else {
                hotkeyBinding = saved
            }
        } else {
            hotkeyBinding = .default
        }

        if let raw = defaults.string(forKey: Keys.selectedProvider),
           let provider = AIProviderKind(rawValue: raw) {
            selectedProvider = provider
        } else {
            selectedProvider = .groq
        }

        customBaseURL = defaults.string(forKey: Keys.customBaseURL) ?? ""
        temperature = defaults.object(forKey: Keys.temperature) as? Double ?? 0.2
        whisperModelVariant = defaults.string(forKey: Keys.whisperModelVariant) ?? WhisperModelCatalog.defaultVariant
        transcriptionLanguage = defaults.string(forKey: Keys.transcriptionLanguage) ?? "en"
        modelByProvider = Self.migratedModels(defaults: defaults)
        defaults.set(modelByProvider, forKey: Keys.modelByProvider)
    }

    /// Folds the legacy single-model keys into the dictionary and rewrites model
    /// IDs that providers have since retired.
    private static func migratedModels(defaults: UserDefaults) -> [String: String] {
        var models = defaults.dictionary(forKey: Keys.modelByProvider) as? [String: String] ?? [:]

        if models[AIProviderKind.groq.rawValue] == nil,
           let legacy = defaults.string(forKey: Keys.legacyGroqModel) {
            models[AIProviderKind.groq.rawValue] = legacy
        }
        if models[AIProviderKind.gemini.rawValue] == nil,
           let legacy = defaults.string(forKey: Keys.legacyGeminiModel) {
            models[AIProviderKind.gemini.rawValue] = legacy
        }

        for (provider, model) in models {
            if let replacement = retiredModels[model] {
                models[provider] = replacement
            }
        }

        return models
    }

    private static let retiredModels: [String: String] = [
        "llama-3.3-70b-versatile": "openai/gpt-oss-120b",
        "llama-3.1-8b-instant": "openai/gpt-oss-20b",
        "gemini-2.0-flash": "gemini-flash-lite-latest",
        "gemini-1.5-flash": "gemini-flash-lite-latest",
        "gemini-1.5-pro": "gemini-pro-latest",
    ]

    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let soundEffectsEnabled = "soundEffectsEnabled"
        static let typeWordByWord = "typeWordByWord"
        static let showWelcomeAtLaunch = "showWelcomeAtLaunch"
        static let hasCompletedWelcome = "hasCompletedWelcome"
        static let hotkeyBinding = "hotkeyBinding"
        static let selectedProvider = "selectedProvider"
        static let modelByProvider = "modelByProvider"
        static let customBaseURL = "customBaseURL"
        static let temperature = "temperature"
        static let whisperModelVariant = "whisperModelVariant"
        static let transcriptionLanguage = "transcriptionLanguage"
        static let legacyGeminiModel = "geminiModel"
        static let legacyGroqModel = "groqModel"
    }
}
