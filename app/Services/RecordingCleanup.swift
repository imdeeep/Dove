import Foundation

enum RecordingCleanup {
    private static let filePrefix = "voiceprompt-"

    /// Remove a single recording, retrying briefly in case the file is still locked.
    static func deleteRecording(at url: URL) {
        for attempt in 1...3 {
            do {
                guard FileManager.default.fileExists(atPath: url.path) else { return }
                try FileManager.default.removeItem(at: url)
                print("[VoicePrompt] Deleted recording: \(url.lastPathComponent)")
                return
            } catch {
                if attempt == 3 {
                    print("[VoicePrompt] Failed to delete recording: \(error.localizedDescription)")
                } else {
                    usleep(100_000)
                }
            }
        }
    }

    /// Remove leftover temp recordings from earlier runs or crashed sessions.
    static func cleanupStaleRecordings() {
        let tempDirectory = FileManager.default.temporaryDirectory
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: tempDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        var removed = 0
        for url in entries where url.lastPathComponent.hasPrefix(filePrefix) && url.pathExtension == "wav" {
            do {
                try FileManager.default.removeItem(at: url)
                removed += 1
            } catch {
                print("[VoicePrompt] Could not remove stale recording \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        if removed > 0 {
            print("[VoicePrompt] Cleaned up \(removed) stale recording(s)")
        }
    }
}
