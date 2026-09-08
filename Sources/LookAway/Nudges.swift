import AppKit
import SwiftUI
import LookAwayCore

/// Animated wellness glyph, modelled on LookAway's posture and blink reminders: a gradient disc in a dark pill or ring.
/// Time-driven (no @State) so it also works on toolchains without SwiftUI's macro plugin.
struct NudgeView: View {
    var nudge: Nudge
    var start = Date()
    static let life = 5.0
    private static let plum = Theme.hex(0x4A1230)
    private static let disc = LinearGradient(colors: [Theme.hex(0xE85AB8), Theme.hex(0xF59A55)], startPoint: .topLeading, endPoint: .bottomTrailing)
    private let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { ctx in
            let t = reduceMotion ? 1.2 : ctx.date.timeIntervalSince(start)
            let enter = min(1, t / 0.45), exit = min(1, max(0, (Self.life - t) / 0.5))
            let eased = 1 - pow(1 - enter, 3)
            VStack(spacing: 14) {
                glyph(t)
                Text(nudge.message).font(.system(size: 15, weight: .medium)).foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center).frame(maxWidth: 280)
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
                .frame(width: 66, height: 134)
            Circle().fill(Self.disc).frame(width: 54, height: 54)
                .overlay(Image(systemName: "arrow.up").font(.system(size: 22, weight: .black)).foregroundStyle(Self.plum))
                .offset(y: 32 - 64 * p)
        }
    }

    /// Eyes squash shut and reopen every 1.6s inside a dark ring.
    private func blink(_ t: Double) -> some View {
        let c = (t / 1.6).truncatingRemainder(dividingBy: 1)
        let open = c < 0.78 ? 1 : (c < 0.88 ? 1 - (c - 0.78) / 0.1 : (c - 0.88) / 0.12)
        return ZStack {
            Circle().fill(Theme.hex(0x2A1326, 0.82)).overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1)).frame(width: 96, height: 96)
            Circle().fill(Self.disc).frame(width: 74, height: 74)
            HStack(spacing: 14) {
                ForEach(0..<2, id: \.self) { _ in Capsule().fill(Self.plum).frame(width: 14, height: max(3, 13 * open)) }
            }
            .offset(y: 2)
        }
    }

    /// Water and stretch: the symbol breathes inside the same disc.
    private func pulse(_ t: Double) -> some View {
        ZStack {
            Circle().fill(Theme.hex(0x2A1326, 0.82)).overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1)).frame(width: 96, height: 96)
            Circle().fill(Self.disc).frame(width: 74, height: 74)
            Image(systemName: nudge.symbol).font(.system(size: 30, weight: .bold)).foregroundStyle(Self.plum)
                .scaleEffect(1 + 0.12 * sin(2 * .pi * t / 1.6))
        }
    }
}

/// Wellness reminders (posture, blink, water, stretch): a short animation, never a full break.
final class Nudges {
    private var due: [String: Date] = [:]
    private var panel: NSPanel?
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

    func show(_ n: Nudge) {
        panel?.orderOut(nil)
        let p = makePanel(NudgeView(nudge: n))
        p.ignoresMouseEvents = true
        p.hasShadow = false
        if let f = NSScreen.main?.visibleFrame {
            p.setFrameOrigin(NSPoint(x: f.midX - p.frame.width / 2, y: f.midY - p.frame.height / 2))
        }
        p.orderFrontRegardless()
        panel = p
        DispatchQueue.main.asyncAfter(deadline: .now() + NudgeView.life + 0.1) { [weak self, weak p] in
            guard let p, self?.panel === p else { return }
            p.orderOut(nil); self?.panel = nil
        }
    }
}
