import SwiftUI
import AppKit
import LookAwayCore

extension AppSettings {
    /// Whether Skip/End break is available this far into a break, per the enforcement level.
    func skipAllowed(elapsed: Int, length: Int) -> Bool {
        switch enforcement {
        case .casual: return true
        case .balanced: return elapsed >= 5
        case .hardcore: return allowEarlyEnd && Double(elapsed) >= Double(length) * 0.8
        }
    }
}

/// Flat vector tree that grows with `progress` (0...1): a bare seedling, two leaves, then a full canopy. Sways gently.
private struct TreeView: View {
    var progress: Double
    var sway: Double          // degrees
    private let trunk = Color(red: 0.72, green: 0.52, blue: 0.33)

    var body: some View {
        let p = min(max(progress, 0), 1)
        let canopy = min(max((p - 0.3) / 0.7, 0), 1)
        let leaves = min(max(p / 0.25, 0), 1)
        let trunkH = 26 + 104 * p
        ZStack(alignment: .bottom) {
            Ellipse().fill(Color.black.opacity(0.25)).frame(width: 170, height: 26).offset(y: 6)
            Ellipse().fill(LinearGradient(colors: [Theme.hex(0x4FA861), Theme.hex(0x2C7A4B)], startPoint: .top, endPoint: .bottom))
                .frame(width: 150, height: 30)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6).fill(trunk).frame(width: 12, height: trunkH)
                // seedling leaves, fading out as the canopy takes over
                Group {
                    Ellipse().fill(Theme.hex(0x7BD47E)).frame(width: 34, height: 18).rotationEffect(.degrees(-28)).offset(x: -20, y: -trunkH + 4)
                    Ellipse().fill(Theme.hex(0x5BBF6E)).frame(width: 34, height: 18).rotationEffect(.degrees(28)).offset(x: 20, y: -trunkH + 4)
                }
                .scaleEffect(leaves).opacity(1 - canopy)
                // canopy: three overlapping blobs
                Group {
                    Circle().fill(Theme.hex(0x3FAE6A)).frame(width: 96, height: 96).offset(x: -34, y: -trunkH + 24)
                    Circle().fill(Theme.hex(0x5BC47A)).frame(width: 108, height: 108).offset(x: 30, y: -trunkH + 20)
                    Circle().fill(Theme.hex(0x8FE08A)).frame(width: 92, height: 92).offset(x: 0, y: -trunkH - 18)
                }
                .scaleEffect(canopy, anchor: .bottom).opacity(canopy)
            }
            .rotationEffect(.degrees(sway), anchor: .bottom)
            .offset(y: -10)
        }
        .frame(width: 280, height: 290, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

/// Crescent moon travelling along a dotted arc from one horizon to the other as `progress` goes 0...1.
private struct MoonSky: View {
    var progress: Double
    var body: some View {
        let p = min(max(progress, 0), 1)
        Canvas { ctx, size in
            func point(_ t: Double) -> CGPoint {
                CGPoint(x: size.width / 2 + (t - 0.5) * (size.width - 140), y: size.height - 50 - sin(.pi * t) * (size.height - 110))
            }
            var arc = Path()
            arc.move(to: point(0))
            for i in 1...60 { arc.addLine(to: point(Double(i) / 60)) }
            ctx.stroke(arc, with: .color(Theme.ink(0.18)), style: StrokeStyle(lineWidth: 1.5, dash: [2, 8]))
            let c = point(p)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - 90, y: c.y - 90, width: 180, height: 180)),
                     with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.93, blue: 0.7).opacity(0.35), .clear]),
                                           center: c, startRadius: 0, endRadius: 90))
            ctx.drawLayer { l in
                l.fill(Path(ellipseIn: CGRect(x: c.x - 40, y: c.y - 40, width: 80, height: 80)), with: .color(Color(red: 1, green: 0.94, blue: 0.76)))
                l.blendMode = .clear
                l.fill(Path(ellipseIn: CGRect(x: c.x - 24, y: c.y - 46, width: 74, height: 74)), with: .color(.black))
            }
        }
        .frame(width: 640, height: 300)
        .accessibilityHidden(true)
    }
}

