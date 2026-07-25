import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

struct InsertionTarget {
    let processID: pid_t
    let bundleIdentifier: String?

    static func captureFrontmost() -> InsertionTarget? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return InsertionTarget(
            processID: app.processIdentifier,
            bundleIdentifier: app.bundleIdentifier
        )
    }
}

enum TextInserterError: LocalizedError {
    case accessibilityNotTrusted
    case noFocusedElement
    case insertionFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessibilityNotTrusted:
            return "Accessibility permission is required to insert text"
        case .noFocusedElement:
            return "No focused text field found"
        case .insertionFailed(let message):
            return message
        }
    }
}

@MainActor
enum TextInserter {
    private static let prePasteSettleMicroseconds: useconds_t = 100_000
    private static let pasteCompletionDelayMicroseconds: useconds_t = 350_000
    private static let commandVKeyCode: CGKeyCode = 9
    private static let returnKeyCode: CGKeyCode = 36

    /// Typing cadence. Values are milliseconds between words.
    private enum Cadence {
        static let word = 22
        static let afterComma = 45
        static let afterSentence = 110
        /// Fraction of `word` added or removed at random so the rhythm is not mechanical.
        static let jitter = 0.4
    }

    /// `CGEvent` truncates long unicode payloads, so words are typed in small slices.
    private static let maxUnicodeUnitsPerEvent = 16

    /// Electron and Chromium apps need clipboard paste; AX often "succeeds" on the wrong element.
    private static let clipboardOnlyBundleIDs: Set<String> = [
        "com.microsoft.VSCode",
        "com.google.Chrome",
        "com.google.Chrome.canary",
        "com.apple.Safari",
        "com.slack.Slack",
        "notion.id",
        "com.figma.Desktop",
    ]

    private static let clipboardOnlyBundleIDPrefixes = [
        "com.todesktop.", // Cursor (ToDesktop builds)
        "com.github.",    // GitHub Desktop and similar Electron apps
    ]

    /// Insert text at the cursor in the currently focused application.
    static func insert(_ text: String, target: InsertionTarget? = nil) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard PermissionsHelper.isAccessibilityTrusted else {
            throw TextInserterError.accessibilityNotTrusted
        }

        let resolvedTarget = target ?? InsertionTarget.captureFrontmost()
        activateTarget(resolvedTarget)

        let bundleID = resolvedTarget?.bundleIdentifier
            ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        if prefersClipboardPaste(bundleID: bundleID) {
            print("[VoicePrompt] Using clipboard paste for \(bundleID ?? "unknown app")")
            try insertViaClipboardPaste(trimmed, targetPID: resolvedTarget?.processID)
            return
        }

        if insertViaAccessibility(trimmed) {
            print("[VoicePrompt] Inserted via Accessibility API")
            return
        }

