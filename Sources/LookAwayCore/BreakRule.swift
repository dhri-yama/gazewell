import Foundation

public struct BreakRule: Codable, Identifiable, Equatable {
    public enum Kind: String, Codable { case eyes, posture, blink }

    public var kind: Kind
    public var interval: TimeInterval
    public var duration: TimeInterval
    public var enabled: Bool
    public var message: String

    public var id: String { kind.rawValue }

    public init(kind: Kind, interval: TimeInterval, duration: TimeInterval, enabled: Bool = true, message: String) {
        self.kind = kind; self.interval = interval; self.duration = duration; self.enabled = enabled; self.message = message
    }

    public var title: String {
        switch kind {
        case .eyes: "Rest your eyes"
        case .posture: "Check your posture"
        case .blink: "Blink"
        }
    }

    public static let defaults = [
        BreakRule(kind: .eyes, interval: 20 * 60, duration: 20, message: "Look at something 20 feet away."),
        BreakRule(kind: .posture, interval: 45 * 60, duration: 30, message: "Sit tall and let your shoulders drop."),
        BreakRule(kind: .blink, interval: 10 * 60, duration: 10, enabled: false, message: "Blink slowly, ten times."),
    ]
}