/// A circle that fills with two rolling waves as `progress` goes 0...1.
private struct WaterOrb: View {
    var progress: Double
    var time: Double
    var body: some View {
        let p = min(max(progress, 0), 1)
        Canvas { ctx, size in
            let rect = CGRect(x: 10, y: 10, width: size.width - 20, height: size.height - 20)
            let orb = Path(ellipseIn: rect)
            ctx.fill(orb, with: .color(Theme.ink(0.07)))
            ctx.drawLayer { l in
                l.clip(to: orb)
                let level = rect.maxY - rect.height * (0.06 + 0.94 * p)
                for (i, color) in [Theme.hex(0x2CC6C8, 0.65), Theme.hex(0x1389B8, 0.85)].enumerated() {
                    var wave = Path()
                    wave.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                    var x = rect.minX
                    while x <= rect.maxX {
                        let phase = time * (i == 0 ? 0.9 : -1.3) + Double(i) * 1.8
                        wave.addLine(to: CGPoint(x: x, y: level + sin((x - rect.minX) / rect.width * 2 * .pi * 1.4 + phase) * (i == 0 ? 9 : 7) + CGFloat(i) * 7))
                        x += 4
                    }
                    wave.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                    wave.closeSubpath()
                    l.fill(wave, with: .color(color))
                }
            }
            ctx.stroke(orb, with: .color(Theme.ink(0.3)), lineWidth: 3)
        }
        .frame(width: 380, height: 380)
        .accessibilityHidden(true)
    }
}

private func hash01(_ i: Int, _ salt: Double) -> Double {
    let x = sin(Double(i) * 91.3458 + salt * 47.853) * 43758.5453
    return x - floor(x)
}

/// Cairn: stones appear one by one, largest at the bottom, as `progress` goes 0...1.
private struct Cairn: View {
    var progress: Double
    private let widths: [Double] = [210, 176, 144, 114, 88, 62]
    private let heights: [Double] = [66, 58, 50, 44, 38, 32]
    private let shifts: [Double] = [0, 12, -10, 7, -5, 2]
    private let tones: [UInt32] = [0x7A6A5A, 0x8B7765, 0x9A8570, 0x6F5E4F, 0x8C7B68, 0xA39078]

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2, ground = size.height - 36
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 170, y: ground - 8, width: 340, height: 34)), with: .color(.black.opacity(0.28)))
            ctx.fill(Path(roundedRect: CGRect(x: cx - 160, y: ground - 4, width: 320, height: 16), cornerRadius: 8), with: .color(Theme.hex(0x4A3322)))
            var y = ground
            for i in 0..<6 {
                let local = min(max(progress * 6 - Double(i), 0), 1)
                let h = heights[i], w = widths[i]
                y -= h * 0.82
                guard local > 0 else { continue }
                let e = 1 - pow(1 - local, 3)
                let rect = CGRect(x: cx + shifts[i] - w / 2, y: y - h / 2 - (1 - e) * 60, width: w, height: h)
                let tone = Theme.hex(tones[i])
                ctx.opacity = e
                ctx.fill(Path(ellipseIn: rect), with: .linearGradient(Gradient(colors: [tone, Theme.hex(tones[i] &- 0x1C1C1C)]),
                                                                        startPoint: CGPoint(x: rect.midX, y: rect.minY), endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
                ctx.fill(Path(ellipseIn: CGRect(x: rect.minX + w * 0.16, y: rect.minY + h * 0.14, width: w * 0.34, height: h * 0.22)), with: .color(.white.opacity(0.18)))
                ctx.opacity = 1
            }
        }
        .frame(width: 360, height: 400)
        .accessibilityHidden(true)
    }
}

/// Dandelion: its seeds detach one by one and drift away on the wind as `progress` goes 0...1; wind streaks flow across the screen.
private struct Dandelion: View {
    var elapsed: Double
    var length: Double
    var time: Double

