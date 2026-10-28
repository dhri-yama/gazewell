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

    private var timerText: some View {
        Text(clock)
            .font(settings.timerFont.font(64)).monospacedDigit()
            .foregroundStyle(Theme.ink(0.5))
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
            if let escHint { Text(escHint).font(.system(size: 17)).foregroundStyle(Theme.ink(0.4)) }
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
                timerText
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
                timerText.font(settings.timerFont.font(88)).foregroundStyle(Theme.ink(0.9))
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

    var body: some View {
        Group {
            if Theme.style.breakLayout == .editorial { editorial } else { centered }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Backdrop(theme: settings.theme, image: image) }
        .ignoresSafeArea()
    }
}
