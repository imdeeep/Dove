import SwiftUI

/// Product configuration for the Dove settings shell.
enum DoveAppConfig {
    static let appName = "Dove"
    static let supportEmail = "mandeep7yadav@gmail.com"

    enum SectionID: String, CaseIterable {
        case general
        case speech
        case hotkey
        case aiProvider
        case contact

        var title: String {
            switch self {
            case .general: return "General"
            case .speech: return "Speech"
            case .hotkey: return "Hotkey"
            case .aiProvider: return "AI Provider"
            case .contact: return "Contact"
            }
        }

        var systemImage: String {
            switch self {
            case .general: return "gearshape"
            case .speech: return "waveform"
            case .hotkey: return "keyboard"
            case .aiProvider: return "sparkles"
            case .contact: return "envelope"
            }
        }
    }

    static let enabledSections: [SectionID] = [.general, .speech, .hotkey, .aiProvider, .contact]

    static func sections() -> [DoveSettingsSection] {
        enabledSections.map { section in
            DoveSettingsSection(
                id: section.rawValue,
                title: section.title,
                systemImage: section.systemImage
            ) {
                switch section {
                case .general:
                    GeneralPreferences()
                case .speech:
                    SpeechPreferences()
                case .hotkey:
                    HotkeyPreferences()
                case .aiProvider:
                    AIProviderPreferences()
                case .contact:
                    ContactPreferences()
                }
            }
        }
    }
}
