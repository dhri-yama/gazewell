import AppKit
import SwiftUI
import GazewellCore

/// A wellness reminder as a full-screen scene: the theme's backdrop, one animation across the whole screen that depends on the
/// reminder (rain, rising chevrons, eyelids, silk ribbons), and the message. Animation colours come from the active theme.
/// Time-driven (no @State) so it also works on toolchains without SwiftUI's macro plugin.
struct NudgeView: View {
    var nudge: Nudge
    var font = FontSpec(family: "system", weight: 2)
    var start = Date()
    static let life = 5.0
    private let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { ctx in
            let t = reduceMotion ? 1.2 : ctx.date.timeIntervalSince(start)
            let enter = min(1, t / 0.45), exit = min(1, max(0, (Self.life - t) / 0.5))
            let fade = min(1 - pow(1 - enter, 3), exit)
            ZStack {
                Backdrop(theme: .olive, image: nil).opacity(0.8)     // the theme's own backdrop (stars for Night sky); the blur shows faintly through
                scene(t)
                VStack(spacing: 14) {
                    Text(nudge.name.uppercased()).font(.system(size: 18, weight: .semibold)).tracking(4).foregroundStyle(Theme.accent)
                    Text(nudge.message).font(font.font(44)).foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center).frame(maxWidth: 900)
                }
                .padding(40)
                .shadow(color: .black.opacity(0.45), radius: 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(fade)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(nudge.message)
    }

    @ViewBuilder private func scene(_ t: Double) -> some View {
        switch nudge.id {
        case "water": RainLayer(time: t)
        case "posture": RiseLayer(time: t)
        case "blink": EyelidLayer(time: t)
        default: RibbonLayer(time: t)
        }
    }
}

/// Deterministic pseudo-random in 0...1 from an index and a salt, so scenes need no stored state.
private func rnd(_ i: Int, _ salt: Double) -> Double {
    let x = sin(Double(i) * 91.3458 + salt * 47.853) * 43758.5453
    return x - floor(x)
}

private func ease(_ x: Double) -> Double { (1 - cos(.pi * min(max(x, 0), 1))) / 2 }

/// Hydration: droplets falling over the whole screen with ripples along the bottom, tinted by the theme accent.
struct RainLayer: View {
    var time: Double

