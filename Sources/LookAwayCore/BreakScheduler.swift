import Foundation

/// Break state machine. Pure logic with an injectable clock so it can be unit tested;
/// the app drives it with a 1s timer calling `tick()`.
public final class BreakScheduler: ObservableObject {
    public enum Phase: Equatable { case working, headsUp, breaking }

    @Published public private(set) var phase: Phase = .working
    /// Seconds until the next phase change (break start while working/headsUp, break end while breaking).
    @Published public private(set) var secondsLeft: Int

    public var interval: TimeInterval
    public var duration: TimeInterval
    public var headsUpLead: TimeInterval
    private let now: () -> Date
    private var deadline: Date

    public init(interval: TimeInterval = 20 * 60, duration: TimeInterval = 20, headsUpLead: TimeInterval = 30,
                now: @escaping () -> Date = Date.init) {
        self.interval = interval
        self.duration = duration
        self.headsUpLead = headsUpLead
        self.now = now
        self.deadline = now().addingTimeInterval(interval)
        self.secondsLeft = Int(interval)
    }

    public func tick() {
        secondsLeft = max(0, Int(deadline.timeIntervalSince(now()).rounded(.up)))
        switch phase {
        case .working where secondsLeft > 0 && TimeInterval(secondsLeft) <= headsUpLead: phase = .headsUp
        case .working, .headsUp: if secondsLeft == 0 { startBreak() }
        case .breaking: if secondsLeft == 0 { endBreak() }
        }
    }

    /// On-demand breaks pass their own length; scheduled ones use `duration`.
    public func startBreak(duration custom: TimeInterval? = nil) {
        let length = custom ?? duration
        phase = .breaking
        deadline = now().addingTimeInterval(length)
        secondsLeft = Int(length)
    }

    /// Ends a break early or skips the upcoming one; either way the full interval restarts.
    public func endBreak() { postpone(by: interval) }

    /// Pushes the next break out by `seconds`. Short delays re-enter the heads-up lead on the next tick.
    public func postpone(by seconds: TimeInterval) {
        phase = .working
        deadline = now().addingTimeInterval(seconds)
        secondsLeft = Int(seconds)
    }
}
