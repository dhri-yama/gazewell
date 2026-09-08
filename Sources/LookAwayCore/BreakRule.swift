import Foundation

public struct BreakRule: Codable, Identifiable, Equatable {
    public enum Kind: String, Codable { case eyes, posture, blink, planned }

    public var kind: Kind
    public var interval: TimeInterval
    public var duration: TimeInterval
    public var enabled: Bool
    public var message: String
    /// Planned breaks only: label shown on the break, fixed time of day, and a unique id (several can exist).
    public var name: String = ""
    public var minuteOfDay: Int = 12 * 60
    public var uid = UUID().uuidString

    public var id: String { kind == .planned ? uid : kind.rawValue }

    public init(kind: Kind, interval: TimeInterval, duration: TimeInterval, enabled: Bool = true, message: String,
                name: String = "", minuteOfDay: Int = 12 * 60) {
        self.kind = kind; self.interval = interval; self.duration = duration; self.enabled = enabled; self.message = message
        self.name = name; self.minuteOfDay = minuteOfDay
    }

    // decodeIfPresent so settings saved before planned breaks existed still load.
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        kind = try c.decode(Kind.self, forKey: .kind)
        interval = try c.decode(TimeInterval.self, forKey: .interval)
        duration = try c.decode(TimeInterval.self, forKey: .duration)
        enabled = try c.decode(Bool.self, forKey: .enabled)
        message = try c.decode(String.self, forKey: .message)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        minuteOfDay = try c.decodeIfPresent(Int.self, forKey: .minuteOfDay) ?? 12 * 60
        uid = try c.decodeIfPresent(String.self, forKey: .uid) ?? UUID().uuidString
    }

    /// When this rule next comes due after `t`: a fixed clock time for planned breaks, otherwise one interval later.
    public func nextDue(after t: Date) -> Date {
        guard kind == .planned else { return t.addingTimeInterval(interval) }
        let parts = DateComponents(hour: minuteOfDay / 60, minute: minuteOfDay % 60)
        return Calendar.current.nextDate(after: t, matching: parts, matchingPolicy: .nextTime) ?? t.addingTimeInterval(86400)
    }

    public var title: String {
        switch kind {
        case .planned: name.isEmpty ? "Planned break" : name
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
