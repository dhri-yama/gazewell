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

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let progress {
                    ZStack {
                        Circle().stroke(.white.opacity(0.3), lineWidth: 2)
                        Circle().trim(from: 0, to: progress).stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round)).rotationEffect(.degrees(-90))
                    }.frame(width: 18, height: 18)
                } else if let symbol {
                    Image(systemName: symbol).font(.system(size: 16, weight: .semibold))
                }
                Text(title).font(.system(size: 22, weight: .semibold))
            }
            .padding(.horizontal, 26).padding(.vertical, 14)
            .background(.white.opacity(enabled ? 0.18 : 0.1), in: Capsule())
            .foregroundStyle(.white.opacity(enabled ? 1 : 0.6))
        }
        .buttonStyle(.plain)
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

    var body: some View {
        let allowed = settings.skipAllowed(elapsed: scheduler.elapsed, length: scheduler.breakLength)
        let showSkip = settings.enforcement != .hardcore || settings.allowEarlyEnd
        VStack(spacing: 0) {
            if settings.showClock {
                (Text("Current time is ") + Text(Self.time.string(from: Date())).fontWeight(.semibold))
                    .font(.system(size: 22, weight: .medium)).foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 70)
            }
            Spacer()
            VStack(spacing: 22) {
                Text(copy.title)
                    .font(.system(size: 72, weight: .bold)).foregroundStyle(.white)
                    .lineLimit(2).minimumScaleFactor(0.5).multilineTextAlignment(.center)
                Text(copy.subtitle)
                    .font(.system(size: 30, weight: .regular)).foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center).lineLimit(3)
                Rectangle().fill(.white.opacity(0.25)).frame(width: 400, height: 1).padding(.vertical, 22)
                Text(clock)
                    .font(.system(size: 64, weight: .semibold)).monospacedDigit()
                    .foregroundStyle(.white.opacity(0.5))
                    .accessibilityLabel(spoken)
            }
            .frame(maxWidth: 1100).padding(.horizontal, 60)
            Spacer()
            VStack(spacing: 18) {
                HStack(spacing: 16) {
                    if showSkip {
                        let lockedOut = settings.enforcement == .balanced && !allowed
                        Pill(title: settings.enforcement == .hardcore ? "End break" : "Skip",
                             symbol: "forward", progress: lockedOut ? min(1, Double(scheduler.elapsed) / 5) : nil,
                             enabled: allowed, action: onSkip)
                    }
                    if settings.showLockButton { Pill(title: "Lock Screen", symbol: "lock", progress: nil, action: onLock) }
                }
                if let escHint { Text(escHint).font(.system(size: 17)).foregroundStyle(.white.opacity(0.4)) }
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { Backdrop(theme: settings.theme, image: image) }
        .ignoresSafeArea()
    }
}
