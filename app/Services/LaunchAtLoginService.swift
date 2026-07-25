import Foundation
import ServiceManagement

enum LaunchAtLoginService {
    static func sync(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[VoicePrompt] Launch at login sync failed: \(error.localizedDescription)")
        }
    }

    static var isRegistered: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
