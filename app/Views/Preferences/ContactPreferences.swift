import AppKit
import SwiftUI

struct ContactPreferences: View {
    @Environment(AppSettings.self) private var settings

    @State private var logSizeBytes: Int64 = 0
    @State private var exportStatus: String?

    private var mailtoURL: URL? {
        URL(string: "mailto:\(DoveAppConfig.supportEmail)?subject=Dove%20Support")
    }

    var body: some View {
        DoveSettingsPane {
            DoveFormSection(
                "Support",
                footer: "Attach a diagnostic report so the problem can be traced without guesswork."
            ) {
                DoveFormRow(label: "Email") {
                    if let mailtoURL {
                        Link(DoveAppConfig.supportEmail, destination: mailtoURL)
                    } else {
                        Text(DoveAppConfig.supportEmail)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: DoveTheme.rowSpacing) {
                    Spacer()
                    if let mailtoURL {
                        Link(destination: mailtoURL) {
                            Text("Send Email")
                        }
                    }
                }
            }

            DoveFormSection(
                "Diagnostics",
                footer: diagnosticsFooter
            ) {
                DoveFormRow(label: "Stored logs") {
                    Text(logSizeLabel)
                        .foregroundStyle(.secondary)
                }

                if let exportStatus {
                    DoveFormRow(label: "Last report") {
                        Text(exportStatus)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: DoveTheme.rowSpacing) {
                    Spacer()
                    Button("Reveal in Finder") {
                        DiagnosticLog.revealInFinder()
                    }
                    Button("Export Report…", action: exportReport)
                    Button("Delete Logs", action: deleteLogs)
                        .disabled(logSizeBytes == 0)
                }
            }
        }
        .onAppear(perform: refreshLogSize)
    }

    private var logSizeLabel: String {
        guard logSizeBytes > 0 else { return "None" }
        return ByteCountFormatter.string(fromByteCount: logSizeBytes, countStyle: .file)
    }

    private var diagnosticsFooter: String {
        """
        Dove records only its own unexpected errors, never your transcripts, prompts, \
        audio, or API keys. Logs stay on this Mac, are capped in size, and are deleted \
        automatically after a week.
        """
    }

    private func refreshLogSize() {
        logSizeBytes = DiagnosticLog.totalSizeBytes()
    }

    private func exportReport() {
        guard let url = DiagnosticLog.exportReport(environment: reportEnvironment) else {
            exportStatus = "Could not create the report."
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([url])
        exportStatus = url.lastPathComponent
        refreshLogSize()
    }

    private func deleteLogs() {
        DiagnosticLog.deleteAll()
        exportStatus = nil
        refreshLogSize()
    }

    private var reportEnvironment: [String: String] {
        [
            "Dove": DiagnosticLog.appVersion,
            "macOS": DiagnosticLog.osVersion,
            "AI provider": ProviderRegistry.spec(for: settings.selectedProvider).displayName,
            "AI model": settings.selectedModel,
            "Speech model": settings.whisperModelVariant,
            "Language": settings.transcriptionLanguage,
            "Types word by word": settings.typeWordByWord ? "yes" : "no",
        ]
    }
}

#Preview("Light") {
    ContactPreferences()
        .environment(AppSettings())
        .frame(width: 500, height: 480)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContactPreferences()
        .environment(AppSettings())
        .frame(width: 500, height: 480)
        .preferredColorScheme(.dark)
}
