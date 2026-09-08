import SwiftUI
import AppKit
import LookAwayCore

struct BreakView: View {
    @ObservedObject var scheduler: BreakScheduler
    var background: NSImage?
    var onSkip: () -> Void
    private let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    private let highContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast

    /// "20" for short breaks, "29:59" once a minute or more is left.
    private var clock: String {
        let s = scheduler.secondsLeft
        return s < 60 ? "\(s)" : String(format: "%d:%02d", s / 60, s % 60)
    }

    private var spoken: String {
        let (m, s) = (scheduler.secondsLeft / 60, scheduler.secondsLeft % 60)
        let parts = [m > 0 ? "\(m) minute\(m == 1 ? "" : "s")" : nil, s > 0 || m == 0 ? "\(s) second\(s == 1 ? "" : "s")" : nil]
        return parts.compactMap { $0 }.joined(separator: " ") + " left"
    }

    var body: some View {
        ZStack {
            VStack(spacing: 40) {
                Text(scheduler.activeRule.title.uppercased())
                    .font(.callout.weight(.medium)).tracking(3)
                    .foregroundStyle(highContrast ? .white : Theme.glow)
                ZStack {
                    // 8s cycle: 4s in, 4s out. Time-derived so no @State (its macro plugin is missing on CLT-only toolchains).
                    TimelineView(.animation(paused: reduceMotion)) { ctx in
                        let phase = reduceMotion ? 1 : (1 - cos(ctx.date.timeIntervalSinceReferenceDate * .pi / 4)) / 2
                        Circle().stroke(Theme.glow.opacity(highContrast ? 0.9 : 0.5), lineWidth: highContrast ? 4 : 2)
                            .frame(width: 360, height: 360)
                            .scaleEffect(0.88 + 0.12 * phase)
                    }
                    .accessibilityHidden(true)
                    Text(clock)
                        .font(Theme.countdown).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .frame(maxWidth: 300)
                        .foregroundStyle(.white)
                        .accessibilityLabel(spoken)
                }
                if !scheduler.activeRule.message.isEmpty {
                    Text(scheduler.activeRule.message)
                        .font(.title2).foregroundStyle(Theme.glow)
                        .shadow(color: Theme.ink.opacity(0.4), radius: 6)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 560)
                        .padding(.horizontal, 40)
                }
            }
            .accessibilityElement(children: .contain)
            VStack {
                Spacer()
                Button(action: onSkip) {
                    HStack(spacing: 8) {
                        Text("Skip")
                        Text("esc").font(.caption).opacity(0.7)
                    }
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.plain)
                .padding(.horizontal, 20).padding(.vertical, 8)
                .background(Theme.ink.opacity(0.55), in: Capsule())
                .foregroundStyle(.white)
                .padding(.bottom, 40)
                .help("Skip this break (Esc)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if let background {
                // Photos get an ink scrim so white text keeps 4.5:1 contrast even on a white image.
                Image(nsImage: background).resizable().scaledToFill()
                    .overlay(Theme.ink.opacity(highContrast ? 0.75 : 0.65)).clipped()
            } else {
                Theme.sky
            }
        }
        .ignoresSafeArea()
    }
}
