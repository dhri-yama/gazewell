import AppKit
import SwiftUI

/// Own window rather than the SwiftUI Settings scene: that one is unreliable to open from an accessory (no Dock icon) app.
enum SettingsWindow {
    private static var window: NSWindow?
    static let nav = SettingsNav()

    static func show(store: SettingsStore, stats: StatsStore, pane: Pane? = nil) {
        if let pane { nav.pane = pane }
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(store: store, stats: stats, nav: nav)))
            w.title = "LookAway Settings"
            w.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.appearance = NSAppearance(named: .darkAqua)
            w.isMovableByWindowBackground = true
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
