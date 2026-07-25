import SwiftUI

struct ListeningView: View {
    let startedAt: Date
    var audioRecorder: AudioRecorder

    var body: some View {
        HUDCapsule(accent: .listening, compact: false) {
            HUDWaveformBars(levelProvider: { audioRecorder.currentLevel() })
        }
    }
}

#Preview("Dark") {
    ListeningView(startedAt: Date(), audioRecorder: AudioRecorder())
        .padding(40)
        .background(Color.black)
}
