import SwiftUI

/// One navigable settings pane in the Dove shell.
struct DoveSettingsSection: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    private let contentBuilder: () -> AnyView

    init(
        id: String,
        title: String,
        systemImage: String,
        @ViewBuilder content: @escaping () -> some View
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.contentBuilder = { AnyView(content()) }
    }

    var content: AnyView {
        contentBuilder()
    }
}
