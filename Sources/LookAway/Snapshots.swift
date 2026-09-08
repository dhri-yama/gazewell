import SwiftUI
import AppKit
import LookAwayCore

/// `LookAway --snapshot <dir>` renders the main screens to PNGs and exits. Used to review the UI without screen-recording permission.
enum Snapshots {
    static func run(into dir: String) {
        _ = NSApplication.shared
        func shot<V: View>(_ name: String, _ view: V, _ size: CGSize) {
            let host = NSHostingView(rootView: view.environment(\.colorScheme, .dark))
            host.frame = CGRect(origin: .zero, size: size)
            let w = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.appearance = NSAppearance(named: .darkAqua)
            w.contentView = host
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.5))
            guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
            host.cacheDisplay(in: host.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
        }

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
            shot("nudge-\(n.id)", NudgeView(nudge: n, start: Date().addingTimeInterval(-[1.2, 1.5, 0.8, 0.8][i])).background(Color.gray), CGSize(width: 760, height: 560))
        }
        shot("menu", MenuPopover(scheduler: hu, store: store, stats: stats).background(Color(white: 0.22)), CGSize(width: 360, height: 420))
        let nav = SettingsNav()
        for pane in Pane.allCases {
            nav.pane = pane
            let tall: CGFloat = pane == .screenBreaks ? 1500 : pane == .breakScreen ? 1500 : 680
            shot("settings-\(pane.rawValue)", SettingsView(store: store, stats: stats, nav: nav, height: tall).background(Color(white: 0.22)), CGSize(width: 960, height: tall))
        }
    }
}
