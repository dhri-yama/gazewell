import SwiftUI
import AppKit
import LookAwayCore

private struct TileButton: View {
    var title: String
    var symbol: String
    var action: () -> Void
    var body: some View {
        Button(action: action) { tileLabel(title, symbol) }.buttonStyle(.plain)
    }
}

private func tileLabel(_ title: String, _ symbol: String) -> some View {
    VStack(spacing: 6) {
        Image(systemName: symbol).font(.system(size: 18, weight: .semibold))
        Text(title).font(.system(size: 12, weight: .medium))
    }
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity).padding(.vertical, 12)
    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    .contentShape(RoundedRectangle(cornerRadius: 12))
}

private struct RowButton: View {
    var title: String
    var symbol: String
    var shortcut: String?
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).frame(width: 20).foregroundStyle(Theme.textDim)
                Text(title)
                Spacer()
                if let shortcut { Text(shortcut).foregroundStyle(Theme.textDim) }
            }
            .font(.system(size: 14)).foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: paused ? "pause.fill" : "eye.fill").font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Theme.tile([0xC8509A, 0xF0884A]), in: RoundedRectangle(cornerRadius: 11))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(heading).font(.system(size: 13)).foregroundStyle(Theme.textDim)
                        if scheduler.hasUpcoming && !paused {
                            Text(clock).font(.system(size: 28, weight: .bold)).monospacedDigit().foregroundStyle(.white)
                        }
                    }
                    Spacer()
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.12))
                        Capsule().fill(Theme.accent).frame(width: g.size.width * progress)
                    }
                }
                .frame(height: 5)
                .accessibilityHidden(true)
            }
            .padding(16)

            HStack(spacing: 8) {
                TileButton(title: "Start break", symbol: "play.fill") { dismissPopover(); scheduler.startBreak() }
                TileButton(title: "Skip next", symbol: "forward.fill") { dismissPopover(); scheduler.endBreak() }
                    .disabled(scheduler.phase == .breaking).opacity(scheduler.phase == .breaking ? 0.4 : 1)
                if paused {
                    TileButton(title: "Resume", symbol: "play.circle") { scheduler.pausedUntil = nil }
                } else {
                    Menu {
                        Button("For 1 hour") { scheduler.pausedUntil = Date().addingTimeInterval(3600) }
                        Button("For 4 hours") { scheduler.pausedUntil = Date().addingTimeInterval(4 * 3600) }
                        Button("Until I turn it back on") { scheduler.pausedUntil = .distantFuture }
                    } label: { tileLabel("Pause", "pause.fill") }
                    .menuStyle(.button).menuIndicator(.hidden).buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            Text("Today: \(today.taken) taken · \(today.skipped) skipped\(stats.stats.streak() > 1 ? " · \(stats.stats.streak())-day streak" : "")")
                .font(.system(size: 12)).foregroundStyle(Theme.textDim)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).padding(.top, 12)

            Rectangle().fill(Theme.hairline).frame(height: 1).padding(.top, 12)
            VStack(spacing: 0) {
                RowButton(title: "Settings…", symbol: "gearshape", shortcut: "⌘,") { dismissPopover(); SettingsWindow.show(store: store, stats: stats) }
                    .keyboardShortcut(",")
                RowButton(title: "Quit LookAway", symbol: "power", shortcut: "⌘Q") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .padding(.vertical, 6)
        }
        .frame(width: 320)
        .background(Theme.windowBg)
        .environment(\.colorScheme, .dark)
    }
}
