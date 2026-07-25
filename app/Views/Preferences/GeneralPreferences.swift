import SwiftUI

struct GeneralPreferences: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        DoveSettingsPane {
            DoveFormSection(
                "Startup",
                footer: "Dove opens in the menu bar. It never appears in the Dock."
            ) {
                Toggle("Launch at login", isOn: Bindable(settings).launchAtLogin)
            }

            DoveFormSection(
                "Insertion",
                footer: "Dove types the prompt word by word. Switch apps mid-way and the rest lands in the field you started in."
            ) {
                Toggle("Type word by word", isOn: Bindable(settings).typeWordByWord)
            }

            DoveFormSection(
                "Feedback",
                footer: "Uses macOS system sounds when the HUD appears and closes."
            ) {
                Toggle("Play sound effects", isOn: Bindable(settings).soundEffectsEnabled)
            }
        }
    }
}

#Preview("Light") {
    GeneralPreferences()
        .environment(AppSettings())
        .frame(width: 460, height: 320)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    GeneralPreferences()
        .environment(AppSettings())
        .frame(width: 460, height: 320)
        .preferredColorScheme(.dark)
}
