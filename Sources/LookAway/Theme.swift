import SwiftUI
import AppKit

enum BreakLayout { case centered, editorial, sun }

/// Everything that makes one visual direction different from another. Views read `Theme`, which reads `Theme.style`.
struct Style {
    var name: String
    var dark: Bool
    var ink: Color                    // text, icons and translucent fills (white on dark styles, near-black on light)
    var veil: Color                   // tint over the blurred window
    var sidebar: Color
    var cardOpacity: Double           // card fill = ink at this opacity
    var strokeOpacity: Double
    var hairlineOpacity: Double
    var accent: Color
    var glowA: Color
    var glowB: Color
    var backdrop: (base: Color, blobs: [Color])   // default break-screen backdrop
    var tileOverride: [UInt32]?       // monochrome styles repaint every icon tile with this gradient
    var cardRadius: CGFloat
    var controlRadius: CGFloat
    var displayDesign: Font.Design    // headings and big numbers
    var material: NSVisualEffectView.Material
    var cardSolid: Color              // heads-up card and reminder container
    var breakLayout: BreakLayout
    var glyph: [UInt32]               // reminder glyph disc gradient
    var glyphInk: UInt32              // arrow / eyes drawn on the disc
    var cardFill: Color? = nil        // solid-ish card colour; nil = a tint of `ink`
    var onAccent: Color = .white      // text on accent-coloured buttons
}

extension Style {
    static func hex(_ v: UInt32, _ a: Double = 1) -> Color {
        Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255, opacity: a)
    }

    /// Warm, friendly and sunny: orange accent, cream surfaces, very round shapes, a sun-circle countdown. Inspired by meditation apps; no third-party assets.
    static let headspace = Style(
        name: "Headspace", dark: false, ink: hex(0x2A2540), veil: hex(0xFFF1DC, 0.5), sidebar: hex(0xFFFFFF, 0.32),
        cardOpacity: 0.06, strokeOpacity: 0.08, hairlineOpacity: 0.09, accent: hex(0xF47D31),
        glowA: hex(0xFFD166, 0.75), glowB: hex(0xFF9E5E, 0.5),
        backdrop: (hex(0xFFA24D), [hex(0xFFD27A), hex(0xFF7F32), hex(0xFFE9C2), hex(0xFFB86B)]),
        tileOverride: [0xFFB347, 0xF47D31], cardRadius: 26, controlRadius: 16, displayDesign: .rounded, material: .popover,
        cardSolid: hex(0xFFF8EC, 0.96), breakLayout: .sun, glyph: [0xFFC15E, 0xF47D31], glyphInk: 0x4A2308,
        cardFill: Color.white.opacity(0.62), onAccent: hex(0x2A2540))

    /// Light frosted paper over soft pastel light, dark ink, serif headings.
    static let paper = Style(
        name: "Paper glass", dark: false, ink: hex(0x1C1B22), veil: hex(0xFFF7EE, 0.45), sidebar: hex(0xFFFFFF, 0.28),
        cardOpacity: 0.07, strokeOpacity: 0.1, hairlineOpacity: 0.1, accent: hex(0xE2572B),
        glowA: hex(0xFFC9A8, 0.7), glowB: hex(0xCDB8FF, 0.55),
        backdrop: (hex(0xF4EEE6), [hex(0xFFC7A1), hex(0xD9C7FF), hex(0xBFE3D4), hex(0xFFE2B8)]),
        tileOverride: nil, cardRadius: 22, controlRadius: 12, displayDesign: .serif, material: .popover,
        cardSolid: hex(0xFFF9F2, 0.92), breakLayout: .centered, glyph: [0xFF9E7A, 0xFFC857], glyphInk: 0x5A2410)

    /// Near-monochrome dark blur, one lime accent, square corners, serif display with mono details.
    static let mono = Style(
        name: "Mono focus", dark: true, ink: hex(0xF2F2EE), veil: hex(0x08090B, 0.5), sidebar: hex(0x000000, 0.3),
        cardOpacity: 0.05, strokeOpacity: 0.1, hairlineOpacity: 0.09, accent: hex(0xC8F560),
        glowA: hex(0x39414F, 0.55), glowB: hex(0x20262E, 0.5),
        backdrop: (hex(0x0B0C0E), [hex(0x2B3340), hex(0x1F242C), hex(0x3A4250), hex(0x161A20)]),
        tileOverride: [0x4A4F58, 0x2C3038], cardRadius: 8, controlRadius: 6, displayDesign: .serif, material: .hudWindow,
        cardSolid: hex(0x14161A, 0.92), breakLayout: .editorial, glyph: [0xC8F560, 0x9BD33A], glyphInk: 0x10130A,
        onAccent: hex(0x10130A))

    static let all = [headspace, paper, mono]
    static func named(_ n: String) -> Style { all.first { $0.name == n } ?? headspace }
}