    var body: some View {
        Canvas { ctx, size in
            let ink = Theme.ink
            let head = CGPoint(x: size.width * 0.34, y: 150)
            // stem
            var stem = Path()
            stem.move(to: CGPoint(x: head.x, y: head.y + 6))
            stem.addQuadCurve(to: CGPoint(x: head.x - 24, y: size.height), control: CGPoint(x: head.x + 40, y: size.height * 0.6))
            ctx.stroke(stem, with: .color(ink.opacity(0.45)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: head.x - 7, y: head.y - 7, width: 14, height: 14)), with: .color(ink.opacity(0.55)))
            let sway = sin(time * 1.4) * 3
            let n = 64
            for i in 0..<n {
                let a = Double(i) / Double(n) * 2 * .pi + hash01(i, 2) * 0.12
                let reach = 50 + 8 * hash01(i, 3)
                let base = CGPoint(x: head.x + cos(a) * reach + sway * 0.3, y: head.y + sin(a) * reach)
                let release = 0.1 + 0.82 * hash01(i, 1)
                let since = elapsed - release * length                               // seconds since this seed let go
                func tuft(_ p: CGPoint, _ angle: Double, _ alpha: Double) {
                    var t = Path()
                    for k in 0..<7 {
                        let d = angle + (Double(k) - 3) * 0.42
                        t.move(to: p); t.addLine(to: CGPoint(x: p.x + cos(d) * 10, y: p.y + sin(d) * 10))
                    }
                    ctx.stroke(t, with: .color(ink.opacity(alpha)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - 1.5, y: p.y - 1.5, width: 3, height: 3)), with: .color(ink.opacity(alpha)))
                }
                if since <= 0 {
                    var spoke = Path(); spoke.move(to: head); spoke.addLine(to: base)
                    ctx.stroke(spoke, with: .color(ink.opacity(0.3)), lineWidth: 1)
                    tuft(base, a, 0.85)
                } else {
                    let v = 70 + 90 * hash01(i, 4)
                    let p = CGPoint(x: base.x + since * v, y: base.y - since * 6 + sin(since * 1.7 + Double(i)) * 16 + since * since * 1.1)
                    tuft(p, a + since * 0.6, max(0, 0.85 - since / 7))
                }
            }
            // wind streaks
            for k in 0..<7 {
                var w = Path()
                let y0 = size.height * (0.1 + 0.13 * Double(k))
                var x = 0.0
                w.move(to: CGPoint(x: 0, y: y0))
                while x <= size.width { x += 10; w.addLine(to: CGPoint(x: x, y: y0 + sin(x / size.width * 5 + Double(k)) * 14 + sin(x / 90 + time * 0.8 + Double(k)) * 4)) }
                ctx.stroke(w, with: .color(ink.opacity(0.14)), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [90, 70], dashPhase: -time * 90 * (0.7 + 0.15 * Double(k))))
            }
        }
        .frame(width: 760, height: 430)
        .accessibilityHidden(true)
    }
}

private struct Pill: View {
    var title: String
    var symbol: String?
    var progress: Double?     // shows a filling ring in place of the icon
    var enabled = true
    var action: () -> Void

    private var pillShape: AnyShape {
        Theme.style.breakLayout == .editorial ? AnyShape(RoundedRectangle(cornerRadius: Theme.controlRadius)) : AnyShape(Capsule())
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let progress {
                    ZStack {
                        Circle().stroke(Theme.ink(0.3), lineWidth: 2)
                        Circle().trim(from: 0, to: progress).stroke(Theme.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round)).rotationEffect(.degrees(-90))
                    }.frame(width: 18, height: 18)
                } else if let symbol {
                    Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                }
                Text(title).font(.system(size: 22, weight: .semibold))
            }
            .padding(.horizontal, 26).padding(.vertical, 14)
            .background(Theme.ink(enabled ? 0.18 : 0.1), in: pillShape)
            .foregroundStyle(Theme.ink(enabled ? 1 : 0.6))
        }
        .buttonStyle(PressStyle())
        .disabled(!enabled)
    }
}

