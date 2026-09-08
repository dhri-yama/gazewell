import Foundation

/// Break state machine. Pure logic with an injectable clock so it can be unit tested;
/// the app drives it with a 1s timer calling `tick()`.
public final class BreakScheduler: ObservableObject {
    public enum Phase: Equatable { case working, breaking }

    @Published public private(set) var phase: Phase = .working
    @Published public private(set) var secondsLeft: Int

    public var interval: TimeInterval
    public var duration: TimeInterval
    private let now: () -> Date
    private var deadline: Date

    public init(interval: TimeInterval = 20 * 60, duration: TimeInterval = 20, now: @escaping () -> Date = Date.init) {
        self.interval = interval
        self.duration = duration
        self.now = now
        self.deadline = now().addingTimeInterval(interval)
        self.secondsLeft = Int(interval)
    }

    public func tick() {
        secondsLeft = max(0, Int(deadline.timeIntervalSince(now()).rounded(.up)))
        guard secondsLeft == 0 else { return }
        phase == .working ? startBreak() : endBreak()
    }

    public func startBreak() {
        phase = .breaking
        deadline = now().addingTimeInterval(duration)
        secondsLeft = Int(duration)
    }

    public func endBreak() {
        phase = .working
        deadline = now().addingTimeInterval(interval)
        secondsLeft = Int(interval)
    }
}
