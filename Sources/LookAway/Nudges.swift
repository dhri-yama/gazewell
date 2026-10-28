import AppKit
import SwiftUI
import LookAwayCore

/// Animated wellness glyph, modelled on LookAway's posture and blink reminders: a gradient disc in a dark pill or ring.
/// Time-driven (no @State) so it also works on toolchains without SwiftUI's macro plugin.
struct NudgeView: View {
    var nudge: Nudge
    var font = FontSpec(family: "system", weight: 2)
    var start = Date()
    static let life = 5.0
    private let k: CGFloat = 2        // glyph scale: big enough to read across a full-screen blur
    private var plum: Color { Theme.hex(Theme.style.glyphInk) }
    private var disc: LinearGradient { LinearGradient(colors: Theme.style.glyph.map { Theme.hex($0) }, startPoint: .topLeading, endPoint: .bottomTrailing) }
    private let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { ctx in
            let t = reduceMotion ? 1.2 : ctx.date.timeIntervalSince(start)
            let enter = min(1, t / 0.45), exit = min(1, max(0, (Self.life - t) / 0.5))
            let eased = 1 - pow(1 - enter, 3)
            ZStack {
                if nudge.id == "water" {
                    // Hydration: cool tint plus droplets falling over the whole screen.
                    Color(red: 0.08, green: 0.45, blue: 0.7).opacity(0.2 * min(eased, exit))
                    RainLayer(time: t).opacity(min(eased, exit))
                }
                VStack(spacing: 14 * k) {
                    glyph(t)
                    Text(nudge.message).font(font.font(15 * k * 0.85)).foregroundStyle(Theme.ink(0.92))
                        .multilineTextAlignment(.center).frame(maxWidth: 620)
                        .shadow(color: .black.opacity(Theme.style.dark ? 0.5 : 0.12), radius: 4)
                }
                .padding(24)
                .scaleEffect(0.8 + 0.2 * eased)
                .opacity(min(eased, exit))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(nudge.message)
    }

    @ViewBuilder private func glyph(_ t: Double) -> some View {
        switch nudge.id {
        case "posture": posture(t)
        case "blink": blink(t)
        case "stretch": stretch(t)
        default: pulse(t)
        }
    }

    /// The disc rises and settles inside a tall pill, like sitting up straight.
    private func posture(_ t: Double) -> some View {
        let p = (1 - cos(2 * .pi * t / 2.4)) / 2          // 0 at the bottom, 1 at the top
        return ZStack {
            Capsule().fill(Theme.style.cardSolid).overlay(Capsule().stroke(Theme.ink(0.1), lineWidth: 1))
                .frame(width: 66 * k, height: 134 * k)
            Circle().fill(disc).frame(width: 54 * k, height: 54 * k)
                .overlay(Image(systemName: "arrow.up").font(.system(size: 22 * k, weight: .black)).foregroundStyle(plum))
                .offset(y: (32 - 64 * p) * k)
        }
    }

    /// Eyes squash shut and reopen every 1.6s inside a dark ring.
    private func blink(_ t: Double) -> some View {
        let c = (t / 1.6).truncatingRemainder(dividingBy: 1)
        let open = c < 0.78 ? 1 : (c < 0.88 ? 1 - (c - 0.78) / 0.1 : (c - 0.88) / 0.12)
        return ZStack {
            Circle().fill(Theme.style.cardSolid).overlay(Circle().stroke(Theme.ink(0.1), lineWidth: 1)).frame(width: 96 * k, height: 96 * k)
            Circle().fill(disc).frame(width: 74 * k, height: 74 * k)
            HStack(spacing: 14 * k) {
                ForEach(0..<2, id: \.self) { _ in Capsule().fill(plum).frame(width: 14 * k, height: max(3 * k, 13 * k * open)) }
            }
            .offset(y: 2 * k)
        }
    }

    /// A simple figure raises its arms overhead and leans side to side, with a ring rippling out, like a morning stretch.
    private func stretch(_ t: Double) -> some View {
        let u = (1 - cos(2 * .pi * t / 3.2)) / 2               // 0 arms down ... 1 arms overhead
        let lean = sin(2 * .pi * t / 6.4) * 7 * u              // degrees
        let ring = (t / 3.2).truncatingRemainder(dividingBy: 1)
        let ink = plum
        return ZStack {
            Circle().stroke(Theme.ink(0.3 * (1 - ring)), lineWidth: 3).frame(width: 96 * k * (1 + 0.45 * ring), height: 96 * k * (1 + 0.45 * ring))
            Circle().fill(Theme.style.cardSolid).overlay(Circle().stroke(Theme.ink(0.1), lineWidth: 1)).frame(width: 96 * k, height: 96 * k)
            Circle().fill(disc).frame(width: 74 * k, height: 74 * k)
            Canvas { ctx, size in
                let s = size.width / 100
                func P(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * s, y: y * s) }
                ctx.translateBy(x: size.width / 2, y: size.height * 0.9)
                ctx.rotate(by: .degrees(lean))
                ctx.translateBy(x: -size.width / 2, y: -size.height * 0.9)
                let style = StrokeStyle(lineWidth: 7 * s, lineCap: .round, lineJoin: .round)
                var body = Path()
                body.move(to: P(42, 90)); body.addLine(to: P(50, 66)); body.addLine(to: P(58, 90))   // legs
                body.move(to: P(50, 66)); body.addLine(to: P(50, 40))                                 // torso
                let th = Double.pi * (0.1 + 0.72 * u)                                                 // 0 = hanging, pi = straight up
                for sign in [-1.0, 1.0] {
                    body.move(to: P(50, 42))
                    body.addLine(to: P(50 + sign * 27 * sin(th), 42 + 27 * cos(th)))                  // arms
                }
                ctx.stroke(body, with: .color(ink), style: style)
                ctx.fill(Path(ellipseIn: CGRect(x: 41 * s, y: 17 * s, width: 18 * s, height: 18 * s)), with: .color(ink))
            }
            .frame(width: 74 * k, height: 74 * k)
        }
    }

