import AppKit
import Foundation

enum UpdateCheckResult: Sendable {
    case upToDate
    case updateAvailable(version: String)
    case checkFailed
}

enum UpdateChecker {
    private struct VersionManifest: Decodable {
        let version: String
        let downloadUrl: String?
    }

    static func checkForUpdates() async -> UpdateCheckResult {
        var request = URLRequest(url: DoveReleaseConfig.versionCheckURL)
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return .checkFailed
            }

            let manifest = try JSONDecoder().decode(VersionManifest.self, from: data)
            let installed = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

            if isVersion(manifest.version, newerThan: installed) {
                return .updateAvailable(version: manifest.version)
            }
            return .upToDate
        } catch {
            return .checkFailed
        }
    }

    @MainActor
    static func presentResult(_ result: UpdateCheckResult) {
        switch result {
        case .upToDate:
            showAlert(
                title: "You're up to date",
                message: "Dove \(installedVersion) is the latest version."
            )

        case .updateAvailable(let version):
            let opened = NSWorkspace.shared.open(DoveReleaseConfig.downloadURL)
            if opened {
                showAlert(
                    title: "Update available",
                    message: "Dove \(version) is available. Your browser will download the latest release."
                )
            } else {
                showAlert(
                    title: "Update available",
                    message: "Dove \(version) is available. Visit \(downloadPageLabel) to get it."
                )
            }

        case .checkFailed:
            _ = NSWorkspace.shared.open(DoveReleaseConfig.downloadURL)
            showAlert(
                title: "Couldn't check for updates",
                message: "Visit \(downloadPageLabel) to get the latest version."
            )
        }
    }

    private static var websiteHost: String {
        DoveReleaseConfig.websiteURL.host ?? "dove.imdeeep.in"
    }

    private static var downloadPageLabel: String {
        "\(websiteHost)/download"
    }

    @MainActor
    private static func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static var installedVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    /// Compares dotted version strings (e.g. 1.0.0 vs 1.1.0).
    static func isVersion(_ remote: String, newerThan installed: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let installedParts = installed.split(separator: ".").compactMap { Int($0) }
        let count = max(remoteParts.count, installedParts.count)

        for index in 0..<count {
            let remoteValue = index < remoteParts.count ? remoteParts[index] : 0
            let installedValue = index < installedParts.count ? installedParts[index] : 0
            if remoteValue > installedValue { return true }
            if remoteValue < installedValue { return false }
        }
        return false
    }
}
