import AppKit

/// Reads Dock settings so the HUD can reserve space when the Dock is auto-hidden.
private struct DockPreferences {
    enum Orientation: String {
        case bottom
        case left
        case right
    }

    let autohide: Bool
    let orientation: Orientation
    let tileSize: CGFloat
    let magnification: Bool
    let largeSize: CGFloat

    static var current: DockPreferences {
        let defaults = UserDefaults(suiteName: "com.apple.dock")
        let orientationRaw = defaults?.string(forKey: "orientation") ?? "bottom"
        return DockPreferences(
            autohide: defaults?.bool(forKey: "autohide") ?? false,
            orientation: Orientation(rawValue: orientationRaw) ?? .bottom,
            tileSize: CGFloat(defaults?.integer(forKey: "tilesize") ?? 48),
            magnification: defaults?.bool(forKey: "magnification") ?? false,
            largeSize: CGFloat(defaults?.integer(forKey: "largesize") ?? 128)
        )
    }

    var estimatedBottomBarHeight: CGFloat {
        let chromePadding = HUDPlacement.autohideDockPadding
        if magnification {
            return min(largeSize, tileSize + 36) + chromePadding
        }
        return tileSize + chromePadding
    }
}

/// Positions the floating HUD at bottom-center, above the Dock safe area.
enum HUDPlacement {
    /// Gap above the bottom of the usable screen (when Dock is always visible).
    static let bottomPadding: CGFloat = 0
    /// Extra Dock chrome height used for auto-hide Dock estimation.
    static let autohideDockPadding: CGFloat = 14
    /// Minimum inset from the left/right edges of the screen.
    static let horizontalPadding: CGFloat = 0
    /// Positive = move HUD down (closer to Dock). Increase to lower, decrease to raise.
    static let bottomOffset: CGFloat = 12

    /// Prefer the screen under the cursor, then main.
    static func targetScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) {
            return screen
        }
        return NSScreen.main
    }

    /// Bottom-center origin, clamped inside the visible work area.
    static func bottomCenterOrigin(panelSize: NSSize, on screen: NSScreen) -> NSPoint {
        let visible = screen.visibleFrame

        var x = visible.midX - panelSize.width / 2
        x = max(visible.minX + horizontalPadding, min(x, visible.maxX - panelSize.width - horizontalPadding))

        let y = visible.minY + bottomSafeInset(on: screen) - bottomOffset
        return NSPoint(x: x, y: y)
    }

    /// Clearance above the bottom edge - accounts for visible and auto-hidden Dock.
    static func bottomSafeInset(on screen: NSScreen) -> CGFloat {
        let dockAlreadyReserved = screen.frame.minY - screen.visibleFrame.minY
        if dockAlreadyReserved > 1 {
            return bottomPadding
        }

        let dock = DockPreferences.current
        guard dock.autohide, dock.orientation == .bottom, hostsDock(screen) else {
            return bottomPadding
        }

        return dock.estimatedBottomBarHeight + bottomPadding
    }

    private static func hostsDock(_ screen: NSScreen) -> Bool {
        screen == NSScreen.main
    }
}
