import SwiftUI

/// Configurable macOS settings shell - sidebar + detail (System Settings pattern).
struct DoveSettingsWindow: View {
    let appName: String
    let sections: [DoveSettingsSection]

    @State private var selection: String

    init(appName: String, sections: [DoveSettingsSection]) {
        self.appName = appName
        self.sections = sections
        _selection = State(initialValue: sections.first?.id ?? "")
    }

    private var selectedSection: DoveSettingsSection? {
        sections.first { $0.id == selection }
    }

    var body: some View {
        NavigationSplitView {
            List(sections, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
            }
            .navigationSplitViewColumnWidth(
                min: DoveTheme.sidebarMinWidth,
                ideal: DoveTheme.sidebarWidth,
                max: DoveTheme.sidebarMaxWidth
            )
            .toolbar(removing: .sidebarToggle)
        } detail: {
            selectedSection?.content
                .navigationTitle(selectedSection?.title ?? appName)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: DoveTheme.windowMinWidth, minHeight: DoveTheme.windowMinHeight)
    }
}

#Preview("Light") {
    DoveSettingsWindow(
        appName: DoveAppConfig.appName,
        sections: DoveAppConfig.sections()
    )
    .environment(AppSettings())
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    DoveSettingsWindow(
        appName: DoveAppConfig.appName,
        sections: DoveAppConfig.sections()
    )
    .environment(AppSettings())
    .preferredColorScheme(.dark)
}
