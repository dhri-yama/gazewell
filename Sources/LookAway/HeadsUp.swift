import AppKit
import SwiftUI
import Combine
import LookAwayCore

struct HeadsUpCard: View {
    @ObservedObject var scheduler: BreakScheduler
    var canSnooze: Bool

    private var clock: String { String(format: "%02d:%02d", scheduler.secondsLeft / 60, scheduler.secondsLeft % 60) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "timer").font(.system(size: 22, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Theme.tile([0xC8509A, 0xF0884A]), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 2) {
                    Text(clock).font(.system(size: 28, weight: .bold)).monospacedDigit().foregroundStyle(.white)
                    Text("Almost time. Your eyes will appreciate this.").font(.system(size: 15)).foregroundStyle(.white.opacity(0.75))
                }
            }
            HStack(spacing: 8) {
                Button("Start break now") { scheduler.startBreak() }
                    .buttonStyle(CapsuleButton(fill: Theme.accent, bold: true))
                ForEach([1, 5, 15], id: \.self) { m in
                    Button("+\(m)m") { scheduler.postpone(by: TimeInterval(m * 60)) }
                        .buttonStyle(CapsuleButton(fill: .white.opacity(0.14), bold: false))
                        .disabled(!canSnooze).opacity(canSnooze ? 1 : 0.4)
                        .help(canSnooze ? "Snooze \(m) minute\(m == 1 ? "" : "s")" : "No snoozes left today")
                }
            }
        }
        .padding(18)
        .frame(width: 440, alignment: .leading)
        .background(Theme.hex(0x2B1B17, 0.94), in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.1), lineWidth: 1))
    }
}

struct CapsuleButton: ButtonStyle {
    var fill: Color
    var bold: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: bold ? .semibold : .medium)).foregroundStyle(.white)
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(fill, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct CursorPill: View {
    @ObservedObject var scheduler: BreakScheduler
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Theme.tile([0xB05CD8, 0xE0609A]), in: RoundedRectangle(cornerRadius: 6))
            Text("\(scheduler.isLongBreak ? "Long" : "Short") break in \(scheduler.secondsLeft)")
                .font(.system(size: 14, weight: .semibold)).monospacedDigit().foregroundStyle(.white)
        }
        .padding(.leading, 6).padding(.trailing, 12).padding(.vertical, 5)
        .background(Theme.hex(0x262A4A, 0.92), in: Capsule())
        .accessibilityHidden(true)
    }
}

func makePanel<V: View>(_ view: V) -> NSPanel {
    let host = NSHostingView(rootView: view)
    let p = NSPanel(contentRect: NSRect(origin: .zero, size: host.fittingSize),
                    styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    p.contentView = host
    p.level = .floating
    p.isOpaque = false
    p.backgroundColor = .clear
    p.hasShadow = true
    p.isReleasedWhenClosed = false
    p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    return p
}

/// Heads-up card (top centre) plus a small countdown pill that trails the cursor while a break is imminent.
final class HeadsUp {
    private var card: NSPanel?
    private var pill: NSPanel?
    private var follow: Timer?
    private var sub: AnyCancellable?
    private let store: SettingsStore
    private let canSnooze: () -> Bool

    init(scheduler: BreakScheduler, store: SettingsStore, canSnooze: @escaping () -> Bool) {
        self.store = store
        self.canSnooze = canSnooze
        sub = scheduler.$phase.removeDuplicates().sink { [weak self] phase in
            phase == .headsUp ? self?.show(scheduler) : self?.hide()
        }
    }

    private func show(_ scheduler: BreakScheduler) {
        hide()
        let card = makePanel(HeadsUpCard(scheduler: scheduler, canSnooze: canSnooze()))
        if let f = NSScreen.main?.visibleFrame {
            card.setFrameOrigin(NSPoint(x: f.midX - card.frame.width / 2, y: f.maxY - card.frame.height - 14))
        }
        card.orderFrontRegardless()
        self.card = card

        guard store.settings.cursorCountdown else { return }
        let pill = makePanel(CursorPill(scheduler: scheduler))
        pill.ignoresMouseEvents = true
        pill.hasShadow = false
        pill.orderFrontRegardless()
        self.pill = pill
        let t = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak pill] _ in
            let m = NSEvent.mouseLocation
            pill?.setFrameOrigin(NSPoint(x: m.x + 18, y: m.y - 36))
        }
        RunLoop.main.add(t, forMode: .common)   // default mode alone would freeze it while a menu is open
        follow = t
    }

    private func hide() {
        follow?.invalidate(); follow = nil
        card?.orderOut(nil); card = nil
        pill?.orderOut(nil); pill = nil
    }
}
