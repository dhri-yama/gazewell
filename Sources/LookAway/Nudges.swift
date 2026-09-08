import AppKit
import SwiftUI
import LookAwayCore

/// Animated wellness glyph, modelled on LookAway's posture and blink reminders: a gradient disc in a dark pill or ring.
/// Time-driven (no @State) so it also works on toolchains without SwiftUI's macro plugin.
struct NudgeView: View {
    var nudge: Nudge
    var start = Date()
    static let life = 5.0
    private let k: CGFloat = 2        // glyph scale: big enough to read across a full-screen blur
    private static let plum = Theme.hex(0x4A1230)
    private static let disc = LinearGradient(colors: [Theme.hex(0xE85AB8), Theme.hex(0xF59A55)], startPoint: .topLeading, endPoint: .bottomTrailing)
    private let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { ctx in
            let t = reduceMotion ? 1.2 : ctx.date.timeIntervalSince(start)
            let enter = min(1, t / 0.45), exit = min(1, max(0, (Self.life - t) / 0.5))
            let eased = 1 - pow(1 - enter, 3)
            VStack(spacing: 14 * k) {
                glyph(t)
                Text(nudge.message).font(.system(size: 15 * k * 0.85, weight: .medium)).foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center).frame(maxWidth: 620)
                    .shadow(color: .black.opacity(0.5), radius: 4)
            }
            .padding(24)
            .scaleEffect(0.8 + 0.2 * eased)
            .opacity(min(eased, exit))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(nudge.message)
    }

    @ViewBuilder private func glyph(_ t: Double) -> some View {
        switch nudge.id {
        case "posture": posture(t)
        case "blink": blink(t)
        default: pulse(t)
        }
    }

    /// The disc rises and settles inside a tall pill, like sitting up straight.
    private func posture(_ t: Double) -> some View {
        let p = (1 - cos(2 * .pi * t / 2.4)) / 2          // 0 at the bottom, 1 at the top
        return ZStack {
            Capsule().fill(Theme.hex(0x2A1326, 0.82)).overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                .frame(width: 66 * k, height: 134 * k)
            Circle().fill(Self.disc).frame(width: 54 * k, height: 54 * k)
                .overlay(Image(systemName: "arrow.up").font(.system(size: 22 * k, weight: .black)).foregroundStyle(Self.plum))
                .offset(y: (32 - 64 * p) * k)
        }
    }

    /// Eyes squash shut and reopen every 1.6s inside a dark ring.
    private func blink(_ t: Double) -> some View {
        let c = (t / 1.6).truncatingRemainder(dividingBy: 1)
        let open = c < 0.78 ? 1 : (c < 0.88 ? 1 - (c - 0.78) / 0.1 : (c - 0.88) / 0.12)
        return ZStack {
            Circle().fill(Theme.hex(0x2A1326, 0.82)).overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1)).frame(width: 96 * k, height: 96 * k)
            Circle().fill(Self.disc).frame(width: 74 * k, height: 74 * k)
            HStack(spacing: 14 * k) {
                ForEach(0..<2, id: \.self) { _ in Capsule().fill(Self.plum).frame(width: 14 * k, height: max(3 * k, 13 * k * open)) }
            }
            .offset(y: 2 * k)
        }
    }

    /// Water and stretch: the symbol breathes inside the same disc.
    private func pulse(_ t: Double) -> some View {
        ZStack {
            Circle().fill(Theme.hex(0x2A1326, 0.82)).overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1)).frame(width: 96 * k, height: 96 * k)
            Circle().fill(Self.disc).frame(width: 74 * k, height: 74 * k)
            Image(systemName: nudge.symbol).font(.system(size: 30 * k, weight: .bold)).foregroundStyle(Self.plum)
                .scaleEffect(1 + 0.12 * sin(2 * .pi * t / 1.6))
        }
    }
}

/// Wellness reminders (posture, blink, water, stretch): a short animation, never a full break.
final class Nudges {
    private var due: [String: Date] = [:]
    private var windows: [NSWindow] = []
    private var token: UUID?
    private let scheduler: BreakScheduler
    private let store: SettingsStore

    init(scheduler: BreakScheduler, store: SettingsStore) {
        self.scheduler = scheduler
        self.store = store
    }

    /// Called every second. A reminder that comes due during a break or a blocked moment waits for the next free tick.
    func tick(now: Date = Date()) {
        for n in store.settings.nudges {
            guard n.enabled else { due[n.id] = nil; continue }
            let d = due[n.id] ?? now.addingTimeInterval(TimeInterval(n.minutes * 60))
            due[n.id] = d
            if d <= now, scheduler.phase == .working, !scheduler.blocked {
                show(n)
                due[n.id] = now.addingTimeInterval(TimeInterval(n.minutes * 60))
            }
        }
    }

    /// Blurs every display and plays the glyph on each, then fades out.
    func show(_ n: Nudge) {
        close()
        let tint = Color.black.opacity(0.3)
        windows = NSScreen.screens.map { screen in
            let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.level = .screenSaver
            w.isOpaque = false
            w.backgroundColor = .clear
            w.hasShadow = false
            w.ignoresMouseEvents = true      // never blocks typing or clicking underneath
            w.isReleasedWhenClosed = false
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            let blur = NSVisualEffectView(frame: NSRect(origin: .zero, size: screen.frame.size))
            blur.material = .hudWindow
            blur.blendingMode = .behindWindow
            blur.state = .active
            let host = NSHostingView(rootView: ZStack { tint; NudgeView(nudge: n) })
            host.frame = blur.bounds
            host.autoresizingMask = [.width, .height]
            blur.addSubview(host)
            w.contentView = blur
            w.alphaValue = 0
            w.setFrame(screen.frame, display: true)
            w.orderFrontRegardless()
            return w
        }
        let reduce = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        fade(to: 1, over: reduce ? 0 : 0.4)
        let token = UUID(); self.token = token
        DispatchQueue.main.asyncAfter(deadline: .now() + NudgeView.life - 0.5) { [weak self] in
            guard self?.token == token else { return }
            self?.fade(to: 0, over: reduce ? 0 : 0.5)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + NudgeView.life + 0.1) { [weak self] in
            guard self?.token == token else { return }
            self?.close()
        }
    }

    private func fade(to alpha: CGFloat, over duration: TimeInterval) {
        NSAnimationContext.runAnimationGroup { $0.duration = duration; windows.forEach { $0.animator().alphaValue = alpha } }
    }

    private func close() {
        token = nil
        windows.forEach { $0.orderOut(nil) }
        windows = []
    }
}
