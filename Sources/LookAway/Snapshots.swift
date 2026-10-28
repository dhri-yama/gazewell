import SwiftUI
import AppKit
import LookAwayCore

/// `LookAway --snapshot <dir>` renders the main screens to PNGs and exits. Used to review the UI without screen-recording permission.
enum Snapshots {
    static func run(into dir: String) {
        _ = NSApplication.shared
        func shot<V: View>(_ name: String, _ view: V, _ size: CGSize) {
            let host = NSHostingView(rootView: view.environment(\.colorScheme, Theme.scheme))
            host.frame = CGRect(origin: .zero, size: size)
            let w = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.appearance = Theme.appearance
            w.contentView = host
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.5))
            guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
            host.cacheDisplay(in: host.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        }

        print("probe inCall=\(Blockers.inCall) display=\(Blockers.displayKeptAwake) idle=\(Int(Blockers.idleSeconds))")
        let sched = BreakScheduler()
        let store = SettingsStore(scheduler: sched)
        let stats = StatsStore()
        sched.startBreak()
        for theme in [BreakTheme.olive, .ocean] {
            var s = store.settings; s.theme = theme
            shot("break-\(theme.rawValue)", BreakView(scheduler: sched, settings: s,
                 copy: BreakCopy(title: "Catch a quick rest", subtitle: "Focus on a distant point until it's time to resume"),
                 image: nil, onSkip: {}, onLock: {}), CGSize(width: 1440, height: 900))
        }
        for preset in FontPreset.all where ["Serif + Sans"].contains(preset.name) {
            var s = store.settings; s.titleFont = preset.title; s.subtitleFont = preset.subtitle; s.timerFont = preset.timer
            shot("break-font-\(preset.name)", BreakView(scheduler: sched, settings: s,
                 copy: BreakCopy(title: "Catch a quick rest", subtitle: "Focus on a distant point until it's time to resume"),
                 image: nil, onSkip: {}, onLock: {}), CGSize(width: 1440, height: 900))
        }
        let hu = BreakScheduler(); hu.postpone(by: 40)
        shot("headsup", HeadsUpCard(scheduler: hu, canSnooze: true).padding(20).background(Color.gray), CGSize(width: 500, height: 190))
        shot("pill", CursorPill(scheduler: hu).padding(20).background(Color.gray), CGSize(width: 260, height: 60))
        for (i, n) in Nudge.defaults.enumerated() {
            shot("nudge-\(n.id)", NudgeView(nudge: n, start: Date().addingTimeInterval(-[1.2, 1.0, 2.2, 1.6][i])).background(Color.gray), CGSize(width: 1440, height: 900))
        }
        shot("menu", MenuPopover(scheduler: hu, store: store, stats: stats).background(Color(white: 0.22)), CGSize(width: 360, height: 420))
        // A break 14s in, so tree-growth layouts show a mid-growth state.
        var clockNow = Date()
        let grown = BreakScheduler(now: { clockNow }); grown.startBreak(duration: 20); clockNow += 14; grown.tick()
        // Direction comparison: every surface once per style.
        let presetFor: [String: Int] = ["Forest": 4, "Earth": 0, "Air": 4, "Night sky": 0, "Ocean": 4, "Medito": 0, "Mono focus": 3]
        for style in Style.all {
            Theme.style = style
            let slug = style.name.lowercased().replacingOccurrences(of: " ", with: "-")
            var s = store.settings; let pre = FontPreset.all[presetFor[style.name] ?? 0]
            s.titleFont = pre.title; s.subtitleFont = pre.subtitle; s.timerFont = pre.timer; s.theme = .olive
            shot("cmp-\(slug)-break", BreakView(scheduler: grown, settings: s,
                 copy: BreakCopy(title: "Catch a quick rest", subtitle: "Focus on a distant point until it's time to resume"),
                 image: nil, onSkip: {}, onLock: {}, appeared: Date().addingTimeInterval(-14)), CGSize(width: 1440, height: 900))
            shot("cmp-\(slug)-headsup", HeadsUpCard(scheduler: hu, canSnooze: true, timerFont: s.timerFont, textFont: s.subtitleFont)
                 .padding(20).background(Theme.style.dark ? Color(white: 0.25) : Color(white: 0.85)), CGSize(width: 500, height: 190))
            shot("cmp-\(slug)-menu", MenuPopover(scheduler: hu, store: store, stats: stats)
                 .background(Theme.style.dark ? Color(white: 0.22) : Color(white: 0.9)), CGSize(width: 360, height: 420))
            for (j, n) in Nudge.defaults.enumerated() {
                shot("cmp-\(slug)-nudge-\(n.id)", NudgeView(nudge: n, font: s.subtitleFont, start: Date().addingTimeInterval(-[1.2, 1.0, 2.2, 1.6][j]))
                     .background(Color(white: 0.2)), CGSize(width: 1440, height: 900))
            }
            let nav3 = SettingsNav(); nav3.pane = .general
            shot("cmp-\(slug)-general", SettingsView(store: store, stats: stats, nav: nav3, height: 760)
                 .background(Theme.style.dark ? Color(white: 0.22) : Color(white: 0.9)), CGSize(width: 880, height: 760))
            let nav2 = SettingsNav(); nav2.pane = .screenBreaks
            shot("cmp-\(slug)-settings", SettingsView(store: store, stats: stats, nav: nav2, height: 1000)
                 .background(Theme.style.dark ? Color(white: 0.22) : Color(white: 0.9)), CGSize(width: 880, height: 1000))
        }
        Theme.style = Style.forest
        let nav = SettingsNav()
        for pane in Pane.allCases {
            nav.pane = pane
            let tall: CGFloat = pane == .screenBreaks ? 1500 : pane == .breakScreen ? 1500 : 680
            shot("settings-\(pane.rawValue)", SettingsView(store: store, stats: stats, nav: nav, height: tall).background(Color(white: 0.22)), CGSize(width: 880, height: tall))
        }
    }
}