struct BreakView: View {
    @ObservedObject var scheduler: BreakScheduler
    var settings: AppSettings
    var copy: BreakCopy
    var image: NSImage?
    var onSkip: () -> Void
    var onLock: () -> Void
    var appeared = Date()      // for scenes that animate continuously across the break

    private static let time: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()

    private var clock: String { String(format: "%02d:%02d", scheduler.secondsLeft / 60, scheduler.secondsLeft % 60) }

    private var spoken: String {
        let (m, s) = (scheduler.secondsLeft / 60, scheduler.secondsLeft % 60)
        let parts = [m > 0 ? "\(m) minute\(m == 1 ? "" : "s")" : nil, s > 0 || m == 0 ? "\(s) second\(s == 1 ? "" : "s")" : nil]
        return parts.compactMap { $0 }.joined(separator: " ") + " left"
    }

    private var escHint: String? {
        guard settings.enforcement != .hardcore else { return nil }
        switch settings.doubleEscape {
        case .skip: return "Press Esc twice to skip"
        case .snooze: return "Press Esc twice to snooze 5 min"
        case .nothing: return nil
        }
    }

    private var allowed: Bool { settings.skipAllowed(elapsed: scheduler.elapsed, length: scheduler.breakLength) }

    private var clockLine: some View {
        (Text("Current time is ") + Text(Self.time.string(from: Date())).fontWeight(.semibold))
            .font(settings.subtitleFont.font(22)).foregroundStyle(Theme.ink(0.85))
    }

    private func timerText(_ size: CGFloat = 64, opacity: Double = 0.5) -> some View {
        Text(clock)
            .font(settings.timerFont.font(size)).monospacedDigit()
            .foregroundStyle(Theme.ink(opacity))
            .accessibilityLabel(spoken)
    }

    private var controls: some View {
        let showSkip = settings.enforcement != .hardcore || settings.allowEarlyEnd
        let lockedOut = settings.enforcement == .balanced && !allowed
        return VStack(alignment: Theme.style.breakLayout == .editorial ? .leading : .center, spacing: 18) {
            HStack(spacing: 16) {
                if showSkip {
                    Pill(title: settings.enforcement == .hardcore ? "End break" : "Skip",
                         symbol: "forward", progress: lockedOut ? min(1, Double(scheduler.elapsed) / 5) : nil,
                         enabled: allowed, action: onSkip)
                }
                if settings.showLockButton { Pill(title: "Lock Screen", symbol: "lock", progress: nil, action: onLock) }
            }
            if let escHint { Text(escHint).font(.system(size: 17)).foregroundStyle(Theme.ink(Theme.style.dark ? 0.45 : 0.7)) }
        }
    }

