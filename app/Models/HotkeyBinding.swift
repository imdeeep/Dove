import AppKit
import CoreGraphics
import Foundation

struct HotkeyBinding: Codable, Equatable {
    var keyCode: UInt16
    var modifierFlags: UInt64

    /// Legacy default (Option+Space) - conflicts with IDE cursor movement.
    static let legacyOptionSpace = HotkeyBinding(
        keyCode: 49,
        modifierFlags: CGEventFlags.maskAlternate.rawValue
    )

    var isLegacyOptionSpace: Bool {
        self == Self.legacyOptionSpace
    }

    /// Control + Shift + Space - avoids Option+Space moving the cursor in IDEs.
    static let `default` = HotkeyBinding(
        keyCode: 49,
        modifierFlags: HotkeyBinding.modifierMask(rawValue: CGEventFlags([.maskControl, .maskShift]).rawValue).rawValue
    )

    var requiredFlags: CGEventFlags {
        Self.modifierMask(rawValue: modifierFlags)
    }

    func matches(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        guard keyCode == self.keyCode else { return false }
        let active = Self.modifierMask(rawValue: flags.rawValue)
        return active.contains(requiredFlags)
    }

    func modifiersStillHeld(_ flags: CGEventFlags) -> Bool {
        let active = Self.modifierMask(rawValue: flags.rawValue)
        return active.contains(requiredFlags)
    }

    func involvesModifierKeyCode(_ keyCode: CGKeyCode) -> Bool {
        guard requiredFlags != [] else { return false }

        if requiredFlags.contains(.maskControl), Self.controlKeyCodes.contains(keyCode) { return true }
        if requiredFlags.contains(.maskShift), Self.shiftKeyCodes.contains(keyCode) { return true }
        if requiredFlags.contains(.maskAlternate), Self.optionKeyCodes.contains(keyCode) { return true }
        if requiredFlags.contains(.maskCommand), Self.commandKeyCodes.contains(keyCode) { return true }
        return false
    }

    private static let controlKeyCodes: Set<CGKeyCode> = [59, 62]
    private static let shiftKeyCodes: Set<CGKeyCode> = [56, 60]
    private static let optionKeyCodes: Set<CGKeyCode> = [58, 61]
    private static let commandKeyCodes: Set<CGKeyCode> = [55, 54]

    private static func modifierMask(rawValue: UInt64) -> CGEventFlags {
        CGEventFlags(rawValue: rawValue).intersection([
            .maskShift, .maskControl, .maskAlternate, .maskCommand, .maskSecondaryFn,
        ])
    }

    var displayString: String {
        var parts: [String] = []
        let flags = requiredFlags

        if flags.contains(.maskControl) { parts.append("⌃") }
        if flags.contains(.maskAlternate) { parts.append("⌥") }
        if flags.contains(.maskShift) { parts.append("⇧") }
        if flags.contains(.maskCommand) { parts.append("⌘") }

        parts.append(Self.keyDisplayName(for: keyCode))
        return parts.joined()
    }

    private static func keyDisplayName(for keyCode: UInt16) -> String {
        switch keyCode {
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 53: return "Escape"
        case 51: return "Delete"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default:
            if let scalar = Self.layoutIndependentKeyCharacter(for: keyCode) {
                return String(scalar).uppercased()
            }
            return "Key \(keyCode)"
        }
    }

    private static func layoutIndependentKeyCharacter(for keyCode: UInt16) -> Character? {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true),
              let nsEvent = NSEvent(cgEvent: event),
              let chars = nsEvent.charactersIgnoringModifiers, let first = chars.first else {
            return nil
        }
        return first
    }
}
