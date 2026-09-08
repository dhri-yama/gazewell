import AppKit
import SwiftUI

/// Own window rather than the SwiftUI Settings scene: that one is unreliable to open from an accessory (no Dock icon) app.
enum SettingsWindow {
    private static var window: NSWindow?

    static func show(store: SettingsStore) {
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(store: store)))
            w.title = "LookAway Settings"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
