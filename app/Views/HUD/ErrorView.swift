import SwiftUI

struct ErrorView: View {
    let message: String
    var onDismiss: () -> Void

    var body: some View {
        HUDCapsule(accent: .error) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(HUDCapsuleColors.secondary)
                    .symbolRenderingMode(.hierarchical)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(HUDCapsuleColors.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .contentShape(Capsule())
        .onTapGesture(perform: onDismiss)
    }
}

#Preview("Light") {
    ErrorView(message: HUDErrorMessage.microphoneUnavailable, onDismiss: {})
        .padding(40)
        .background(Color(red: 0.97, green: 0.97, blue: 0.95))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ErrorView(message: HUDErrorMessage.microphoneUnavailable, onDismiss: {})
        .padding(40)
        .background(Color.black)
        .preferredColorScheme(.dark)
}
