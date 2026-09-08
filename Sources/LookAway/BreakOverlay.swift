import AppKit
import SwiftUI
import Combine
import LookAwayCore

/// Borderless window that can take key focus so Esc/Skip works.
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

/// Shows one full-screen overlay per display while the scheduler is breaking.
final class BreakOverlay {
    private var windows: [NSWindow] = []
    private var sub: AnyCancellable?

    init(scheduler: BreakScheduler) {
        sub = scheduler.$phase.removeDuplicates().sink { [weak self] phase in
            phase == .breaking ? self?.show(scheduler) : self?.hide()
        }
    }

    private func show(_ scheduler: BreakScheduler) {
        hide()
        let skip = { scheduler.endBreak() }
        windows = NSScreen.screens.map { screen in
            let w = OverlayWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.level = .screenSaver
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            w.isReleasedWhenClosed = false
            w.contentView = NSHostingView(rootView: BreakView(scheduler: scheduler, onSkip: skip))
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
