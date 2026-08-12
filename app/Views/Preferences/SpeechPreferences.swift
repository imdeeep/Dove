import SwiftUI

struct SpeechPreferences: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.transcriptionService) private var transcriptionService

    @State private var downloadedVariantIDs: Set<String> = WhisperModelCache.downloadedVariantIDs()

    private var selectedModel: WhisperModel? {
        WhisperModelCatalog.model(id: settings.whisperModelVariant)
    }

    private var isEnglishOnly: Bool {
        selectedModel?.isEnglishOnly ?? settings.whisperModelVariant.hasSuffix(".en")
    }

    private var isSelectedModelDownloaded: Bool {
        downloadedVariantIDs.contains(settings.whisperModelVariant)
            || transcriptionService?.isModelInstalled(settings.whisperModelVariant) == true
    }

    var body: some View {
        DoveSettingsPane {
            DoveFormSection(
                "Speech Model",
                footer: statusMessage
            ) {
                Picker("Model", selection: Bindable(settings).whisperModelVariant) {
                    ForEach(WhisperModelCatalog.all) { model in
                        Text(model.pickerLabel(isDownloaded: isDownloaded(model.id)))
                            .tag(model.id)
                    }
                }
                .onChange(of: settings.whisperModelVariant) { _, newVariant in
                    if WhisperModelCatalog.model(id: newVariant)?.isEnglishOnly == true {
                        settings.transcriptionLanguage = "en"
                    }
                    refreshDownloadedVariants()
                    Task { await reloadModel() }
                }

                if !isEnglishOnly {
                    Picker("Language", selection: Bindable(settings).transcriptionLanguage) {
                        ForEach(WhisperModelCatalog.languages, id: \.code) { language in
                            Text(language.name).tag(language.code)
                        }
                    }
                }

                HStack(spacing: DoveTheme.rowSpacing) {
                    Spacer()
                    Button(downloadButtonTitle) {
                        Task { await downloadModel() }
                    }
                    .disabled(transcriptionService?.isDownloading == true)
                }
            }

            DoveFormSection(
                "How it works",
                footer: "Models are stored in your Documents folder and work offline after the first download."
            ) {
                DoveFormRow(label: "Status") {
                    Text(installationStatusLabel)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            transcriptionService?.revalidateInstalledModels()
            refreshDownloadedVariants()
        }
    }

    private func isDownloaded(_ variant: String) -> Bool {
        downloadedVariantIDs.contains(variant)
            || transcriptionService?.isModelInstalled(variant) == true
    }

    private func refreshDownloadedVariants() {
        downloadedVariantIDs = WhisperModelCache.downloadedVariantIDs()
            .union(transcriptionService.map { service in
                Set(WhisperModelCatalog.all.compactMap { service.isModelInstalled($0.id) ? $0.id : nil })
            } ?? [])
    }

    private var downloadButtonTitle: String {
        if transcriptionService?.lastError != nil {
            return "Repair Model"
        }
        return isSelectedModelDownloaded ? "Load Model" : "Download Now"
    }

    private var statusMessage: String {
        guard let service = transcriptionService else {
            return "Speech engine is unavailable."
        }

        if let error = service.lastError {
            return error
        }

        if service.isDownloading {
            let percent = Int(service.downloadProgress * 100)
            return "Downloading \(settings.whisperModelVariant)… \(percent)%"
        }

        if service.isModelReady && service.loadedVariant == settings.whisperModelVariant {
            return "Ready for offline transcription."
        }

        if isSelectedModelDownloaded {
            return "Downloaded to disk. Dove loads it automatically when you record."
        }

        return "Dove downloads this model automatically on first use. Use Download Now to fetch it ahead of time."
    }

    private var installationStatusLabel: String {
        guard let service = transcriptionService else { return "Unavailable" }

        if service.isModelReady && service.loadedVariant == settings.whisperModelVariant {
            return "Ready"
        }
        if service.isDownloading {
            return "Downloading…"
        }
        if isSelectedModelDownloaded {
            return "Already downloaded"
        }
        return "Not downloaded yet"
    }

    private func downloadModel() async {
        guard let service = transcriptionService else { return }
        await service.prepareModelIfNeeded(settings: settings)
        refreshDownloadedVariants()
    }

    private func reloadModel() async {
        guard let service = transcriptionService else { return }
        service.invalidateLoadedModel()

        if isSelectedModelDownloaded {
            await service.prepareModelIfNeeded(settings: settings)
        }

        refreshDownloadedVariants()
    }
}

#Preview("Light") {
    SpeechPreferences()
        .environment(AppSettings())
        .frame(width: 500, height: 460)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SpeechPreferences()
        .environment(AppSettings())
        .frame(width: 500, height: 460)
        .preferredColorScheme(.dark)
}
