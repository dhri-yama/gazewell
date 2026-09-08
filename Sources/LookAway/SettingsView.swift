import SwiftUI
import LookAwayCore

private struct RuleEditor: View {
    @Binding var rule: BreakRule

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(rule.title, isOn: $rule.enabled).font(.headline)
            if rule.enabled {
                Stepper(value: $rule.interval, in: 60...7200, step: 60) {
                    Text("Every \(Int(rule.interval / 60)) min")
                }
                Stepper(value: $rule.duration, in: 5...600, step: 5) {
                    Text("For \(Int(rule.duration)) sec")
                }
                TextField("Message shown during the break", text: $rule.message)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        TabView {
            Form {
                ForEach($store.settings.rules) { $rule in
                    RuleEditor(rule: $rule)
                    Divider()
                }
            }
            .padding(24)
            .tabItem { Label("Breaks", systemImage: "eye") }

            Form {
                Text("Don't interrupt me during").font(.headline)
                Toggle("Calls and meetings (mic or camera in use)", isOn: $store.settings.pauseForCalls)
                Toggle("Screen recording", isOn: $store.settings.pauseForRecording)
                Toggle("Video playback", isOn: $store.settings.pauseForVideo)
                Toggle("Fullscreen apps and games", isOn: $store.settings.pauseForFullscreen)
                Text("Breaks also wait for you to stop typing, and time away from the keyboard counts as a break.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            .padding(24)
            .tabItem { Label("Smart Pause", systemImage: "pause.circle") }

            Form {
                Stepper(value: $store.settings.headsUpLead, in: 5...120, step: 5) {
                    Text("Heads-up \(Int(store.settings.headsUpLead)) sec before a break")
                }
            }
            .padding(24)
            .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: 480, height: 440)
    }
}
