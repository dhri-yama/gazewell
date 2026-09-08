import SwiftUI

/// Design tokens from docs/design-direction.md ("Dusk window").
enum Theme {
    static let ink = Color(red: 0.106, green: 0.106, blue: 0.227)      // #1B1B3A
    static let dusk = Color(red: 0.290, green: 0.247, blue: 0.561)     // #4A3F8F
    static let horizon = Color(red: 1.0, green: 0.722, blue: 0.549)    // #FFB88C
    static let glow = Color(red: 1.0, green: 0.890, blue: 0.812)       // #FFE3CF
    static let accent = Color(red: 1.0, green: 0.478, blue: 0.349)     // #FF7A59

    static let sky = LinearGradient(
        stops: [.init(color: ink, location: 0), .init(color: dusk, location: 0.78), .init(color: horizon, location: 1)],
        startPoint: .top, endPoint: .bottom)

    static let countdown = Font.system(size: 160, weight: .ultraLight, design: .rounded)
}
