import SwiftUI

struct SuccessView: View {
    var body: some View {
        HUDCapsule(accent: .success) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(HUDBrandColors.waveformTop)
                    .symbolRenderingMode(.hierarchical)

                Text("Prompt Inserted")
                    .font(.headline)
                    .foregroundStyle(HUDCapsuleColors.primary)
            }
        }
    }
}

#Preview("Light") {
    SuccessView()
        .padding(40)
        .background(Color(red: 0.97, green: 0.97, blue: 0.95))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SuccessView()
        .padding(40)
        .background(Color.black)
        .preferredColorScheme(.dark)
}
