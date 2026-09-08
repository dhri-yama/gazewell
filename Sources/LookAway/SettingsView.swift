import SwiftUI
import AppKit
import UniformTypeIdentifiers
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

private struct PlannedEditor: View {
    @Binding var rule: BreakRule
    var onDelete: () -> Void

    private var time: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: rule.minuteOfDay / 60, minute: rule.minuteOfDay % 60, second: 0, of: Date()) ?? Date()
        } set: {
            let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
            rule.minuteOfDay = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("", isOn: $rule.enabled).labelsHidden()
                TextField("Name (e.g. Lunch)", text: $rule.name).textFieldStyle(.roundedBorder)
                DatePicker("", selection: time, displayedComponents: .hourAndMinute).labelsHidden()
                Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
                    .buttonStyle(.borderless).accessibilityLabel("Delete planned break")
            }
            Stepper(value: $rule.duration, in: 60...3600, step: 60) { Text("For \(Int(rule.duration / 60)) min") }
            TextField("Message", text: $rule.message).textFieldStyle(.roundedBorder)
        }
        .padding(.vertical, 8)
    }
}

private func chooseFile(types: [UTType], _ pick: (String) -> Void) {
    let p = NSOpenPanel()
    p.allowedContentTypes = types
    p.allowsMultipleSelection = false
    if p.runModal() == .OK, let url = p.url { pick(url.path) }
}

private struct AppearanceTab: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        Form {
            Picker("Background", selection: $store.settings.background) {
                Text("Dusk gradient").tag(BackgroundStyle.gradient)
                Text("Desktop wallpaper").tag(BackgroundStyle.wallpaper)
                Text("Custom image").tag(BackgroundStyle.image)
            }
            if store.settings.background == .image {
                HStack {
                    Text(store.settings.imagePath.isEmpty ? "No image chosen" : (store.settings.imagePath as NSString).lastPathComponent)
                        .foregroundStyle(.secondary).lineLimit(1)
                    Button("Choose…") { chooseFile(types: [.image]) { store.settings.imagePath = $0 } }
                }
            }
            Picker("Sound", selection: $store.settings.sound) {
                Text("None").tag("")
                ForEach(Chime.systemSounds, id: \.self) { Text($0).tag($0) }
                Text("Custom file").tag("custom")
            }
            if store.settings.sound == "custom" {
                HStack {
                    Text(store.settings.soundPath.isEmpty ? "No file chosen" : (store.settings.soundPath as NSString).lastPathComponent)
                        .foregroundStyle(.secondary).lineLimit(1)
                    Button("Choose…") { chooseFile(types: [.audio]) { store.settings.soundPath = $0 } }
                }
            }
            Button("Preview a break") { store.scheduler.startBreak(duration: 6) }
        }
        .padding(24)
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

            AppearanceTab(store: store)
                .tabItem { Label("Appearance", systemImage: "paintpalette") }

            VStack(alignment: .leading) {
                Text("Fixed-time breaks, like lunch. They still wait for calls and focus.").foregroundStyle(.secondary)
                ScrollView {
                    ForEach($store.settings.planned) { $rule in
                        PlannedEditor(rule: $rule) { store.settings.planned.removeAll { $0.id == rule.id } }
                        Divider()
                    }
                }
                Button("Add planned break") {
                    store.settings.planned.append(BreakRule(kind: .planned, interval: 86400, duration: 1800,
                                                            message: "Step away and eat something.", name: "Lunch"))
                }
            }
            .padding(24)
            .tabItem { Label("Planned", systemImage: "calendar") }

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
                Toggle("Open at login", isOn: $store.launchAtLogin)
                Section("When a break starts or ends, run") {
                    TextField("Start: Shortcut name or AppleScript path", text: $store.settings.startHook)
                    TextField("End: Shortcut name or AppleScript path", text: $store.settings.endHook)
                }
                Text("Global shortcuts: ⌃⌥B start a break, ⌃⌥S skip the next break, ⌃⌥P turn breaks off or on.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            .padding(24)
            .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: 480, height: 440)
    }
}