    /// Water: the drop symbol breathes inside the disc (the rain behind it is `RainLayer`).
    private func pulse(_ t: Double) -> some View {
        ZStack {
            Circle().fill(Theme.style.cardSolid).overlay(Circle().stroke(Theme.ink(0.1), lineWidth: 1)).frame(width: 96 * k, height: 96 * k)
            Circle().fill(disc).frame(width: 74 * k, height: 74 * k)
            Image(systemName: nudge.symbol).font(.system(size: 30 * k, weight: .bold)).foregroundStyle(plum)
                .scaleEffect(1 + 0.12 * sin(2 * .pi * t / 1.6))
        }
    }
}

/// Water droplets falling over the whole screen, with ripples along the bottom edge. Positions come from a hash of the drop index.
struct RainLayer: View {
    var time: Double

    var body: some View {
        Canvas { ctx, size in
            func r(_ i: Int, _ salt: Double) -> Double { let x = sin(Double(i) * 91.3458 + salt * 47.853) * 43758.5453; return x - floor(x) }
            let cycle = 1.18
            for i in 0..<90 {
                let x = r(i, 1) * size.width
                let radius = 6 + 12 * r(i, 2) * r(i, 2)
                let speed = 0.4 + 0.75 * r(i, 3)                                   // cycles of the screen per second
                let travel = (time * speed * 0.55 + r(i, 4) * cycle).truncatingRemainder(dividingBy: cycle) / cycle
                let y = -0.1 * size.height + travel * size.height * 1.2
                let len = radius * (2.6 + 1.6 * speed)
                var drop = Path()
                drop.move(to: CGPoint(x: x, y: y - len))
                drop.addQuadCurve(to: CGPoint(x: x - radius, y: y), control: CGPoint(x: x - radius * 0.9, y: y - len * 0.45))
                drop.addArc(center: CGPoint(x: x, y: y), radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
                drop.addQuadCurve(to: CGPoint(x: x, y: y - len), control: CGPoint(x: x + radius * 0.9, y: y - len * 0.45))
                drop.closeSubpath()
                ctx.fill(drop, with: .linearGradient(Gradient(colors: [Color(red: 0.75, green: 0.94, blue: 1).opacity(0.35), Color(red: 0.29, green: 0.72, blue: 0.91).opacity(0.9)]),
                                                     startPoint: CGPoint(x: x, y: y - len), endPoint: CGPoint(x: x, y: y + radius)))
                ctx.fill(Path(ellipseIn: CGRect(x: x - radius * 0.55, y: y - radius * 0.5, width: radius * 0.5, height: radius * 0.7)),
                         with: .color(.white.opacity(0.55)))
            }
            for j in 0..<10 {
                let ph = (time * 0.45 + r(j, 7)).truncatingRemainder(dividingBy: 1)
                let w = 24 + 190 * ph
                let rect = CGRect(x: r(j, 8) * size.width - w / 2, y: size.height - 30 - r(j, 9) * 46, width: w, height: w * 0.22)
                ctx.stroke(Path(ellipseIn: rect), with: .color(Color(red: 0.7, green: 0.93, blue: 1).opacity(0.55 * (1 - ph))), lineWidth: 2)
            }
        }
        .allowsHitTesting(false)
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
        guard store.settings.enabled else { due = [:]; return }
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
        let tint = Theme.style.veil
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
            blur.material = Theme.style.material
            blur.blendingMode = .behindWindow
            blur.state = .active
            let host = NSHostingView(rootView: ZStack { tint; NudgeView(nudge: n, font: store.settings.subtitleFont) })
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
