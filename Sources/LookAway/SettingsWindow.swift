import AppKit
import SwiftUI

/// Own window rather than the SwiftUI Settings scene: that one is unreliable to open from an accessory (no Dock icon) app.
enum SettingsWindow {
    private static var window: NSWindow?
    static let nav = SettingsNav()

    static func show(store: SettingsStore, stats: StatsStore, pane: Pane? = nil) {
        if let pane { nav.pane = pane }
        if window == nil {
            let host = NSHostingView(rootView: SettingsView(store: store, stats: stats, nav: nav))
            let blur = NSVisualEffectView()
            blur.material = .hudWindow
            blur.blendingMode = .behindWindow
            blur.state = .active
            host.translatesAutoresizingMaskIntoConstraints = false
            blur.addSubview(host)
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: blur.leadingAnchor), host.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
                host.topAnchor.constraint(equalTo: blur.topAnchor), host.bottomAnchor.constraint(equalTo: blur.bottomAnchor),
            ])
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 960, height: 680), styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView], backing: .buffered, defer: false)
            w.contentView = blur
            w.title = "LookAway Settings"
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
