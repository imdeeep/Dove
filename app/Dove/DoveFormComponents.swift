import SwiftUI

/// One settings pane. Wraps content in a single grouped `Form` so macOS owns
/// the scrolling, insets, and section rhythm (System Settings pattern).
struct DoveSettingsPane<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        Form {
            content
        }
        .formStyle(.grouped)
    }
}

/// Grouped section inside a `DoveSettingsPane`.
struct DoveFormSection<Footer: View, Content: View>: View {
    let title: String
    var footer: Footer
    @ViewBuilder var content: Content

    init(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) where Footer == EmptyView {
        self.title = title
        self.footer = EmptyView()
        self.content = content()
    }

    init(
        _ title: String,
        footer: String,
        @ViewBuilder content: () -> Content
    ) where Footer == Text {
        self.title = title
        self.footer = Text(footer)
        self.content = content()
    }

    var body: some View {
        Section {
            content
        } header: {
            Text(title)
                .font(.headline)
        } footer: {
            footer
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Label left, control right - the System Settings row.
struct DoveFormRow<Control: View>: View {
    let label: String
    @ViewBuilder var control: Control

    var body: some View {
        LabeledContent(label) {
            control
        }
    }
}
