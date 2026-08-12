import AppKit
import SwiftUI

struct ContactPreferences: View {
    @Environment(AppSettings.self) private var settings

    @State private var logSizeBytes: Int64 = 0
    @State private var exportStatus: String?

    var body: some View {
        DoveSettingsPane {
            DoveFormSection(
                "Support",
                footer: "Opens Mail with a diagnostic report attached. Logs never include transcripts, audio, or API keys."
            ) {
                DoveFormRow(label: "Developer") {
                    Text(DoveAppConfig.supportEmail)
                        .foregroundStyle(.secondary)
                }

                if let exportStatus {
                    DoveFormRow(label: "Status") {
                        Text(exportStatus)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: DoveTheme.rowSpacing) {
                    Spacer()
                    Button("Email Logs to Developer", action: emailLogsToDeveloper)
                        .buttonStyle(.borderedProminent)
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
        Dove records only its own unexpected errors. Logs stay on this Mac, are capped in size, \
        and are deleted automatically after a week.
        """
    }

    private func refreshLogSize() {
        logSizeBytes = DiagnosticLog.totalSizeBytes()
    }

    private func emailLogsToDeveloper() {
        switch DiagnosticLog.emailReport(
            to: DoveAppConfig.supportEmail,
            environment: reportEnvironment
        ) {
        case .opened:
            exportStatus = "Mail opened with the report attached."
        case .exportFailed:
            exportStatus = "Could not create the report."
        case .mailUnavailable(let url):
            NSWorkspace.shared.activateFileViewerSelecting([url])
            if let mailtoURL = supportMailtoURL {
                NSWorkspace.shared.open(mailtoURL)
            }
            exportStatus = "Attach the report shown in Finder to your email."
        }
        refreshLogSize()
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

    private var supportMailtoURL: URL? {
        URL(string: "mailto:\(DoveAppConfig.supportEmail)?subject=Dove%20Diagnostic%20Report")
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
