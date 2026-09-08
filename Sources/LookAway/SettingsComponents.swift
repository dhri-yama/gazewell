import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SectionTitle: View {
    var text: String
    var body: some View { Text(text).font(.system(size: 17, weight: .semibold)).foregroundStyle(.white).padding(.leading, 4) }
}

/// A titled group of cards. Blocks are spaced 24pt apart; everything inside a block 10pt.
struct Block<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title { SectionTitle(text: title) }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Footnote under a card.
struct Note: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.system(size: 12)).foregroundStyle(Theme.textDim).fixedSize(horizontal: false, vertical: true).padding(.horizontal, 4)
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.cardStroke, lineWidth: 1))
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
        .padding(.horizontal, 16).padding(.vertical, 10)
        .frame(minHeight: 54)
    }
}

struct ToggleRow: View {
    var title: String
    var subtitle: String?
    var symbol: String?
    @Binding var isOn: Bool
    var body: some View {
        Row(title: title, subtitle: subtitle, symbol: symbol) { Switch(label: title, isOn: $isOn) }
    }
}

struct MenuRow<T: Hashable>: View {
    var title: String
    var subtitle: String?
    @Binding var selection: T
    var options: [(T, String)]
    var body: some View {
        Row(title: title, subtitle: subtitle) { Dropdown(label: title, selection: $selection, options: options) }
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

/// Hour and minute dropdowns, matching the other controls (the native time picker clashes with them).
struct TimeField: View {
    var label: String
    @Binding var minutes: Int
    var body: some View {
        let mins = Array(stride(from: 0, to: 60, by: 5))
        let current = minutes % 60
        HStack(spacing: 4) {
            Dropdown(label: "\(label) hour", selection: Binding(get: { minutes / 60 }, set: { minutes = $0 * 60 + minutes % 60 }),
                     options: (0..<24).map { ($0, String(format: "%02d", $0)) })
            Text(":").foregroundStyle(Theme.textDim)
            Dropdown(label: "\(label) minute", selection: Binding(get: { minutes % 60 }, set: { minutes = minutes / 60 * 60 + $0 }),
                     options: (mins.contains(current) ? mins : (mins + [current]).sorted()).map { ($0, String(format: "%02d", $0)) })
        }
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
            .font(.system(size: 13))
            .padding(.horizontal, 10).frame(height: Control.height)
            .background(Control.fill, in: RoundedRectangle(cornerRadius: Control.radius))
            .foregroundStyle(.white)
    }
}

/// Shared metrics so every control in a row lines up.
enum Control {
    static let height: CGFloat = 30
    static let radius: CGFloat = 8
    static let fill = Color.white.opacity(0.1)
    static let blue = Theme.hex(0x1E78FF)
}

struct ControlButton: ButtonStyle {
    var primary = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
            .padding(.horizontal, 12).frame(height: Control.height)
            .background(primary ? Theme.accent : Control.fill, in: RoundedRectangle(cornerRadius: Control.radius))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .pressSpring(configuration.isPressed)
    }
}

/// Square icon-only button (e.g. play preview).
struct IconButton: View {
    var symbol: String
    var label: String
    var enabled = true
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 12, weight: .semibold)).frame(width: Control.height, height: Control.height)
        }
        .buttonStyle(IconStyle())
        .disabled(!enabled).opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }
    private struct IconStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label.foregroundStyle(.white)
                .background(Control.fill, in: RoundedRectangle(cornerRadius: Control.radius))
                .opacity(configuration.isPressed ? 0.7 : 1)
                .pressSpring(configuration.isPressed)
        }
    }
}

/// On/off switch drawn by us so it looks the same whether or not the window is active.
struct Switch: View {
    var label: String
    @Binding var isOn: Bool
    var body: some View {
        Button { isOn.toggle() } label: {
            Capsule().fill(isOn ? Control.blue : Color.white.opacity(0.18))
                .frame(width: 44, height: 26)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle().fill(.white).frame(width: 22, height: 22).padding(2).shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
                }
                .animation(.easeOut(duration: 0.15), value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

/// Pop-up menu styled like the other controls: current value plus an up/down chevron.
struct Dropdown<T: Hashable>: View {
    var label: String
    @Binding var selection: T
    var options: [(T, String)]
    var body: some View {
        Menu {
            Picker(label, selection: $selection) { ForEach(options, id: \.0) { Text($0.1).tag($0.0) } }.pickerStyle(.inline)
        } label: {
            HStack(spacing: 8) {
                Text(options.first { $0.0 == selection }?.1 ?? "").lineLimit(1)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.textDim)
            }
            .font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
            .padding(.horizontal, 10).frame(height: Control.height)
            .background(Control.fill, in: RoundedRectangle(cornerRadius: Control.radius))
        }
        .menuStyle(.button).menuIndicator(.hidden).buttonStyle(.plain).fixedSize()
        .accessibilityLabel(label)
    }
}
