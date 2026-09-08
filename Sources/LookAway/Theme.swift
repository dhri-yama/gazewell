import SwiftUI
import AppKit

/// Design tokens from docs/design-direction.md (revision 2: match real LookAway).
enum Theme {
    static func hex(_ v: UInt32, _ a: Double = 1) -> Color {
        Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255, opacity: a)
    }

    // Settings window
    static let windowBg = hex(0x171826)
    static let sidebarBg = hex(0x1D1E30)
    static let card = hex(0x252739)
    static let hairline = Color.white.opacity(0.08)
    static let textDim = Color.white.opacity(0.6)
    static let accent = hex(0xFF6B2C)

    /// Backdrop colours for the break screen: near-black base plus soft blobs.
    static func palette(_ t: BreakTheme) -> (base: Color, blobs: [Color]) {
        switch t {
        case .olive, .wallpaper, .image: return (hex(0x121A14), [hex(0x8C8446), hex(0x5A5A32), hex(0x2E3A28), hex(0xA08A3C)])
        case .dusk: return (hex(0x12122B), [hex(0x4A3F8F), hex(0x8F4F7A), hex(0x2A2A66), hex(0xC47A6A)])
        case .ocean: return (hex(0x0B1A2A), [hex(0x1F5F8B), hex(0x2BA3A3), hex(0x14305A), hex(0x3A7FB0)])
        case .rose: return (hex(0x1E1016), [hex(0xA8456A), hex(0xD98C6A), hex(0x5A2A48), hex(0x8A3A5A)])
        case .slate: return (hex(0x14161A), [hex(0x3A4150), hex(0x5A6678), hex(0x262B34), hex(0x485064)])
        }
    }

    /// Gradient tiles behind sidebar icons.
    static func tile(_ colors: [UInt32]) -> LinearGradient {
        LinearGradient(colors: colors.map { hex($0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
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
