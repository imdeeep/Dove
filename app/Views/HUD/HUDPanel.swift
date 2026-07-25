import SwiftUI

struct HUDPanelView: View {
    @Bindable var controller: HUDController
    var audioRecorder: AudioRecorder

    var body: some View {
        Group {
            switch controller.state {
            case .idle:
                EmptyView()
            case .listening(let startedAt):
                ListeningView(startedAt: startedAt, audioRecorder: audioRecorder)
            case .processing(let step):
                ProcessingView(step: step)
            case .success:
                SuccessView()
            case .error(let message):
                ErrorView(message: message) {
                    controller.dismissEarly()
                }
            }
        }
        .frame(width: 320, height: 48)
        .background(Color.clear)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
        .animation(.easeOut(duration: HUDMotion.appearDuration), value: controller.state)
    }
}

#Preview("HUD Panel Light") {
    HUDPanelView(controller: HUDController(), audioRecorder: AudioRecorder())
        .padding()
        .preferredColorScheme(.light)
}

#Preview("HUD Panel Dark") {
    HUDPanelView(controller: HUDController(), audioRecorder: AudioRecorder())
        .padding()
        .preferredColorScheme(.dark)
}
