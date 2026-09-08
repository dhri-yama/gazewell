import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SectionTitle: View {
    var text: String
    var body: some View { Text(text).font(.system(size: 17, weight: .semibold)).foregroundStyle(.white).padding(.top, 10) }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct Sep: View { var body: some View { Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 16) } }

/// Label (and optional hint) on the left, any control on the right.
struct Row<Control: View>: View {
    var title: String
    var subtitle: String?
    var symbol: String?
    var tile: [UInt32] = [0xC8509A, 0xF0884A]
    @ViewBuilder var control: Control

    var body: some View {
        HStack(spacing: 12) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 30, height: 30).background(Theme.tile(tile), in: RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14)).foregroundStyle(.white)
                if let subtitle { Text(subtitle).font(.system(size: 12)).foregroundStyle(Theme.textDim).fixedSize(horizontal: false, vertical: true) }
            }
            Spacer(minLength: 12)
            control
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct ToggleRow: View {
    var title: String
    var subtitle: String?
    var symbol: String?
    @Binding var isOn: Bool
    var body: some View {
        Row(title: title, subtitle: subtitle, symbol: symbol) { Toggle(title, isOn: $isOn).labelsHidden().toggleStyle(.switch) }
    }
}

struct MenuRow<T: Hashable>: View {
    var title: String
    var subtitle: String?
    @Binding var selection: T
    var options: [(T, String)]
    var body: some View {
        Row(title: title, subtitle: subtitle) {
            Picker(title, selection: $selection) { ForEach(options, id: \.0) { Text($0.1).tag($0.0) } }
                .labelsHidden().pickerStyle(.menu).fixedSize()
        }
    }
}

/// "45 seconds", "1 minute", "1 hour 30 min".
func durationLabel(_ seconds: Int) -> String {
    if seconds < 60 { return "\(seconds) seconds" }
    let (h, m) = (seconds / 3600, seconds % 3600 / 60)
    if h == 0 { return m == 1 ? "1 minute" : "\(m) minutes" }
    return m == 0 ? (h == 1 ? "1 hour" : "\(h) hours") : "\(h) hour\(h == 1 ? "" : "s") \(m) min"
}

/// Preset durations plus the current value if it isn't one of them, so the menu never shows blank.
func durationOptions(_ presets: [Int], including current: Int) -> [(Int, String)] {
    (presets.contains(current) ? presets : (presets + [current]).sorted()).map { ($0, durationLabel($0)) }
}

struct DurationRow: View {
    var title: String
    var subtitle: String?
    @Binding var seconds: TimeInterval
    var presets: [Int]
    var body: some View {
        MenuRow(title: title, subtitle: subtitle,
                selection: Binding(get: { Int(seconds) }, set: { seconds = TimeInterval($0) }),
                options: durationOptions(presets, including: Int(seconds)))
    }
}

func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
    Binding {
        Calendar.current.date(bySettingHour: minutes.wrappedValue / 60, minute: minutes.wrappedValue % 60, second: 0, of: Date()) ?? Date()
    } set: {
        let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
        minutes.wrappedValue = (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}

func chooseFile(types: [UTType], _ pick: (String) -> Void) {
    let p = NSOpenPanel()
    p.allowedContentTypes = types
    p.allowsMultipleSelection = false
    if p.runModal() == .OK, let url = p.url { pick(url.path) }
}

struct PaneHeader: View {
    var pane: Pane
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: pane.symbol).font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 34, height: 34).background(Theme.tile(pane.tile), in: RoundedRectangle(cornerRadius: 9))
            Text(pane.title).font(.system(size: 22, weight: .semibold)).foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 28).padding(.vertical, 16)
    }
}

/// Dark native-looking text field used inside cards.
struct FieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.textFieldStyle(.plain)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.white)
    }
}
