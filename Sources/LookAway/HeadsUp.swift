import AppKit
import SwiftUI
import Combine
import LookAwayCore

private struct HeadsUpCard: View {
    @ObservedObject var scheduler: BreakScheduler

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Break in \(scheduler.secondsLeft)s").font(.headline).monospacedDigit()
                Text("Look away from the screen soon.").font(.subheadline).foregroundStyle(.secondary)
            }
            Button("Start now") { scheduler.startBreak() }
                .buttonStyle(.borderedProminent).tint(Theme.accent)
            Menu("Later") {
                ForEach([1, 5, 15], id: \.self) { m in
                    Button("In \(m) min") { scheduler.postpone(by: TimeInterval(m * 60)) }
                }
            }
            .menuStyle(.borderlessButton).fixedSize()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct CursorPill: View {
    @ObservedObject var scheduler: BreakScheduler
    var body: some View {
        Text("\(scheduler.secondsLeft)")
            .font(.system(.callout, design: .rounded).weight(.medium)).monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Theme.ink.opacity(0.7), in: Capsule())
            .accessibilityHidden(true)
    }
}

private func makePanel<V: View>(_ view: V, activating: Bool) -> NSPanel {
    let host = NSHostingView(rootView: view)
    let p = NSPanel(contentRect: NSRect(origin: .zero, size: host.fittingSize),
                    styleMask: activating ? [.borderless] : [.borderless, .nonactivatingPanel],
                    backing: .buffered, defer: false)
    p.contentView = host
    p.level = .floating
    p.isOpaque = false
    p.backgroundColor = .clear
    p.hasShadow = true
    p.isReleasedWhenClosed = false
    p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    return p
}

/// Heads-up card (top right) plus a small countdown pill that trails the cursor while a break is imminent.
final class HeadsUp {
    private var card: NSPanel?
    private var pill: NSPanel?
    private var follow: Timer?
    private var sub: AnyCancellable?

    init(scheduler: BreakScheduler) {
        sub = scheduler.$phase.removeDuplicates().sink { [weak self] phase in
            phase == .headsUp ? self?.show(scheduler) : self?.hide()
        }
    }

    private func show(_ scheduler: BreakScheduler) {
        hide()
        let card = makePanel(HeadsUpCard(scheduler: scheduler), activating: false)
        if let f = NSScreen.main?.visibleFrame {
            card.setFrameOrigin(NSPoint(x: f.maxX - card.frame.width - 16, y: f.maxY - card.frame.height - 16))
        }
        card.orderFrontRegardless()
        self.card = card

        let pill = makePanel(CursorPill(scheduler: scheduler), activating: false)
        pill.ignoresMouseEvents = true
        pill.hasShadow = false
        pill.alphaValue = 0.6
        pill.orderFrontRegardless()
        self.pill = pill
        follow = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak pill] _ in
            let m = NSEvent.mouseLocation
            pill?.setFrameOrigin(NSPoint(x: m.x + 16, y: m.y - 32))
        }
    }

    private func hide() {
        follow?.invalidate(); follow = nil
        card?.orderOut(nil); card = nil
        pill?.orderOut(nil); pill = nil
    }
}
