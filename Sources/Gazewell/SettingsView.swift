import SwiftUI
import AppKit

enum Pane: String, CaseIterable, Identifiable {
    case general, screenBreaks, breakScreen, smartPause, wellness, stats, alerts, sounds, shortcuts, automation, about
    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .screenBreaks: "Screen Breaks"
        case .breakScreen: "Break Screen"
        case .smartPause: "Smart Pause"
        case .wellness: "Wellness Reminders"
        case .stats: "Stats"
        case .alerts: "Alerts / Nudges"
        case .sounds: "Sounds"
        case .shortcuts: "Keyboard Shortcuts"
        case .automation: "Automation"
        case .about: "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .screenBreaks: "leaf.fill"
        case .breakScreen: "paintbrush.pointed.fill"
        case .smartPause: "pause.fill"
        case .wellness: "heart.fill"
        case .stats: "chart.bar.fill"
        case .alerts: "bell.fill"
        case .sounds: "speaker.wave.2.fill"
        case .shortcuts: "command"
        case .automation: "arrow.triangle.2.circlepath"
        case .about: "info"
        }
    }

    /// Label under the toolbar icon.
    var short: String {
        switch self {
        case .general: "General"
        case .screenBreaks: "Breaks"
        case .breakScreen: "Screen"
        case .smartPause: "Pause"
        case .wellness: "Wellness"
        case .stats: "Stats"
        case .alerts: "Alerts"
        case .sounds: "Sounds"
        case .shortcuts: "Keys"
        case .automation: "Automate"
        case .about: "About"
        }
    }

    var blurb: String {
        switch self {
        case .general: "Theme, startup and the master switch."
        case .screenBreaks: "How often, how long, and how strictly you rest."
        case .breakScreen: "Background, type and messages for the break screen."
        case .smartPause: "Stay out of the way during calls, recordings and focus."
        case .wellness: "Gentle full-screen nudges for posture, blinking, water and stretching."
        case .stats: "How your breaks are going."
        case .alerts: "The heads-up before a break begins."
        case .sounds: "What you hear when a break starts and ends."
        case .shortcuts: "Global keys that work from any app."
        case .automation: "Run a Shortcut or script around breaks."
        case .about: "About this app."
        }
    }
}

final class SettingsNav: ObservableObject {
    @Published var pane: Pane = .general
}

/// One icon-over-label tab in the top toolbar.
private struct TabItem: View {
    var pane: Pane
    var selected: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: pane.symbol).font(.system(size: 17, weight: .medium)).frame(height: 22)
                Text(pane.short).font(.system(size: 11, weight: selected ? .semibold : .medium))
            }
            .foregroundStyle(selected ? Theme.ink : Theme.ink(0.5))
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .overlay(alignment: .bottom) { Capsule().fill(Theme.accent).frame(width: selected ? 28 : 0, height: 3) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pane.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var stats: StatsStore
    @ObservedObject var nav: SettingsNav
    var height: CGFloat = 720

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar of tabs across the top, under the traffic lights.
            HStack(spacing: 0) {
                ForEach(Pane.allCases) { pane in
                    TabItem(pane: pane, selected: nav.pane == pane) { nav.pane = pane }
                }
            }
            .padding(.horizontal, 14).padding(.top, 30)
            .background(Theme.sidebarBg)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 1) }

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    PaneHeader(pane: nav.pane)
                    content
                }
                .frame(maxWidth: 740, alignment: .leading)
                .padding(.horizontal, 40).padding(.vertical, 34)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 880, height: height)
        .background { Theme.glow }
        .id(store.settings.appStyle)    // rebuild the tree so every view re-reads the new theme
        .environment(\.colorScheme, Theme.scheme)
    }

    @ViewBuilder private var content: some View {
        switch nav.pane {
        case .general: GeneralPane(store: store, stats: stats)
        case .screenBreaks: ScreenBreaksPane(store: store, nav: nav)
        case .breakScreen: BreakScreenPane(store: store)
        case .smartPause: SmartPausePane(store: store)
        case .wellness: WellnessPane(store: store)
        case .stats: StatsPane(stats: stats)
        case .alerts: AlertsPane(store: store)
        case .sounds: SoundsPane(store: store)
        case .shortcuts: ShortcutsPane(store: store)
        case .automation: AutomationPane(store: store)
        case .about: AboutPane()
        }
    }
}
