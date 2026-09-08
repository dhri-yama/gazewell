import Foundation

/// Days and hours in which breaks run. Ranges may wrap past midnight (e.g. 08:00 to 02:00).
public struct OfficeHours: Codable, Equatable {
    public var enabled = false
    public var start = 9 * 60       // minutes after midnight
    public var end = 18 * 60
    public var days: Set<Int> = [2, 3, 4, 5, 6]   // Calendar weekday: 1 = Sunday

    public init() {}

    public func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard enabled else { return true }
        let c = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        let m = (c.hour ?? 0) * 60 + (c.minute ?? 0), day = c.weekday ?? 1
        if start <= end { return days.contains(day) && m >= start && m < end }
        if m >= start { return days.contains(day) }
        if m < end { return days.contains(day == 1 ? 7 : day - 1) }   // after midnight: belongs to the previous day's shift
        return false
    }
}
