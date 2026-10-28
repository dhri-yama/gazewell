import Foundation

public struct DayStats: Codable, Equatable {
    public var taken = 0, skipped = 0, snoozed = 0
    public init() {}
}

/// Per-day break counts, keyed "yyyy-MM-dd".
public struct Stats: Codable, Equatable {
    public var days: [String: DayStats] = [:]
    public init() {}

    public static func key(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    public mutating func record(_ event: BreakScheduler.Event, on date: Date = Date()) {
        var d = days[Self.key(date)] ?? DayStats()
        switch event { case .taken: d.taken += 1; case .skipped: d.skipped += 1; case .snoozed: d.snoozed += 1 }
        days[Self.key(date)] = d
    }

    public func day(_ date: Date) -> DayStats { days[Self.key(date)] ?? DayStats() }

    /// The last `n` days ending today, oldest first.
    public func recent(_ n: Int, from date: Date = Date(), calendar: Calendar = .current) -> [(date: Date, stats: DayStats)] {
        (0..<n).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: date) }.map { ($0, day($0)) }
    }

    /// Consecutive days (ending today, or yesterday if nothing yet today) with at least one break taken.
    public func streak(from date: Date = Date(), calendar: Calendar = .current) -> Int {
        var d = date, n = 0
        if day(d).taken == 0 { d = calendar.date(byAdding: .day, value: -1, to: d) ?? d }
        while day(d).taken > 0 { n += 1; d = calendar.date(byAdding: .day, value: -1, to: d) ?? d }
        return n
    }

    public var snoozesToday: Int { day(Date()).snoozed }
}
