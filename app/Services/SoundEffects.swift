import AppKit

/// Short macOS system sounds for HUD feedback. Respects the user's sound toggle.
enum SoundEffects {
    enum HUD {
        static let appear = NSSound.Name("Tink")
        static let dismiss = NSSound.Name("Purr")
    }

    static func playHUDAppear(enabled: Bool) {
        play(HUD.appear, enabled: enabled)
    }

    static func playHUDDismiss(enabled: Bool) {
        play(HUD.dismiss, enabled: enabled)
    }

    private static func play(_ name: NSSound.Name, enabled: Bool) {
        guard enabled else { return }
        guard let sound = NSSound(named: name) else { return }
        sound.stop()
        sound.play()
    }
}
