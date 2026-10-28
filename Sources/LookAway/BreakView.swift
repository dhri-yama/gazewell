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

    /// Centred stack: clock on top, copy and countdown in the middle, controls at the bottom.
    private var centered: some View {
        VStack(spacing: 0) {
            if settings.showClock { clockLine.padding(.top, 70) }
            Spacer()
            VStack(spacing: 22) {
                Text(copy.title)
                    .font(settings.titleFont.font(72)).foregroundStyle(Theme.ink)
                    .lineLimit(2).minimumScaleFactor(0.5).multilineTextAlignment(.center)
                Text(copy.subtitle)
                    .font(settings.subtitleFont.font(30)).foregroundStyle(Theme.ink(0.8))
                    .multilineTextAlignment(.center).lineLimit(3)
                Rectangle().fill(Theme.ink(0.25)).frame(width: 400, height: 1).padding(.vertical, 22)
                timerText()
            }
            .frame(maxWidth: 1100).padding(.horizontal, 60)
            Spacer()
            controls.padding(.bottom, 60)
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

    /// Sun: copy on top, the countdown inside a soft glowing circle that gently breathes, controls below.
    private var sun: some View {
        let reduce = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        return VStack(spacing: 0) {
            if settings.showClock { clockLine.padding(.top, 70) }
            Spacer()
            VStack(spacing: 18) {
                Text(copy.title)
                    .font(settings.titleFont.font(64)).foregroundStyle(Theme.ink)
                    .lineLimit(2).minimumScaleFactor(0.5).multilineTextAlignment(.center)
                Text(copy.subtitle)
                    .font(settings.subtitleFont.font(26)).foregroundStyle(Theme.ink(0.75))
                    .multilineTextAlignment(.center).lineLimit(3)
            }
            .frame(maxWidth: 900).padding(.horizontal, 60)
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduce)) { ctx in
                let t = reduce ? 0 : ctx.date.timeIntervalSinceReferenceDate
                let breathe = 1 + 0.035 * sin(t * 2 * .pi / 6)      // 6s in/out
                ZStack {
                    Circle().fill(Color.white.opacity(0.28)).frame(width: 380, height: 380).scaleEffect(breathe * 1.06)
                    Circle().fill(Color.white.opacity(0.5)).frame(width: 300, height: 300).scaleEffect(breathe)
                    timerText(72, opacity: 1)
                }
            }
            .padding(.top, 34)
            Spacer()
            controls.padding(.bottom, 56)
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

    var body: some View {
        Group {
            switch Theme.style.breakLayout {
            case .night: night
            case .ocean: ocean
            case .breathe: breathe
            case .forest: forest
            case .editorial: editorial
            case .sun: sun
            case .centered: centered
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Backdrop(theme: settings.theme, image: image) }
        .ignoresSafeArea()
    }
}
