import Foundation

/// One downloadable WhisperKit variant.
struct WhisperModel: Identifiable, Hashable {
    let id: String
    let displayName: String
    let approximateSizeMB: Int
    /// English-only models ignore the language picker.
    let isEnglishOnly: Bool

    var pickerLabel: String {
        "\(displayName) · ~\(approximateSizeMB) MB"
    }

    func pickerLabel(isDownloaded: Bool) -> String {
        if isDownloaded {
            return "\(displayName) · Already downloaded"
        }
        return pickerLabel
    }
}

/// Curated WhisperKit variants Dove supports. Dove downloads these automatically -
/// users never install models manually.
enum WhisperModelCatalog {
    static let defaultVariant = "small.en"

    static let all: [WhisperModel] = [
        WhisperModel(id: "tiny.en", displayName: "Tiny (English)", approximateSizeMB: 40, isEnglishOnly: true),
        WhisperModel(id: "base.en", displayName: "Base (English)", approximateSizeMB: 75, isEnglishOnly: true),
        WhisperModel(id: "small.en", displayName: "Small (English)", approximateSizeMB: 150, isEnglishOnly: true),
        WhisperModel(id: "medium.en", displayName: "Medium (English)", approximateSizeMB: 750, isEnglishOnly: true),
        WhisperModel(id: "small", displayName: "Small (Multilingual)", approximateSizeMB: 460, isEnglishOnly: false),
        WhisperModel(id: "medium", displayName: "Medium (Multilingual)", approximateSizeMB: 750, isEnglishOnly: false),
        WhisperModel(id: "large-v3", displayName: "Large v3 (Multilingual)", approximateSizeMB: 950, isEnglishOnly: false),
        WhisperModel(id: "large-v3-v20240930_626MB", displayName: "Large v3 Sep 2024", approximateSizeMB: 626, isEnglishOnly: false),
        WhisperModel(id: "distil-large-v3", displayName: "Distil Large v3", approximateSizeMB: 594, isEnglishOnly: false),
    ]

    static func model(id: String) -> WhisperModel? {
        all.first { $0.id == id }
    }

    static let languages: [(code: String, name: String)] = [
        ("en", "English"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("it", "Italian"),
        ("pt", "Portuguese"),
        ("nl", "Dutch"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("zh", "Chinese"),
        ("hi", "Hindi"),
        ("auto", "Auto-detect"),
    ]
}