        print("[VoicePrompt] Accessibility insert unavailable - using clipboard paste")
        try insertViaClipboardPaste(trimmed, targetPID: resolvedTarget?.processID)
    }

    /// Type the prompt one word at a time so it lands like real typing rather than a paste.
    ///
    /// Focus is re-checked before every word. If the user switches app or clicks into a
    /// different field mid-way, typing stops immediately and whatever is left is delivered
    /// in one go to the field the prompt started in - so no words leak into the wrong place.
    static func insertByTyping(_ text: String, target: InsertionTarget? = nil) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard PermissionsHelper.isAccessibilityTrusted else {
            throw TextInserterError.accessibilityNotTrusted
        }

        let resolvedTarget = target ?? InsertionTarget.captureFrontmost()
        activateTarget(resolvedTarget)

        let anchorElement = focusedElement()
        let words = words(in: trimmed)

        for (index, word) in words.enumerated() {
            guard focusIsUnchanged(target: resolvedTarget, anchor: anchorElement) else {
                let remainder = words[index...].joined()
                print("[Dove] Focus changed while typing - inserting the rest at once")
                try insertRemainder(remainder, anchor: anchorElement, target: resolvedTarget)
                return
            }

            guard typeWord(word) else {
                let remainder = words[index...].joined()
                print("[Dove] Typing unavailable - inserting the rest at once")
                try insertRemainder(remainder, anchor: anchorElement, target: resolvedTarget)
                return
            }

            if index < words.count - 1 {
                try? await Task.sleep(for: .milliseconds(delay(after: word)))
            }
        }
    }

    // MARK: - Typing

    /// Splits into words that carry their own trailing spaces, so joining any suffix
    /// reproduces the original text exactly. Newlines become their own chunk.
    private static func words(in text: String) -> [String] {
        var chunks: [String] = []
        var current = ""

        for character in text {
            if character.isNewline {
                if !current.isEmpty {
                    chunks.append(current)
                    current = ""
                }
                chunks.append(String(character))
            } else if character == " " {
                current.append(character)
                chunks.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }

        if !current.isEmpty {
            chunks.append(current)
        }
        return chunks
    }

    private static func delay(after word: String) -> Int {
        let base: Int
        switch word.trimmingCharacters(in: .whitespaces).last {
        case ".", "!", "?":
            base = Cadence.afterSentence
        case ",", ";", ":":
            base = Cadence.afterComma
        default:
            base = Cadence.word
        }

        let spread = Double(Cadence.word) * Cadence.jitter
        return max(1, base + Int(Double.random(in: -spread...spread)))
    }

    private static func typeWord(_ word: String) -> Bool {
        if word == "\n" || word == "\r\n" {
            return postKey(returnKeyCode)
        }

        let units = Array(word.utf16)
        var start = units.startIndex
        while start < units.endIndex {
            let end = min(start + maxUnicodeUnitsPerEvent, units.endIndex)
            guard postUnicode(Array(units[start..<end])) else { return false }
            start = end
        }
        return true
    }

    private static func postUnicode(_ units: [UInt16]) -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            return false
        }

        keyDown.flags = []
        keyUp.flags = []

        units.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            keyDown.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
            keyUp.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
        }

        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
        return true
    }

    private static func postKey(_ keyCode: CGKeyCode) -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return false
        }

        keyDown.flags = []
        keyUp.flags = []
        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
        return true
    }

    private static func focusIsUnchanged(target: InsertionTarget?, anchor: AXUIElement?) -> Bool {
        if let target,
           NSWorkspace.shared.frontmostApplication?.processIdentifier != target.processID {
            return false
        }

        guard let anchor else { return true }
        guard let current = focusedElement() else { return false }
        return CFEqual(current, anchor)
    }

    /// Deliver the untyped tail to the original field, preferring a direct
    /// Accessibility write so we never have to yank focus back from the user.
    private static func insertRemainder(
        _ remainder: String,
        anchor: AXUIElement?,
        target: InsertionTarget?
    ) throws {
        guard !remainder.isEmpty else { return }

        if let anchor,
           setAttributeIfPossible(
               anchor,
               attribute: kAXSelectedTextAttribute as CFString,
               value: remainder as CFTypeRef
           ),
           verifyTextPresent(in: anchor, text: remainder) {
            return
        }

        activateTarget(target)
        try insertViaClipboardPaste(remainder, targetPID: target?.processID)
    }

    // MARK: - Target app

    private static func prefersClipboardPaste(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        if clipboardOnlyBundleIDs.contains(bundleID) { return true }
        return clipboardOnlyBundleIDPrefixes.contains { bundleID.hasPrefix($0) }
    }

    private static func activateTarget(_ target: InsertionTarget?) {
        guard let target else { return }
        NSRunningApplication(processIdentifier: target.processID)?
            .activate(options: [.activateIgnoringOtherApps])
        usleep(prePasteSettleMicroseconds)
    }

    // MARK: - Accessibility

    private static func insertViaAccessibility(_ text: String) -> Bool {
        guard let element = focusedElement() else { return false }

        if setAttributeIfPossible(element, attribute: kAXSelectedTextAttribute as CFString, value: text as CFTypeRef),
           verifyTextPresent(in: element, text: text) {
            return true
        }

        if appendViaValueAttribute(element, text: text),
           verifyTextPresent(in: element, text: text) {
            return true
        }

        return false
    }

    private static func focusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focused
        ) == .success, let focused else {
            return nil
        }
        return (focused as! AXUIElement)
    }

    private static func setAttributeIfPossible(
        _ element: AXUIElement,
        attribute: CFString,
        value: CFTypeRef
    ) -> Bool {
        var settable = DarwinBoolean(false)
        guard AXUIElementIsAttributeSettable(element, attribute, &settable) == .success,
              settable.boolValue else {
            return false
        }
        return AXUIElementSetAttributeValue(element, attribute, value) == .success
    }

    private static func appendViaValueAttribute(_ element: AXUIElement, text: String) -> Bool {
        guard isAttributeSettable(element, attribute: kAXValueAttribute as CFString) else {
            return false
        }

        var currentValue: CFTypeRef?
        let readResult = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &currentValue
        )

        let current = (readResult == .success ? currentValue as? String : nil) ?? ""
        let combined = current + text
        return AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            combined as CFTypeRef
        ) == .success
    }

    private static func verifyTextPresent(in element: AXUIElement, text: String) -> Bool {
        if let value = attributeString(element, attribute: kAXValueAttribute as CFString),
           value.contains(text) {
            return true
        }
        if let selected = attributeString(element, attribute: kAXSelectedTextAttribute as CFString),
           selected.contains(text) {
            return true
        }
        return false
    }

    private static func attributeString(_ element: AXUIElement, attribute: CFString) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else {
            return nil
        }
        return value as? String
    }

    private static func isAttributeSettable(_ element: AXUIElement, attribute: CFString) -> Bool {
        var settable = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(element, attribute, &settable) == .success
            && settable.boolValue
    }

    // MARK: - Clipboard fallback

    private static func insertViaClipboardPaste(_ text: String, targetPID: pid_t?) throws {
        let pasteboard = NSPasteboard.general
        let savedString = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw TextInserterError.insertionFailed("Could not write prompt to clipboard")
        }

        let pid = targetPID ?? NSWorkspace.shared.frontmostApplication?.processIdentifier
        guard postCommandV(to: pid) else {
            restoreClipboard(savedString: savedString, pasteboard: pasteboard)
            throw TextInserterError.insertionFailed("Could not simulate ⌘V paste")
        }

        usleep(pasteCompletionDelayMicroseconds)
        restoreClipboard(savedString: savedString, pasteboard: pasteboard)
    }

    private static func postCommandV(to pid: pid_t?) -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return false }

        guard let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: commandVKeyCode,
            keyDown: true
        ), let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: commandVKeyCode,
            keyDown: false
        ) else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        if let pid {
            keyDown.postToPid(pid)
            keyUp.postToPid(pid)
        } else {
            keyDown.post(tap: .cgSessionEventTap)
            keyUp.post(tap: .cgSessionEventTap)
        }
        return true
    }

    private static func restoreClipboard(savedString: String?, pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        if let savedString {
            pasteboard.setString(savedString, forType: .string)
        }
    }
}
