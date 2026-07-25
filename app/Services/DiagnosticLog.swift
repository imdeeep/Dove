import AppKit
import Foundation

enum DiagnosticLog {
    static var directory: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("Dove/Logs", isDirectory: true)
    }

    // MARK: - Recording

    static func recordFailure(context: String, detail: String) {
        append("FAIL  \(context): \(detail)")
    }

    static func recordNote(_ message: String) {
        append("NOTE  \(message)")
    }

    static func beginSession() {
        let defaults = UserDefaults.standard
        let previousSessionLeftOpen = defaults.bool(forKey: sessionOpenKey)
        defaults.set(true, forKey: sessionOpenKey)

        queue.async { rotate() }

        if previousSessionLeftOpen {
            recordNote("Previous session ended unexpectedly")
        }
        recordNote("Session started - Dove \(appVersion), macOS \(osVersion)")
    }

    static func endSession() {
        UserDefaults.standard.set(false, forKey: sessionOpenKey)
    }

    // MARK: - Management

    static func totalSizeBytes() -> Int64 {
        queue.sync {
            logFiles().reduce(into: Int64(0)) { total, url in
                total += fileSize(url)
            }
        }
    }

    static func deleteAll() {
        queue.sync {
            for url in logFiles() {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    static func revealInFinder() {
        let directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([directory])
    }

    /// Writes a single readable report the user can inspect before emailing it.
    /// Pairs Dove's own log with any macOS crash reports for the app.
    static func exportReport(environment: [String: String]) -> URL? {
        queue.sync { rotate() }

        var report = "Dove Diagnostic Report\n"
        report += "Generated: \(timestamp())\n\n"

        report += "== Environment ==\n"
        for key in environment.keys.sorted() {
            report += "\(key): \(environment[key] ?? "")\n"
        }

        report += "\n== Dove Error Log ==\n"
        let entries = queue.sync { readAllLogs() }
        report += entries.isEmpty ? "No errors recorded.\n" : entries

        report += "\n== Recent macOS Crash Reports ==\n"
        report += crashReports()

        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("Dove-Diagnostics-\(fileStamp()).txt")

        do {
            try report.write(to: destination, atomically: true, encoding: .utf8)
            return destination
        } catch {
            return nil
        }
    }

    // MARK: - Writing

    private static func append(_ line: String) {
        let entry = "[\(timestamp())] \(redact(line))\n"
        queue.async {
            write(entry)
            trimIfNeeded()
        }
    }

    private static func write(_ entry: String) {
        let fileManager = FileManager.default
        let url = todayFileURL()

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            if !fileManager.fileExists(atPath: url.path) {
                try Data().write(to: url)
            }
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(entry.utf8))
        } catch {
            // Diagnostics must never be the reason the app misbehaves.
        }
    }

    /// Keeps a single day's file bounded even during a long, noisy session.
    private static func trimIfNeeded() {
        let url = todayFileURL()
        guard fileSize(url) > maxFileBytes else { return }
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return }

        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
        let kept = lines.suffix(lines.count / 2).joined(separator: "\n")
        try? kept.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Age first, then total size, so the log can never grow without bound.
    private static func rotate() {
        let fileManager = FileManager.default
        let cutoff = Date().addingTimeInterval(-maxAgeDays * 24 * 60 * 60)

        for url in logFiles() where modificationDate(url) < cutoff {
            try? fileManager.removeItem(at: url)
        }

        var files = logFiles().sorted { modificationDate($0) < modificationDate($1) }
        var total = files.reduce(into: Int64(0)) { $0 += fileSize($1) }

        while total > maxTotalBytes, let oldest = files.first {
            total -= fileSize(oldest)
            try? fileManager.removeItem(at: oldest)
            files.removeFirst()
        }
    }

    // MARK: - Reading

    private static func logFiles() -> [URL] {
        let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )
        return (contents ?? []).filter { $0.pathExtension == "log" }
    }

    private static func readAllLogs() -> String {
        logFiles()
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { try? String(contentsOf: $0, encoding: .utf8) }
            .joined()
    }

    /// A hard crash never reaches our own logger, so the system report fills the gap.
    private static func crashReports() -> String {
        let reportsDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/DiagnosticReports")

        let contents = try? FileManager.default.contentsOfDirectory(
            at: reportsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        let doveReports = (contents ?? [])
            .filter { $0.lastPathComponent.hasPrefix("Dove") }
            .sorted { modificationDate($0) > modificationDate($1) }
            .prefix(maxCrashReports)

        guard !doveReports.isEmpty else {
            return "None found.\n"
        }

        var output = ""
        for url in doveReports {
            output += "\n--- \(url.lastPathComponent) ---\n"
            if let contents = try? String(contentsOf: url, encoding: .utf8) {
                output += redact(String(contents.prefix(maxCrashReportCharacters)))
                if contents.count > maxCrashReportCharacters {
                    output += "\n… (truncated)\n"
                }
            } else {
                output += "Could not be read.\n"
            }
        }
        return output
    }

    // MARK: - Redaction

    /// Last line of defence. Call sites are already careful, but a stray key or
    /// home-directory path must never survive into a file the user emails.
    private static func redact(_ text: String) -> String {
        var result = text.replacingOccurrences(of: NSHomeDirectory(), with: "~")

        for pattern in secretPatterns {
            result = result.replacingOccurrences(
                of: pattern,
                with: "[redacted]",
                options: [.regularExpression]
            )
        }

        if result.count > maxEntryCharacters {
            result = String(result.prefix(maxEntryCharacters)) + "… (truncated)"
        }

        return result
    }

    // MARK: - Helpers

    private static func todayFileURL() -> URL {
        directory.appendingPathComponent("dove-\(dayStamp()).log")
    }

    private static func fileSize(_ url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    private static func modificationDate(_ url: URL) -> Date {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate ?? .distantPast
    }

    private static func timestamp() -> String {
        Date().formatted(.iso8601)
    }

    private static func dayStamp() -> String {
        Date().formatted(.iso8601.year().month().day().dateSeparator(.dash))
    }

    private static func fileStamp() -> String {
        Date().formatted(
            .iso8601
                .year().month().day()
                .dateSeparator(.dash)
                .time(includingFractionalSeconds: false)
        )
        .replacingOccurrences(of: ":", with: "")
    }

    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    static var osVersion: String {
        ProcessInfo.processInfo.operatingSystemVersionString
    }

    private static let queue = DispatchQueue(label: "com.mandeep.Dove.diagnostics")

    private static let secretPatterns = [
        "(?i)\\b(sk|gsk|xai|api|key|token|secret)[-_][A-Za-z0-9_-]{8,}",
        "\\b[A-Za-z0-9_-]{32,}\\b",
    ]

    private static let sessionOpenKey = "diagnosticSessionOpen"
    private static let maxAgeDays: TimeInterval = 7
    private static let maxTotalBytes: Int64 = 5 * 1024 * 1024
    private static let maxFileBytes: Int64 = 1024 * 1024
    private static let maxEntryCharacters = 600
    private static let maxCrashReports = 2
    private static let maxCrashReportCharacters = 12_000
}
