import SwiftUI
import AppKit
import GazewellCore

/// Hover state for a row. An object rather than @State so it builds on toolchains without SwiftUI's macro plugin.
private final class HoverModel: ObservableObject { @Published var on = false }

private let glassStroke = Theme.ink(0.12)

private struct RowLabel: View {
    var title: String
    var symbol: String
    var trailing: String?
    var chevron = false
    @StateObject private var hover = HoverModel()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 15, weight: .medium)).frame(width: 22).foregroundStyle(Theme.ink(0.65))
            Text(title)
            Spacer()
            if let trailing { Text(trailing).foregroundStyle(Theme.ink(0.45)) }
            if chevron { Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.ink(0.45)) }
        }
        .font(.system(size: 15)).foregroundStyle(Theme.ink)
        .padding(.horizontal, 12).frame(height: 40)
        .background(Theme.ink(hover.on ? 0.1 : 0), in: RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .onHover { hover.on = $0 }
    }
}

private struct RowButton: View {
    var title: String
    var symbol: String
    var shortcut: String?
    var action: () -> Void
    var body: some View {
        Button(action: action) { RowLabel(title: title, symbol: symbol, trailing: shortcut) }.buttonStyle(.plain)
    }
}

/// Closes the menu bar popover after an action.
func dismissPopover() { NSApp.keyWindow?.orderOut(nil) }

struct MenuPopover: View {
    @ObservedObject var scheduler: BreakScheduler
    @ObservedObject var store: SettingsStore
    @ObservedObject var stats: StatsStore

    private var paused: Bool { scheduler.pausedUntil != nil }
    private var clock: String { String(format: "%d:%02d", scheduler.secondsLeft / 60, scheduler.secondsLeft % 60) }

    private var off: Bool { !store.settings.enabled }

    private var heading: String {
        if off { return "Gazewell is off" }
        if paused { return "Breaks are paused" }
        if !scheduler.hasUpcoming { return "No breaks scheduled" }
        switch scheduler.phase {
        case .breaking: return "On a break"
        case .headsUp: return "Break starting soon"
        case .working: return scheduler.activeRule.kind == .planned ? "Next: \(scheduler.activeRule.title)" : "Next break in"
        }
    }

    private var progress: Double {
        guard scheduler.hasUpcoming, !paused, scheduler.phase == .working || scheduler.phase == .headsUp else { return 0 }
        let total = min(scheduler.activeRule.interval, 6 * 3600)
        return max(0, min(1, 1 - Double(scheduler.secondsLeft) / total))
    }

    var body: some View {
        let today = stats.stats.day(Date())
        let streak = stats.stats.streak()
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(heading).font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.ink(0.65))
                if off {
                    Text("Off").font(.system(size: 52, weight: .bold)).foregroundStyle(Theme.ink(0.5))
                } else if scheduler.hasUpcoming && !paused {
                    Text(clock).font(Theme.display(52, .bold)).monospacedDigit().foregroundStyle(Theme.ink)
                } else {
                    Text(paused ? "Paused" : "—").font(.system(size: 52, weight: .bold)).foregroundStyle(Theme.ink(0.5))
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.ink(0.14))
                        Capsule().fill(Theme.ink(0.85)).frame(width: max(8, g.size.width * progress))
                    }
                }
                .frame(height: 8).padding(.top, 10)
                .accessibilityHidden(true)
                Text("Today · \(today.taken) taken · \(today.skipped) skipped\(streak > 1 ? " · \(streak)-day streak" : "")")
                    .font(.system(size: 13)).foregroundStyle(Theme.ink(0.55)).padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22).padding(.vertical, 22)

            Rectangle().fill(Theme.ink(0.1)).frame(height: 1)
            VStack(spacing: 2) {
                if off {
                    RowButton(title: "Turn Gazewell on", symbol: "power", shortcut: "⌃⌥P") { store.settings.enabled = true }
                } else {
                RowButton(title: "Start break now", symbol: "play.fill", shortcut: "⌃⌥B") { dismissPopover(); scheduler.startBreak() }
                RowButton(title: "Skip next break", symbol: "forward.fill", shortcut: "⌃⌥S") { dismissPopover(); scheduler.endBreak() }
                    .disabled(scheduler.phase == .breaking).opacity(scheduler.phase == .breaking ? 0.4 : 1)
                if paused {
                    RowButton(title: "Resume breaks", symbol: "play.circle", shortcut: "⌃⌥P") { scheduler.pausedUntil = nil }
                } else {
                    Menu {
                        Button("For 1 hour") { scheduler.pausedUntil = Date().addingTimeInterval(3600) }
                        Button("For 4 hours") { scheduler.pausedUntil = Date().addingTimeInterval(4 * 3600) }
                        Button("Until I turn it back on") { scheduler.pausedUntil = .distantFuture }
                    } label: { RowLabel(title: "Pause breaks", symbol: "pause.fill", trailing: nil, chevron: true) }
                    .menuStyle(.button).menuIndicator(.hidden).buttonStyle(.plain)
                }
                }
            }
            .padding(10)

            Rectangle().fill(Theme.ink(0.1)).frame(height: 1)
            VStack(spacing: 2) {
                RowButton(title: "Settings…", symbol: "gearshape", shortcut: "⌘,") { dismissPopover(); SettingsWindow.show(store: store, stats: stats) }
                    .keyboardShortcut(",")
                RowButton(title: "Quit Gazewell", symbol: "power", shortcut: "⌘Q") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .padding(10)
        }
        .frame(width: 360)
        .background {
            // Same family as the break screen: a warm olive glow over a blurred, dark glass.
            ZStack {
                Rectangle().fill(.regularMaterial)
                Theme.glow
            }
        }
        .environment(\.colorScheme, Theme.scheme)
        .id(store.settings.appStyle)
    }
}
