import AppKit
import SwiftUI

struct HotkeyPreferences: View {
    @Environment(AppSettings.self) private var settings

    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        DoveSettingsPane {
            DoveFormSection(
                "Recording Shortcut",
                footer: "Press the shortcut once to start recording, again to stop. Include at least one modifier key."
            ) {
                DoveFormRow(label: "Shortcut") {
                    Text(isRecording ? "Listening for keys…" : settings.hotkeyBinding.displayString)
                        .font(.body.monospaced())
                        .foregroundStyle(isRecording ? Color.accentColor : .primary)
                }

                HStack(spacing: DoveTheme.rowSpacing) {
                    Button(isRecording ? "Cancel" : "Change Shortcut…") {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }

                    Button("Reset") {
                        settings.hotkeyBinding = .default
                    }
                    .disabled(isRecording)
                }
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard flags.rawValue != 0 else { return event }

            settings.hotkeyBinding = HotkeyBinding(
                keyCode: event.keyCode,
                modifierFlags: UInt64(flags.rawValue)
            )
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
}

#Preview("Light") {
    HotkeyPreferences()
        .environment(AppSettings())
        .frame(width: 460, height: 320)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    HotkeyPreferences()
        .environment(AppSettings())
        .frame(width: 460, height: 320)
        .preferredColorScheme(.dark)
}