    var body: some View {
        Canvas { ctx, size in
            let accent = Theme.accent
            let cycle = 1.18
            for i in 0..<90 {
                let x = rnd(i, 1) * size.width
                let radius = 6 + 12 * rnd(i, 2) * rnd(i, 2)
                let speed = 0.4 + 0.75 * rnd(i, 3)
                let travel = (time * speed * 0.55 + rnd(i, 4) * cycle).truncatingRemainder(dividingBy: cycle) / cycle
                let y = -0.1 * size.height + travel * size.height * 1.2
                let len = radius * (2.6 + 1.6 * speed)
                var drop = Path()
                drop.move(to: CGPoint(x: x, y: y - len))
                drop.addQuadCurve(to: CGPoint(x: x - radius, y: y), control: CGPoint(x: x - radius * 0.9, y: y - len * 0.45))
                drop.addArc(center: CGPoint(x: x, y: y), radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
                drop.addQuadCurve(to: CGPoint(x: x, y: y - len), control: CGPoint(x: x + radius * 0.9, y: y - len * 0.45))
                drop.closeSubpath()
                ctx.fill(drop, with: .linearGradient(Gradient(colors: [accent.opacity(0.3), accent.opacity(0.9)]),
                                                     startPoint: CGPoint(x: x, y: y - len), endPoint: CGPoint(x: x, y: y + radius)))
                ctx.fill(Path(ellipseIn: CGRect(x: x - radius * 0.55, y: y - radius * 0.5, width: radius * 0.5, height: radius * 0.7)),
                         with: .color(.white.opacity(0.5)))
            }
            for j in 0..<10 {
                let ph = (time * 0.45 + rnd(j, 7)).truncatingRemainder(dividingBy: 1)
                let w = 24 + 190 * ph
                let rect = CGRect(x: rnd(j, 8) * size.width - w / 2, y: size.height - 30 - rnd(j, 9) * 46, width: w, height: w * 0.22)
                ctx.stroke(Path(ellipseIn: rect), with: .color(accent.opacity(0.6 * (1 - ph))), lineWidth: 2)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Posture: chevrons rise through the whole screen and fade out near the top, like sitting taller.
struct RiseLayer: View {
    var time: Double

    var body: some View {
        Canvas { ctx, size in
            let accent = Theme.accent
            for i in 0..<46 {
                let x = rnd(i, 1) * size.width
                let s = 14 + 40 * rnd(i, 2)
                let speed = 0.12 + 0.2 * rnd(i, 3)
                let travel = (time * speed + rnd(i, 4)).truncatingRemainder(dividingBy: 1)       // 0 bottom ... 1 top
                let y = size.height + s - travel * (size.height + 2 * s)
                let alpha = sin(.pi * travel) * (0.25 + 0.55 * rnd(i, 5))
                var chevron = Path()
                chevron.move(to: CGPoint(x: x - s, y: y + s * 0.5))
                chevron.addLine(to: CGPoint(x: x, y: y - s * 0.5))
                chevron.addLine(to: CGPoint(x: x + s, y: y + s * 0.5))
                ctx.stroke(chevron, with: .color(accent.opacity(alpha)), style: StrokeStyle(lineWidth: max(3, s * 0.22), lineCap: .round, lineJoin: .round))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Blink: soft eyelids close from the top and bottom of the whole screen and reopen, slowly, again and again.
struct EyelidLayer: View {
    var time: Double

    var body: some View {
        GeometryReader { g in
            let ph = time.truncatingRemainder(dividingBy: 1.8)
            let closed = ph < 0.45 ? ease(ph / 0.45) : ph < 0.6 ? 1 : ph < 1.05 ? 1 - ease((ph - 0.6) / 0.45) : 0
            let lid = Theme.palette(.olive).base
            let h = g.size.height / 2 * closed
            ZStack {
                VStack(spacing: 0) {
                    LinearGradient(stops: [.init(color: lid, location: 0), .init(color: lid, location: 0.8), .init(color: lid.opacity(0), location: 1)],
                                   startPoint: .top, endPoint: .bottom).frame(height: h)
                    Spacer(minLength: 0)
                    LinearGradient(stops: [.init(color: lid.opacity(0), location: 0), .init(color: lid, location: 0.2), .init(color: lid, location: 1)],
                                   startPoint: .top, endPoint: .bottom).frame(height: h)
                }
                // a thin glow along each lid edge
                VStack(spacing: 0) {
                    Color.clear.frame(height: max(0, h - 2))
                    Theme.accent.opacity(0.35 * closed).frame(height: 2)
                    Spacer(minLength: 0)
                    Theme.accent.opacity(0.35 * closed).frame(height: 2)
                    Color.clear.frame(height: max(0, h - 2))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Stretch: translucent silk ribbons sweep across the screen, widening and flattening like a long stretch and release.
struct RibbonLayer: View {
    var time: Double

    var body: some View {
        Canvas { ctx, size in
            let u = (1 - cos(2 * .pi * time / 3.2)) / 2                     // 0 relaxed ... 1 fully stretched
            let colors = [Theme.accent, Theme.style.glowA, Theme.style.glowB, Theme.accent]
            for k in 0..<5 {
                let baseY = size.height * (0.22 + 0.14 * Double(k))
                let amp = size.height * (0.05 + 0.08 * u) * (1 + 0.25 * Double(k % 2))
                let thick = size.height * (0.035 + 0.05 * u)
                let freq = 1.1 + 0.25 * Double(k)
                var top: [CGPoint] = [], bottom: [CGPoint] = []
                var x = -20.0
                while x <= size.width + 20 {
                    let ph = x / size.width * 2 * .pi * freq + time * (0.7 + 0.15 * Double(k)) + Double(k) * 1.3
                    let y = baseY + amp * sin(ph)
                    top.append(CGPoint(x: x, y: y - thick)); bottom.append(CGPoint(x: x, y: y + thick))
                    x += 8
                }
                var ribbon = Path()
                ribbon.move(to: top[0])
                top.dropFirst().forEach { ribbon.addLine(to: $0) }
                bottom.reversed().forEach { ribbon.addLine(to: $0) }
                ribbon.closeSubpath()
                ctx.fill(ribbon, with: .linearGradient(Gradient(colors: [colors[k % colors.count].opacity(0.0), colors[k % colors.count].opacity(0.45),
                                                                          colors[(k + 1) % colors.count].opacity(0.0)]),
                                                       startPoint: CGPoint(x: 0, y: baseY), endPoint: CGPoint(x: size.width, y: baseY)))
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

    /// Covers every display with the themed full-screen animation, then fades out.
    func show(_ n: Nudge) {
        close()
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
            let host = NSHostingView(rootView: NudgeView(nudge: n, font: store.settings.subtitleFont))
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
