import AppKit
import SwiftUI
import Combine

/// Own window rather than the SwiftUI Settings scene: that one is unreliable to open from an accessory (no Dock icon) app.
enum SettingsWindow {
    private static var window: NSWindow?
    static let nav = SettingsNav()
    private static var blur: NSVisualEffectView?
    private static var themeSub: AnyCancellable?

    static func show(store: SettingsStore, stats: StatsStore, pane: Pane? = nil) {
        if let pane { nav.pane = pane }
        if window == nil {
            let host = NSHostingView(rootView: SettingsView(store: store, stats: stats, nav: nav))
            let blur = NSVisualEffectView()
            Self.blur = blur
            blur.material = Theme.style.material
            blur.blendingMode = .behindWindow
            blur.state = .active
            host.translatesAutoresizingMaskIntoConstraints = false
            blur.addSubview(host)
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: blur.leadingAnchor), host.trailingAnchor.constraint(equalTo: blur.trailingAnchor),
                host.topAnchor.constraint(equalTo: blur.topAnchor), host.bottomAnchor.constraint(equalTo: blur.bottomAnchor),
            ])
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 880, height: 720), styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView], backing: .buffered, defer: false)
            w.contentView = blur
            w.title = "Gazewell Settings"
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.appearance = Theme.appearance
            w.isMovableByWindowBackground = true
            w.isReleasedWhenClosed = false
            w.center()
            window = w
            // The window chrome (blur material, light/dark appearance) isn't SwiftUI, so follow theme changes by hand.
            themeSub = store.$settings.map(\.appStyle).removeDuplicates().sink { _ in
                DispatchQueue.main.async {
                    Self.blur?.material = Theme.style.material
                    window?.appearance = Theme.appearance
                }
            }
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
