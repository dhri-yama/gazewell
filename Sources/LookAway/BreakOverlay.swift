import AppKit
import SwiftUI
import Combine
import LookAwayCore

/// Borderless window that can take key focus so Esc works.
private final class OverlayWindow: NSWindow {
    var onEscape: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { onEscape?() }
}

enum Lock {
    /// Sleeps the display; the Mac locks if "require password" is set to immediately.
    static func screen() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        p.arguments = ["displaysleepnow"]
        try? p.run()
    }
}

/// Shows one full-screen overlay per display while the scheduler is breaking.
final class BreakOverlay {
    private var windows: [NSWindow] = []
    private var sub: AnyCancellable?
    private var lastEscape = Date.distantPast
    private let store: SettingsStore
    private let stats: StatsStore

    init(scheduler: BreakScheduler, store: SettingsStore, stats: StatsStore) {
        self.store = store
        self.stats = stats
        sub = scheduler.$phase.removeDuplicates().sink { [weak self] phase in
            phase == .breaking ? self?.show(scheduler) : self?.hide()
        }
    }

    private func background(for screen: NSScreen) -> NSImage? {
        let s = store.settings
        switch s.theme {
        case .image: return NSImage(contentsOfFile: s.imagePath)
        case .wallpaper: return NSWorkspace.shared.desktopImageURL(for: screen).flatMap { NSImage(contentsOf: $0) }
        default: return nil
        }
    }

    /// Esc twice within 0.6s runs the configured action, if the enforcement level allows leaving.
    private func handleEscape(_ scheduler: BreakScheduler) {
        defer { lastEscape = Date() }
        let s = store.settings
        guard Date().timeIntervalSince(lastEscape) < 0.6, s.enforcement != .hardcore else { return }
        switch s.doubleEscape {
        case .skip: if s.skipAllowed(elapsed: scheduler.elapsed, length: scheduler.breakLength) { scheduler.endBreak() }
        case .snooze: if snoozesLeft() { scheduler.postpone(by: 300) }
        case .nothing: break
        }
    }

    func snoozesLeft() -> Bool {
        let n = store.settings.snoozesPerDay
        return n < 0 || stats.stats.snoozesToday < n
    }

    private func show(_ scheduler: BreakScheduler) {
        hide()
        let copy = BreakCopy.pick(rule: scheduler.activeRule, long: scheduler.isLongBreak, custom: store.settings.customMessages)
        windows = NSScreen.screens.map { screen in
            let w = OverlayWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.level = .screenSaver
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            w.isReleasedWhenClosed = false
            w.onEscape = { [weak self] in self?.handleEscape(scheduler) }
            w.contentView = NSHostingView(rootView: BreakView(
                scheduler: scheduler, settings: store.settings, copy: copy, image: background(for: screen),
                onSkip: { scheduler.endBreak() }, onLock: { Lock.screen() }))
            w.alphaValue = 0
            w.setFrame(screen.frame, display: true)
            return w
        }
        NSApp.activate(ignoringOtherApps: true)
        windows.first?.makeKeyAndOrderFront(nil)
        windows.dropFirst().forEach { $0.orderFrontRegardless() }
        let fade = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.4
        NSAnimationContext.runAnimationGroup { $0.duration = fade; windows.forEach { $0.animator().alphaValue = 1 } }
    }

    private func hide() {
        windows.forEach { $0.orderOut(nil) }
        windows = []
    }
}