/// Current look. Set once at launch (or per render in the snapshot harness).
enum Theme {
    static var style = Style.headspace

    static func hex(_ v: UInt32, _ a: Double = 1) -> Color { Style.hex(v, a) }

    static var ink: Color { style.ink }
    static func ink(_ opacity: Double) -> Color { style.ink.opacity(opacity) }
    /// Text on accent-coloured or gradient surfaces, which is white in every style.
    static let onAccent = Color.white
    static var textDim: Color { ink(0.6) }
    static var accent: Color { style.accent }
    /// Foreground for text that sits on the accent colour.
    static var onAccentText: Color { style.onAccent }

    static var sidebarBg: Color { style.sidebar }
    static var card: Color { style.cardFill ?? ink(style.cardOpacity) }
    static var cardStroke: Color { ink(style.strokeOpacity) }
    static var hairline: Color { ink(style.hairlineOpacity) }
    static var cardRadius: CGFloat { style.cardRadius }
    static var controlRadius: CGFloat { style.controlRadius }
    static var scheme: ColorScheme { style.dark ? .dark : .light }
    static var appearance: NSAppearance? { NSAppearance(named: style.dark ? .darkAqua : .aqua) }

    /// Display face for headings and big numbers.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: style.displayDesign)
    }

    /// Tint plus two soft glows over the blurred window, shared by settings, menu and reminders.
    static var glow: some View {
        ZStack {
            style.veil
            RadialGradient(colors: [style.glowA, .clear], center: .topLeading, startRadius: 0, endRadius: 620)
            RadialGradient(colors: [style.glowB, .clear], center: .bottomTrailing, startRadius: 0, endRadius: 560)
        }
    }

    /// Backdrop colours for the break screen. The signature theme follows the style; the other themes are fixed palettes.
    static func palette(_ t: BreakTheme) -> (base: Color, blobs: [Color]) {
        switch t {
        case .olive, .wallpaper, .image: return style.backdrop
        case .dusk: return (hex(0x12122B), [hex(0x4A3F8F), hex(0x8F4F7A), hex(0x2A2A66), hex(0xC47A6A)])
        case .ocean: return (hex(0x0B1A2A), [hex(0x1F5F8B), hex(0x2BA3A3), hex(0x14305A), hex(0x3A7FB0)])
        case .rose: return (hex(0x1E1016), [hex(0xA8456A), hex(0xD98C6A), hex(0x5A2A48), hex(0x8A3A5A)])
        case .slate: return (hex(0x14161A), [hex(0x3A4150), hex(0x5A6678), hex(0x262B34), hex(0x485064)])
        }
    }

    /// Gradient tiles behind icons.
    static func tile(_ colors: [UInt32]) -> LinearGradient {
        LinearGradient(colors: (style.tileOverride ?? colors).map { hex($0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension View {
    /// Springy shrink while pressed (the mobile-ui skill's press pattern); skipped under Reduce Motion.
    func pressSpring(_ pressed: Bool) -> some View {
        scaleEffect(pressed ? 0.95 : 1)
            .animation(NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.55), value: pressed)
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label.pressSpring(configuration.isPressed) }
}
