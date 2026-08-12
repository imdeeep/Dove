import Foundation

/// Cache layer over the WhisperKit models on disk.
///
/// A model has to be loaded into memory once per app launch, but the work in front
/// of that - asking Hugging Face to resolve the repo and scanning the cache
/// directory - only needs to happen the first time. This remembers where each
/// variant landed so later launches load straight from disk, offline and without a
/// network round trip.
enum WhisperModelCache {
    static var downloadBase: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("huggingface")
    }

    /// Usable folder for `variant`, or `nil` when it still needs downloading.
    static func resolvedFolder(for variant: String) -> URL? {
        if let remembered = rememberedFolder(for: variant), isComplete(remembered) {
            return remembered
        }

        guard let found = locateOnDisk(variant) else {
            forget(variant)
            return nil
        }

        remember(found, for: variant)
        return found
    }

    static func remember(_ folder: URL, for variant: String) {
        guard isComplete(folder) else { return }
        var index = folderIndex()
        index[variant] = folder.path
        UserDefaults.standard.set(index, forKey: folderIndexKey)
    }

    static func isDownloaded(_ variant: String) -> Bool {
        resolvedFolder(for: variant) != nil
    }

    static func downloadedVariantIDs() -> Set<String> {
        Set(WhisperModelCatalog.all.map(\.id).filter(isDownloaded))
    }

    /// Drops every remembered path so the next lookup rescans the disk.
    static func invalidate() {
        UserDefaults.standard.removeObject(forKey: folderIndexKey)
    }

    /// Removes a variant's on-disk folder (even when incomplete) and clears its cache entry.
    static func purgeInstall(for variant: String) {
        forget(variant)

        let fileManager = FileManager.default
        for folder in matchingFolders(for: variant, requireComplete: false) {
            try? fileManager.removeItem(at: folder)
        }
    }

    private static func forget(_ variant: String) {
        var index = folderIndex()
        guard index.removeValue(forKey: variant) != nil else { return }
        UserDefaults.standard.set(index, forKey: folderIndexKey)
    }

    private static func rememberedFolder(for variant: String) -> URL? {
        guard let path = folderIndex()[variant] else { return nil }
        return URL(fileURLWithPath: path)
    }

    private static func folderIndex() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: folderIndexKey) as? [String: String] ?? [:]
    }

    /// An interrupted download leaves a folder behind, so presence alone is not
    /// enough - every Core ML bundle WhisperKit needs has to be there with weights.
    private static func isComplete(_ folder: URL) -> Bool {
        requiredBundles.allSatisfy { bundleHasWeights(in: folder, bundle: $0) }
    }

    private static func bundleHasWeights(in folder: URL, bundle: String) -> Bool {
        let bundleURL = folder.appendingPathComponent(bundle)
        guard isDirectory(bundleURL) else { return false }

        let weightsURL = bundleURL.appendingPathComponent("weights/weight.bin")
        guard FileManager.default.fileExists(atPath: weightsURL.path) else { return false }

        let size = (try? weightsURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return size > 0
    }

    private static func locateOnDisk(_ variant: String) -> URL? {
        matchingFolders(for: variant, requireComplete: true).first
    }

    private static func matchingFolders(for variant: String, requireComplete: Bool) -> [URL] {
        let roots = [
            downloadBase.appendingPathComponent("models/argmaxinc/whisperkit-coreml"),
            downloadBase.appendingPathComponent("models/openai"),
        ]

        var matches: [URL] = []

        for root in roots {
            guard let entries = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in entries {
                guard isDirectory(entry) else { continue }
                guard folderMatches(entry.lastPathComponent, variant: variant) else { continue }
                if requireComplete, !isComplete(entry) { continue }
                matches.append(entry)
            }
        }

        return matches
    }

    private static func isDirectory(_ url: URL) -> Bool {
        if url.hasDirectoryPath { return true }
        guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey]) else { return false }
        return values.isDirectory == true
    }

    private static func folderMatches(_ folderName: String, variant: String) -> Bool {
        let normalized = folderName.lowercased()
        let token = "whisper-\(variant.lowercased())"

        guard normalized.contains(token) else { return false }

        // Multilingual "small" / "medium" must not match their English-only siblings.
        if variant == "small" {
            return !normalized.contains("whisper-small.en")
        }
        if variant == "medium" {
            return !normalized.contains("whisper-medium.en")
        }
        if variant == "large-v3" {
            return !normalized.contains("large-v3-v20240930") && !normalized.contains("distil-large-v3")
        }

        return true
    }

    private static let requiredBundles = [
        "MelSpectrogram.mlmodelc",
        "AudioEncoder.mlmodelc",
        "TextDecoder.mlmodelc",
    ]

    private static let folderIndexKey = "whisperModelFolders"
}
