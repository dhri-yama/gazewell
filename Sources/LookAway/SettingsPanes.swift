import SwiftUI
import AppKit
import UniformTypeIdentifiers
import LookAwayCore

// MARK: General

struct GeneralPane: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var stats: StatsStore
    var body: some View {
        Card {
            ToggleRow(title: "Open at login", subtitle: "Works when running the bundled LookAway.app", symbol: "power", isOn: $store.launchAtLogin)
            Sep()
            ToggleRow(title: "Show time in the menu bar", subtitle: "Countdown to your next break next to the icon", symbol: "menubar.rectangle",
                      isOn: $store.settings.showTimeInMenuBar)
        }
        Block(title: "Data") { Card {
            Row(title: "Reset all settings", subtitle: "Restores every option to its default") {
                Button("Reset") { store.reset() }.buttonStyle(ControlButton())
            }
            Sep()
            Row(title: "Clear stats", subtitle: "Deletes your break history") {
                Button("Clear") { stats.clear() }.buttonStyle(ControlButton())
            }
        } }
    }
}

// MARK: Screen breaks

private struct EnforcementTile: View {
    var level: Enforcement
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    LinearGradient(colors: [Theme.hex(0x7A4FA8), Theme.hex(0xC0384A), Theme.hex(0xE08A3A)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    HStack(spacing: 8) {
                        switch level {
                        case .casual: Image(systemName: "forward")
                        case .balanced: Circle().trim(from: 0, to: 0.75).stroke(.white, lineWidth: 2).frame(width: 16, height: 16).rotationEffect(.degrees(-90))
                        case .hardcore: Image(systemName: "nosign")
                        }
                        Text("Skip Break").font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(level == .hardcore ? 0.55 : 1))
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(.white.opacity(0.2), in: Capsule())
                }
                .frame(height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hex(0x1E78FF), lineWidth: selected ? 3 : 0).padding(-3))
                Text(level.title).font(.system(size: 14, weight: selected ? .semibold : .regular)).foregroundStyle(.white)
                Text(level.detail).font(.system(size: 12)).foregroundStyle(Theme.textDim)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct PlannedEditor: View {
    @Binding var rule: BreakRule
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Switch(label: "Enabled", isOn: $rule.enabled)
                TextField("Name (e.g. Lunch)", text: $rule.name).textFieldStyle(FieldStyle())
                TimeField(label: "Start", minutes: $rule.minuteOfDay)
                IconButton(symbol: "trash", label: "Delete planned break", action: onDelete)
            }
            HStack(spacing: 10) {
                Dropdown(label: "Length", selection: Binding(get: { Int(rule.duration) }, set: { rule.duration = TimeInterval($0) }),
                         options: durationOptions([300, 600, 900, 1800, 2700, 3600], including: Int(rule.duration)))
                TextField("Message", text: $rule.message).textFieldStyle(FieldStyle())
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct ScreenBreaksPane: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var nav: SettingsNav

    private let days: [(Int, String)] = [(2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S"), (1, "S")]

    var body: some View {
        Card { ToggleRow(title: "Screen breaks", subtitle: "Regular breaks to rest your eyes", symbol: "leaf.fill", isOn: $store.settings.breaksEnabled) }
        Block(title: "General") {
        Card {
            DurationRow(title: "Show breaks after", subtitle: "Of focused screen time", seconds: $store.settings.breakEvery,
                        presets: [600, 900, 1200, 1500, 1800, 2700, 3600, 5400, 7200])
            Sep()
            DurationRow(title: "Break duration", seconds: $store.settings.breakDuration, presets: [10, 15, 20, 30, 45, 60, 90, 120])
        }
        Card {
            Button { nav.pane = .breakScreen } label: {
                Row(title: "Customize break screen", symbol: "paintbrush.pointed.fill", tile: [0xB05CD8, 0xE0609A]) {
                    Image(systemName: "chevron.right").foregroundStyle(Theme.textDim)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
            Sep()
            MenuRow(title: "Long breaks", subtitle: "Every few breaks, rest for longer",
                    selection: $store.settings.longBreakEvery,
                    options: [(0, "Off"), (2, "Every 2nd break"), (3, "Every 3rd break"), (4, "Every 4th break"), (5, "Every 5th break")])
            if store.settings.longBreakEvery > 0 {
                Sep()
                DurationRow(title: "Long break duration", seconds: $store.settings.longBreakDuration, presets: [120, 180, 300, 600, 900])
            }
            Sep()
            ToggleRow(title: "Office hours", subtitle: "Only remind me during these days and hours", symbol: "briefcase.fill",
                      isOn: $store.settings.officeHours.enabled)
            if store.settings.officeHours.enabled {
                Sep()
                Row(title: "From") {
                    HStack(spacing: 8) {
                        TimeField(label: "Start", minutes: $store.settings.officeHours.start)
                        Text("to").foregroundStyle(Theme.textDim)
                        TimeField(label: "End", minutes: $store.settings.officeHours.end)
                    }
                }
                Sep()
                Row(title: "Days") {
                    HStack(spacing: 6) {
                        ForEach(days, id: \.0) { d in
                            let on = store.settings.officeHours.days.contains(d.0)
                            Button(d.1) {
                                if on { store.settings.officeHours.days.remove(d.0) } else { store.settings.officeHours.days.insert(d.0) }
                            }
                            .buttonStyle(.plain).font(.system(size: 13, weight: .semibold))
                            .frame(width: 28, height: 28)
                            .background(on ? Theme.accent : Color.white.opacity(0.1), in: Circle())
                            .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
        }
        Block(title: "Break enforcement") { Card {
            HStack(alignment: .top, spacing: 16) {
                ForEach(Enforcement.allCases, id: \.self) { level in
                    EnforcementTile(level: level, selected: store.settings.enforcement == level) { store.settings.enforcement = level }
                }
            }
            .padding(16)
            Sep()
            MenuRow(title: "Snoozes allowed per day", selection: $store.settings.snoozesPerDay,
                    options: [(0, "None"), (1, "1"), (2, "2"), (3, "3"), (5, "5"), (10, "10"), (-1, "Unlimited")])
        } }
        Block(title: "More") { Card {
            MenuRow(title: "Double escape action on break screen", selection: $store.settings.doubleEscape,
                    options: EscAction.allCases.map { ($0, $0.title) })
            Sep()
            ToggleRow(title: "Let me \u{201C}End break\u{201D} early if nearly done", isOn: $store.settings.allowEarlyEnd)
            Sep()
            ToggleRow(title: "Lock my Mac automatically when a break starts", isOn: $store.settings.lockOnBreakStart)
        } }
        Block(title: "Planned breaks") { Card {
            ForEach($store.settings.planned) { $rule in
                PlannedEditor(rule: $rule) { store.settings.planned.removeAll { $0.id == rule.id } }
                Sep()
            }
            Row(title: "Fixed-time breaks, like lunch", subtitle: "They still wait for calls and focus") {
                Button("Add planned break") {
                    store.settings.planned.append(BreakRule(kind: .planned, interval: 86400, duration: 1800,
                                                            message: "Step away and eat something.", name: "Lunch"))
                }.buttonStyle(ControlButton(primary: true))
            }
        } }
    }
}

// MARK: Break screen

private struct FontRow: View {
    var title: String
    @Binding var spec: FontSpec
    var body: some View {
        Row(title: title) {
            HStack(spacing: 8) {
                Dropdown(label: "\(title) font", selection: $spec.family, options: FontSpec.allFamilies)
                Dropdown(label: "\(title) weight", selection: $spec.weight, options: FontSpec.weights.enumerated().map { ($0.offset, $0.element) })
            }
        }
    }
}

/// Live sample of the three type roles on the break-screen glow.
private struct FontPreview: View {
    var settings: AppSettings
    var body: some View {
        VStack(spacing: 8) {
            Text("Catch a quick rest").font(settings.titleFont.font(34)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.5)
            Text("Focus on a distant point until it's time to resume").font(settings.subtitleFont.font(15)).foregroundStyle(.white.opacity(0.8))
            Text("00:20").font(settings.timerFont.font(26)).monospacedDigit().foregroundStyle(.white.opacity(0.55)).padding(.top, 4)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 22)
        .background(Backdrop(theme: settings.theme, image: nil, reduceMotion: true))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.cardStroke, lineWidth: 1))
        .accessibilityHidden(true)
    }
}

struct BreakScreenPane: View {
    @ObservedObject var store: SettingsStore

    private var currentPreset: String {
        let s = store.settings
        return FontPreset.all.first { $0.title == s.titleFont && $0.subtitle == s.subtitleFont && $0.timer == s.timerFont }?.name ?? "Custom"
    }

    private func apply(_ name: String) {
        guard let p = FontPreset.all.first(where: { $0.name == name }) else { return }
        store.settings.titleFont = p.title; store.settings.subtitleFont = p.subtitle; store.settings.timerFont = p.timer
    }

    private func swatch(_ t: BreakTheme) -> some View {
        let p = Theme.palette(t)
        let selected = store.settings.theme == t
        return Button { store.settings.theme = t } label: {
            VStack(spacing: 6) {
                ZStack {
                    LinearGradient(colors: [p.base] + p.blobs.prefix(3).map { $0.opacity(0.85) } , startPoint: .bottomLeading, endPoint: .topTrailing)
                    if t == .wallpaper || t == .image { Image(systemName: t == .image ? "photo" : "desktopcomputer").foregroundStyle(.white.opacity(0.8)) }
                }
                .frame(height: 64).clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.hex(0x1E78FF), lineWidth: selected ? 3 : 0).padding(-3))
                Text(t.title).font(.system(size: 12, weight: selected ? .semibold : .regular)).foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    var body: some View {
        Block(title: "Theme") { Card {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 14)], spacing: 16) {
                ForEach(BreakTheme.allCases, id: \.self) { swatch($0) }
            }
            .padding(16)
            if store.settings.theme == .image {
                Sep()
                Row(title: store.settings.imagePath.isEmpty ? "No image chosen" : (store.settings.imagePath as NSString).lastPathComponent) {
                    Button("Choose…") { chooseFile(types: [.image]) { store.settings.imagePath = $0 } }
                        .buttonStyle(ControlButton())
                }
            }
        } }
        Block(title: "Typography") {
            Card {
                MenuRow(title: "Pairing", subtitle: "Start from a preset, then adjust each part below",
                        selection: Binding(get: { currentPreset }, set: { apply($0) }),
                        options: [("Custom", "Custom")] + FontPreset.all.map { ($0.name, $0.name) })
                Sep()
                FontRow(title: "Title", spec: $store.settings.titleFont)
                Sep()
                FontRow(title: "Subtitle and clock", spec: $store.settings.subtitleFont)
                Sep()
                FontRow(title: "Countdown", spec: $store.settings.timerFont)
            }
            FontPreview(settings: store.settings)
        }
        Block(title: "Display") { Card {
            ToggleRow(title: "Show current time", subtitle: "\u{201C}Current time is 14:58\u{201D} at the top", isOn: $store.settings.showClock)
            Sep()
            ToggleRow(title: "Show Lock Screen button", isOn: $store.settings.showLockButton)
        } }
        Block(title: "Messages") {
            Card {
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $store.settings.customMessages)
                    .scrollContentBackground(.hidden).font(.system(size: 13)).foregroundStyle(.white)
                    .frame(height: 110).padding(6)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(16)
            }
            Note("One per line. Write \u{201C}Title | Subtitle\u{201D} to set both lines; a single phrase is used as the subtitle. Leave empty for the built-in messages.")
        }
        Button("Preview break screen") { store.scheduler.startBreak(duration: 8) }
            .buttonStyle(ControlButton(primary: true))
    }
}

// MARK: Smart pause

struct SmartPausePane: View {
    @ObservedObject var store: SettingsStore
    var body: some View {
        Block {
        Note("Breaks stay out of your way. LookAway holds the break back while any of these is happening.")
        Card {
            ToggleRow(title: "Calls and meetings", subtitle: "Microphone or camera in use", symbol: "phone.fill", isOn: $store.settings.pauseForCalls)
            Sep()
            ToggleRow(title: "Screen recording", symbol: "record.circle", isOn: $store.settings.pauseForRecording)
            Sep()
            ToggleRow(title: "Video playback", subtitle: "Anything keeping the display awake", symbol: "play.rectangle.fill", isOn: $store.settings.pauseForVideo)
            Sep()
            ToggleRow(title: "Fullscreen apps and games", symbol: "arrow.up.left.and.arrow.down.right", isOn: $store.settings.pauseForFullscreen)
        }
        }
        Block(title: "Natural pauses") { Card {
            ToggleRow(title: "Count time away as a break", subtitle: "If you step away for as long as a break, the timer restarts",
                      symbol: "moon.zzz.fill", isOn: $store.settings.idleCountsAsBreak)
        }
        Note("Breaks also wait up to 30 seconds for you to stop typing.") }
    }
}

// MARK: Wellness

struct WellnessPane: View {
    @ObservedObject var store: SettingsStore
    var body: some View {
        Block {
        Note("Gentle animated reminders that fade in over a blurred screen for a few seconds. They never interrupt with a full break.")
        ForEach($store.settings.nudges) { $n in
            Card {
                ToggleRow(title: n.name, symbol: n.symbol, isOn: $n.enabled)
                if n.enabled {
                    Sep()
                    MenuRow(title: "Remind me every", selection: $n.minutes,
                            options: ([10, 15, 20, 30, 45, 60, 90, 120].contains(n.minutes) ? [10, 15, 20, 30, 45, 60, 90, 120] : ([10, 15, 20, 30, 45, 60, 90, 120] + [n.minutes]).sorted())
                                .map { ($0, durationLabel($0 * 60)) })
                    Sep()
                    Row(title: "Message") {
                        TextField("Message", text: $n.message).textFieldStyle(FieldStyle()).frame(width: 300)
                    }
                    Sep()
                    Row(title: "Try it") {
                        Button("Show now") { AppModel.shared.nudges.show(n) }.buttonStyle(ControlButton())
                    }
                }
            }
        }
        }
    }
}

// MARK: Stats

private struct StatTile: View {
    var value: Int
    var label: String
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.system(size: 34, weight: .bold)).foregroundStyle(.white).monospacedDigit()
            Text(label).font(.system(size: 12)).foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.cardStroke, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

struct StatsPane: View {
    @ObservedObject var stats: StatsStore
    var body: some View {
        let today = stats.stats.day(Date())
        let week = stats.stats.recent(7)
        let peak = max(1, week.map(\.stats.taken).max() ?? 1)
        Block(title: "Today") {
        HStack(spacing: 10) {
            StatTile(value: today.taken, label: "Breaks taken")
            StatTile(value: today.skipped, label: "Skipped")
            StatTile(value: today.snoozed, label: "Snoozed")
        }
        Card { Row(title: "Current streak", subtitle: "Days in a row with at least one break taken", symbol: "flame.fill", tile: [0xE08A20, 0xF05030]) {
            Text("\(stats.stats.streak()) day\(stats.stats.streak() == 1 ? "" : "s")").foregroundStyle(.white).font(.system(size: 14, weight: .semibold))
        } }
        }
        Block(title: "Last 7 days") { Card {
            HStack(alignment: .bottom, spacing: 14) {
                ForEach(0..<week.count, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text("\(week[i].stats.taken)").font(.system(size: 12)).foregroundStyle(Theme.textDim)
                        RoundedRectangle(cornerRadius: 5).fill(week[i].stats.taken > 0 ? Theme.accent : Color.white.opacity(0.1))
                            .frame(height: max(6, 100 * CGFloat(week[i].stats.taken) / CGFloat(peak)))
                        Text(week[i].date, format: .dateTime.weekday(.narrow)).font(.system(size: 12)).foregroundStyle(Theme.textDim)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(height: 150, alignment: .bottom).padding(16)
        } }
    }
}

// MARK: Alerts

struct AlertsPane: View {
    @ObservedObject var store: SettingsStore
    var body: some View {
        Block {
        Card {
            ToggleRow(title: "Heads-up before a break", subtitle: "A card with Start break now and snooze options", symbol: "bell.fill", isOn: $store.settings.headsUpEnabled)
            if store.settings.headsUpEnabled {
                Sep()
                DurationRow(title: "Show it", subtitle: "Before the break starts", seconds: $store.settings.headsUpLead, presets: [10, 15, 30, 45, 60])
                Sep()
                ToggleRow(title: "Countdown next to the cursor", subtitle: "A small timer that follows your pointer", isOn: $store.settings.cursorCountdown)
            }
        }
        Note("The +1m, +5m and +15m buttons use your daily snooze allowance (Screen Breaks).")
        }
    }
}

// MARK: Sounds

private struct SoundRow: View {
    var title: String
    @Binding var choice: String
    var volume: Double

    private var options: [(String, String)] {
        var o = [("", "None")] + Chime.systemSounds.map { ($0, $0) }
        if choice.hasPrefix("file:") { o.append((choice, (String(choice.dropFirst(5)) as NSString).lastPathComponent)) }
        return o
    }

    var body: some View {
        Row(title: title) {
            HStack(spacing: 8) {
                Dropdown(label: title, selection: $choice, options: options)
                IconButton(symbol: "play.fill", label: "Play \(title)", enabled: !choice.isEmpty) { Chime.play(choice, volume: volume) }
                Button("File…") { chooseFile(types: [.audio]) { choice = "file:" + $0 } }
                    .buttonStyle(ControlButton())
            }
        }
    }
}

struct SoundsPane: View {
    @ObservedObject var store: SettingsStore
    var body: some View {
        Card {
            SoundRow(title: "When a break starts", choice: $store.settings.startSound, volume: store.settings.soundVolume)
            Sep()
            SoundRow(title: "When a break ends", choice: $store.settings.endSound, volume: store.settings.soundVolume)
            Sep()
            Row(title: "Volume", subtitle: "Relative to your Mac's volume") {
                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill").font(.system(size: 11)).foregroundStyle(Theme.textDim)
                    Slider(value: $store.settings.soundVolume, in: 0.05...1).frame(width: 180).tint(Theme.accent)
                    Image(systemName: "speaker.wave.3.fill").font(.system(size: 11)).foregroundStyle(Theme.textDim)
                }
            }
        }
    }
}

// MARK: Shortcuts

struct ShortcutsPane: View {
    @ObservedObject var store: SettingsStore
    private func keys(_ s: String) -> some View {
        Text(s).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(.white)
            .padding(.horizontal, 10).frame(height: Control.height).background(Control.fill, in: RoundedRectangle(cornerRadius: Control.radius))
    }
    var body: some View {
        Block {
        Card { ToggleRow(title: "Global keyboard shortcuts", subtitle: "Work from any app", symbol: "command", isOn: $store.settings.shortcutsEnabled) }
        Card {
            Row(title: "Start a break now") { keys("⌃⌥B") }
            Sep()
            Row(title: "Skip the next break") { keys("⌃⌥S") }
            Sep()
            Row(title: "Turn breaks off or on") { keys("⌃⌥P") }
            Sep()
            Row(title: "Leave a break (double press)") { keys("Esc Esc") }
        }
        }
    }
}

// MARK: Automation

struct AutomationPane: View {
    @ObservedObject var store: SettingsStore
    var body: some View {
        Block {
        Note("Run a Shortcut or an AppleScript file when a break starts or ends. Enter a Shortcut's name, or the path to a .scpt or .applescript file.")
        Card {
            Row(title: "When a break starts", symbol: "play.fill", tile: [0xE08A20, 0xF0B030]) {
                TextField("Shortcut name or script path", text: $store.settings.startHook).textFieldStyle(FieldStyle()).frame(width: 300)
            }
            Sep()
            Row(title: "When a break ends", symbol: "stop.fill", tile: [0xE08A20, 0xF0B030]) {
                TextField("Shortcut name or script path", text: $store.settings.endHook).textFieldStyle(FieldStyle()).frame(width: 300)
            }
        }
        }
    }
}

// MARK: About

struct AboutPane: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "eye.fill").font(.system(size: 36, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 84, height: 84).background(Theme.tile([0xC8509A, 0xF0884A]), in: RoundedRectangle(cornerRadius: 20))
            Text("LookAway").font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
            Text("Version 0.2").font(.system(size: 13)).foregroundStyle(Theme.textDim)
            Text("A personal clone of the LookAway break reminder for macOS. Not affiliated with LookAway.")
                .font(.system(size: 13)).foregroundStyle(Theme.textDim).multilineTextAlignment(.center).frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity).padding(.top, 40)
    }
}
