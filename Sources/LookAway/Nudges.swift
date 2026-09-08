import AppKit
import SwiftUI
import LookAwayCore

struct ToastView: View {
    var symbol: String
    var text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Theme.tile([0xC8509A, 0xF0884A]), in: Circle())
            Text(text).font(.system(size: 15, weight: .medium)).foregroundStyle(.white)
        }
        .padding(.leading, 10).padding(.trailing, 20).padding(.vertical, 10)
        .background(Theme.hex(0x22233A, 0.95), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
    }
}

/// Wellness reminders (posture, blink, water, stretch): a short toast, never a full break.
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
        let p = makePanel(ToastView(symbol: n.symbol, text: n.message))
        if let f = NSScreen.main?.visibleFrame {
            p.setFrameOrigin(NSPoint(x: f.midX - p.frame.width / 2, y: f.maxY - p.frame.height - 14))
        }
        p.orderFrontRegardless()
        panel = p
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self, weak p] in
            guard let p, self?.panel === p else { return }
            p.orderOut(nil); self?.panel = nil
        }
    }
}
