import SwiftUI

struct ProcessingView: View {
    let step: ProcessingStep

    var body: some View {
        HUDCapsule(accent: .processing) {
            HStack(spacing: 12) {
                HUDWaveformBars(
                    barCount: 3,
                    barWidth: 2,
                    maxHeight: 14,
                    spacing: 3,
                    speed: HUDMotion.processingSpeed
                )
                .frame(width: 14)

                Text(label)
                    .font(.headline)
                    .foregroundStyle(HUDCapsuleColors.primary)
            }
        }
    }

    private var label: String {
        switch step {
        case .transcribing:
            return "Transcribing…"
        case .polishing:
            return "Polishing Prompt…"
        case .inserting:
            return "Inserting…"
        }
    }
}

#Preview("Light") {
    VStack(spacing: 16) {
        ProcessingView(step: .transcribing)
        ProcessingView(step: .polishing)
    }
    .padding(40)
    .background(Color(red: 0.97, green: 0.97, blue: 0.95))
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 16) {
        ProcessingView(step: .transcribing)
        ProcessingView(step: .polishing)
    }
    .padding(40)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
