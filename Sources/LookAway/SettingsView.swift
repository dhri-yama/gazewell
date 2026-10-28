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

    var tile: [UInt32] {
        switch self {
        case .general: [0xB05CD8, 0xE0609A]
        case .screenBreaks, .breakScreen, .smartPause, .wellness, .stats: [0xC8509A, 0xF0609A]
        case .alerts, .sounds, .shortcuts: [0xE0505A, 0xF08050]
        case .automation: [0xE08A20, 0xF0B030]
        case .about: [0xE0B020, 0xF0C840]
        }
    }

    static let groups: [(String?, [Pane])] = [
        (nil, [.general]),
        ("Focus & Wellbeing", [.screenBreaks, .breakScreen, .smartPause, .wellness, .stats]),
        ("Behavior & Feedback", [.alerts, .sounds, .shortcuts]),
        ("Integrations", [.automation]),
        ("LookAway", [.about]),
    ]
}

final class SettingsNav: ObservableObject {
    @Published var pane: Pane = .general
}

private struct SidebarItem: View {
    var pane: Pane
    var selected: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: pane.symbol).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.onAccent)
                    .frame(width: 28, height: 28).background(Theme.tile(pane.tile), in: RoundedRectangle(cornerRadius: 8))
                Text(pane.title).font(.system(size: 14, weight: selected ? .semibold : .regular)).foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(selected ? Theme.ink(0.1) : .clear, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var stats: StatsStore
    @ObservedObject var nav: SettingsNav
    var height: CGFloat = 680

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Pane.groups, id: \.0) { group in
                        if let name = group.0 {
                            Text(name).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textDim)
                                .padding(.leading, 10).padding(.top, 18).padding(.bottom, 4)
                        }
                        ForEach(group.1) { pane in
                            SidebarItem(pane: pane, selected: nav.pane == pane) { nav.pane = pane }
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.top, 52).padding(.bottom, 16)
            }
            .frame(width: 244)
            .background(Theme.sidebarBg)

            VStack(spacing: 0) {
                PaneHeader(pane: nav.pane).padding(.top, 26)
                Rectangle().fill(Theme.hairline).frame(height: 1)
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) { content }
                        .padding(.horizontal, 28).padding(.vertical, 22)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(width: 960, height: height)
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