    /// Editorial: oversized left-aligned title bottom-left, countdown and clock top-right, controls under the copy.
    private var editorial: some View {
        ZStack {
            VStack(alignment: .trailing, spacing: 6) {
                timerText(88, opacity: 0.9)
                if settings.showClock { clockLine.font(settings.subtitleFont.font(18)).foregroundStyle(Theme.ink(0.6)) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(70)
            VStack(alignment: .leading, spacing: 22) {
                Spacer()
                Rectangle().fill(Theme.accent).frame(width: 64, height: 4)
                Text(copy.title)
                    .font(settings.titleFont.font(116)).foregroundStyle(Theme.ink)
                    .lineLimit(3).minimumScaleFactor(0.4).multilineTextAlignment(.leading)
                Text(copy.subtitle)
                    .font(settings.subtitleFont.font(28)).foregroundStyle(Theme.ink(0.75))
                    .multilineTextAlignment(.leading).lineLimit(3).frame(maxWidth: 760, alignment: .leading)
                controls.padding(.top, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading).padding(.horizontal, 90).padding(.bottom, 80)
        }
    }

    /// Forest: a tree grows through the break inside a soft glow, countdown beneath it.
    private var forest: some View {
        let reduce = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let progress = Double(scheduler.elapsed) / Double(max(1, scheduler.breakLength))
        return VStack(spacing: 0) {
            if settings.showClock { clockLine.padding(.top, 60) }
            Spacer()
            Text(copy.title)
                .font(settings.titleFont.font(60)).foregroundStyle(Theme.ink)
                .lineLimit(2).minimumScaleFactor(0.5).multilineTextAlignment(.center).padding(.horizontal, 60)
            Text(copy.subtitle)
                .font(settings.subtitleFont.font(24)).foregroundStyle(Theme.ink(0.78))
                .multilineTextAlignment(.center).lineLimit(2).frame(maxWidth: 820).padding(.top, 14)
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduce)) { ctx in
                let sway = reduce ? 0 : 1.8 * sin(ctx.date.timeIntervalSinceReferenceDate * 2 * .pi / 6)
                ZStack {
                    Circle().fill(RadialGradient(colors: [Theme.hex(0xC9E265, 0.32), .clear], center: .center, startRadius: 0, endRadius: 230))
                        .frame(width: 460, height: 460)
                    TreeView(progress: progress, sway: sway).scaleEffect(1.55, anchor: .bottom).offset(y: 20)
                }
            }
            .frame(height: 400).padding(.top, 10)
            timerText(52, opacity: 0.85)
            Spacer()
            controls.padding(.bottom, 52)
        }
    }

    /// Breathe: a gold progress ring around a softly pulsing disc, with Breathe in / out prompts every 4 seconds.
    private var breathe: some View {
        let reduce = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let progress = Double(scheduler.elapsed) / Double(max(1, scheduler.breakLength))
        return VStack(spacing: 0) {
            if settings.showClock { clockLine.padding(.top, 70) }
            Spacer()
            Text(copy.title)
                .font(settings.titleFont.font(52)).foregroundStyle(Theme.ink)
                .lineLimit(2).minimumScaleFactor(0.5).multilineTextAlignment(.center).padding(.horizontal, 60)
            Text(copy.subtitle)
                .font(settings.subtitleFont.font(24)).foregroundStyle(Theme.ink(0.75))
                .multilineTextAlignment(.center).lineLimit(2).frame(maxWidth: 820).padding(.top, 12)
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduce)) { ctx in
                // 8s cycle: 4s in, 4s out
                let t = reduce ? 0 : ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 8)
                let inhale = t < 4
                let ease = (1 - cos(.pi * (inhale ? t / 4 : (t - 4) / 4))) / 2     // 0...1 within each half
                let size = inhale ? ease : 1 - ease
                ZStack {
                    Circle().stroke(Theme.ink(0.12), lineWidth: 4).frame(width: 380, height: 380)
                    Circle().trim(from: 0, to: progress).stroke(Theme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 380, height: 380).rotationEffect(.degrees(-90))
                    Circle().fill(RadialGradient(colors: [Theme.accent.opacity(0.4), .clear], center: .center, startRadius: 0, endRadius: 170))
                        .frame(width: 340, height: 340).scaleEffect(0.8 + 0.2 * size)
                    Circle().fill(Theme.ink(0.1)).frame(width: 250, height: 250).scaleEffect(0.84 + 0.16 * size)
                    VStack(spacing: 6) {
                        Text(reduce ? "Breathe" : inhale ? "Breathe in" : "Breathe out")
                            .font(Theme.display(22, .medium)).foregroundStyle(Theme.accent)
                        timerText(64, opacity: 0.95)
                    }
                }
            }
            .frame(height: 400).padding(.top, 26)
            Spacer()
            controls.padding(.bottom, 56)
        }
    }

    /// Night: the moon crosses a starry sky over the break; countdown beneath.
    private var night: some View {
        let progress = Double(scheduler.elapsed) / Double(max(1, scheduler.breakLength))
        return VStack(spacing: 0) {
            if settings.showClock { clockLine.padding(.top, 70) }
            Spacer()
            Text(copy.title)
                .font(settings.titleFont.font(58)).foregroundStyle(Theme.ink)
                .lineLimit(2).minimumScaleFactor(0.5).multilineTextAlignment(.center).padding(.horizontal, 60)
            Text(copy.subtitle)
                .font(settings.subtitleFont.font(24)).foregroundStyle(Theme.ink(0.78))
                .multilineTextAlignment(.center).lineLimit(2).frame(maxWidth: 820).padding(.top, 12)
            MoonSky(progress: progress).padding(.top, 20)
            timerText(56, opacity: 0.9)
            Spacer()
            controls.padding(.bottom, 56)
        }
    }

    /// Ocean: water rises in a circle through the break with the countdown floating on it.
    private var ocean: some View {
        let reduce = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let progress = Double(scheduler.elapsed) / Double(max(1, scheduler.breakLength))
        return VStack(spacing: 0) {
            if settings.showClock { clockLine.padding(.top, 60) }
            Spacer()
            Text(copy.title)
                .font(settings.titleFont.font(58)).foregroundStyle(Theme.ink)
                .lineLimit(2).minimumScaleFactor(0.5).multilineTextAlignment(.center).padding(.horizontal, 60)
            Text(copy.subtitle)
                .font(settings.subtitleFont.font(24)).foregroundStyle(Theme.ink(0.8))
                .multilineTextAlignment(.center).lineLimit(2).frame(maxWidth: 820).padding(.top, 12)
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduce)) { ctx in
                ZStack {
                    WaterOrb(progress: progress, time: reduce ? 0 : ctx.date.timeIntervalSinceReferenceDate)
                    timerText(68, opacity: 1).shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                }
            }
            .padding(.top, 24)
            Spacer()
            controls.padding(.bottom, 52)
        }
    }

    /// Earth: a cairn of stones stacks up through the break.
    private var earth: some View {
        let reduce = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        return VStack(spacing: 0) {
            if settings.showClock { clockLine.padding(.top, 60) }
            Spacer()
            Text(copy.title)
                .font(settings.titleFont.font(58)).foregroundStyle(Theme.ink)
                .lineLimit(2).minimumScaleFactor(0.5).multilineTextAlignment(.center).padding(.horizontal, 60)
            Text(copy.subtitle)
                .font(settings.subtitleFont.font(24)).foregroundStyle(Theme.ink(0.78))
                .multilineTextAlignment(.center).lineLimit(2).frame(maxWidth: 820).padding(.top, 12)
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduce)) { ctx in
                let exact = reduce ? Double(scheduler.elapsed) : ctx.date.timeIntervalSince(appeared)
                Cairn(progress: min(1, exact / Double(max(1, scheduler.breakLength))))
            }
            .padding(.top, 10)
            timerText(52, opacity: 0.9)
            Spacer()
            controls.padding(.bottom, 52)
        }
    }

    /// Air: a dandelion loses its seeds to the wind over the break.
    private var air: some View {
        let reduce = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        return VStack(spacing: 0) {
            if settings.showClock { clockLine.padding(.top, 60) }
            Spacer()
            Text(copy.title)
                .font(settings.titleFont.font(58)).foregroundStyle(Theme.ink)
                .lineLimit(2).minimumScaleFactor(0.5).multilineTextAlignment(.center).padding(.horizontal, 60)
            Text(copy.subtitle)
                .font(settings.subtitleFont.font(24)).foregroundStyle(Theme.ink(0.75))
                .multilineTextAlignment(.center).lineLimit(2).frame(maxWidth: 820).padding(.top, 12)
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduce)) { ctx in
                let exact = reduce ? Double(scheduler.elapsed) : ctx.date.timeIntervalSince(appeared)
                Dandelion(elapsed: exact, length: Double(max(1, scheduler.breakLength)), time: reduce ? 0 : ctx.date.timeIntervalSinceReferenceDate)
            }
            .padding(.top, 6)
            timerText(52, opacity: 0.85)
            Spacer()
            controls.padding(.bottom, 52)
        }
    }

    var body: some View {
        Group {
            switch Theme.style.breakLayout {
            case .earth: earth
            case .air: air
            case .night: night
            case .ocean: ocean
            case .breathe: breathe
            case .forest: forest
            case .editorial: editorial
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Backdrop(theme: settings.theme, image: image) }
        .ignoresSafeArea()
    }
}
