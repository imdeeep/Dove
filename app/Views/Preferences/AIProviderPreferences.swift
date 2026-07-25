import SwiftUI

struct AIProviderPreferences: View {
    @Environment(AppSettings.self) private var settings

    @State private var apiKey = ""
    @State private var keyStatus = ""
    @State private var hasStoredKey = false
    @State private var models: [AIModel] = []
    @State private var modelStatus = ""
    @State private var isRefreshing = false

    private var spec: ProviderSpec {
        ProviderRegistry.spec(for: settings.selectedProvider)
    }

    var body: some View {
        @Bindable var settings = settings

        DoveSettingsPane {
            DoveFormSection(
                "Provider",
                footer: "Without an API key, Dove inserts the raw transcript instead of a polished prompt."
            ) {
                Picker("Service", selection: $settings.selectedProvider) {
                    ForEach(AIProviderKind.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                if let url = URL(string: spec.consoleURL) {
                    DoveFormRow(label: "API Key Page") {
                        Link(spec.displayName, destination: url)
                    }
                }
            }

            DoveFormSection("Credentials", footer: keyStatus) {
                if spec.isEditableBaseURL {
                    DoveFormRow(label: "Base URL") {
                        TextField("", text: $settings.customBaseURL, prompt: Text("http://localhost:11434/v1"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: DoveTheme.controlWidth)
                    }
                }

                DoveFormRow(label: "API Key") {
                    SecureField("", text: $apiKey, prompt: Text(spec.keyPlaceholder))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: DoveTheme.controlWidth)
                }

                HStack(spacing: DoveTheme.rowSpacing) {
                    Spacer()
                    Button("Remove") {
                        removeAPIKey()
                    }
                    .disabled(!hasStoredKey && apiKey.isEmpty)

                    Button("Save Key") {
                        saveAPIKey()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }

            DoveFormSection("Model", footer: modelStatus) {
                modelPicker

                if supportsTemperature {
                    DoveFormRow(label: "Temperature") {
                        HStack(spacing: DoveTheme.rowSpacing) {
                            Slider(value: $settings.temperature, in: 0...1, step: 0.1)
                            Text(String(format: "%.1f", settings.temperature))
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .trailing)
                        }
                        .frame(width: DoveTheme.controlWidth)
                    }
                }

                HStack(spacing: DoveTheme.rowSpacing) {
                    Spacer()
                    Button("Refresh Models") {
                        Task { await refreshModels() }
                    }
                    .disabled(isRefreshing)
                }
            }
        }
        .onAppear {
            reloadProvider()
        }
        .onChange(of: settings.selectedProvider) { _, _ in
            reloadProvider()
        }
    }

    @ViewBuilder
    private var modelPicker: some View {
        @Bindable var settings = settings

        if models.isEmpty {
            DoveFormRow(label: "Model") {
                TextField("", text: $settings.selectedModel, prompt: Text("model-id"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: DoveTheme.controlWidth)
            }
        } else {
            Picker("Model", selection: $settings.selectedModel) {
                ForEach(models) { model in
                    Text(model.displayName).tag(model.id)
                }
            }
        }
    }

    private var supportsTemperature: Bool {
        ModelCatalog.supportsTemperature(modelID: settings.selectedModel, for: settings.selectedProvider)
    }

    // MARK: - Actions

    private func reloadProvider() {
        loadAPIKey()
        models = ModelDirectoryService.mergedModels(for: settings.selectedProvider)

        let current = settings.selectedModel
        if !models.isEmpty, !models.contains(where: { $0.id == current }) {
            settings.selectedModel = models[0].id
        }

        if let fetched = ModelDirectoryService.lastFetchDate(for: settings.selectedProvider) {
            modelStatus = "Model list updated \(Self.dateFormatter.string(from: fetched))."
        } else {
            modelStatus = "Refresh to pull the current model list from \(spec.displayName)."
        }
    }

    private func refreshModels() async {
        isRefreshing = true
        modelStatus = "Refreshing…"
        defer { isRefreshing = false }

        do {
            _ = try await ModelDirectoryService.refresh(
                spec: spec,
                apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                customBaseURL: settings.customBaseURL
            )
            models = ModelDirectoryService.mergedModels(for: settings.selectedProvider)
            modelStatus = "Model list updated \(Self.dateFormatter.string(from: Date()))."
        } catch {
            modelStatus = ErrorReporter.report(
                error,
                context: "Refresh models for \(spec.displayName)",
                origin: .expected
            )
        }
    }

    private func loadAPIKey() {
        do {
            if let stored = try KeychainService.load(forKey: settings.selectedProvider.keychainAccount),
               !stored.isEmpty {
                hasStoredKey = true
                apiKey = stored
                keyStatus = "Saved in Keychain."
            } else {
                hasStoredKey = false
                apiKey = ""
                keyStatus = "Stored securely in Keychain, never in preferences."
            }
        } catch {
            hasStoredKey = false
            keyStatus = ErrorReporter.report(error, context: "Load API key")
        }
    }

    private func saveAPIKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            keyStatus = "Enter a key before saving."
            return
        }

        do {
            try KeychainService.save(trimmed, forKey: settings.selectedProvider.keychainAccount)
            hasStoredKey = true
            keyStatus = "Saved in Keychain."
        } catch {
            keyStatus = ErrorReporter.report(error, context: "Save API key")
        }
    }

    private func removeAPIKey() {
        do {
            try KeychainService.delete(forKey: settings.selectedProvider.keychainAccount)
            apiKey = ""
            hasStoredKey = false
            keyStatus = "Key removed."
        } catch {
            keyStatus = ErrorReporter.report(error, context: "Remove API key")
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview("Light") {
    AIProviderPreferences()
        .environment(AppSettings())
        .frame(width: 500, height: 460)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    AIProviderPreferences()
        .environment(AppSettings())
        .frame(width: 500, height: 460)
        .preferredColorScheme(.dark)
}
