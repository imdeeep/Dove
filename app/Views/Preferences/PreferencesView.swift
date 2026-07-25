import SwiftUI

struct PreferencesView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        DoveSettingsWindow(
            appName: DoveAppConfig.appName,
            sections: DoveAppConfig.sections()
        )
        .environment(settings)
    }
}

#Preview("Light") {
    PreferencesView()
        .environment(AppSettings())
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PreferencesView()
        .environment(AppSettings())
        .preferredColorScheme(.dark)
}
