import SwiftUI
import AppKit
import LookAwayCore

/// Hover state for a row. An object rather than @State so it builds on toolchains without SwiftUI's macro plugin.
private final class HoverModel: ObservableObject { @Published var on = false }

private let glassStroke = Color.white.opacity(0.12)

private struct TileButton: View {
    var title: String
    var symbol: String
    var tint: Color?
    var action: () -> Void
    var body: some View {
        Button(action: action) { tileLabel(title, symbol, tint: tint) }.buttonStyle(PressStyle())
    }
}

private func tileLabel(_ title: String, _ symbol: String, tint: Color? = nil) -> some View {
    VStack(spacing: 7) {
        Image(systemName: symbol).font(.system(size: 17, weight: .semibold))
        Text(title).font(.system(size: 12, weight: .medium))
    }
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity).padding(.vertical, 13)
    .background((tint ?? .white).opacity(tint == nil ? 0.08 : 0.32), in: RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(glassStroke, lineWidth: 1))
    .contentShape(RoundedRectangle(cornerRadius: 14))
}

private struct RowButton: View {
    var title: String
    var symbol: String
    var shortcut: String
    var action: () -> Void
    @StateObject private var hover = HoverModel()

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).frame(width: 20).foregroundStyle(.white.opacity(0.6))
                Text(title)
                Spacer()
                Text(shortcut).foregroundStyle(.white.opacity(0.5))
            }
            .font(.system(size: 14)).foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(.white.opacity(hover.on ? 0.1 : 0), in: RoundedRectangle(cornerRadius: 9))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover.on = $0 }
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

    private var heading: String {
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
            VStack(alignment: .leading, spacing: 4) {
                Text(heading).font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.65))
                if scheduler.hasUpcoming && !paused {
                    Text(clock).font(.system(size: 44, weight: .bold)).monospacedDigit().foregroundStyle(.white)
                } else {
                    Text(paused ? "Paused" : "—").font(.system(size: 44, weight: .bold)).foregroundStyle(.white.opacity(0.5))
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.14))
                        Capsule().fill(.white.opacity(0.85)).frame(width: max(5, g.size.width * progress))
                    }
                }
                .frame(height: 5).padding(.top, 8)
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 14)

            HStack(spacing: 8) {
                TileButton(title: "Start break", symbol: "play.fill", tint: Theme.accent) { dismissPopover(); scheduler.startBreak() }
                TileButton(title: "Skip next", symbol: "forward.fill", tint: nil) { dismissPopover(); scheduler.endBreak() }
                    .disabled(scheduler.phase == .breaking).opacity(scheduler.phase == .breaking ? 0.4 : 1)
                if paused {
                    TileButton(title: "Resume", symbol: "play.circle", tint: nil) { scheduler.pausedUntil = nil }
                } else {
                    Menu {
                        Button("For 1 hour") { scheduler.pausedUntil = Date().addingTimeInterval(3600) }
                        Button("For 4 hours") { scheduler.pausedUntil = Date().addingTimeInterval(4 * 3600) }
                        Button("Until I turn it back on") { scheduler.pausedUntil = .distantFuture }
                    } label: { tileLabel("Pause", "pause.fill") }
                    .menuStyle(.button).menuIndicator(.hidden).buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)

            Text("Today · \(today.taken) taken · \(today.skipped) skipped\(streak > 1 ? " · \(streak)-day streak" : "")")
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 18).padding(.top, 14)

            Rectangle().fill(.white.opacity(0.1)).frame(height: 1).padding(.top, 14)
            VStack(spacing: 2) {
                RowButton(title: "Settings…", symbol: "gearshape", shortcut: "⌘,") { dismissPopover(); SettingsWindow.show(store: store, stats: stats) }
                    .keyboardShortcut(",")
                RowButton(title: "Quit LookAway", symbol: "power", shortcut: "⌘Q") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .padding(8)
        }
        .frame(width: 320)
        .background {
            // Same family as the break screen: a warm olive glow over a blurred, dark glass.
            ZStack {
                Rectangle().fill(.regularMaterial)
                Color.black.opacity(0.28)
                RadialGradient(colors: [Theme.hex(0x8C8446, 0.55), .clear], center: .topLeading, startRadius: 0, endRadius: 260)
                RadialGradient(colors: [Theme.hex(0x5A5A32, 0.35), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 220)
            }
        }
        .environment(\.colorScheme, .dark)
    }
}
