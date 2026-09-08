import SwiftUI
import AppKit
import LookAwayCore

struct BreakView: View {
    @ObservedObject var scheduler: BreakScheduler
    var onSkip: () -> Void
    private let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    var body: some View {
        ZStack {
            Theme.sky.ignoresSafeArea()
            VStack(spacing: 40) {
                Text(scheduler.activeRule.title.uppercased())
                    .font(.callout.weight(.medium)).tracking(3)
                    .foregroundStyle(Theme.glow)
                ZStack {
                    // 8s cycle: 4s in, 4s out. Time-derived so no @State (its macro plugin is missing on CLT-only toolchains).
                    TimelineView(.animation(paused: reduceMotion)) { ctx in
                        let phase = reduceMotion ? 1 : (1 - cos(ctx.date.timeIntervalSinceReferenceDate * .pi / 4)) / 2
                        Circle().stroke(Theme.glow.opacity(0.5), lineWidth: 2)
                            .frame(width: 360, height: 360)
                            .scaleEffect(0.88 + 0.12 * phase)
                    }
                    Text("\(scheduler.secondsLeft)")
                        .font(Theme.countdown).monospacedDigit()
                        .foregroundStyle(.white)
                        .accessibilityLabel("\(scheduler.secondsLeft) seconds left")
                }
                Text(scheduler.activeRule.message)
                    .font(.title3).foregroundStyle(.white)
            }
            VStack {
                Spacer()
                Button("Skip", action: onSkip)
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24).padding(.vertical, 8)
                    .background(.white.opacity(0.9), in: Capsule())
                    .foregroundStyle(Theme.ink)
                    .padding(.bottom, 40)
            }
        }
    }
}
