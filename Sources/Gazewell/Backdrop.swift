import SwiftUI
import AppKit

/// Deterministic twinkling starfield (no stored state: positions come from a hash of the star index).
struct StarField: View {
    var time: Double
    var body: some View {
        Canvas { ctx, size in
            for i in 0..<170 {
                let h = Double(i)
                func r(_ s: Double) -> Double { let x = sin(h * 12.9898 + s * 78.233) * 43758.5453; return x - floor(x) }
                let base = 0.35 + 0.65 * r(3)
                let twinkle = 0.45 + 0.55 * sin(time * (0.5 + r(4) * 1.5) + r(5) * 6.28)
                let d = 1 + 2.6 * r(6) * r(6)
                ctx.fill(Path(ellipseIn: CGRect(x: r(1) * size.width, y: r(2) * size.height, width: d, height: d)),
                         with: .color(.white.opacity(base * (0.4 + 0.6 * twinkle))))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Dark base with slowly drifting blurred colour blobs; photos get an ink scrim instead.
struct Backdrop: View {
    var theme: BreakTheme
    var image: NSImage?
    var reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    var body: some View {
        if let image {
            Image(nsImage: image).resizable().scaledToFill()
                .overlay(Color.black.opacity(0.62)).clipped()
        } else {
            let p = Theme.palette(theme)
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reduceMotion)) { ctx in
                let t = reduceMotion ? 0 : ctx.date.timeIntervalSinceReferenceDate
                GeometryReader { g in
                    ZStack {
                        p.base
                        ForEach(0..<p.blobs.count, id: \.self) { i in
                            let k = Double(i)
                            // Radial falloff instead of .blur: soft edges that render the same everywhere and cost less.
                            let w = g.size.width * (0.7 + 0.1 * sin(k))
                            Rectangle()
                                .fill(RadialGradient(colors: [p.blobs[i].opacity(0.8), p.blobs[i].opacity(0)],
                                                     center: .center, startRadius: 0, endRadius: w / 2))
                                .frame(width: w, height: w)
                                .position(x: g.size.width * (0.5 + 0.38 * sin(t / 23 + k * 1.7)),
                                          y: g.size.height * (0.5 + 0.35 * cos(t / 29 + k * 2.3)))
                        }
                        if theme == .olive && Theme.style.stars { StarField(time: t) }
                    }
                    .clipped()
                }
            }
        }
    }
}
