import SwiftUI
import AppKit

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
                    }
                    .clipped()
                }
            }
        }
    }
}
