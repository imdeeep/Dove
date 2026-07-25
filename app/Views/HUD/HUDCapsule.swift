import SwiftUI

enum HUDCapsuleAccent {
    case listening
    case processing
    case success
    case error
}

/// Motion tokens - Linear precision + calm pacing (design-tokens.md).
enum HUDMotion {
    static let frameInterval: TimeInterval = 0.08
    static let appearDuration: TimeInterval = 0.25
    static let dismissDuration: TimeInterval = 0.20
    static let waveformSpeed: Double = 1.6
    static let processingSpeed: Double = 1.2
    static let gradientDriftSpeed: Double = 0.35
    static let sheenDriftSpeed: Double = 0.40
}

/// Logo-inspired capsule: matte black field with a slow, quiet gradient drift.
struct HUDCapsule<Content: View>: View {
    let accent: HUDCapsuleAccent
    var compact: Bool
    @ViewBuilder var content: Content

    init(
        accent: HUDCapsuleAccent,
        compact: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.accent = accent
        self.compact = compact
        self.content = content()
    }

    private var width: CGFloat { compact ? 280 : 320 }
    private var height: CGFloat { compact ? 44 : 48 }
    private var horizontalPadding: CGFloat { compact ? 24 : 32 }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, horizontalPadding)
            .frame(width: width, height: height)
            .background {
                CapsuleBackground(accent: accent)
                    .clipShape(Capsule())
                    .drawingGroup(opaque: false)
            }
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(HUDBrandColors.border, lineWidth: 0.5)
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        AnimatedBorderGradient(accent: accent),
                        lineWidth: 0.5
                    )
            }
    }
}

private struct AnimatedBorderGradient: ShapeStyle {
    let accent: HUDCapsuleAccent

    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(borderHighlightOpacity),
                Color.white.opacity(0.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var borderHighlightOpacity: Double {
        switch accent {
        case .listening: 0.07
        case .processing: 0.05
        case .success: 0.06
        case .error: 0.04
        }
    }
}

private struct CapsuleBackground: View {
    let accent: HUDCapsuleAccent

    var body: some View {
        TimelineView(.animation(minimumInterval: HUDMotion.frameInterval)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                Capsule()
                    .fill(baseGradient(phase: phase))

                driftingSheen(phase: phase)
                    .clipShape(Capsule())

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.03),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.55)
                        )
                    )
            }
        }
    }

    private func baseGradient(phase: TimeInterval) -> LinearGradient {
        let drift = sin(phase * HUDMotion.gradientDriftSpeed) * 0.06
        return LinearGradient(
            colors: [
                HUDBrandColors.capsuleTop,
                HUDBrandColors.capsuleMid,
                HUDBrandColors.capsuleBottom,
            ],
            startPoint: UnitPoint(x: 0.5 + drift, y: 0),
            endPoint: UnitPoint(x: 0.5 - drift, y: 1)
        )
    }

    @ViewBuilder
    private func driftingSheen(phase: TimeInterval) -> some View {
        let intensity = sheenIntensity
        let x = 0.42 + 0.14 * sin(phase * HUDMotion.sheenDriftSpeed)
        let y = 0.46 + 0.04 * cos(phase * HUDMotion.sheenDriftSpeed * 0.7)

        GeometryReader { geo in
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(intensity),
                            Color.white.opacity(intensity * 0.35),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: geo.size.width * 0.24
                    )
                )
                .frame(width: geo.size.width * 0.44, height: geo.size.height * 1.08)
                .position(x: geo.size.width * x, y: geo.size.height * y)
        }
    }

    private var sheenIntensity: Double {
        switch accent {
        case .listening: 0.055
        case .processing: 0.035
        case .success: 0.045
        case .error: 0.025
        }
    }
}

/// Shared waveform - linear pulse with a soft animated gradient fill.
struct HUDWaveformBars: View {
    var barCount: Int = 7
    var barWidth: CGFloat = 3
    var maxHeight: CGFloat = 24
    var spacing: CGFloat = 4
    var levelProvider: (() -> CGFloat)?
    var speed: Double = HUDMotion.waveformSpeed

    var body: some View {
        TimelineView(.animation(minimumInterval: HUDMotion.frameInterval)) { timeline in
            HStack(spacing: spacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    Capsule()
                        .fill(barGradient(index: index, date: timeline.date))
                        .frame(width: barWidth, height: barHeight(index: index, date: timeline.date))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: maxHeight, alignment: .center)
        }
    }

    private func barGradient(index: Int, date: Date) -> LinearGradient {
        let phase = date.timeIntervalSinceReferenceDate * speed
        let breathe = 0.04 * sin(phase * 0.5 + Double(index) * 0.4)
        return LinearGradient(
            colors: [
                Color.white.opacity(0.80 + breathe),
                Color.white.opacity(0.48 + breathe * 0.5),
            ],
            startPoint: UnitPoint(x: 0.5, y: 0),
            endPoint: UnitPoint(x: 0.5, y: 1)
        )
    }

    private func barHeight(index: Int, date: Date) -> CGFloat {
        let phase = date.timeIntervalSinceReferenceDate * speed
        let idlePulse = 0.38 + 0.10 * sin(phase + Double(index) * 0.55)
        let level = levelProvider?() ?? 0
        let activeLevel = level > 0.05 ? level : CGFloat(idlePulse)
        let variation = 0.82 + 0.18 * sin(phase * 0.65 + Double(index) * 0.75)
        return max(4, maxHeight * activeLevel * variation)
    }
}

/// Brand palette - warm dark field, soft silver accents.
enum HUDBrandColors {
    static let capsuleTop = Color(white: 0.12)
    static let capsuleMid = Color(white: 0.10)
    static let capsuleBottom = Color(white: 0.08)
    static let border = Color.white.opacity(0.08)
    static let textPrimary = Color.white.opacity(0.88)
    static let textSecondary = Color.white.opacity(0.48)

    static let waveformTop = Color.white.opacity(0.80)
    static let waveformBottom = Color.white.opacity(0.48)
}

enum HUDCapsuleColors {
    static let primary = HUDBrandColors.textPrimary
    static let secondary = HUDBrandColors.textSecondary
}

#Preview("Capsule Waveform") {
    HUDCapsule(accent: .listening, compact: false) {
        HUDWaveformBars()
    }
    .padding(40)
    .background(Color(white: 0.15))
}

#Preview("Processing") {
    HUDCapsule(accent: .processing) {
        HUDWaveformBars(barCount: 3, barWidth: 2, maxHeight: 14, spacing: 3, speed: HUDMotion.processingSpeed)
    }
    .padding(40)
    .background(Color(white: 0.15))
}
