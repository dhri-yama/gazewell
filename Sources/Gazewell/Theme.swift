import SwiftUI
import AppKit

enum BreakLayout { case editorial, forest, breathe, night, ocean, earth, air }

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
    var stars = false                 // twinkling starfield on the signature break backdrop
}

extension Style {
    static func hex(_ v: UInt32, _ a: Double = 1) -> Color {
        Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255, opacity: a)
    }

    /// Deep leafy green glass, mint and cream, a flat tree that grows through the break. Inspired by focus-and-grow apps; no third-party assets.
    static let forest = Style(
        name: "Forest", dark: true, ink: hex(0xF1F6E8), veil: hex(0x06231A, 0.5), sidebar: hex(0x04191A, 0.34),
        cardOpacity: 0.08, strokeOpacity: 0.13, hairlineOpacity: 0.11, accent: hex(0x6FD38A),
        glowA: hex(0x2FA46A, 0.55), glowB: hex(0xC9E265, 0.28),
        backdrop: (hex(0x0A2E22), [hex(0x1F7A4D), hex(0x4E9F5E), hex(0x145A3E), hex(0x6FA84A)]),
        tileOverride: [0x7BD47E, 0x2E8B57], cardRadius: 20, controlRadius: 12, displayDesign: .rounded, material: .hudWindow,
        cardSolid: hex(0x0F3A2B, 0.94), breakLayout: .forest, glyph: [0xB5E36F, 0x3FAE6A], glyphInk: 0x0B2E1F,
        onAccent: hex(0x06231A))

    /// Midnight blue glass, one warm gold accent, a breathing ring with Breathe in / out prompts. Inspired by meditation apps; no third-party assets.
    static let medito = Style(
        name: "Medito", dark: true, ink: hex(0xEEF1FA), veil: hex(0x050A1C, 0.5), sidebar: hex(0x030715, 0.4),
        cardOpacity: 0.07, strokeOpacity: 0.12, hairlineOpacity: 0.1, accent: hex(0xF2C14E),
        glowA: hex(0x3B4BA8, 0.5), glowB: hex(0xF2C14E, 0.16),
        backdrop: (hex(0x070C24), [hex(0x1E2A78), hex(0x2F3C9E), hex(0x151F5C), hex(0x4B3A8A)]),
        tileOverride: [0x6B7BEA, 0x3B4BA8], cardRadius: 22, controlRadius: 14, displayDesign: .default, material: .hudWindow,
        cardSolid: hex(0x0E1536, 0.94), breakLayout: .breathe, glyph: [0xFFE08A, 0xF2C14E], glyphInk: 0x2B2000,
        onAccent: hex(0x1B1500))

    /// Black-violet sky with twinkling stars and a crescent moon that crosses the sky as the break passes.
    static let night = Style(
        name: "Night sky", dark: true, ink: hex(0xEAF0FF), veil: hex(0x03040F, 0.55), sidebar: hex(0x02030B, 0.45),
        cardOpacity: 0.07, strokeOpacity: 0.12, hairlineOpacity: 0.1, accent: hex(0xB7A8FF),
        glowA: hex(0x2B1B6B, 0.55), glowB: hex(0x1B3A8A, 0.35),
        backdrop: (hex(0x04030F), [hex(0x1B1148), hex(0x2D1B69), hex(0x0F1A4A), hex(0x3A1F6E)]),
        tileOverride: [0x8B7BFF, 0x4A3BC4], cardRadius: 20, controlRadius: 12, displayDesign: .serif, material: .hudWindow,
        cardSolid: hex(0x0B0A22, 0.94), breakLayout: .night, glyph: [0xD6CCFF, 0x8B7BFF], glyphInk: 0x1A1040,
        onAccent: hex(0x0B0820), stars: true)

    /// Deep teal water with aqua light; the break fills a circle with rolling waves.
    static let ocean = Style(
        name: "Ocean", dark: true, ink: hex(0xF2FAFF), veil: hex(0x03283A, 0.42), sidebar: hex(0x021E2C, 0.38),
        cardOpacity: 0.09, strokeOpacity: 0.14, hairlineOpacity: 0.11, accent: hex(0x4DE1D2),
        glowA: hex(0x1CA3C6, 0.55), glowB: hex(0x7FF0E0, 0.25),
        backdrop: (hex(0x06394F), [hex(0x0F7FA8), hex(0x2CC6C8), hex(0x0B5A86), hex(0x66DDE0)]),
        tileOverride: [0x47D6D0, 0x1389B8], cardRadius: 24, controlRadius: 14, displayDesign: .rounded, material: .hudWindow,
        cardSolid: hex(0x08455F, 0.94), breakLayout: .ocean, glyph: [0x9AF0E6, 0x2CC6C8], glyphInk: 0x02323F,
        onAccent: hex(0x03283A))

    /// Warm clay, soil and sand; a cairn of stones stacks up through the break.
    static let earth = Style(
        name: "Earth", dark: true, ink: hex(0xF6EEE2), veil: hex(0x1C120B, 0.5), sidebar: hex(0x140C07, 0.4),
        cardOpacity: 0.08, strokeOpacity: 0.13, hairlineOpacity: 0.11, accent: hex(0xE29A63),
        glowA: hex(0xA0522D, 0.5), glowB: hex(0xD9B26F, 0.22),
        backdrop: (hex(0x1B120C), [hex(0x6B3F24), hex(0x8C5A35), hex(0x3E2616), hex(0xB07A45)]),
        tileOverride: [0xD58A55, 0x9A5530], cardRadius: 18, controlRadius: 12, displayDesign: .serif, material: .hudWindow,
        cardSolid: hex(0x2A1B12, 0.94), breakLayout: .earth, glyph: [0xF0B88A, 0xC67A45], glyphInk: 0x2A140A,
        onAccent: hex(0x2A140A))

    /// Light, airy sky blue and white; a dandelion's seeds blow away on the wind as the break passes.
    static let air = Style(
        name: "Air", dark: false, ink: hex(0x1E2B3A), veil: hex(0xE8F4FF, 0.5), sidebar: hex(0xFFFFFF, 0.3),
        cardOpacity: 0.06, strokeOpacity: 0.09, hairlineOpacity: 0.09, accent: hex(0x1F7AE0),
        glowA: hex(0xBFE3FF, 0.75), glowB: hex(0xFFFFFF, 0.55),
        backdrop: (hex(0xCFE8FA), [hex(0xA9D6F5), hex(0xE8F5FF), hex(0x8FC4EE), hex(0xFFFFFF)]),
        tileOverride: [0x6FB7F5, 0x2D8CFF], cardRadius: 24, controlRadius: 14, displayDesign: .rounded, material: .popover,
        cardSolid: hex(0xF4FAFF, 0.94), breakLayout: .air, glyph: [0xBFE3FF, 0x6FB7F5], glyphInk: 0x0B2B4A,
        cardFill: Color.white.opacity(0.55), onAccent: .white)

    /// Near-monochrome dark blur, one lime accent, square corners, serif display with mono details.
    static let mono = Style(
        name: "Mono focus", dark: true, ink: hex(0xF2F2EE), veil: hex(0x08090B, 0.5), sidebar: hex(0x000000, 0.3),
        cardOpacity: 0.05, strokeOpacity: 0.1, hairlineOpacity: 0.09, accent: hex(0xC8F560),
        glowA: hex(0x39414F, 0.55), glowB: hex(0x20262E, 0.5),
        backdrop: (hex(0x0B0C0E), [hex(0x2B3340), hex(0x1F242C), hex(0x3A4250), hex(0x161A20)]),
        tileOverride: [0x4A4F58, 0x2C3038], cardRadius: 8, controlRadius: 6, displayDesign: .serif, material: .hudWindow,
        cardSolid: hex(0x14161A, 0.92), breakLayout: .editorial, glyph: [0xC8F560, 0x9BD33A], glyphInk: 0x10130A,
        onAccent: hex(0x10130A))

    static let all = [forest, earth, ocean, air, night, medito, mono]
    static func named(_ n: String) -> Style { all.first { $0.name == n } ?? forest }
}

/// Current look. Set once at launch (or per render in the snapshot harness).
enum Theme {
    static var style = Style.forest

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
